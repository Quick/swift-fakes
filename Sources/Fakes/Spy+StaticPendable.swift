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
    /// Records the arguments and handles the result according to ``Pendable/resolve(delay:)-hvhg``.
    ///
    /// - parameter arguments: The arguments to record.
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// returning the `pendingFallback`. If the `Pendable` is .finished, then this value is ignored.
    ///
    /// Because of how ``Pendable`` currently works, you must provide a fallback option for when the Pendable is pending.
    /// Alternatively, you can use the throwing version of `callAsFunction`, which will thorw an error instead of returning the fallback.
    public func callAsFunction<Value>(
        _ arguments: Arguments,
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Returning == Pendable<Value> {
        return await call(arguments).resolve(delay: pendingDelay)
    }

    /// Records that a call was made and handles the result according to ``Pendable/resolve(delay:)-hvhg``.
    ///
    /// - parameter pendingDelay: The amount of seconds to delay if the `Pendable` is .pending before
    /// returning the `pendingFallback`. If the `Pendable` is .finished, then this value is ignored.
    ///
    /// Because of how ``Pendable`` currently works, you must provide a fallback option for when the Pendable is pending.
    /// Alternatively, you can use the throwing version of `callAsFunction`, which will thorw an error instead of returning the fallback.
    public func callAsFunction<Value>(
        pendingDelay: TimeInterval = PendableDefaults.delay
    ) async -> Value where Arguments == Void, Returning == Pendable<Value> {
        return await call(()).resolve(delay: pendingDelay)
    }
}
