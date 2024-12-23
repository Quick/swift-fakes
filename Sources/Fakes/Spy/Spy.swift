import Foundation

/// A Spy is a test double for recording calls to methods, and returning stubbed results.
///
/// Spies should be used to verify that Fakes are called correctly, and to provide pre-stubbed values
/// that the Fake returns to the caller.
public final class Spy<Arguments, Returning> {
    public typealias Stub = DynamicResult<Arguments, Returning>.Stub

    private let lock = NSRecursiveLock()

    private var _calls: [Arguments] = []
    public var calls: [Arguments] {
        lock.lock()
        defer { lock.unlock() }
        return _calls
    }

    private var _stub: DynamicResult<Arguments, Returning>

    // MARK: - Initializers
    /// Create a Spy with the given stubbed values.
    public init(_ value: Returning, _ values: Returning...) {
        _stub = DynamicResult(Array(value, values))
    }

    internal init(_ values: [Returning]) {
        _stub = DynamicResult(values)
    }

    public init(_ closure: @escaping @Sendable (Arguments) -> Returning) {
        _stub = DynamicResult(closure)
    }

    public init(_ stub: Stub, _ stubs: Stub...) {
        _stub = DynamicResult(Array(stub, stubs))
    }

    internal init(_ stubs: [Stub]) {
        _stub = DynamicResult(stubs)
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
        defer { lock.unlock () }
        _calls = []
    }

    // MARK: Stubbing
    /// Replaces the Spy's stubs with the given values.
    ///
    /// - parameter value: The first value to return when `callAsFunction()` is called.
    /// - parameter values: The list of other values (in order) to return when `callAsFunction()` is called.
    ///
    /// - Note: This resolves any pending Pendables during replacement.
    public func stub(_ value: Returning, _ values: Returning...) {
        stub(Array(value, values))
    }

    internal func stub(_ values: [Returning]) {
        lock.lock()
        defer { lock.unlock () }
        _stub.replace(values)
    }

    /// Replaces the Spy's stubs with the given closure.
    ///
    /// - parameter closure: The closure to call with the arguments when `callAsFunction()` is called.
    ///
    /// - Note: This resolves any pending Pendables during replacement.
    public func stub(_ closure: @escaping @Sendable (Arguments) -> Returning) {
        lock.lock()
        defer { lock.unlock () }
        _stub.replace(closure)
    }

    /// Replace the Spy's stubs with the new list of stubs
    ///
    /// - parameter stub: The first stub to call when `callAsFunction()` is called.
    /// - parameter stubs: The list of other stubs (in order) to return when `callAsFunction()` is called.
    ///
    /// - Note: This resolves any pending Pendables during replacement.
    public func replace(
        _ stub: Stub,
        _ stubs: Stub...
    ) {
        lock.lock()
        defer { lock.unlock () }
        _stub.replace(Array(stub, stubs))
    }

    /// Append the values to the Spy's stubs
    ///
    /// - parameter value: The first value to append to the list of stubs
    /// - parameter values: The remaining values to append to the list of stubs
    public func append(_ value: Returning, _ values: Returning...) {
        lock.lock()
        defer { lock.unlock () }
        _stub.append(Array(value, values))
    }

    /// Append the closure to the list of Spy's stubs
    ///
    /// - parameter closure: The new closure to call at the end of the list of stubs
    public func append(_ closure: @escaping @Sendable (Arguments) -> Returning) {
        lock.lock()
        defer { lock.unlock () }
        _stub.append(closure)
    }

    /// Append the stubs to the list of stubs.
    ///
    /// - parameter value: The first stub to append to the list of stubs
    /// - parameter values: The remaining stubs to append to the list of stubs
    public func append(
        _ stub: Stub,
        _ stubs: Stub...
    ) {
        lock.lock()
        defer { lock.unlock () }
        _stub.append(Array(stub, stubs))
    }

    internal func call(_ arguments: Arguments) -> Returning {
        lock.lock()
        defer { lock.unlock() }

        _calls.append(arguments)

        return _stub.call(arguments)
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
        _stub.stubHistory.forEach {
            $0.resolve(with: value)
        }
    }
}

extension Spy: @unchecked Sendable where Arguments: Sendable, Returning: Sendable {}
