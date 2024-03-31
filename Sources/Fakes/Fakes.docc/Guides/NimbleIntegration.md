#  Nimble Integration

Nimble Matchers to make asserting on ``Spy`` significantly nicer.

## Contents

- The ``beCalled(_:)-82qlg`` without any arguments matches if the `Spy` has been
called at least once. This is especially useful for verifying there are no
interactions with the `Spy`, by using `expect(spy).toNot(beCalled())`.
- The ``beCalled(_:times:)-6125c`` without any matcher arguments, matches if the
`Spy` has been called exactly the amount of times specified in the `times`
argument. For example, `expect(spy).to(beCalled(times: 3))` will pass if the
`Spy` has been called with any arguments exactly 3 times.
- The ``beCalled(_:)-82qlg`` matcher with any non-zero amount of matchers will
match if at least one of the calls to the `Spy` matches all of the passed-in
matchers. That is, `expect(spy).to(beCalled(equal(1), equal(2)))` will never
pass, because no single call to the `Spy` can pass both `equal(1)` and
`equal(2)`.
- The ``beCalled(_:times:)-6125c`` matcher with a non-zero matcher arguments
is effectively the same as `satisfyAllOf(beCalled(times:), beCalled(...))`. That
is, it matches if the `Spy` has been called exactly `times` times, and at least
one of the calls to the `Spy` matches all of the passed-in matchers.
For example:

```swift
let spy = Spy<Int, Void>()
spy(1)
spy(2)

expect(spy).to(beCalled(equal(1), times: 2))
```

will match because the `Spy` has been called twice, and at least one of those
calls is equal to 1.

- The ``mostRecentlyBeCalled(_:)-9i9t9`` matcher will match if the last recorded
call to the `Spy` matches all of the passed in matchers. Unlike the `beCalled`
matchers, ``mostRecentlyBeCalled(_:)-9i9t9`` will unconditionally fail if you
don't pass in any matchers.

- For all of variants of `beCalled` and `mostRecentlyBeCalled`: If the
`Arguments` to the `Spy` conforms to `Equatable`, you can directly pass in a
value of the same type to `beCalled` or `mostRecentlyBeCalled`. For example,
if you have a `Spy<Int, ...>`, you can use `beCalled(123)` in place of
`beCalled(equal(123))`. See ``beCalled(_:)-7sn1o``,
``beCalled(_:times:)-9320x``, and ``mostRecentlyBeCalled(_:)-91ves``.


> Tip: If your `Spy` takes multiple `Arguments` - that is, the `Arguments` generic is a
Tuple -, then you can make use of Nimble's built-in
[`map` matcher](https://quick.github.io/Nimble/documentation/nimble/map(_:_:)-6ykjm)
to easily verify a call to the matcher. For example:

```swift
let spy = Spy<(arg1: Double, arg2: String), Void>()

spy((1337.001, "hello world"))

expect(spy).to(beCalled(
    map(\.arg1, beCloseTo(1337, within: 0.01)),
    map(\.arg2, beginWith("hello"))
))
```

> Note: If you want to check that a Spy is not ever called as part of code
running on a background thread, use `expect(spy).toNever(beCalled())`.
