#  Verifying Callbacks and Faking DispatchQueue

When testing a method that calls a callback, how do you verify that the
callback actually works?

## Contents

Let's say we're testing a method that uses a callback as part of its behavior.
How would we verify that the callback actually gets called?

To examine that, let's look at a function that does some expensive computation.
This function uses `DispatchQueue` to do that computation on a background
thread. To let the caller know that the work has finished, this function takes
in a completion handler in the form of a callback.

Let's say that method looks something like this:

```swift
func expensiveComputation(completionHandler: @escaping (Int) -> Void) {
    DispatchQueue.global().async {
        // ... do some work, to compute a value
        let value: Int = 1337 // for the sake of example.
        completionHandler(value)
    }
}
```

In that case, we could pass a closure that calls a ``Spy`` with the
completion handler's arguments:

```swift
final class ExpensiveComputationTests: XCTestCase {
    func testCallsTheCompletionHandler() {
        let completionHandler = Spy<Int, Void>()

        let expectation = self.expectation(
            description: "expensiveComputation completion handler"
        )

        expensiveComputation {
            completionHandler.callAsFunction($0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(completionHandler.calls, [1])
    }
}
```

This has a lot of boilerplate. Setting up an `Expectation`, fulfilling it,
and waiting for it to be called is exactly the kind of situation that
[Nimble's Polling Expectations](https://quick.github.io/Nimble/documentation/nimble/pollingexpectations)
were created to handle.

Let's refactor the test using Polling Expectations:

```swift
final class ExpensiveComputationTests: XCTestCase {
    func testCallsTheCallback() {
        let completionHandler = Spy<Int, Void>()

        expensiveComputation(completionHandler: completionHandler.callAsFunction)

        expect(completionHandler).toEventually(beCalled(1337))
    }
}
```

### Writing Fakes that use Callbacks

Of course, even better than waiting for the completion handler to eventually be
called, is being able to control when it's called.

> Note: This section assumes you're familiar with writing fakes and injecting
them to the subject using Dependency Injection. See <doc:DependencyInjection>
for a refresher.

Because `DispatchQueue` is an open class, we could write a subclass that
overrides its public API and does the right thing. That's doable, but
[`DispatchQueue`](https://developer.apple.com/documentation/dispatch/dispatchqueue)
has a very large public API, and our subclass would have to implement all of that
plus keep up with any changes Apple makes in the future to avoid accidentally
calling into the base DispatchQueue class.

Instead, whenever possible, you should favor composition over inheritance.
Which, for this case, means we'll write a protocol to wrap `DispatchQueue`.

We're only calling `async` with the default arguments, so our protocol can
be a single method that takes the `execute` argument:

```swift
protocol DispatchQueueProtocol {
    func async(execute work: @escaping @Sendable () -> Void)
}

extension DispatchQueue: DispatchQueueProtocol {
    func async(execute work: @escaping @Sendable () -> Void) {
        self.async(group: nil, execute: work)
    }
}
```

Our `DispatchQueueProtocol` is only using one of the arguments to DispatchQueue's [`async(group:qos:flags:execute:)`](https://developer.apple.com/documentation/dispatch/dispatchqueue/2016098-async),
so the protocol wrapping `DispatchQueue` only really needs the `execute`
argument. Because default arguments don't really play well with protocols, we
need to manually implement `async(execute:)`, and also specify one of the
default arguments to prevent recursively calling `async(execute:)`.

Now, we can inject our `DispatchQueueProtocol`:

```swift
func expensiveComputation(dispatchQueue: DispatchQueueProtocol, completionHandler: @escaping (Int) -> Void) {
    dispatchQueue.async {
        // ... do some work, to compute a value
        let value: Int = 1337 // for the sake of example.
        completionHandler(value)
    }
}
```

and then turn our attention to to implementing `FakeDispatchQueue`.

Following the example from <doc:DependencyInjection>, we will implement
`FakeDispatchQueue` using only `Spy`:

```swift
final class FakeDispatchQueue: DispatchQueueProtocol {
    let asyncSpy = Spy<@Sendable () -> Void, Void>()
    func async(execute work: @escaping @Sendable () -> Void) {
        asyncSpy(work)
    }
}
```

This will work similarly to when we used a Spy as the completion handler to
`expensiveComputation(completionHandler:)` earlier.

Now we use `FakeDispatchQueue` in our tests for `expensiveComputation`:

```swift
final class ExpensiveComputationTests: XCTestCase {
    func testCallsTheCallback() throws {
        let dispatchQueue = FakeDispatchQueue()
        let completionHandler = Spy<Int, Void>()

        expensiveComputation(
            dispatchQueue: dispatchQueue,
            completionHandler: completionHandler.callAsFunction
        )

        try require(dispatchQueue.asyncSpy).to(beCalled())

        dispatchQueue.asyncSpy.calls.last?() // call the recorded completion handler.

        expect(completionHandler).to(beCalled(1337))
    }
}
```

This has quite a bit more boilerplate than simply using
`expect(completionHandler).toEventually(beCalled(...))`. However, the benefit of
this boilerplate is that this test runs significantly faster. We no longer have
to wait for the system to decide to run the closure that calls the completion
handler, which results in a small reduction in test runtime.

Additionally, we can also control when this closure is run, which allows us
to verify any other behavior that might be happening before the code is
run in the background, or while code is run in the background.

### Improving FakeDispatchQueue

The current implementation of `FakeDispatchQueue` still leaves a lot to be
desired. Yes, it works, but it's clunky. Having to first require that `async`
was called, then call the last call recorded is a lot of typing. Being able to
control when closures run is great, but having to go through ``Spy`` makes it
really easy to either run the same closure twice, or not run one that should
have run.

To address this, we'll flesh out `FakeDispatchQueue`
some more, adding some logic to record closures, call them at a later time, or
run the closure when `async(execute:)` is called.

```swift
import Foundation

final class FakeDispatchQueue: DispatchQueueProtocol, @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var calls = [@Sendable () -> Void]()

    func pendingTaskCount() -> Int {
        lock.withLock { calls.count }
    }

    func runNextTask() {
        lock.withLock {
            guard !calls.isEmpty else { return }
            calls.removeFirst()()
        }
    }

    func async(execute work: @escaping @Sendable () -> Void) {
        lock.withLock {
            guard _runSynchronously == false else {
                return work()
            }
            calls.append(work)
        }
    }
}
```

Before we can use this new `FakeDispatchQueue`, it's very important to realize
that, because it now has logic in it, we have to [write tests for that logic](https://blog.rachelbrindle.com/2023/06/25/testing-test-helpers/).
Otherwise, we have no idea if a test failure is caused by something
in the production code, or something in `FakeDispatchQueue`.

Some tests that verify thet entire API for `FakeDispatchQueue` look like this:

```swift
final class FakeDispatchQueueTests: XCTestCase {
    func testRunNextTaskWithoutPendingTasksDoesntBlowUp() {
        let subject = FakeDispatchQueue()

        expect { subject.runNextTask() }.toNot(throwAssertion())
    }

    func testRunNextTaskWithPendingTasksCallsTheCallback() {
        let subject = FakeDispatchQueue()
        let spy = Spy<Void, Void>()

        subject.async { spy.call() }

        expect(spy).toNot(beCalled())

        subject.runNextTask()

        expect(spy).to(beCalled())
    }

    func testPendingTaskCountReturnsNumberOfUnRunTasks() {
        let subject = FakeDispatchQueue()
        let spy = Spy<Void, Void>()

        expect(subject.pendingTaskCount).to(equal(0))

        subject.async { spy.call() }

        expect(subject.pendingTaskCount).to(equal(1))

        subject.async { spy.call() }

        expect(subject.pendingTaskCount).to(equal(2))

        subject.runNextTask()

        expect(subject.pendingTaskCount).to(equal(1))

        subject.runNextTask()

        expect(subject.pendingTaskCount).to(equal(0))
    }

    func testPendingTasksAreRunInTheOrderReceived() {
        let subject = FakeDispatchQueue()
        let spy = Spy<Int, Void>()

        subject.async { spy.call(1) }
        subject.async { spy.call(2) }

        subject.runNextTask()
        subject.runNextTask()

        expect(subject.calls).to(equal([1, 2]))
    }
}
```

> Important: Any code that has logic in it must have tests driving out that logic.

These tests do the basic of ensuring that tasks are queued up properly, and
are actually ran in a queue. They make sure that we can correctly assert on
the number of queued up tasks. And, most importantly, they ensure that if
we try to run a task when there aren't any to run, the tests don't crash.

Now, with `FakeDispatchQueue` implemented and tested, we can use it in
`ExpensiveComputationTests`:

```swift
final class ExpensiveComputationTests: XCTestCase {
    func testCallsTheCallback() {
        let dispatchQueue = FakeDispatchQueue()
        let completionHandler = Spy<Int, Void>()

        expensiveComputation(
            dispatchQueue: dispatchQueue,
            completionHandler: completionHandler.callAsFunction
        )

        expect(dispatchQueue.pendingTaskCount).to(equal(1))

        dispatchQueue.runNextTask()

        expect(completionHandler).to(beCalled(1337))
    }
}
```

Which isn't that much different, but it's now significantly easier to understand
what's actually going on. `runNextTask()` is so much easier to read than
`asyncSpy.calls.last?()`, and it has way fewer sharp edges to cut yourself on.

### Conclusion

In this article, we discussed verifying callbacks as well as designing and
testing code using `DispatchQueue` to run code asynchronously. Verify callbacks
by injecting a ``Spy``, and do whatever you can to control when dispatched code
actually runs.

Swift Concurrency (async/await) brings its own challenges, which will be
addressed in a separate article.
