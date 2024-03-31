import XCTest

final class RecipeServiceTests: XCTestCase {
    var networkInterface: FakeNetworkInterface!
    var subject: RecipeService!

    override func setUp() {
        super.setUp()

        networkInterface = FakeNetworkInterface()
        subject = RecipeService(networkInterface: networkInterface)
    }

    func testFetchRecipes() throws {
        // Arrange step
        networkInterface.getSpy.stub(success: recipesArrayAsData) // when using
        // `ThrowingSpy`, to set the Success stub, use the `stub(success:)`
        // overload. You could also use `stub(.success(...))` to do the same
        // thing, though.

        // Act step
        let recipes = try subject.recipes()

        XCTAssertEqual(recipes, [...])
        XCTAssertEqual(
            networkInterface.getSpy.calls,
            [URL(string: "https://example.com/recipes")!]
        )
    }

    func testFetchRecipesRethrowsErrors() {
        // Arrange step
        let expectedError = TestError()
        networkInterface.getSpy.stub(failure: expectedError)

        // Act step
        let result = Result { try subject.recipes() }

        // Assert step
        switch result {
        case .success:
            XCTFail("Expected `recipes` to throw an error, but succeeded.")
        case .failure(let failure):
            XCTAssertEqual(failure as TestError, expectedError) // because
            // we are specifically testing that the error from
            // `NetworkInterface.get` is rethrown, we should specifically
            // test that the thrown error is the same error we stubbed
            // networkInterface with.
        }
    }

    func testStoreRecipe() throws {
        // Act step
        try subject.store(recipe: Recipe(...))

        // Assert Step
        XCTAssertEqual(networkInterface.postSpy.calls.count, 1)
        XCTAssertEqual(
            networkInterface.postSpy.calls.last?.data,
            expectedRecipeData
        )
        XCTAssertEqual(
            networkInterface.postSpy.calls.last?.url,
            URL(string: "https://example.com/recipes/store")!
        )
    }

    func testStoreRecipeRethrowsErrors() {
        // (You get the idea from `testFetchRecipesRethrowsErrors`)
    }
}
