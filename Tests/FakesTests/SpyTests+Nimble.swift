#if Include_Nimble
import Nimble
import Testing
import Fakes

struct SpyNimbleMatchersTest {
    @Test func testBeCalledWithoutArguments() {
        let spy = Spy<Int, Void>()

        // beCalled should match if spy has been called any number of times.
        expect(spy).toNot(beCalled())

        spy(1)
        expect(spy).to(beCalled())

        spy(2)
        expect(spy).to(beCalled())
    }

    @Test func testBeCalledWithArguments() {
        let spy = Spy<Int, Void>()

        expect(spy).toNot(beCalled())

        spy(3)
        expect(spy).toNot(beCalled(equal(2)))
        expect(spy).to(beCalled(equal(3)))

        // beCalled without a matcher argument is available when Arguments conforms to Equatable.
        expect(spy).toNot(beCalled(2))
        expect(spy).to(beCalled(3))
    }

    @Test func testBeCalledWithMultipleArguments() {
        let spy = Spy<Int, Void>()

        spy(3)
        expect(spy).toNot(beCalled(
            equal(2),
            beLessThan(4)
        ))
        expect(spy).to(beCalled(
            equal(3),
            beLessThan(4)
        ))
    }

    @Test func testBeCalledWithTimes() {
        let spy = Spy<Int, Void>()

        expect(spy).to(beCalled(times: 0))
        expect(spy).toNot(beCalled(times: 2))
        expect(spy).toNot(beCalled(times: 1))

        spy(1)
        expect(spy).to(beCalled(times: 1))
        expect(spy).toNot(beCalled(times: 2))
        expect(spy).toNot(beCalled(times: 0))

        spy(2)
        expect(spy).to(beCalled(times: 2))
        expect(spy).toNot(beCalled(times: 0))
        expect(spy).toNot(beCalled(times: 1))
    }

    @Test func testBeCalledWithArgumentsAndTimes() {
        let spy = Spy<Int, Void>()

        spy(1)

        expect(spy).toNot(beCalled(equal(2), times: 1))
        expect(spy).toNot(beCalled(3, times: 1))
        expect(spy).to(beCalled(equal(1), times: 1))
        expect(spy).to(beCalled(1, times: 1))

        spy(3)
        expect(spy).toNot(beCalled(equal(2), times: 2))
        expect(spy).to(beCalled(equal(3), times: 2))

        expect(spy).toNot(beCalled(2, times: 2))
        expect(spy).to(beCalled(3, times: 2))
    }

    @Test func testBeCalledWithMultipleArgumentsAndTimes() {
        let spy = Spy<Int, Void>()

        spy(1)

        expect(spy).toNot(beCalled(equal(2), beLessThan(3), times: 1))
        expect(spy).to(beCalled(equal(1), beLessThan(3), times: 1))

        spy(3)
        expect(spy).toNot(beCalled(equal(2), beLessThan(4), times: 2))
        expect(spy).to(beCalled(equal(3), beLessThan(4), times: 2))
    }

    @Test func testMostRecentlyBeCalled() {
        let spy = Spy<Int, Void>()

        spy(1)
        expect(spy).to(mostRecentlyBeCalled(equal(1)))
        expect(spy).toNot(mostRecentlyBeCalled(equal(2)))
        expect(spy).to(mostRecentlyBeCalled(1))
        expect(spy).toNot(mostRecentlyBeCalled(2))

        spy(2)
        expect(spy).toNot(mostRecentlyBeCalled(equal(1)))
        expect(spy).to(mostRecentlyBeCalled(equal(2)))

        expect(spy).toNot(mostRecentlyBeCalled(1))
        expect(spy).to(mostRecentlyBeCalled(2))
    }

    @Test func testMostRecentlyBeCalledWithMultipleArguments() {
        let spy = Spy<Int, Void>()

        spy(1)
        expect(spy).to(mostRecentlyBeCalled(
            equal(1),
            beLessThan(3)
        ))
        expect(spy).toNot(mostRecentlyBeCalled(
            equal(2),
            beLessThan(3)
        ))

        spy(2)
        expect(spy).toNot(mostRecentlyBeCalled(
            equal(1),
            beLessThan(3)
        ))
        expect(spy).to(mostRecentlyBeCalled(
            equal(2),
            beLessThan(3)
        ))
    }
}
#endif
