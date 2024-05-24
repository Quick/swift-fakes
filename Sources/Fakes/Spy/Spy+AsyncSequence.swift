extension Spy {
    public func record<AS: AsyncSequence>(_ sequence: AS) async where Arguments == Result<AS.Element, Error>, Returning == Void {
        do {
            for try await value in sequence {
                self(.success(value))
            }
        } catch {
            self(.failure(error))
        }
    }
}
