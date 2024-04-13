import Foundation

public typealias PendableSpy<Arguments, Value> = Spy<Arguments, DynamicPendable<Value>>

extension Spy {
    /// Create a pendable Spy that is pre-stubbed to return return a a pending that will block for a bit before returning the fallback value.
    public convenience init<Value>(pendingFallback: Value) where Returning == DynamicPendable<Value> {
        self.init(.pending(fallback: pendingFallback))
    }

    /// Create a pendable Spy that is pre-stubbed to return return a a pending that will block for a bit before returning Void.
    public convenience init() where Returning == DynamicPendable<Void> {
        self.init(.pending(fallback: ()))
    }

    /// Create a pendable Spy that is pre-stubbed to return a finished value.
    public convenience init<Value>(finished: Value) where Returning == DynamicPendable<Value> {
        self.init(.finished(finished))
    }
}

extension Spy {
    /// Update the pendable Spy's stub to be in a pending state.
    public func stub<Value>(pendingFallback: Value) where Returning == DynamicPendable<Value> {
        self.stub(.pending(fallback: pendingFallback))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stubPending() where Returning == DynamicPendable<Void> {
        self.stub(.pending(fallback: ()))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stubPending<Wrapped>() where Returning == DynamicPendable<Optional<Wrapped>> {
        self.stub(.pending(fallback: nil))
    }

    /// Update the pendable Spy's stub to return the given value.
    ///
    /// - parameter finished: The value to return  when `callAsFunction` is called.
    public func stub<Value>(finished: Value) where Returning == DynamicPendable<Value> {
        self.stub(.finished(finished))
    }

    /// Update the pendable Spy's stub to be in a pending state.
    public func stubFinished() where Returning == DynamicPendable<Void> {
        self.stub(.finished(()))
    }
}

extension Spy {
    /// Records the arguments and handles the result according to ``Pendable/resolve(delay:)-hvhg``.
    ///
    /// - parameter arguments: The arguments to record.
    /// - parameter fallbackDelay: The amount of seconds to delay if the `Pendable` is pending before
    /// returning its fallback value. If the `Pendable` is finished, then this value is ignored.
    public func callAsFunction<Value>(
        _ arguments: Arguments,
        fallbackDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Returning == DynamicPendable<Value> {
        return await call(arguments).call(fallbackDelay: fallbackDelay)
    }

    /// Records that a call was made and handles the result according to ``Pendable/resolve(delay:)-hvhg``.
    ///
    /// - parameter fallbackDelay: The amount of seconds to delay if the `Pendable` is pending before
    /// returning its fallback value. If the `Pendable` is finished, then this value is ignored.
    public func callAsFunction<Value>(
        fallbackDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Arguments == Void, Returning == DynamicPendable<Value> {
        return await call(()).call(fallbackDelay: fallbackDelay)
    }
}
