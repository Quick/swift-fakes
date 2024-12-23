import Foundation

/// A DynamicResult is specifically for mocking out when multiple results for a call can happen.
///
/// DynamicResult is intended to be an implementation detail of ``Spy``,
/// but is exposed publicly to be composed with other types as desired.
public final class DynamicResult<Arguments, Returning> {
    /// A value or closure to be used by the DynamicResult
    public enum Stub {
        /// A static value
        case value(Returning)
        /// A closure to be called.
        case closure(@Sendable (Arguments) -> Returning)

        /// Call the stub.
        /// If the stub is a `.value`, then return the value.
        /// If the stub is a `.closure`, then call the closure with the arguments.
        func call(_ arguments: Arguments) -> Returning {
            switch self {
            case .value(let returning):
                return returning
            case .closure(let closure):
                return closure(arguments)
            }
        }
    }

    private let lock = NSRecursiveLock()
    private var stubs: [Stub]

    private var _stubHistory: [Returning] = []
    var stubHistory: [Returning] {
        lock.lock()
        defer { lock.unlock () }
        return _stubHistory
    }

    /// Create a new DynamicResult stubbed to return the values in the given order.
    /// That is, given `DynamicResult<Void, Int>(1, 2, 3)`,
    /// if you call `.call` 5 times, you will get back `1, 2, 3, 3, 3`.
    public init(_ value: Returning, _ values: Returning...) {
        self.stubs = Array(value, values).map { Stub.value($0) }
    }

    internal init(_ values: [Returning]) {
        self.stubs = values.map { Stub.value($0) }
    }

    /// Create a new DynamicResult stubbed to call the given closure.
    public init(_ closure: @escaping @Sendable (Arguments) -> Returning) {
        self.stubs = [.closure(closure)]
    }

    /// Create a new DynamicResult stubbed to call the given stubs.
    public init(_ stub: Stub, _ stubs: Stub...) {
        self.stubs = Array(stub, stubs)
    }

    internal init(_ stubs: [Stub]) {
        self.stubs = stubs
    }

    /// Call the DynamicResult, returning the next stub in the list of stubs.
    public func call(_ arguments: Arguments) -> Returning {
        lock.lock()
        defer { lock.unlock () }
        let value = nextStub().call(arguments)
        _stubHistory.append(value)
        return value
    }

    /// Call the DynamicResult, returning the next stub in the list of stubs.
    public func call() -> Returning where Arguments == Void {
        call(())
    }

    /// Replace the stubs with the new static values
    public func replace(_ value: Returning, _ values: Returning...) {
        replace(Array(value, values))
    }

    /// Replace the stubs with the new static values
    internal func replace(_ values: [Returning]) {
        lock.lock()
        defer { lock.unlock () }
        self.resolvePendables()
        self.stubs = values.map { .value($0) }
    }

    /// Replace the stubs with the new closure.
    public func replace(_ closure: @escaping @Sendable (Arguments) -> Returning) {
        lock.lock()
        defer { lock.unlock () }
        self.resolvePendables()
        self.stubs = [.closure(closure)]
    }

    /// Replace the stubs with the new list of stubs
    public func replace(_ stub: Stub, _ stubs: Stub...) {
        lock.lock()
        defer { lock.unlock () }
        self.resolvePendables()
        self.stubs = Array(stub, stubs)
    }

    /// Replace the stubs with the new list of stubs
    internal func replace(_ stubs: [Stub]) {
        lock.lock()
        defer { lock.unlock () }
        self.resolvePendables()
        self.stubs = stubs
    }

    /// Append the values to the list of stubs.
    public func append(_ value: Returning, _ values: Returning...) {
        append(Array(value, values))
    }

    internal func append(_ values: [Returning]) {
        lock.lock()
        defer { lock.unlock () }
        stubs.append(contentsOf: values.map { .value($0) })
    }

    /// Append the closure to the list of stubs.
    public func append(_ closure: @escaping @Sendable (Arguments) -> Returning) {
        lock.lock()
        defer { lock.unlock () }
        stubs.append(.closure(closure))
    }

    /// Append the stubs to the list of stubs.
    public func append(_ stub: Stub, _ stubs: Stub...) {
        append(Array(stub, stubs))
    }

    internal func append(_ stubs: [Stub]) {
        lock.lock()
        defer { lock.unlock () }
        self.stubs.append(contentsOf: stubs)
    }

    private func nextStub() -> Stub {
        guard let stub = stubs.first else {
            fatalError("Fakes: DynamicResult \(self) has 0 stubs. This should never happen. File a bug at https://github.com/Quick/swift-fakes/issues/new")
        }
        if stubs.count > 1 {
            stubs.removeFirst()
        }
        return stub
    }

    private func resolvePendables() {
        stubs.forEach {
            guard case .value(let value) = $0 else { return }
            if let resolvable = value as? ResolvableWithFallback {
                resolvable.resolveWithFallback()
            }
        }
    }
}

extension DynamicResult: @unchecked Sendable where Arguments: Sendable, Returning: Sendable {}

internal extension Array {
    init(_ value: Element, _ values: [Element]) {
        self = [value] + values
    }

    mutating func append(_ value: Element, _ values: [Element]) {
        self.append(contentsOf: Array(value, values))
    }
}
