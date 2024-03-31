import Foundation

protocol ResolvableWithFallback {
    func resolveWithFallback()
}

public final class DynamicPendable<Value: Sendable>: @unchecked Sendable, ResolvableWithFallback {
    private enum State: Sendable {
        case pending
        case finished(Value)
    }

    private let lock = NSRecursiveLock()
    private var state = State.pending

    private var inProgressCalls = [UnsafeContinuation<Value, Never>]()

    private let fallbackValue: Value

    deinit {
        resolveWithFallback()
    }

    public static func finished(_ value: Value) -> DynamicPendable<Value> {
        let pendable = DynamicPendable(fallbackValue: value)
        pendable.resolve(with: value)
        return pendable
    }

    public init(fallbackValue: Value) {
        self.fallbackValue = fallbackValue
    }

    public convenience init() where Value == Void {
        self.init(fallbackValue: ())
    }

    public convenience init<Wrapped>() where Value == Optional<Wrapped> {
        self.init(fallbackValue: nil)
    }

    public func call() async -> Value {
        return await withUnsafeContinuation { continuation in
            lock.lock()
            defer { lock.unlock() }
            switch state {
            case .pending:
                recordContinuation(continuation)
            case .finished(let value):
                continuation.resume(returning: value)
            }
        }
    }

    public func call<Success, Failure: Error>() async throws -> Success where Value == Result<Success, Failure> {
        try await call().get()
    }

    public func resolveWithFallback() {
        resolve(with: fallbackValue)
    }

    public func resolve(with value: Value) {
        lock.lock()
        self.state = .finished(value)
        self.inProgressCalls.forEach {
            $0.resume(returning: value)
        }
        self.inProgressCalls = []

        lock.unlock()
    }

    private func recordContinuation(_ continuation: UnsafeContinuation<Value, Never>) {
        self.inProgressCalls.append(continuation)
    }
}
