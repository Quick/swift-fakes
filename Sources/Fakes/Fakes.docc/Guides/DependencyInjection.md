# Dependency Injection

Providing dependencies instead of reaching out to them.

## Contents

**Dependency Injection** means to provide the dependencies for an object, instead
of the object _a priori_ knowing how to either reach them, or how to make them
itself. Dependency injection is a fundamental design pattern for enabling and
improving not just testability of an object, but also the reliability of the
entire system.

An object can have 2 types of dependencies: Implicit and Explicit. Explicit
dependencies are anything passed in or otherwise given to the object. Implicit
dependencies, thus, are anything the object itself knows how to call or make.
Even putting aside testability, implicit dependencies inherently make your
system's dependency graph harder to read. That said, not all implicit
dependencies are bad: it would be absurd to inject the `+` operator just for
testability.

## Testing `greetingForTimeOfDay`

For example, consider a function that uses the current time in order to greet
the user with one of either "Good morning", "Good afternoon", or "Good evening".
Without using dependency injection, you might write the code as:

```swift
func greetingForTimeOfDay() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 0..<12: return "Good morning"
    case 12..<18: return "Good afternoon"
    default: return "Good evening"
    }
}
```

Which, sure, works, but is impossible to reliably test. The result of
`greetingForTimeOfDay`, by definition, depends on the current time of
day. Which means that you have three choices for testing this as-written:

- Don't test it.
- Write a weaker test, just checking that the output is one of the three choices:
That is: `XCTAssert(["Good morning", "Good afternoon", "Good evening"].contains(greetingForTimeOfDay()))`.
This is not only harder to read, but you're bundling up the three behaviors of
`greetingForTimeOfDay` and making the tests less clear than asserting on the
exact output.
- Add logic to your tests, wherein you basically end up re-implementing
`greetingForTimeOfDay` in your tests, thus creating a tautology.
That is, writing your test like:

```swift
func testGreetingForTimeOfDay() {
    let greeting = greetingForCurrentTimeOfDay()

    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 0..<12: XCTAssertEqual(greeting, "Good morning")
    case 12..<18: XCTAssertEqual(greeting, "Good afternoon")
    default: XCTAssertEqual(greeting, "Good evening")
    }
}
```

