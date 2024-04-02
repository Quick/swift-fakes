protocol NetworkInterface {
    func get(from url: URL) throws -> Data
    func post(data: Data, to url: URL) throws
}
