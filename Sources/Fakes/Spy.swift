import Foundation

/// A Spy is a test double for recording calls to methods, and returning stubbed results.
///
/// Spies should be used to verify that Fakes are called correctly, and to provide pre-stubbed values
/// that the Fake returns to the caller.
public final class Spy<Arguments, Returning> {
    private let lock = NSRecursiveLock()

    private var _calls: [Arguments] = []
    public var calls: [Arguments] {
        lock.lock()
        defer { lock.unlock() }
        return _calls
    }

    private var _stub: Returning

    // MARK: - Initializers
    /// Create a Spy with the given stubbed value.
    public init(_ stub: Returning) {
        _stub = stub
    }

    /// Create a Spy that returns Void
    public convenience init() where Returning == Void {
        self.init(())
    }

    // MARK: Stubbing
    /// Update the Spy's stub to return the given value.
    ///
    /// - parameter value: The value to return when `callAsFunction()` is called.
    public func stub(_ value: Returning) {
        lock.lock()
        _stub = value
        lock.unlock()
    }

    fileprivate func call(_ arguments: Arguments) -> Returning {
        lock.lock()
        defer { lock.unlock() }

        _calls.append(arguments)

        return _stub
    }
}

extension Spy {
    // MARK: - Returning Result
    /// Create a throwing Spy that is pre-stubbed with some Success value.
    public convenience init<Success, Failure: Error>(success: Success) where Returning == Result<Success, Failure> {
        self.init(.success(success))
    }

    /// Create a throwing Spy that is pre-stubbed with a Void Success value
    public convenience init<Failure: Error>() where Returning == Result<Void, Failure> {
        self.init(.success(()))
    }

    /// Create a throwing Spy that is pre-stubbed with some Failure error.
    public convenience init<Success, Failure: Error>(failure: Failure) where Returning == Result<Success, Failure> {
        self.init(.failure(failure))
    }

    /// Update the throwing Spy's stub to be successful, with the given value.
    ///
    /// - parameter success: The success state to set the stub to, returned when `callAsFunction` is called.
    public func stub<Success, Failure: Error>(success: Success) where Returning == Result<Success, Failure> {
        self.stub(.success(success))
    }

    /// Update the throwing Spy's stub to be successful, with the given value.
    ///
    /// - parameter success: The success state to set the stub to, returned when `callAsFunction` is called.
    public func stub<Failure: Error>() where Returning == Result<Void, Failure> {
        self.stub(.success(()))
    }

    /// Update the throwing Spy's stub to throw the given error.
    ///
    /// - parameter failure: The error to throw when `callAsFunction` is called.
    public func stub<Success, Failure: Error>(failure: Failure) where Returning == Result<Success, Failure> {
        self.stub(.failure(failure))
    }

}

extension Spy {
    // MARK: - Returning Pendable
    /// Create a pendable Spy that is pre-stubbed to return `.pending`.
    public convenience init<Value>() where Returning == Pendable<Value> {
        self.init(.pending)
    }

    /// Create a pendable Spy that is pre-stubbed to return `.finished(finished)`.
    public convenience init<Value>(finished: Value) where Returning == Pendable<Value> {
        self.init(.finished(finished))
    }

    /// Create a throwing pendable Spy that is pre-stubbed to return a finish & successful value.
    public convenience init<Success, Failure: Error>(success: Success) where Returning == ThrowingPendable<Success, Failure> {
        self.init(.finished(.success(success)))
    }

    /// Create a throwing pendable Spy that is pre-stubbed to throw the given error.
    public convenience init<Success, Failure: Error>(failure: Failure) where Returning == ThrowingPendable<Success, Failure> {
        self.init(.finished(.failure(failure)))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stub<Value>() where Returning == Pendable<Value> {
        self.stub(.pending)
    }

    /// Update the pendable Spy's stub to return the given value.
    ///
    /// - parameter finished: The value to return  when `callAsFunction` is called.
    public func stub<Value>(finished: Value) where Returning == Pendable<Value> {
        self.stub(.finished(finished))
    }

    /// Update the throwing pendable Spy's stub to be successful, with the given value.
    ///
    /// - parameter success: The value to return when `callAsFunction` is called.
    public func stub<Success, Failure: Error>(success: Success) where Returning == ThrowingPendable<Success, Failure> {
        self.stub(.finished(.success(success)))
    }

    /// Update the throwing pendable Spy's stub to throw the given error.
    ///
    /// - parameter failure: The error to throw when `callAsFunction` is called.
    public func stub<Success, Failure: Error>(failure: Failure) where Returning == ThrowingPendable<Success, Failure> {
        self.stub(.finished(.failure(failure)))
    }
}

extension Spy {
    // MARK: - Calling
    /// Records the arguments and returns the value stubbed in the initializer, or using one of the `stub()` methods.
    public func callAsFunction(_ arguments: Arguments) -> Returning {
        return call(arguments)
    }

