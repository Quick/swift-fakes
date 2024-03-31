protocol NetworkInterface {
    func get(from url: URL) -> Data
    func post(data: Data, to url: URL)
}
