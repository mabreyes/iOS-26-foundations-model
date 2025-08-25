import Foundation

enum RecipeParser {
    static func parseRecipeItems(from text: String) -> [String] {
        let rawLines = text.components(separatedBy: .newlines)
        let cleaned: [String] = rawLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                var l = line
                let patterns: [String] = [
                    "^[-*•‣◦]\\s+",
                    "^\\d+\\.\\s+",
                    "^\\(\\d+\\)\\s+",
                    "^#+\\s+",
                    "^[☐✅❌]\\s*"
                ]
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        l = regex.stringByReplacingMatches(in: l, range: NSRange(location: 0, length: l.utf16.count), withTemplate: "")
                    }
                }
                // Trim common markdown emphasis and trailing punctuation (e.g., **Ingredients:**)
                let punctuation = CharacterSet(charactersIn: "*_`~:;—- ")
                l = l.trimmingCharacters(in: punctuation.union(.whitespacesAndNewlines))
                return l.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { line in
                let lower = line.lowercased()
                // Normalize by trimming punctuation/emphasis around headings
                let norm = lower.trimmingCharacters(in: CharacterSet(charactersIn: " :*-_`~!()[]{}.,\"'\t").union(.whitespacesAndNewlines))
                let bannedWords = [
                    "sure!", "here's", "here is", "recipe:",
                    "ingredients", "ingredient",
                    "instructions", "instruction",
                    "directions", "direction",
                    "steps", "step"
                ]
                if bannedWords.contains(where: { norm == $0 || norm.hasPrefix($0) }) { return false }
                return true
            }
        return cleaned
    }

    static func parseRecipeSections(from text: String) -> ([RecipeItem], [RecipeItem]) {
        let parts = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n---\n")

        let ingredientsBlock: String
        let stepsBlock: String

        if parts.count >= 2 {
            ingredientsBlock = parts[0]
            stepsBlock = parts[1...].joined(separator: "\n")
        } else {
            let lines = text.components(separatedBy: .newlines)
            if let idx = lines
                .firstIndex(where: {
                    $0.lowercased().trimmingCharacters(in: .whitespaces).hasPrefix("instruction") || $0.lowercased()
                        .trimmingCharacters(in: .whitespaces).hasPrefix("direction")
                })
            {
                ingredientsBlock = lines[..<idx].joined(separator: "\n")
                stepsBlock = lines[idx...].joined(separator: "\n")
            } else {
                let items = parseRecipeItems(from: text).map { RecipeItem(text: $0) }
                return (items, [])
            }
        }

        let ingredients = parseRecipeItems(from: ingredientsBlock).map { RecipeItem(text: $0) }
        let steps = parseRecipeItems(from: stepsBlock).map { RecipeItem(text: $0) }
        return (ingredients, steps)
    }
}
