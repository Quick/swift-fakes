protocol NetworkInterface {
    func get(from url: URL) async throws -> Data
    func post(data: Data, to url: URL) async throws
}
