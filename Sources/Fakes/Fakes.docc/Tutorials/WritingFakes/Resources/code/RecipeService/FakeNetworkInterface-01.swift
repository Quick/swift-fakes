final class FakeNetworkInterface: NetworkInterface {
    func get(from url: URL) -> Data {
        Data()
    }

    func post(data: Data, to url: URL) {}
}
