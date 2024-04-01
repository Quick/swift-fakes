public typealias ThrowingSpy<Arguments, Success, Failure: Error> = Spy<Arguments, Result<Success, Failure>>

extension Spy {
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
}

extension Spy {
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
    /// Records the arguments and returns the success (or throws an error), as defined by the current stub.
    public func callAsFunction<Success, Failure: Error>(_ arguments: Arguments) throws -> Success where Returning == Result<Success, Failure> {
        return try call(arguments).get()
    }

    /// Records that a call was made and returns the success (or throws an error), as defined by the current stub.
    public func callAsFunction<Success, Failure: Error>() throws -> Success where Arguments == Void, Returning == Result<Success, Failure> {
        return try call(()).get()
    }
}
