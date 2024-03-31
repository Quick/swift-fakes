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
        // First, we stub the networkInterface with some data that
        // converts to an array of recipes. Because we are using a real
        // JSONDecoder in RecipeService, we must provide data that can be
        // converted to [Recipe].
        // Whatever you do, DO NOT start with an Array of Recipe, and convert
        // it to Data using `JSONEncoder`. That creates a tautology, and doesn't
        // actually check that your Recipe data can convert to actual Recipes.
        // If we update Recipe and forget to update the fixture, we want the
        // test to fail in order to let us know we either need to update the
        // fixture, or that we made a breaking change.
        networkInterface.getSpy.stub(recipesArrayAsData)

        // Act step
        let recipes = try subject.recipes()

        // Assert step
        XCTAssertEqual(
            recipes,
            [...]
        ) // verify that we retrieved and decoded the expected recipes.
        XCTAssertEqual(
            networkInterface.getSpy.calls,
            [URL(string: "https://example.com/recipes")!]
        ) // Verify that we actually made the call to networkInterface.get(from:)
    }

    func testStoreRecipe() throws {
        // Arrange step
        // Because NetworkInterface.post returns Void, we don't need
        // to stub anything.
        let recipe = Recipe(...)

        // Act step
        try subject.store(recipe: recipe)

        // Assert Step
        XCTAssertEqual(
            networkInterface.postSpy.calls.count,
            1
        ) // Verify that only one call to post was made.
        XCTAssertEqual(
            networkInterface.postSpy.calls.last?.data,
            expectedRecipeData
        ) // Verify that the Recipe was converted to Data correctly. As with
        // `testFetchRecipes`, we want to have an actual fixture we can compare
        // with, and not just use JSONEncoder().encode(recipe). Again, if we
        // did so, that would create a tautology, and doesn't actually check
        // that we converted to Data correctly.
        XCTAssertEqual(
            networkInterface.postSpy.calls.last?.url,
            URL(string: "https://example.com/recipes/store")!
        )
    }
}
