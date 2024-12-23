public typealias ThrowingSpy<Arguments, Success, Failure: Error> = Spy<Arguments, Result<Success, Failure>>

extension Spy {
    /// Create a throwing Spy that is pre-stubbed with some Success values.
    public convenience init<Success, Failure: Error>(success: Success, _ successes: Success...) where Returning == Result<Success, Failure> {
        self.init(Array(success, successes).map { .success($0) })
    }

    /// Create a throwing Spy that is pre-stubbed with a Void Success value
    public convenience init<Failure: Error>() where Returning == Result<Void, Failure> {
        self.init(.success(()))
    }

    /// Create a throwing Spy that is pre-stubbed with some Failure error.
    public convenience init<Success, Failure: Error>(failure: Failure) where Returning == Result<Success, Failure> {
        self.init(.failure(failure))
    }

    public convenience init<Success>() where Returning == Result<Success, Error> {
        self.init(.failure(EmptyError()))
    }

#if swift(>=6.0)
    public convenience init<Success, Failure: Error>(_ closure: @escaping @Sendable (Arguments) throws(Failure) -> Success) where Returning == Result<Success, Failure> {
        self.init { args in
            do {
                return .success(try closure(args))
            } catch let error {
                return .failure(error)
            }
        }
    }
#else
    public convenience init<Success>(_ closure: @escaping @Sendable (Arguments) throws -> Success) where Returning == Result<Success, Swift.Error> {
        self.init { args in
            do {
                return .success(try closure(args))
            } catch let error {
                return .failure(error)
            }
        }
    }
#endif
}

extension Spy {
    /// Update the throwing Spy's stub to be successful, with the given value.
    ///
    /// - parameter success: The success state to set the stub to, returned when `callAsFunction` is called.
    public func stub<Success, Failure: Error>(success: Success, _ successes: Success...) where Returning == Result<Success, Failure> {
        self.stub(Array(success, successes).map { .success($0) })
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

#if swift(>=6.0)
    public func stub<Success, Failure: Error>(_ closure: @escaping @Sendable (Arguments) throws(Failure) -> Success) where Returning == Result<Success, Failure> {
        self.stub { args in
            do {
                return .success(try closure(args))
            } catch let error {
                return .failure(error)
            }
        }
    }
#else
    public func stub<Success>(_ closure: @escaping @Sendable (Arguments) throws -> Success) where Returning == Result<Success, Swift.Error> {
        self.stub { args in
            do {
                return .success(try closure(args))
            } catch let error {
                return .failure(error)
            }
        }
    }
#endif
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
