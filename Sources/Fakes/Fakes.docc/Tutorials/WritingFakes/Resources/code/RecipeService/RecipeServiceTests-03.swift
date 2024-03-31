import XCTest

final class RecipeServiceTests: XCTestCase {
    var networkInterface: FakeNetworkInterface!
    var subject: RecipeService!

    override func setUp() {
        super.setUp()

        networkInterface = FakeNetworkInterface()
        subject = RecipeService(networkInterface: networkInterface)
    }

    func testFetchRecipes() async throws {
        // Arrange step
        networkInterface.getSpy.stub(success: recipesArrayAsData)
        // `ThrowingPendableSpy` basically has the same interface as
        // `ThrowingSpy`.

        // Act step
        let recipes = try await subject.recipes()

        XCTAssertEqual(recipes, [...])
        XCTAssertEqual(
            networkInterface.getSpy.calls,
            [URL(string: "https://example.com/recipes")!]
        )
    }

    func testFetchRecipesRethrowsErrors() async throws {
        // ...
    }

    func testStoreRecipe() async throws {
        // Arrange step
        networkInterface.postSpy.stub(success: ()) // if we don't restub
        // `postSpy`, then we will end up blocking the test and throwing a
        // `PendableInProgressError`.

        // Act step
        try await subject.store(recipe: Recipe(...))

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

    func testStoreRecipeRethrowsErrors() async throws {
        // ...
    }
}
