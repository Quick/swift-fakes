import Fakes
import Testing

struct PendableTests {
    @Test func testSingleCall() async throws {
        let subject = Pendable<Int>.pending(fallback: 0)

        async let result = subject.call()

        try await Task.sleep(nanoseconds: UInt64(0.01 * 1_000_000_000))

        subject.resolve(with: 2)

        let value = await result
        #expect(value == 2)
    }

    @Test func testMultipleCalls() async throws {
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

        try await Task.sleep(nanoseconds: UInt64(0.1 * 1_000_000_000))

        subject.resolve(with: 3)

        let value = await result
        #expect(value == Array(repeating: 3, count: 100))
    }

    @Test func testAutoresolve() async throws {
        let subject = Pendable<Int>.pending(fallback: 3)
        let spy = Spy<Int, Void>()

        Task<Void, Never> {
            let value = await subject.call(fallbackDelay: 0.1)
            spy(value)
        }

        try await Task.sleep(for: .milliseconds(500))

        #expect(spy.wasCalled(with: 3))
    }
}
