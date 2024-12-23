import Fakes
import Nimble
import XCTest

final class SettablePropertySpyTests: XCTestCase {
    func testGettingPropertyWhenTypesMatch() {
        struct AnObject {
            @SettablePropertySpy(1)
            var value: Int
        }

        let object = AnObject()

        expect(object.value).to(equal(1))
        // because we called it, we should expect for the getter spy to be called
        expect(object.$value.getter).to(beCalled())

        // We never interacted with the setter, so it shouldn't have been called.
        expect(object.$value.setter).toNot(beCalled())
    }

    func testSettingPropertyWhenTypesMatch() {
        struct AnObject {
            @SettablePropertySpy(1)
            var value: Int
        }

        var object = AnObject()
        object.value = 3

        expect(object.$value.getter).toNot(beCalled())
        expect(object.$value.setter).to(beCalled(3))

        // the returned value should now be updated with the new value
        expect(object.value).to(equal(3))

        // and because we called the getter, the getter spy should be called.
        expect(object.$value.getter).to(beCalled())
    }

    func testGettingPropertyProtocolInheritence() {
        struct ImplementedProtocol: SomeProtocol {
            var value: Int = 1
        }

        struct AnObject {
            @SettablePropertySpy(ImplementedProtocol(value: 2))
            var value: SomeProtocol
        }

        let object = AnObject()

        expect(object.value).to(beAKindOf(ImplementedProtocol.self))
        // because we called it, we should expect for the getter spy to be called
        expect(object.$value.getter).to(beCalled())

        // We never interacted with the setter, so it shouldn't have been called.
        expect(object.$value.setter).toNot(beCalled())
    }

    func testSettingPropertyProtocolInheritence() {
        struct ImplementedProtocol: SomeProtocol, Equatable {
            var value: Int = 1
        }

        struct AnObject {
            @SettablePropertySpy(ImplementedProtocol())
            var value: SomeProtocol
        }

        var object = AnObject()
        object.value = ImplementedProtocol(value: 2)

        expect(object.$value.getter).toNot(beCalled())
        expect(object.$value.setter).to(beCalled(satisfyAllOf(
            beAKindOf(ImplementedProtocol.self),
            map(\.value, equal(2))
        )))

        // the returned value should now be updated with the new value
        expect(object.value).to(satisfyAllOf(
            beAKindOf(ImplementedProtocol.self),
            map(\.value, equal(2))
        ))
        // and because we called the getter, the getter spy should be called.
        expect(object.$value.getter).to(beCalled(times: 1))
    }
}

final class PropertySpyTests: XCTestCase {
    func testGettingPropertyWhenTypesMatch() {
        struct AnObject {
            @PropertySpy(1)
            var value: Int
        }

        let object = AnObject()

        expect(object.value).to(equal(1))
        // because we called it, we should expect for the getter spy to be called
        expect(object.$value).to(beCalled())
    }

    func testGettingPropertyProtocolInheritence() {
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

        expect(object.value).to(beAnInstanceOf(ImplementedProtocol.self))
        // because we called it, we should expect for the getter spy to be called
        expect(object.$value).to(beCalled())
        expect(object.$value).to(beAnInstanceOf(Spy<Void, SomeProtocol>.self))

        let otherObject = ObjectUsingDirectInstance()

        expect(otherObject.$value).to(beAnInstanceOf(Spy<Void, ImplementedProtocol>.self))
    }
}

protocol SomeProtocol {
    var value: Int { get }
}
