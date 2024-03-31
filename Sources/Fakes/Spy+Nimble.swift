import Nimble

// MARK: - Verifying any calls to the Spy.

/// A Nimble matcher for ``Spy`` that succeeds when any of the calls to the spy matches the given matchers.
///
/// If no matchers are specified, then this matcher will succeed if the spy has been called at all.
///
/// - parameter matchers: The matchers to run against the calls to spy to verify it has been called correctly
/// - Note: If the Spy's `Arguments` is Equatable, you can use `BeCalled` with
/// the expected value. This is the same as `beCalled(equal(expectedValue))`.
/// - Note: All matchers for a single call must pass in order for this matcher
/// to pass. Specifying multiple matchers DOES NOT verify multiple calls.
/// Passing in multiple matchers is a shorthand for `beCalled(satisfyAllOf(...))`.
/// - SeeAlso: ``mostRecentlyBeCalled(_:)-9i9t9`` for when you want to check that
/// only the most recent call to the spy matches the matcher.
public func beCalled<Arguments, Returning>(
    _ matchers: Matcher<Arguments>...
) -> Matcher<Spy<Arguments, Returning>> {
    let rawMessage: String
    if matchers.isEmpty {
        rawMessage = "be called"
    } else {
        rawMessage = "be called with \(matchers.count) matchers"
    }
    return _beCalled(rawMessage: rawMessage) { validatorArgs in
        if matchers.isEmpty {
            return MatcherResult(
                bool: validatorArgs.spy.calls.isEmpty == false,
                message: validatorArgs.message)
        }
        for call in validatorArgs.spy.calls {
            let matcherExpression = Expression(
                expression: { call },
                location: validatorArgs.expression.location
            )
            let results = try matchers.map {
                try $0.satisfies(matcherExpression)
            }
            if results.allSatisfy({ $0.toBoolean(expectation: .toMatch) }) {
                return MatcherResult(
                    bool: true,
                    message: validatorArgs.message.appended(
                        details: results.map {
                            $0.message.toString(
                                actual: stringify(validatorArgs.spy)
                            )
                        }.joined(separator: "\n")
                    )
                )
            }
        }
        return MatcherResult(bool: false, message: validatorArgs.message)
    }
}