    /// Records that a call was made and returns the value stubbed in the initializer, or using one of the `stub()` methods.
    public func callAsFunction() -> Returning where Arguments == Void {
        return call(())
    }

    // Returning == Result
    /// Records the arguments and returns the success (or throws an error), as defined by the current stub.
    public func callAsFunction<Success, Failure: Error>(_ arguments: Arguments) throws -> Success where Returning == Result<Success, Failure> {
        return try call(arguments).get()
    }

    /// Records that a call was made and returns the success (or throws an error), as defined by the current stub.
    public func callAsFunction<Success, Failure: Error>() throws -> Success where Arguments == Void, Returning == Result<Success, Failure> {
        return try call(()).get()
    }

    // Returning == Pendable
    /// Records the arguments and handles the result according to ``Pendable.call(delay:)``.
    ///
    /// - parameter arguments: The arguments to record.
    /// - parameter pendingFallback: The value to return if the `Pendable` is .pending.
    /// If the `Pendable` is .finished, then this value is ignored.
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// returning the `pendingFallback`. If the `Pendable` is .finished, then this value is ignored.
    ///
    /// Because of how ``Pendable`` currently works, you must provide a fallback option for when the Pendable is pending.
    /// Alternatively, you can use the throwing version of `callAsFunction`, which will thorw an error instead of returning the fallback.
    public func callAsFunction<Value>(
        _ arguments: Arguments,
        pendingFallback: Value,
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Returning == Pendable<Value> {
        return await call(arguments).resolve(pendingFallback: pendingFallback, delay: pendingDelay)
    }

    /// Records that a call was made and handles the result according to ``Pendable.call(delay:)``.
    ///
    /// - parameter pendingFallback: The value to return if the `Pendable` is .pending.
    /// If the `Pendable` is .finished, then this value is ignored.
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// returning the `pendingFallback`. If the `Pendable` is .finished, then this value is ignored.
    ///
    /// Because of how ``Pendable`` currently works, you must provide a fallback option for when the Pendable is pending.
    /// Alternatively, you can use the throwing version of `callAsFunction`, which will thorw an error instead of returning the fallback.
    public func callAsFunction<Value>(
        pendingFallback: Value,
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Arguments == Void, Returning == Pendable<Value> {
        return await call(()).resolve(pendingFallback: pendingFallback, delay: pendingDelay)
    }

    /// Records the arguments and handles the result according to ``Pendable.call(delay:)``.
    ///
    /// - parameter arguments: The arguments to record.
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// throwing a `PendableInProgressError`. If the `Pendable` is .finished, then this value is ignored.
    public func callAsFunction<Value>(
        _ arguments: Arguments,
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async throws -> Value where Returning == Pendable<Value> {
        return try await call(arguments).resolve(delay: pendingDelay)
    }

    /// Records that a call was made and handles the result according to ``Pendable.call(delay:)``.
    ///
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// throwing a `PendableInProgressError`. If the `Pendable` is .finished, then this value is ignored.
    public func callAsFunction<Value>(
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async throws -> Value where Arguments == Void, Returning == Pendable<Value> {
        return try await call(()).resolve(delay: pendingDelay)
    }

    // Returning == ThrowingPendable
    /// Records the arguments and handles the result according to ``Pendable.call(delay:)``.
    /// This call then throws or returns the success, according to `Result.get`.
    ///
    /// - parameter arguments: The arguments to record.
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// throwing a `PendableInProgressError`. If the `Pendable` is .finished, then this value is ignored.
    public func callAsFunction<Success, Failure: Error>(
        _ arguments: Arguments,
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async throws -> Success where Returning == ThrowingPendable<Success, Failure> {
        return try await call(arguments).resolve(delay: pendingDelay)
    }

    /// Records that a call was made and handles the result according to ``Pendable.call(delay:)``.
    /// This call then throws or returns the success, according to `Result.get`.
    ///
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// throwing a `PendableInProgressError`. If the `Pendable` is .finished, then this value is ignored.
    public func callAsFunction<Success, Failure: Error>(
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async throws -> Success where Arguments == Void, Returning == ThrowingPendable<Success, Failure> {
        return try await call(()).resolve(delay: pendingDelay)
    }
}

extension Spy: @unchecked Sendable where Arguments: Sendable, Returning: Sendable {}

public typealias ThrowingSpy<Arguments, Success, Failure: Error> = Spy<Arguments, Result<Success, Failure>>
public typealias PendableSpy<Arguments, Value> = Spy<Arguments, Pendable<Value>>
public typealias ThrowingPendableSpy<Arguments, Success, Failure: Error> = Spy<Arguments, ThrowingPendable<Success, Failure>>
