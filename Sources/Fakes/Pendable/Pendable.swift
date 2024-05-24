import Foundation

/// A way to type-erase Pendable, specifically just for resolving with the fallback.
///
/// This is meant to be used by ```Spy``` as part of changing the stub in order to quickly resolve pending calls.
public protocol ResolvableWithFallback {
    func resolveWithFallback()
}

/// Pendable is a safe way to represent the 2 states that an asynchronous call can be in
///
/// - `pending`, the state while waiting for the call to finish.
/// - `finished`, the state once the call has finished.
///
/// Pendable allows you to finish a pending call after it's been made. This makes Pendable behave very
/// similarly to something like Combine's `Future`.
///
/// - Note: The reason you must provide a fallback value is to prevent deadlock when used in test.
/// Unlike something like Combine's `Future`, it is very often the case that you will write
/// tests which end while the call is in the pending state. If you do this too much, then your
/// entire test suite will deadlock, as Swift Concurrency works under the assumption that
/// blocked tasks of work will always eventually be unblocked. To help prevent this, pending calls
/// are always resolved with the fallback after a given delay. You can also manually force this
/// by calling the ``Pendable\resolveWithFallback()`` method.
public final class Pendable<Value: Sendable>: @unchecked Sendable, ResolvableWithFallback {
    private enum State: Sendable {
        case pending
        case finished(Value)
    }

    private let lock = NSRecursiveLock()
    private var state = State.pending

    private var inProgressCalls = [UnsafeContinuation<Value, Never>]()

    private let fallbackValue: Value

    private var currentValue: Value {
        switch state {
        case .pending:
            return fallbackValue
        case .finished(let value):
            return value
        }
    }

    deinit {
        resolveWithFallback()
    }

    /// Initializes a new `Pendable`, in a pending state, with the given fallback value.
    public init(fallbackValue: Value) {
        self.fallbackValue = fallbackValue
    }

    /// Gets the value for the `Pendable`, possibly waiting until it's resolved.
    ///
    /// - parameter fallbackDelay: The amount of time (in seconds) to wait until the call returns
    /// the fallback value. This is only used when the `Pendable` is in a pending state.
    public func call(fallbackDelay: TimeInterval = PendableDefaults.delay) async -> Value {
        return await withTaskGroup(of: Value.self) { taskGroup in
            taskGroup.addTask { await self.handleCall() }
            taskGroup.addTask { await self.resolveAfterDelay(fallbackDelay) }

            guard let value = await taskGroup.next() else {
                fatalError("There were no tasks in the task group. This should not ever happen.")
            }
            taskGroup.cancelAll()
            return value

        }
    }

    /// Resolves the `Pendable` with the fallback value.
    ///
    /// - Note: This no-ops if the pendable is already in a resolved state.
    /// - Note: This is called for when you re-stub a `Spy` in ``Spy/stub(_:)``
    public func resolveWithFallback() {
        lock.lock()
        defer { lock.unlock() }

        if case .pending = state {
            resolve(with: fallbackValue)
        }
    }

    /// Resolves the `Pendable` with the given value.
    ///
    /// Even if the pendable is already resolves, this resets the resolved value to the given value.
    public func resolve(with value: Value) {
        lock.lock()
        defer { lock.unlock() }
        state = .finished(value)
        inProgressCalls.forEach {
            $0.resume(returning: value)
        }
        inProgressCalls = []

    }

    /// Resolves any outstanding calls to the `Pendable` with the current value,
    /// and resets it back into the pending state.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        inProgressCalls.forEach {
            $0.resume(returning: currentValue)
        }
        inProgressCalls = []
        state = .pending
    }

    // MARK: - Private
    private func handleCall() async -> Value {
        return await withUnsafeContinuation { continuation in
            lock.lock()
            defer { lock.unlock() }
            switch state {
            case .pending:
                inProgressCalls.append(continuation)
            case .finished(let value):
                continuation.resume(returning: value)
            }
        }
    }

    private func resolveAfterDelay(_ delay: TimeInterval) async -> Value {
        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        } catch {}
        resolveWithFallback()
        return fallbackValue
    }
}

@available(*, deprecated, renamed: "ThrowingPendable")
public typealias ThrowingDynamicPendable<Success, Failure: Error> = Pendable<Result<Success, Failure>>

public typealias ThrowingPendable<Success, Failure: Error> = Pendable<Result<Success, Failure>>

extension Pendable {
    /// Gets or throws value for the `Pendable`, possibly waiting until it's resolved.
    ///
    /// - parameter resolveDelay: The amount of time (in seconds) to wait until the call returns
    /// the fallback value. This is only  used when the `Pendable` is in a pending state.
    public func call<Success, Failure: Error>(
        resolveDelay: TimeInterval = PendableDefaults.delay
    ) async throws -> Success where Value == Result<Success, Failure> {
        try await call(fallbackDelay: resolveDelay).get()
    }
}

extension Pendable {
    /// Creates a new finished `Pendable` pre-resolved with the given value.
    public static func finished(_ value: Value) -> Pendable<Value> {
        let pendable = Pendable(fallbackValue: value)
        pendable.resolve(with: value)
        return pendable
    }

    /// Creates a new finished `Pendable` pre-resolved  with Void.
    public static func finished() -> Pendable where Value == Void {
        return Pendable.finished(())
    }
}

extension Pendable {
    /// Creates a new pending `Pendable` with the given fallback value.
    public static func pending(fallback: Value) -> Pendable<Value> {
        Pendable(fallbackValue: fallback)
    }

    /// Creates a new pending `Pendable` with a fallback value of Void.
    public static func pending() -> Pendable<Value> where Value == Void {
        Pendable(fallbackValue: ())
    }

    /// Creates a new pending `Pendable` with a fallback value of nil.
    public static func pending<Wrapped>() -> Pendable<Value> where Value == Optional<Wrapped> {
        // swiftlint:disable:previous syntactic_sugar
        Pendable(fallbackValue: nil)
    }

    /// Creatse a new pending `Pendable` with a fallback value of an error.
    public static func pending<Success>() -> Pendable<Value> where Value == Result<Success, Error> {
        Pendable(fallbackValue: Result<Success, Error>.failure(PendableDefaultError()))
    }
}

/// An error that can be used as a default error for ``Pendable`` when returning a `Result<..., Error>`.
public struct PendableDefaultError: Error, Sendable {}
