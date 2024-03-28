import Nimble

/// A Nimble matcher for ``Spy`` that succeeds when the spy has been called at least once.
public func beCalled<Arguments, Returning>() -> Matcher<Spy<Arguments, Returning>> {
    return Matcher.define("be called") { expression, message in
        guard let spy = try expression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }
        return MatcherResult(bool: spy.calls.isEmpty == false, message: message)
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when the spy has been called the exact amount of times specified.
///
/// - parameter times: the amount of times you expect the Spy to have been called.
public func beCalled<Arguments, Returning>(times: Int) -> Matcher<Spy<Arguments, Returning>> {
    return Matcher.define("be called") { expression, message in
        guard let spy = try expression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }
        return MatcherResult(bool: spy.calls.count == times, message: message)
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when any of the calls to the spy matches the given matcher.
///
/// - parameter matcher: The matcher to run against the calls to spy to verify it has been called correctly
/// - Note: If the Spy's `Arguments` is Equatable, you can use `BeCalled` with the expected value. This is the same as `beCalled(equal(expectedValue))`.
/// - SeeAlso: ``mostRecentlyBeCalled(_:)`` for when you want to check that only the most recent call to the spy matches the matcher.
public func beCalled<Arguments, Returning>(_ matcher: Matcher<Arguments>) -> Matcher<Spy<Arguments, Returning>> {
    return Matcher.define("be called with \(stringify(matcher))") { expression, message in
        guard let spy = try expression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        for call in spy.calls {
            let matcherExpression = Expression(
                expression: { call },
                location: expression.location
            )
            let result = try matcher.satisfies(matcherExpression)
            if result.toBoolean(expectation: .toMatch) {
                return MatcherResult(bool: true, message: message)
            }
        }
        return MatcherResult(bool: false, message: message)
    }
}

/// A nimble matcher for ``Spy`` that succeeds when the spy has been called
/// `times` times, and it has been called at least once with arguments that match
/// the matcher.
///
/// For example, if your spy has been called a total of 4 times, and at least of those times matching whatever your matcher is, then `beCalled(..., times: 4)` will match.
/// However, `beCalled(..., times: 3)` will not match, because the matcher has been called 4 times.
/// If you wish to check how much the spy has been called in total, use ``beCalled(times:)``.
///
/// This is a shorthand for `satisfyAllOf(beCalled(times: times), beCalled(matcher))`
///
/// - parameter matcher: The matcher used to search for matching calls.
/// - parameter times: The expected amount of calls the Spy should have been called.
public func beCalled<Arguments, Returning>(_ matcher: Matcher<Arguments>, times: Int) -> Matcher<Spy<Arguments, Returning>> {
    return Matcher.define("be called with \(stringify(matcher)) \(times) times") { expression, message in
        guard let spy = try expression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        let calls = spy.calls

        if calls.count != times {
            return MatcherResult(bool: false, message: message.appended(details: "but was called \(calls.count) times"))
        }

        for call in calls {
            let matcherExpression = Expression(
                expression: { call },
                location: expression.location
            )
            let result = try matcher.satisfies(matcherExpression)
            if result.toBoolean(expectation: .toMatch) {
                return MatcherResult(bool: true, message: message)
            }
        }
        return MatcherResult(bool: false, message: message)
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when any of the calls to the spy are equal to the given value.
///
/// - parameter value: The expected value of any of the calls to the `Spy`.
/// - SeeAlso: ``beCalled(_:)``
public func beCalled<Arguments, Returning>(_ value: Arguments) -> Matcher<Spy<Arguments, Returning>> where Arguments: Equatable {
    beCalled(equal(value))
}

/// A Nimble matcher for ``Spy`` that succeeds when the spy has been called `times` times,
/// and at least one of those calls is equal to the given value.
///
/// This is a shorthand for `satisfyAllOf(beCalled(times: times), beCalled(value))`
///
/// - parameter value: The expected value of any of the calls to the `Spy`.
/// - parameter times: The expected amount of calls the Spy should have been called.
/// - SeeAlso: ``beCalled(_:)``
public func beCalled<Arguments, Returning>(_ value: Arguments, times: Int) -> Matcher<Spy<Arguments, Returning>> where Arguments: Equatable {
    beCalled(equal(value), times: times)
}

/// A Nimble matcher for ``Spy`` that succeeds when the most recent call to the spy matches the given matcher.
///
/// - SeeAlso: ``beCalled(_:)`` for when you want to check if any of the calls to the spy match the matcher.
/// - SeeAlso: ``mostRecentlyBeCalled(_:)`` as a shorthand when Arguments is equatable, and you want to check if it's equal to some value.
public func mostRecentlyBeCalled<Arguments, Returning>(_ matcher: Matcher<Arguments>) -> Matcher<Spy<Arguments, Returning>> {
    return Matcher.define("most recently be called with \(stringify(matcher))") { expression, message in
        guard let spy = try expression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard let lastCall = spy.calls.last else {
            return MatcherResult(status: .fail, message: message.appended(message: "but spy was never called."))
        }


        let matcherExpression = Expression(
            expression: { lastCall },
            location: expression.location
        )
        let result = try matcher.satisfies(matcherExpression)

        return MatcherResult(bool: result.toBoolean(expectation: .toMatch), message: message)
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when the most recent call to the spy is equal to the expected value.
///
/// - SeeAlso: ``beCalled(_:)`` for when you want to check if any of the calls to the spy are equal to the expected value
/// - SeeAlso: ``mostRecentlyBeCalled(_:)`` when you want to use a Matcher to check if the most recent call matches.
public func mostRecentlyBeCalled<Arguments, Returning>(_ value: Arguments) -> Matcher<Spy<Arguments, Returning>> where Arguments: Equatable {
    mostRecentlyBeCalled(equal(value))
}

extension Spy: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Spy<\(stringify(Arguments.self)), \(stringify(Returning.self))>, calls: \(stringify(calls))"
    }
}
