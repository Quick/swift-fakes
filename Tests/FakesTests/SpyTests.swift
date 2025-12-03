#if Include_Nimble
import Nimble
#endif
import Testing
@testable import Fakes

struct SpyTests {
    @Test func testVoid() {
        let subject = Spy<Void, Void>()

        // it returns the returning argument as the result, without stubbing.
        #expect(throws: Never.self) {
            subject(())
        }

        // it records the call
        #expect(subject.calls.count == 1)
        #expect(subject.calls.first! == ())

        // allows Void arguments to be called without passing in a void
        #expect(throws: Never.self) {
            subject()
        }

        // it records the call.
        #expect(subject.calls.count == 2)
        #expect(subject.calls.last! == ())
    }

    @Test func testStubbing() {
        let subject = Spy<Void, Int>(123)

        #expect(subject() == 123)

        subject.stub(456)

        #expect(subject() == 456)
    }

    @Test func testMultipleStubs() {
        let subject = Spy<Void, Int>(1, 2, 3)

        #expect(subject() == 1)
        #expect(subject() == 2)
        #expect(subject() == 3)
        #expect(subject() == 3)
    }

    @Test func testClosureStubs() {
        let subject = Spy<Int, Int> { $0 }

        #expect(subject(1) == 1)
        #expect(subject(2) == 2)
        #expect(subject(3) == 3)
        #expect(subject(10) == 10)
    }

    @Test func testReplacingStubs() {
        let subject = Spy<Void, Int>(5)
        subject.stub(1, 2, 3)

        #expect(subject() == 1)
        #expect(subject() == 2)
        #expect(subject() == 3)
        #expect(subject() == 3)
    }

    @Test func testReplacingClosures() {
        let subject = Spy<Int, Int>(5)
        subject.stub { $0 }

        #expect(subject(1) == 1)
        #expect(subject(2) == 2)
        #expect(subject(3) == 3)
        #expect(subject(10) == 10)
    }

    @Test func testResult() throws {
        let subject = Spy<Void, Result<Int, TestError>>(.failure(TestError.uhOh))

        #expect(throws: TestError.uhOh) {
            try subject() as Int
        }

        #expect(throws: TestError.uhOh) {
            try subject(()) as Int
        }

        // stub(success:)

        subject.stub(success: 2)

        #expect(try subject() == 2)

        // stub(failure:)

        subject.stub(failure: .ohNo)

        #expect(throws: TestError.ohNo) {
            try subject() as Int
        }
    }

    @Test func testResultInitializers() throws {
        let subject = ThrowingSpy<Void, Int, TestError>(failure: .ohNo)

        #expect(throws: TestError.ohNo) {
            try subject() as Int
        }

        let subject2 = ThrowingSpy<Void, Int, TestError>(success: 3)
        #expect(try subject2() == 3)
    }

    @Test func testResultTakesNonVoidArguments() {
        let intSpy = Spy<Int, Void>()

        intSpy(1)

        #expect(intSpy.calls == [1])

        intSpy(1)
    }

#if Include_Nimble
    // TODO: Reimplement this using polling confirmations once they're a thing.
    @Test func testPendable() async {
        let subject = PendableSpy<Void, Int>(pendingFallback: 1)

        await expect {
            await subject(fallbackDelay: 0)
        }.toEventually(equal(1))

        subject.stub(finished: 4)

        await expect {
            await subject(fallbackDelay: 0)
        }.toEventually(equal(4))
    }
#endif

    @Test func testPendableTakesNonVoidArguments() async throws {
        let subject = PendableSpy<Int, Void>(finished: ())

        await subject(3, fallbackDelay: 0)

        #expect(subject.calls == [3])
    }

#if Include_Nimble
    // TODO: Reimplement this using polling confirmations once they're a thing.
    @Test func testThrowingPendable() async {
        let subject = ThrowingPendableSpy<Void, Int, TestError>(pendingSuccess: 0)

        await expect {
            try await subject(fallbackDelay: 0)
        }.toEventually(equal(0))

        subject.stub(success: 5)

        await expect {
            try await subject(fallbackDelay: 0)
        }.toEventually(equal(5))

        subject.stub(failure: TestError.uhOh)
        await expect {
            try await subject(fallbackDelay: 0)
        }.toEventually(throwError(TestError.uhOh))
    }
#endif

    @Test func testThrowingPendableTakesNonVoidArguments() async throws {
        let subject = ThrowingPendableSpy<Int, Void, TestError>(success: ())

        try await subject(8, fallbackDelay: 0)

        #expect(subject.calls == [8])
    }

    @Test func testClearCalls() {
        let subject = Spy<Int, Void>()

        subject(1)
        subject(2)

        subject.clearCalls()
        #expect(subject.calls == [])
    }

#if Include_Nimble
    // TODO: Reimplement this using polling confirmations once they're a thing.
    @Test func testDynamicPendable() async {
        let subject = Spy<Void, Pendable<Void>>()

        let managedTask = await ManagedTask<Void, Never>.running {
            await subject()
        }

        await expect { await managedTask.isFinished }.toNever(beTrue())

        subject.resolveStub(with: ())

        await expect { await managedTask.isFinished }.toEventually(beTrue())
    }

    @Test func testDynamicPendableDeinit() async {
        let subject = Spy<Void, Pendable<Void>>()

        let managedTask = await ManagedTask<Void, Never>.running {
            await subject()
        }

        await expect { await managedTask.hasStarted }.toEventually(beTrue())

        subject.stub(Pendable.pending())
        subject.resolveStub(with: ())

        await expect { await managedTask.isFinished }.toEventually(beTrue())
    }
#endif
}

actor ManagedTask<Success: Sendable, Failure: Error> {
    var hasStarted = false
    var isFinished = false

    var task: Task<Success, Failure>!

    static func running(closure: @escaping @Sendable () async throws -> Success) async -> ManagedTask where Failure == Error {
        let task = ManagedTask()

        await task.run(closure: closure)

        return task
    }

    static func running(closure: @escaping @Sendable () async -> Success) async -> ManagedTask where Failure == Never {
        let task = ManagedTask()

        await task.run(closure: closure)

        return task
    }

    private init() {}

    private func run(closure: @escaping @Sendable () async throws -> Success) where Failure == Error {
        task = Task {
            self.recordStarted()
            let result = try await closure()
            self.recordFinished()
            return result
        }
    }

    private func run(closure: @escaping @Sendable () async -> Success) where Failure == Never {
        task = Task {
            self.recordStarted()
            let result = await closure()
            self.recordFinished()
            return result
        }
    }

    private func recordStarted() {
        self.hasStarted = true
    }

    private func recordFinished() {
        self.isFinished = true
    }

    var result: Result<Success, Failure> {
        get async {
            await task.result
        }
    }

    var value: Success {
        get async throws {
            try await task.value
        }
    }
}

enum TestError: Error {
    case uhOh
    case ohNo
}
