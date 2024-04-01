import Foundation

public typealias ThrowingPendableSpy<Arguments, Success, Failure: Error> = Spy<Arguments, ThrowingPendable<Success, Failure>>

extension Spy {
    /// Create a throwing pendable Spy that is pre-stubbed to return a pending that will block for a bit before returning success.
    public convenience init<Success, Failure: Error>(pendingSuccess: Success) where Returning == ThrowingPendable<Success, Failure> {
        self.init(.pending(fallback: .success(pendingSuccess)))
    }

    /// Create a throwing pendable Spy that is pre-stubbed to return a pending that will block for a bit before returning Void.
    public convenience init<Failure: Error>() where Returning == ThrowingPendable<(), Failure> {
        self.init(.pending(fallback: .success(())))
    }

    /// Create a throwing pendable Spy that is pre-stubbed to return a pending that will block for a bit before throwing an error.
    public convenience init<Success, Failure: Error>(pendingFailure: Failure) where Returning == ThrowingPendable<Success, Failure> {
        self.init(.pending(fallback: .failure(pendingFailure)))
    }

    /// Create a throwing pendable Spy that is pre-stubbed to return a finished & successful value.
    public convenience init<Success, Failure: Error>(success: Success) where Returning == ThrowingPendable<Success, Failure> {
        self.init(.finished(.success(success)))
    }

    /// Create a throwing pendable Spy that is pre-stubbed to throw the given error.
    public convenience init<Success, Failure: Error>(failure: Failure) where Returning == ThrowingPendable<Success, Failure> {
        self.init(.finished(.failure(failure)))
    }
}

extension Spy {
    /// Update the pendable Spy's stub to be in a pending state.
    public func stub<Success, Failure: Error>(pendingSuccess: Success) where Returning == ThrowingPendable<Success, Failure> {
        self.stub(.pending(fallback: .success(pendingSuccess)))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stub<Success, Failure: Error>(pendingFailure: Failure) where Returning == ThrowingPendable<Success, Failure> {
        self.stub(.pending(fallback: .failure(pendingFailure)))
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
