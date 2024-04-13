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

    /// Create a Spy that returns nil
    public convenience init<Wrapped>() where Returning == Optional<Wrapped> {
        // swiftlint:disable:previous syntactic_sugar
        self.init(nil)
    }

    /// Clear out existing call records.
    ///
    /// This removes all previously recorded calls from the spy. It does not otherwise
    /// mutate the spy.
    public func clearCalls() {
        lock.lock()
        _calls = []
        lock.unlock()
    }

    // MARK: Stubbing
    /// Update the Spy's stub to return the given value.
    ///
    /// - parameter value: The value to return when `callAsFunction()` is called.
    public func stub(_ value: Returning) {
        lock.lock()

        if let resolvable = _stub as? ResolvableWithFallback {
            resolvable.resolveWithFallback()
        }
        _stub = value
        lock.unlock()
    }

    internal func call(_ arguments: Arguments) -> Returning {
        lock.lock()
        defer { lock.unlock() }

        _calls.append(arguments)

        return _stub
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
}

extension Spy {
    public func resolveStub<Value>(with value: Value) where Returning == Pendable<Value> {
        lock.lock()
        defer { lock.unlock() }
        _stub.resolve(with: value)
    }
}

extension Spy: @unchecked Sendable where Arguments: Sendable, Returning: Sendable {}
