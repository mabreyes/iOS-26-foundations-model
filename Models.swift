import Foundation

struct RecipeItem: Identifiable {
    let id = UUID()
    let text: String
    var isChecked: Bool = false
}

enum ViewFilter: String, CaseIterable, Identifiable {
    case both = "Both"
    case ingredients = "Ingredients"
    case steps = "Steps"
    var id: String { rawValue }
}
