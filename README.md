# swift-fakes

Swift Fakes aims to improve the testability of Swift by providing standardized
[test doubles](https://martinfowler.com/bliki/TestDouble.html).

Test doubles are objects used to replace production objects for testing purposes.

## Installation

To use the `Fakes` library in a SwiftPM project, add the following line to the
dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/Quick/swift-fakes", from: "0.0.1"),
```

Include `"Fakes"` as a dependency for your test target:

```swift
.testTarget(name: "<target>", dependencies: [
    .product(name: "Fakes", package: "swift-fakes"),
]),
```

## Motivation

When writing tests, we want to write one thing at a time. This is best done by
providing _fakes_ or non-production test-controllable objects to the thing being
tested (the [subject](https://github.com/testdouble/contributing-tests/wiki/Subject)).
This is typically done by writing fakes that implement the protocols that the
subject depends on. Swift Fakes aims to make writing Fakes as easy as possible.

## Contents

For the time being, Swift Fakes only offers the `Spy` object. `Spy`s are a kind
of test double that record calls to the object, and return a preset response.

### Spy

Spies are meant to be used in Fake objects, for example:

```swift
protocol SomeProtocol {
    func methodA(argument: Int) -> String
    func methodB(argumentA: Int, argumentB: String) throws
    func methodC() async throws
}

final class FakeSomeProtocol: SomeProtocol {
    let methodASpy = Spy<Int, String>("some default response")
    func methodA(argument: Int) -> String {
        methodASpy(argument)
    }
    
    let methodBSpy = ThrowingSpy<(argumentA: Int, argumentB: String), Void, Error>()
    func methodB(argumentA: Int, argumentB: String) throws {
        try methodBSpy((argumentA, argumentB))
    }
    
    let methodCSpy = ThrowingPendableSpy<Void, Void, Error>()
    func methodC(argumentA: Int, argumentB: String) async throws {
        try await methodCSpy()
    }
}
```

In test, a spy can then be asserted on by checking the `calls` property.

#### Nimble Integration

In addition to directly checking the `calls` property, Swift Fakes provides some
[Nimble](https://github.com/Quick/Nimble) matchers to make asserting on Spies
significantly better:

- The `beCalled()` matcher without any arguments matches if the Spy has been
called at least once. This is especially useful for verifying there are no
interactions with the Spy, by using `expect(spy).toNot(beCalled())`.
- The `beCalled(times:)` matcher matches if the Spy has been called exactly the
amount of times specified in the `times` argument. For example,
`expect(spy).to(beCalled(times: 3))` will pass if the spy has been called with
any arguments exactly 3 times.
- The `beCalled(_:)` matcher with a matcher argument will match if the Spy has
been called at least once with arguments that match the passed-in Matcher.
For example, `expect(spy).to(beCalled(haveCount(3)))` will pass if the Spy
has been called with an array containing 3 items at least once.
Note: By combining the `satisfyAllOf` and `map` matchers, you can easily verify
multiple arguments (as represented in a Tuple) to a Spy. For example:

```swift
let spy = Spy<(argumentA: Int, argumentB: String), Void>()
spy((1, "a"))

expect(spy).to(beCalled(satisfyAllOf(
    map(\.argumentA, equal(1)),
    map(\.argumentB, equal("a"))
)))
```

- As a shorthand, when there is only 1 argument to the Spy, and that argument
is Equatable, you can pass a value to the `beCalled` matcher in place of an
`equal` matcher. That is, you can use `beCalled(1)` instead of `beCalled(equal(1))`.
- The `beCalled(_:times)` matchers match when the Spy has been called `times`
times, and at least one of those calls matches the given matcher (or is equal to
the given value). This is effectively a shorthand for
`satisfyAllOf(beCalled(...), beCalled(times: times))`.
- The `mostRecentlyBeCalled(_:)` matchers match only when the most recent call to
the Spy matches the matcher or is equal to the expected value.

## Source Stability

Swift Fakes is currently available as an Alpha. By 1.0, we aim to have it source
stable and following Semantic Versioning.
