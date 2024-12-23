/// An immutable property spy.
@propertyWrapper public struct PropertySpy<T, U> {
    public var wrappedValue: U {
        mapping(projectedValue())
    }

    /// the ``Spy`` recording the getter calls.
    public let projectedValue: Spy<Void, T>

    public let mapping: @Sendable (T) -> U

    /// Creates an immutable PropertySpy stubbed with the given value, which lets you map from one type to another
    ///
    /// - parameter value: The initial value to be stubbed
    /// - parameter mapping: A closure to map from the initial value to the property's return type
    ///
    /// - Note: This initializer is particularly useful when the property is returning a protocol of some value, but you want to stub it with a particular instance of the protocol.
    public init(_ value: T, as mapping: @escaping @Sendable (T) -> U) {
        projectedValue = Spy(value)
        self.mapping = mapping
    }

    /// Creates an immutable PropertySpy stubbed with the given value
    ///
    /// - parameter value: The initial value to be stubbed
    public init(_ value: T) where T == U {
        projectedValue = Spy(value)
        self.mapping = { $0 }
    }
}

/// A mutable property spy.
@propertyWrapper public struct SettablePropertySpy<T, U> {
    public var wrappedValue: U {
        get {
            getMapping(projectedValue.getter())
        }
        set {
            projectedValue.setter(newValue)
            projectedValue.getter.stub(setMapping(newValue))
        }
    }

    public struct ProjectedValue {
        /// A ``Spy`` recording every time the property has been set, with whatever the new value is, prior to mapping
        public let setter: Spy<U, Void>
        /// A ``Spy`` recording every time the property has been called. It is re-stubbed whenever the property's setter is called.
        public let getter: Spy<Void, T>
    }

    /// The spies recording the setter and getter calls.
    public let projectedValue: ProjectedValue

    public let getMapping: @Sendable (T) -> U
    public let setMapping: @Sendable (U) -> T

    /// Creates a mutable PropertySpy stubbed with the given value, which lets you map from one type to another and back again
    ///
    /// - parameter value: The initial value to be stubbed
    /// - parameter getMapping: A closure to map from the initial value to the property's return type
    /// - parameter setMapping: A closure to map from the property's return type back to the initial value's type.
    ///
    /// - Note: This initializer is particularly useful when the property is returning a protocol of some value, but you want to stub it with a particular instance of the protocol.
    public init(_ value: T, getMapping: @escaping @Sendable (T) -> U, setMapping: @escaping @Sendable (U) -> T) {
        projectedValue = ProjectedValue(setter: Spy(), getter: Spy(value))
        self.getMapping = getMapping
        self.setMapping = setMapping
    }

    /// Creatse a mutable PropertySpy stubbed with the given value
    ///
    /// - parameter value: The inital value to be stubbed
    public init(_ value: T) where T == U {
        projectedValue = ProjectedValue(setter: Spy(), getter: Spy(value))
        self.getMapping = { $0 }
        self.setMapping = { $0 }
    }
}
