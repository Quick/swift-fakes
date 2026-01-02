import Fakes
import Testing

struct DynamicResultTests {
    @Test func testSingleStaticValue() {
        let subject = DynamicResult<Int, Int>(1)

        #expect(subject.call(1) == 1)
        #expect(subject.call(1) == 1)
        #expect(subject.call(1) == 1)
    }

    @Test func testMultipleStaticValues() {
        let subject = DynamicResult<Void, Int>(1, 2, 3)

        #expect(subject.call() == 1)
        #expect(subject.call() == 2)
        #expect(subject.call() == 3)
        // After the last call, we continue to return the last stub in the list
        #expect(subject.call() == 3)
        #expect(subject.call() == 3)
    }

    @Test func testClosure() {
        let subject = DynamicResult<Int, Int>({ $0 + 1 })

        #expect(subject.call(1) == 2)
        #expect(subject.call(2) == 3)
        #expect(subject.call(3) == 4)
    }

    @Test func testStubs() {
        let subject = DynamicResult<Int, Int>(
            .value(1),
            .closure({ $0 * 3}),
            .value(4)
        )

        #expect(subject.call(1) == 1)
        #expect(subject.call(2) == 6)
        #expect(subject.call(3) == 4)
        #expect(subject.call(3) == 4)
    }

    // MARK: - Replacement Tests

    @Test func testReplacementStaticValue() {
        let subject = DynamicResult<Void, Int>(1)

        subject.replace(2, 3, 4, 6)

        #expect(subject.call() == 2)
        #expect(subject.call() == 3)
        #expect(subject.call() == 4)
        #expect(subject.call() == 6)
        // After the last call, we continue to return the last stub in the list
        #expect(subject.call() == 6)
    }

    @Test func testReplacementClosure() {
        let subject = DynamicResult<Int, Int>(1)

        subject.replace({ $0 + 4})

        #expect(subject.call(1) == 5)
        #expect(subject.call(2) == 6)
        #expect(subject.call(3) == 7)
    }

    @Test func testReplacementStubs() {
        let subject = DynamicResult<Int, Int>(1)

        subject.replace(
            .value(2),
            .closure({ $0 * 3}),
            .value(4)
        )

        #expect(subject.call(1) == 2)
        #expect(subject.call(2) == 6)
        #expect(subject.call(3) == 4)
        #expect(subject.call(3) == 4)
    }

    // MARK: - Appending Tests

    @Test func testAppendingStaticValue() {
        let subject = DynamicResult<Void, Int>(1, 2, 3)

        subject.append(4, 5, 6)

        #expect(subject.call() == 1)
        #expect(subject.call() == 2)
        #expect(subject.call() == 3)
        #expect(subject.call() == 4)
        #expect(subject.call() == 5)
        #expect(subject.call() == 6)
        // After the last call, we continue to return the last stub in the list
        #expect(subject.call() == 6)
    }

    @Test func testAppendingClosure() {
        let subject = DynamicResult<Int, Int>(1, 2, 3)

        subject.append({ $0 + 10})

        #expect(subject.call(1) == 1)
        #expect(subject.call(2) == 2)
        #expect(subject.call(3) == 3)
        #expect(subject.call(4) == 14)
        #expect(subject.call(5) == 15)
    }

    @Test func testAppendingStubs() {
        let subject = DynamicResult<Int, Int>(1, 2, 3)

        subject.append(
            .value(4),
            .closure({ $0 * 3}),
            .value(6)
        )

        #expect(subject.call(1) == 1)
        #expect(subject.call(2) == 2)
        #expect(subject.call(3) == 3)
        #expect(subject.call(4) == 4)
        #expect(subject.call(5) == 15)
        #expect(subject.call(6) == 6)
        #expect(subject.call(7) == 6)
    }
}
