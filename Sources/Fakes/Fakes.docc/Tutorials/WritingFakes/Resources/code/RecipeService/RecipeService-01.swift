import Foundation

struct Recipe: Equatable, Codable {
    // ...
}

struct RecipeService {
    let networkInterface: NetworkInterface

    func recipes() throws -> [Recipe] {
        let url = URL(string: "https://example.com/recipes")!
        let data = networkInterface.get(from: url)
        return try JSONDecoder().decode([Recipe].self, from: data)
    }

    func store(recipe: Recipe) throws {
        let url = URL(string: "https://example.com/recipes/store")!
        let data = try JSONEncoder().encode(recipe)
        networkInterface.post(data: data, to: url)
    }
}
