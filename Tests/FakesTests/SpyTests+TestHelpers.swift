import Fakes
import Testing

struct SpyTestHelpersTest {
    @Test func wasCalledWithoutArguments() {
        let spy = Spy<Int, Void>()

        // beCalled should match if spy has been called any number of times.
        #expect(spy.wasCalled == false)
        #expect(spy.wasNotCalled)

        spy(1)
        #expect(spy.wasCalled)
        #expect(spy.wasNotCalled == false)

        spy(2)
        #expect(spy.wasCalled)
        #expect(spy.wasNotCalled == false)
    }

    @Test func wasCalledWithArguments() {
        let spy = Spy<Int, Void>()

        spy(3)
        #expect(spy.wasCalled(with: 3))
        #expect(spy.wasCalled(with: 2) == false)

        #expect(spy.wasCalled(matching: { $0 == 3 }))
        #expect(spy.wasCalled(matching: { $0 == 2 }) == false)

        spy(4)
        #expect(spy.wasCalled(with: 3))
        #expect(spy.wasCalled(matching: { $0 == 3 }))

        #expect(spy.wasCalled(with: 4))
        #expect(spy.wasCalled(matching: { $0 == 4 }))
    }

    @Test func wasCalledWithTimes() {
        let spy = Spy<Int, Void>()

        #expect(spy.wasCalled(times: 0))
        #expect(spy.wasCalled(times: 1) == false)
        #expect(spy.wasCalled(times: 2) == false)

        spy(1)
        #expect(spy.wasCalled(times: 0) == false)
        #expect(spy.wasCalled(times: 1))
        #expect(spy.wasCalled(times: 2) == false)

        spy(2)
        #expect(spy.wasCalled(times: 0) == false)
        #expect(spy.wasCalled(times: 1) == false)
        #expect(spy.wasCalled(times: 2))
    }

    @Test func wasCalledWithMultipleArgumentsAndTimes() {
        let spy = Spy<Int, Void>()

        spy(1)
        spy(3)

        #expect(spy.wasCalled(with: [1, 3]))
        #expect(spy.wasCalled(with: [3, 1]) == false) // order matters

        #expect(spy.wasCalled(
            matching: [
                { $0 == 1},
                { $0 == 3 }
            ]
        ))
        #expect(spy.wasCalled(
            matching: [
                { $0 == 3 },
                { $0 == 1 }
            ]
        ) == false)
    }

    @Test func testMostRecentlyBeCalled() {
        let spy = Spy<Int, Void>()

        spy(1)
        #expect(spy.wasMostRecentlyCalled(with: 1))
        #expect(spy.wasMostRecentlyCalled(with: 2) == false)

        #expect(spy.wasMostRecentlyCalled(matching: { $0 == 1}))
        #expect(spy.wasMostRecentlyCalled(matching: { $0 == 2}) == false)

        spy(2)
        #expect(spy.wasMostRecentlyCalled(with: 1) == false)
        #expect(spy.wasMostRecentlyCalled(with: 2))

        #expect(spy.wasMostRecentlyCalled(matching: { $0 == 1}) == false)
        #expect(spy.wasMostRecentlyCalled(matching: { $0 == 2}))
    }
}

