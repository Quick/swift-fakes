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

Spies are meant to be used in Fake objects to record arguments to a call, and
return pre-stubbed responses.

See the [documentation](https://quick.github.io/swift-fakes/documentation/fakes).

## Source Stability

Swift Fakes is currently available as an Alpha. By 1.0, we aim to have it source
stable and following Semantic Versioning.
