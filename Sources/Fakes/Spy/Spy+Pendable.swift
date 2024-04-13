import Foundation

public typealias PendableSpy<Arguments, Value> = Spy<Arguments, Pendable<Value>>

extension Spy {
    /// Create a pendable Spy that is pre-stubbed to return return a a pending that will block for a bit before returning the fallback value.
    public convenience init<Value>(pendingFallback: Value) where Returning == Pendable<Value> {
        self.init(.pending(fallback: pendingFallback))
    }

    /// Create a pendable Spy that is pre-stubbed to return return a a pending that will block for a bit before returning Void.
    public convenience init() where Returning == Pendable<Void> {
        self.init(.pending(fallback: ()))
    }

    /// Create a pendable Spy that is pre-stubbed to return a finished value.
    public convenience init<Value>(finished: Value) where Returning == Pendable<Value> {
        self.init(.finished(finished))
    }
}

extension Spy {
    /// Update the pendable Spy's stub to be in a pending state.
    public func stub<Value>(pendingFallback: Value) where Returning == Pendable<Value> {
        self.stub(.pending(fallback: pendingFallback))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stubPending() where Returning == Pendable<Void> {
        self.stub(.pending(fallback: ()))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stubPending<Wrapped>() where Returning == Pendable<Optional<Wrapped>> {
        // swiftlint:disable:previous syntactic_sugar
        self.stub(.pending(fallback: nil))
    }

    /// Update the pendable Spy's stub to return the given value.
    ///
    /// - parameter finished: The value to return  when `callAsFunction` is called.
    public func stub<Value>(finished: Value) where Returning == Pendable<Value> {
        self.stub(.finished(finished))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stubFinished() where Returning == Pendable<Void> {
        self.stub(.finished(()))
    }
}

extension Spy {
    /// Records the arguments and handles the result according to ``Pendable/call(fallbackDelay:)``.
    ///
    /// - parameter arguments: The arguments to record.
    /// - parameter fallbackDelay: The amount of seconds to delay if the `Pendable` is pending before
    /// returning its fallback value. If the `Pendable` is finished, then this value is ignored.
    public func callAsFunction<Value>(
        _ arguments: Arguments,
        fallbackDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Returning == Pendable<Value> {
        return await call(arguments).call(fallbackDelay: fallbackDelay)
    }

    /// Records that a call was made and handles the result according to ``Pendable/call(fallbackDelay:)``.
    ///
    /// - parameter fallbackDelay: The amount of seconds to delay if the `Pendable` is pending before
    /// returning its fallback value. If the `Pendable` is finished, then this value is ignored.
    public func callAsFunction<Value>(
        fallbackDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Arguments == Void, Returning == Pendable<Value> {
        return await call(()).call(fallbackDelay: fallbackDelay)
    }
}
