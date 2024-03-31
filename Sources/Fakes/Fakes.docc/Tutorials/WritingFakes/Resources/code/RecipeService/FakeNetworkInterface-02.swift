final class FakeNetworkInterface: NetworkInterface {
    // by convention, the name of a spy is the first part of the method name,
    // followed by Spy.
    let getSpy = Spy<URL, Data>(Data()) // Spies that do not return Void or
    // Pendable must be initialized with a default value.
    func get(from url: URL) -> Data {
        getSpy(url)
    }

    let postSpy = Spy<(data: Data, url: URL), Void>() // The first type for
    // a Spy is either a tuple of the arguments to the method, or the singular
    // argument to the method. When you use a tuple, it is most helpful to
    // create a named tuple. We will see more when we write the test.
    func post(data: Data, to url: URL) {
        postSpy((data, url)) // Swift allows us to pass an unnamed tuple in
        // place of a named tuple with the same types.
    }
}
