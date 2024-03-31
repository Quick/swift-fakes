import Foundation

struct Recipe: Equatable, Codable {
    // ...
}

struct RecipeService {
    let networkInterface: NetworkInterface

    func recipes() async throws -> [Recipe] {
        let url = URL(string: "https://example.com/recipes")!
        let data = try await networkInterface.get(from: url)
        return try JSONDecoder().decode([Recipe].self, from: data)
    }

    func store(recipe: Recipe) async throws {
        let url = URL(string: "https://example.com/recipes/store")!
        let data = try JSONEncoder().encode(recipe)
        try await networkInterface.post(data: data, to: url)
    }
}
