import Fakes
import Nimble
import XCTest

final class DynamicPendableTests: XCTestCase {
    func testSingleCall() async {
        let subject = Pendable<Int>.pending(fallback: 0)

        async let result = subject.call()

        try! await Task.sleep(nanoseconds: UInt64(0.01 * 1_000_000_000))

        subject.resolve(with: 2)

        let value = await result
        expect(value).to(equal(2))
    }

    func testMultipleCalls() async {
        let subject = Pendable<Int>.pending(fallback: 0)

        async let result = withTaskGroup(of: Int.self, returning: [Int].self) { taskGroup in
            for _ in 0..<100 {
                taskGroup.addTask { await subject.call() }
            }

            var results = [Int]()
            for await value in taskGroup {
                results.append(value)
            }
            return results
        }

        try! await Task.sleep(nanoseconds: UInt64(0.1 * 1_000_000_000))

        subject.resolve(with: 3)

        let value = await result
        expect(value).to(equal(Array(repeating: 3, count: 100)))
    }

    func testAutoresolve() async {
        let subject = Pendable<Int>.pending(fallback: 3)

        let expectation = self.expectation(description: "Autoresolves after the given delay")

        let task = Task<Void, Never> {
            _ = await subject.call(fallbackDelay: 0.1)
            expectation.fulfill()
        }

        await self.fulfillment(of: [expectation], timeout: 1)
        task.cancel()
    }
}
