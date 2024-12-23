import Fakes
import Nimble
import XCTest

final class DynamicResultTests: XCTestCase {
    func testSingleStaticValue() {
        let subject = DynamicResult<Int, Int>(1)

        expect(subject.call(1)).to(equal(1))
        expect(subject.call(1)).to(equal(1))
        expect(subject.call(1)).to(equal(1))
    }

    func testMultipleStaticValues() {
        let subject = DynamicResult<Void, Int>(1, 2, 3)

        expect(subject.call()).to(equal(1))
        expect(subject.call()).to(equal(2))
        expect(subject.call()).to(equal(3))
        // After the last call, we continue to return the last stub in the list
        expect(subject.call()).to(equal(3))
        expect(subject.call()).to(equal(3))
    }

    func testClosure() {
        let subject = DynamicResult<Int, Int>({ $0 + 1 })

        expect(subject.call(1)).to(equal(2))
        expect(subject.call(2)).to(equal(3))
        expect(subject.call(3)).to(equal(4))
    }

    func testStubs() {
        let subject = DynamicResult<Int, Int>(
            .value(1),
            .closure({ $0 * 3}),
            .value(4)
        )

        expect(subject.call(1)).to(equal(1))
        expect(subject.call(2)).to(equal(6))
        expect(subject.call(3)).to(equal(4))
        expect(subject.call(3)).to(equal(4))
    }

    // MARK: - Replacement Tests

    func testReplacementStaticValue() {
        let subject = DynamicResult<Void, Int>(1)

        subject.replace(2, 3, 4, 6)

        expect(subject.call()).to(equal(2))
        expect(subject.call()).to(equal(3))
        expect(subject.call()).to(equal(4))
        expect(subject.call()).to(equal(6))
        // After the last call, we continue to return the last stub in the list
        expect(subject.call()).to(equal(6))
    }

    func testReplacementClosure() {
        let subject = DynamicResult<Int, Int>(1)

        subject.replace({ $0 + 4})

        expect(subject.call(1)).to(equal(5))
        expect(subject.call(2)).to(equal(6))
        expect(subject.call(3)).to(equal(7))
    }

    func testReplacementStubs() {
        let subject = DynamicResult<Int, Int>(1)

        subject.replace(
            .value(2),
            .closure({ $0 * 3}),
            .value(4)
        )

        expect(subject.call(1)).to(equal(2))
        expect(subject.call(2)).to(equal(6))
        expect(subject.call(3)).to(equal(4))
        expect(subject.call(3)).to(equal(4))
    }

    // MARK: - Appending Tests

    func testAppendingStaticValue() {
        let subject = DynamicResult<Void, Int>(1, 2, 3)

        subject.append(4, 5, 6)

        expect(subject.call()).to(equal(1))
        expect(subject.call()).to(equal(2))
        expect(subject.call()).to(equal(3))
        expect(subject.call()).to(equal(4))
        expect(subject.call()).to(equal(5))
        expect(subject.call()).to(equal(6))
        // After the last call, we continue to return the last stub in the list
        expect(subject.call()).to(equal(6))
    }

    func testAppendingClosure() {
        let subject = DynamicResult<Int, Int>(1, 2, 3)

        subject.append({ $0 + 10})

        expect(subject.call(1)).to(equal(1))
        expect(subject.call(2)).to(equal(2))
        expect(subject.call(3)).to(equal(3))
        expect(subject.call(4)).to(equal(14))
        expect(subject.call(5)).to(equal(15))
    }

    func testAppendingStubs() {
        let subject = DynamicResult<Int, Int>(1, 2, 3)

        subject.append(
            .value(4),
            .closure({ $0 * 3}),
            .value(6)
        )

        expect(subject.call(1)).to(equal(1))
        expect(subject.call(2)).to(equal(2))
        expect(subject.call(3)).to(equal(3))
        expect(subject.call(4)).to(equal(4))
        expect(subject.call(5)).to(equal(15))
        expect(subject.call(6)).to(equal(6))
        expect(subject.call(7)).to(equal(6))
    }
}
