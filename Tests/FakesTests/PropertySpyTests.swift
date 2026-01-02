import Fakes
import Testing

struct SettablePropertySpyTests {
    @Test func testGettingPropertyWhenTypesMatch() {
        struct AnObject {
            @SettablePropertySpy(1)
            var value: Int
        }

        let object = AnObject()

        #expect(object.value == 1)
        // because we called it, we should expect for the getter spy to be called
        #expect(object.$value.getter.wasCalled)

        // We never interacted with the setter, so it shouldn't have been called.
        #expect(object.$value.setter.wasNotCalled)
    }

    @Test func testSettingPropertyWhenTypesMatch() {
        struct AnObject {
            @SettablePropertySpy(1)
            var value: Int
        }

        var object = AnObject()
        object.value = 3

        #expect(object.$value.getter.wasNotCalled)
        #expect(object.$value.setter.wasCalled(with: 3))

        // the returned value should now be updated with the new value
        #expect(object.value == 3)

        // and because we called the getter, the getter spy should be called.
        #expect(object.$value.getter.wasCalled)
    }

    @Test func testGettingPropertyProtocolInheritence() {
        struct ImplementedProtocol: SomeProtocol {
            var value: Int = 1
        }

        struct AnObject {
            @SettablePropertySpy(ImplementedProtocol(value: 2))
            var value: SomeProtocol
        }

        let object = AnObject()

        #expect(object.value is ImplementedProtocol)
        // because we called it, we should expect for the getter spy to be called
        #expect(object.$value.getter.wasCalled)

        // We never interacted with the setter, so it shouldn't have been called.
        #expect(object.$value.setter.wasNotCalled)
    }

    @Test func testSettingPropertyProtocolInheritence() {
        struct ImplementedProtocol: SomeProtocol, Equatable {
            var value: Int = 1
        }

        struct AnObject {
            @SettablePropertySpy(ImplementedProtocol())
            var value: SomeProtocol
        }

        var object = AnObject()
        object.value = ImplementedProtocol(value: 2)

        #expect(object.$value.getter.wasNotCalled)

        // the returned value should now be updated with the new value
        #expect((object.value as? ImplementedProtocol)?.value == 2)
        // and because we called the getter, the getter spy should be called.
        #expect(object.$value.getter.wasCalled(times: 1))
    }
}

struct PropertySpyTests {
    @Test func testGettingPropertyWhenTypesMatch() {
        struct AnObject {
            @PropertySpy(1)
            var value: Int
        }

        let object = AnObject()

        #expect(object.value == 1)
        // because we called it, we should expect for the getter spy to be called
        #expect(object.$value.wasCalled)
    }

    @Test func testGettingPropertyProtocolInheritence() {
        struct ImplementedProtocol: SomeProtocol {
            var value: Int = 1
        }

        struct ObjectUsingProtocol {
            @PropertySpy(ImplementedProtocol(value: 2))
            var value: SomeProtocol
        }

        struct ObjectUsingDirectInstance {
            @PropertySpy(ImplementedProtocol(value: 2), as: { $0 })
            var value: SomeProtocol
        }

        let object = ObjectUsingProtocol()

        #expect(object.value is ImplementedProtocol)
        // because we called it, we should expect for the getter spy to be called
        #expect(object.$value.wasCalled)

        // it can be initialized and expressed.
        let _ = ObjectUsingDirectInstance()
    }
}

protocol SomeProtocol {
    var value: Int { get }
}