/// A nimble matcher for ``Spy`` that succeeds when the spy has been called
/// `times` times, and it has been called at least once with arguments that match
/// the matcher.
///
/// If no matchers are given, then this matcher will succeed if the spy has
/// been called exactly the number of times specified.
///
/// For example, if your spy has been called a total of 4 times, and at least one of those times matching
/// whatever your matcher is, then `beCalled(..., times: 4)` will match.
/// However, `beCalled(..., times: 3)` will not match, because the matcher has been called 4 times.
///
/// Alternatively, if your spy has been called a total of 4 times, and you pass in 0 matchers, then
/// `beCalled(times: 4)` will match, regardless of what those calls are.
///
/// - parameter matchers: The matchers used to search for matching calls.
/// - parameter times: The expected amount of calls the Spy should have been called.
///
/// - Note: All matchers for a single call must pass in order for this matcher
/// to pass. Specifying multiple matchers DOES NOT verify multiple calls.
/// Passing in multiple matchers is a shorthand for `beCalled(satisfyAllOf(...))`.
public func beCalled<Arguments, Returning>(
    _ matchers: Matcher<Arguments>...,
    times: Int
) -> Matcher<Spy<Arguments, Returning>> {
    let rawMessage: String
    if matchers.isEmpty {
        rawMessage = "be called \(times) times"
    } else {
        rawMessage = "be called \(times) times, at least one of them matches \(matchers.count) matchers"
    }
    return _beCalled(rawMessage: rawMessage) { validatorArgs in
        let calls = validatorArgs.spy.calls

        if calls.count != times {
            return MatcherResult(
                bool: false,
                message: validatorArgs.message.appended(
                    details: "but was called \(calls.count) times"
                )
            )
        }

        if matchers.isEmpty {
            return MatcherResult(bool: true, message: validatorArgs.message)
        }
        for call in calls {
            let matcherExpression = Expression(
                expression: { call },
                location: validatorArgs.expression.location
            )
            let results = try matchers.map {
                try $0.satisfies(matcherExpression)
            }
            if results.allSatisfy({ $0.toBoolean(expectation: .toMatch) }) {
                return MatcherResult(
                    bool: true,
                    message: validatorArgs.message.appended(
                        details: results.map {
                            $0.message.toString(
                                actual: stringify(validatorArgs.spy)
                            )
                        }.joined(separator: "\n")
                    )
                )
            }
        }
        return MatcherResult(bool: false, message: validatorArgs.message)
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when any of the calls to the spy are equal to the given value.
///
/// - parameter value: The expected value of any of the calls to the `Spy`.
/// - SeeAlso: ``beCalled(_:)-82qlg``
public func beCalled<Arguments, Returning>(
    _ value: Arguments
) -> Matcher<Spy<Arguments, Returning>> where Arguments: Equatable {
    let rawMessage = "be called with \(stringify(value))"
    return _beCalled(rawMessage: rawMessage) { validatorArgs in
        return MatcherResult(
            bool: validatorArgs.spy.calls.contains(value),
            message: validatorArgs.message
        )
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when the spy has been called `times` times,
/// and at least one of those calls is equal to the given value.
///
/// This is a shorthand for `satisfyAllOf(beCalled(times: times), beCalled(value))`
///
/// - parameter value: The expected value of any of the calls to the `Spy`.
/// - parameter times: The expected amount of calls the Spy should have been called.
/// - SeeAlso: ``beCalled(_:times:)-6125c``
public func beCalled<Arguments, Returning>(_ value: Arguments, times: Int) -> Matcher<Spy<Arguments, Returning>> where Arguments: Equatable {
    let rawMessage = "be called \(times) times, at least one of them is \(stringify(value))"
    return _beCalled(rawMessage: rawMessage) { validatorArgs in
        let calls = validatorArgs.spy.calls
        if calls.count != times {
            return MatcherResult(
                bool: false,
                message: validatorArgs.message.appended(
                    details: "but was called \(calls.count) times"
                )
            )
        }
        return MatcherResult(
            bool: calls.contains(value),
            message: validatorArgs.message
        )
    }
}

// MARK: - Verifying the last call to the Spy

/// A Nimble matcher for ``Spy`` that succeeds when the most recent call to the spy matches the given matchers.
///
/// - Note: This matcher will fail if no matchers have been passed.
/// - SeeAlso: ``beCalled(_:)-82qlg`` for when you want to check if any of the calls to the spy match the matcher.
/// - SeeAlso: ``mostRecentlyBeCalled(_:)-91ves`` as a shorthand when Arguments is equatable, and you want to check if it's equal to some value.
public func mostRecentlyBeCalled<Arguments, Returning>(_ matchers: Matcher<Arguments>...) -> Matcher<Spy<Arguments, Returning>> {
    let rawMessage = "most recently be called with \(matchers.count) matchers"
    return _mostRecentlyBeCalled(rawMessage: rawMessage) { validatorArgs in
        guard matchers.isEmpty == false else {
            return MatcherResult(status: .fail, message: validatorArgs.message.appended(
                message: "Error: No matchers were specified. " +
                "Use `beCalled()` to check if the spy has been called at all."
            ))
        }

        let matcherExpression = Expression(
            expression: { validatorArgs.lastCall },
            location: validatorArgs.expression.location
        )
        let results = try matchers.map {
            try $0.satisfies(matcherExpression)
        }
        if results.allSatisfy({ $0.toBoolean(expectation: .toMatch) }) {
        }
        return MatcherResult(
            bool: results.allSatisfy { $0.toBoolean(expectation: .toMatch) },
            message: validatorArgs.message.appended(details: results.map {
                $0.message.toString(
                    actual: stringify(validatorArgs.spy)
                )
            }.joined(separator: "\n"))
        )
    }
}

/// A Nimble matcher for ``Spy`` that succeeds when the most recent call to the spy is equal to the expected value.
///
/// - SeeAlso: ``beCalled(_:)-7sn1o`` for when you want to check if any of the calls to the spy are equal to the expected value
/// - SeeAlso: ``mostRecentlyBeCalled(_:)-9i9t9`` when you want to use a Matcher to check if the most recent call matches.
public func mostRecentlyBeCalled<Arguments, Returning>(
    _ value: Arguments
) -> Matcher<Spy<Arguments, Returning>> where Arguments: Equatable {
    let rawMessage = "most recently be called with \(stringify(value))"
    return _mostRecentlyBeCalled(rawMessage: rawMessage) { validatorArgs in
        return MatcherResult(
            bool: validatorArgs.lastCall == value,
            message: validatorArgs.message.appended(
                message: "but got \(stringify(validatorArgs.lastCall))"
            )
        )
    }
}

extension Spy: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Spy<\(stringify(Arguments.self)), \(stringify(Returning.self))>, calls: \(stringify(calls))"
    }
}

// MARK: - Private

private struct BeCalledValidatorArgs<Arguments, Returning> {
    let spy: Spy<Arguments, Returning>
    let expression: Expression<Spy<Arguments, Returning>>
    let message: ExpectationMessage

    init(
        _ spy: Spy<Arguments, Returning>,
        _ expression: Expression<Spy<Arguments, Returning>>,
        _ message: ExpectationMessage
    ) {
        self.spy = spy
        self.expression = expression
        self.message = message
    }
}

private func _beCalled<Arguments, Returning>(
    rawMessage: String,
    validator: @escaping (BeCalledValidatorArgs<Arguments, Returning>) throws -> MatcherResult
) -> Matcher<Spy<Arguments, Returning>> {
    return Matcher.define(rawMessage) { expression, message in
        guard let spy = try expression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        return try validator(BeCalledValidatorArgs(spy, expression, message))
    }
}

private struct MostRecentlyBeCalledValidatorArgs<Arguments, Returning> {
    let lastCall: Arguments
    let spy: Spy<Arguments, Returning>
    let expression: Expression<Spy<Arguments, Returning>>
    let message: ExpectationMessage

    init(
        _ lastCall: Arguments,
        _ spy: Spy<Arguments, Returning>,
        _ expression: Expression<Spy<Arguments, Returning>>,
        _ message: ExpectationMessage
    ) {
        self.lastCall = lastCall
        self.spy = spy
        self.expression = expression
        self.message = message
    }
}

private func _mostRecentlyBeCalled<Arguments, Returning>(
    rawMessage: String,
    validator: @escaping (
        MostRecentlyBeCalledValidatorArgs<Arguments, Returning>
    ) throws -> MatcherResult
) -> Matcher<Spy<Arguments, Returning>> {
    return _beCalled(rawMessage: rawMessage) { beCalledValidatorArgs in
        guard let lastCall = beCalledValidatorArgs.spy.calls.last else {
            return MatcherResult(
                status: .fail,
                message: beCalledValidatorArgs.message.appended(
                    message: "but spy was never called."
                )
            )
        }
        return try validator(
            MostRecentlyBeCalledValidatorArgs(
                lastCall,
                beCalledValidatorArgs.spy,
                beCalledValidatorArgs.expression,
                beCalledValidatorArgs.message
            )
        )
    }
}
