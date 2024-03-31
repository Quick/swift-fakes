final class FakeNetworkInterface: NetworkInterface {
    // a `ThrowingPendableSpy` is just a typealias for `Spy<..., ThrowingPendable<..., ...>>`.
    // Thus, it is still used exactly same way that `Spy` is.
    let getSpy = ThrowingPendableSpy<URL, Data, Error>() // PendableSpy and
    // ThrowingPendableSpy default to stub with `.pending`.
    func get(from url: URL) throws -> Data {
        try await getSpy(url)
    }

    let postSpy = ThrowingPendableSpy<(data: Data, url: URL), Void, Error>()
    func post(data: Data, to url: URL) throws {
        try await postSpy((data, url))
    }
}
