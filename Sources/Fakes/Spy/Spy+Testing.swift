//
//  Spy+Testing.swift
//  swift-fakes
//
//  Created by Rachel Brindle on 9/29/25.
//

extension Spy {
    /// Returns true if this spy has been called at least once.
    public var wasCalled: Bool {
        calls.isEmpty == false
    }

    /// Returns true if this spy has been called exactly as many times as specified.
    public func wasCalled(times: Int) -> Bool {
        calls.count == times
    }

    /// Returns true if this spy has not been called.
    public var wasNotCalled: Bool {
        calls.isEmpty
    }

    /// Returns whether this spy called at any time with the given value.
    public func wasCalled(with value: Arguments) -> Bool where Arguments: Equatable {
        calls.contains { call in
            call == value
        }
    }

    /// Returns whether this spy called with precisely these values, in this order.
    public func wasCalled(with values: [Arguments]) -> Bool where Arguments: Equatable {
        let currentCalls = calls
        guard currentCalls.count == values.count else { return false }

        for idx in 0..<currentCalls.count {
            if currentCalls[idx] != values[idx] { return false }
        }
        return true
    }

    /// Returns whether this spy was called at any time with a value that matches the given closure.
    public func wasCalled(matching matcher: (Arguments) -> Bool) -> Bool {
        calls.contains { call in
            matcher(call)
        }
    }

    /// Returns whether this spy was called with values that correspond to the order of closures given.
    ///
    /// For example, if this spy was called with `[1, 2]`, then `wasCalled(matching: [{ $0 == 1 }, { $0 == 2}])` would return true.
    public func wasCalled(matching matchers: [(Arguments) -> Bool]) -> Bool {
        let currentCalls = calls
        guard currentCalls.count == matchers.count else { return false }

        for idx in 0..<currentCalls.count {
            if matchers[idx](currentCalls[idx]) == false { return false }
        }
        return true
    }

    /// Returns whether the most recent call to the spy equals the given value.
    public func wasMostRecentlyCalled(with value: Arguments) -> Bool where Arguments: Equatable {
        calls.last == value
    }

    /// Returns whether the most recent call to the spy matches the given closure.
    public func wasMostRecentlyCalled(matching matcher: (Arguments) -> Bool) -> Bool where Arguments: Equatable {
        guard let lastCall = calls.last else { return false }
        return matcher(lastCall)
    }
}