> Note: A Tautological Test is a test that is a mirror of the production code.
In this example, this is fairly easy to identify, but they can get quite tricky
as we introduce fakes. See [this post from Fabio Pereira](https://www.fabiopereira.me/blog/2010/05/27/ttdd-tautological-test-driven-development-anti-pattern/).

Neither of these three options are examples of strong, reliable, easy-to-read
tests. Instead, to be able to write better tests, we must improve the testability
of `greetingForTimeOfDay` by injecting the dependencies.

`greetingForTimeOfDay` has 2 implicit dependencies: The `Calendar` object,
and the current `Date`. In this particular case, we could inject either one and
be able to massively improve the testability of the function. For the sake of
teaching, let's cover both.

### Injecting a DateProvider

First, let's look at injecting a way to get the current `Date`, instead of
making a new `Date` object that Foundation helpfully assigns to the current
`Date`. We could do this in one of three ways: Directly pass in a `Date` object,
Inject a protocol that has a method which returns the current `Date`, or inject
a closure that returns the current `Date`. The first is just kicking the issue
of getting the date up the stack, and thus not something we should do. The
second is doable, but rather complex for this particular case. So, let's go with
the third option.

```swift
typealias DateProvider = () -> Date // The typealias is not necessary, but it
// does help a lot with readability.

func greetingForTimeOfDay(dateProvider: DateProvider) -> String {
    let hour = Calendar.current.component(.hour, from: dateProvider())
    switch hour {
    case 0..<12: return "Good morning"
    case 12..<18: return "Good afternoon"
    default: return "Good evening"
    }
}
```

This is already a massive improvement! Now, we can write our tests for the 3
potential states like so:

```swift
final class GreetingForTimeOfDayTests: XCTestCase {
    var dateSpy: Spy<Void, Date>!
    override func setUp() {
        super.setUp()
        dateSpy = .init(Date())
    }

    func testMorning() {
        // Arrange
        dateSpy.stub(Date(timeIntervalSince1970: 3600)) // Jan 1st, 1970 at ~1 am.

        // Act
        let greeting = greetingForTimeOfDay(dateProvider: dateSpy.callAsFunction)

        // Assert
        XCTAssertEqual(greeting, "Good morning")
    }

    func testAfternoon() {
        // Arrange
        dateSpy.stub(Date(timeIntervalSince1970: 3600 * 12)) // Jan 1st, 1970 at ~noon am.

        // Act
        let greeting = greetingForTimeOfDay(dateProvider: dateSpy.callAsFunction)

        // Assert
        XCTAssertEqual(greeting, "Good afternoon")
    }

    func testEvening() {
        // Arrange
        dateSpy.stub(Date(timeIntervalSince1970: 3600 * 18)) // Jan 1st, 1970 at ~6 pm.

        // Act
        let greeting = greetingForTimeOfDay(dateProvider: dateSpy.callAsFunction)

        // Assert
        XCTAssertEqual(greeting, "Good evening")
    }
}
```

> Note: Annoyed at the setup and act repitition? Check out
[Quick](https://github.com/Quick/Quick/)! It provides a simple DSL enabling
powerful test simplifications.

This is significantly easier to understand the three behaviors that
`greetingForTimeOfDay` has. However, it still requires us to carefully construct
the Date objects that are then passed into the `Calendar`. So, let's look at
injecting the `Calendar`.

### Injecting `Calendar`

We could follow the same procedure as with `DateProvider`, and inject a closure
in lieu of `Calendar.current.component(_:from:)`. However, this case is just
complicated enough that we should take advantage of one of Swift's most powerful
features: protocol oriented programming.

> Tip: If you haven't watched the amazing WWDC 2015 talk, [Protocol Oriented
Programming in Swift](https://www.youtube.com/watch?v=p3zo4ptMBiQ), be sure to
take the time to do so!

Let's start by creating a protocol to wrap `Calendar`. For this case, we only
need a single method in that protocol, but you can imagine this protocol might
grow with time (or not, as per the [Interface Segregation Principle](https://en.wikipedia.org/wiki/Interface_segregation_principle)).

```swift
protocol CalendarProtocol {
    func component(
        _ component: Calendar.Component,
        from date: Date
    ) -> Int
}

extension Calendar: CalendarProtocol {}
```

Because `component(_:from:)` is already an existing method on `Calendar`,
conforming `Calendar` to `CalendarProtocol` requires no additional methods.

Next, we have to inject our `CalendarProtocol` into `greetingForTimeOfDay`:

```swift
func greetingForTimeOfDay(calendar: CalendarProtocol, dateProvider: DateProvider) -> String {
    let hour = calendar.component(.hour, from: dateProvider())
    switch hour {
    case 0..<12: return "Good morning"
    case 12..<18: return "Good afternoon"
    default: return "Good evening"
    }
}
```

Which, again, is a fairly straightforward thing to do.

Now, let's create a Fake implementation of `CalendarProtocol`. For more details
on creating fakes, please check out the tutorial <doc:WritingFakes>.

```swift
final class FakeCalendar: CalendarProtocol {
    let componentSpy = Spy<(component: Calendar.Component, date: Date), Int>(0)
    func component(
        _ component: Calendar.Component,
        from date: Date
    ) -> Int {
        componentSpy((component, date))
    }
}
```

Finally, we can update our tests to use `FakeCalendar`.

```swift
final class GreetingForTimeOfDayTests: XCTestCase {
    var dateSpy: Spy<Void, Date>!
    var calendar: FakeCalendar!
    override func setUp() {
        super.setUp()
        dateSpy = .init(Date())
        calendar = FakeCalendar()
    }

    func testMorning() {
        // Arrange
        calendar.componentsSpy.stub(0)

        // Act
        let greeting = greetingForTimeOfDay(
            calendar: calendar,
            dateProvider: dateSpy.callAsFunction
        )

        // Assert
        XCTAssertEqual(greeting, "Good morning")
    }

    func testAfternoon() {
        // Arrange
        calendar.componentsSpy.stub(12)

        // Act
        let greeting = greetingForTimeOfDay(
            calendar: calendar,
            dateProvider: dateSpy.callAsFunction
        )

        // Assert
        XCTAssertEqual(greeting, "Good afternoon")
    }

    func testEvening() {
        // Arrange
        calendar.componentsSpy.stub(18)

        // Act
        let greeting = greetingForTimeOfDay(
            calendar: calendar,
            dateProvider: dateSpy.callAsFunction
        )

        // Assert
        XCTAssertEqual(greeting, "Good evening")
    }
}
```

This is significantly easier to read. By injecting our `FakeCalendar`, we were
able to make `greetingForTimeOfDay` significantly easier to test, as well as
drastically improving the readability and reliability of the tests.

You might notice that these tests never verified that `FakeCalendar` or
`dateSpy` were called. That's because it's entirely unnecessary to do so in
this case. Generally, you only need to verify those as either part of
scaffolding tests (tests which are only necessary while writing out the
component), or when they have some kind of side effect in addition to their
return value. For example, making a network call by definition has side
effects (in addition to returning the data/throwing an error). So you would want
to verify that the ``Spy`` for the network call has recorded a call.

### Dependency Injection for Types

If `greetingForTimeOfDay` were wrapped in a type, you should inject
`CalendarProtocol` and `DateProvider` as arguments to the types initializer.
That way, callers of `greetingForTimeOfDay` only need the wrapping type, and not
the `CalendarProtocol` and `DateProvider`. Like so:

```swift
struct Greeter {
    let calendar: CalendarProtocol
    let dateProvider: DateProvider

    func greetingForTimeOfDay() -> String {
        let hour = calendar.component(.hour, from: dateProvider())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
```

---

By the way, did you notice the other three potential issues here? That's
right, different people and cultures might define morning, afternoon, and
evening differently.
