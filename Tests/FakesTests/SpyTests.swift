import Nimble
import XCTest
@testable import Fakes

final class SpyTests: XCTestCase {
    func testVoid() {
        let subject = Spy<Void, Void>()

        // it returns the returning argument as the result, without stubbing.
        expect {
            subject(())
        }.to(beVoid())

        // it records the call
        expect(subject.calls).to(haveCount(1))
        expect(subject.calls.first).to(beVoid())

        // allows Void arguments to be called without passing in a void
        expect {
            subject()
        }.to(beVoid())

        // it records the call.
        expect(subject.calls).to(haveCount(2))
        expect(subject.calls.last).to(beVoid())
    }

    func testStubbing() {
        let subject = Spy<Void, Int>(123)

        expect {
            subject()
        }.to(equal(123))

        subject.stub(456)

        expect {
            subject()
        }.to(equal(456))
    }

    func testResult() {
        let subject = Spy<Void, Result<Int, TestError>>(.failure(TestError.uhOh))

        expect {
            try subject() as Int
        }.to(throwError(TestError.uhOh))

        expect {
            try subject(()) as Int
        }.to(throwError(TestError.uhOh))

        // stub(success:)

        subject.stub(success: 2)

        expect {
            try subject()
        }.to(equal(2))

        // stub(failure:)

        subject.stub(failure: .ohNo)

        expect {
            try subject() as Int
        }.to(throwError(TestError.ohNo))
    }

    func testResultInitializers() {
        let subject = ThrowingSpy<Void, Int, TestError>(failure: .ohNo)

        expect {
            try subject() as Int
        }.to(throwError(TestError.ohNo))

        let subject2 = ThrowingSpy<Void, Int, TestError>(success: 3)
        expect {
            try subject2()
        }.to(equal(3))
    }

    func testResultTakesNonVoidArguments() {
        let intSpy = Spy<Int, Void>()

        intSpy(1)

        expect(intSpy.calls).to(equal([1]))

        intSpy(1)
    }

    func testPendable() async {
        let subject = PendableSpy<Void, Int>(pendingFallback: 1)

        await expect {
            await subject(pendingDelay: 0)
        }.toEventually(equal(1))

        subject.stub(finished: 4)

        await expect {
            await subject(pendingDelay: 0)
        }.toEventually(equal(4))
    }

    func testPendableTakesNonVoidArguments() async throws {
        let subject = PendableSpy<Int, Void>(finished: ())

        await subject(3, pendingDelay: 0)

        expect(subject.calls).to(equal([3]))
    }

    func testThrowingPendable() async {
        let subject = ThrowingPendableSpy<Void, Int, TestError>(pendingSuccess: 0)

        await expect {
            try await subject(pendingDelay: 0)
        }.toEventually(equal(0))

        subject.stub(success: 5)

        await expect {
            try await subject(pendingDelay: 0)
        }.toEventually(equal(5))

        subject.stub(failure: TestError.uhOh)
        await expect {
            try await subject(pendingDelay: 0)
        }.toEventually(throwError(TestError.uhOh))
    }

    func testThrowingPendableTakesNonVoidArguments() async throws {
        let subject = ThrowingPendableSpy<Int, Void, TestError>(success: ())

        try await subject(8, pendingDelay: 0)

        expect(subject.calls).to(equal([8]))
    }

    func testClearCalls() {
        let subject = Spy<Int, Void>()

        subject(1)
        subject(2)

        subject.clearCalls()
        expect(subject.calls).to(beEmpty())
    }

    func testDynamicPendable() async {
        let subject = Spy<Void, DynamicPendable<Void>>()

        let managedTask = ManagedTask<Void, Never> {
            await subject()
        }

        await expect { await managedTask.isFinished }.toNever(beTrue())

        subject.resolveStub(with: ())

        await expect { await managedTask.isFinished }.toEventually(beTrue())
    }

    func testDynamicPendableDeinit() async {
        let subject = Spy<Void, DynamicPendable<Void>>()

        let managedTask = ManagedTask<Void, Never> {
            await subject()
        }

        await expect { await managedTask.hasStarted }.toEventually(beTrue())

        subject.stub(DynamicPendable())
        subject.resolveStub(with: ())

        await expect { await managedTask.isFinished }.toEventually(beTrue())
    }
}

actor ManagedTask<Success, Failure: Error> {
    var hasStarted = false
    var isFinished = false

    var _task: Task<Success, Failure>!

    init(closure: @escaping () async throws -> Success) where Failure == Error {
        _task = Task {
            await self.recordStarted()
            let result = try await closure()
            await self.recordFinished()
            return result
        }
    }

    init(closure: @escaping () async -> Success) where Failure == Never {
        _task = Task {
            await self.recordStarted()
            let result = await closure()
            await self.recordFinished()
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
            await _task.result
        }
    }

    var value: Success {
        get async throws {
            try await _task.value
        }
    }
}

enum TestError: Error {
    case uhOh
    case ohNo
}
