final class FakeNetworkInterface: NetworkInterface {
    // a `ThrowingSpy` is just a typealias for `Spy<..., Result<..., ...>>`.
    // Thus, it is still used exactly same way that `Spy` is.
    let getSpy = ThrowingSpy<URL, Data, Error>(Data())
    func get(from url: URL) throws -> Data {
        try getSpy(url) // This now uses the overload of `callAsFunction` to one
        // that can either return `Success` (in this case, `Data`) or throw an error
    }

    let postSpy = ThrowingSpy<(data: Data, url: URL), Void, Error>()
    func post(data: Data, to url: URL) throws {
        return try postSpy((data, url)) // the return statement here is necessary
        // to force swift to use the correct form of Spy's `callAsFunction`.
    }
}
