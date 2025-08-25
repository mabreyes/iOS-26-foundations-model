import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum RecipeGeneratorError: Error {
    case unsupportedPlatform
    case emptyResponse
}

enum RecipeGenerator {
    @available(iOS 18.0, *)
    static func generate(for idea: String) async throws -> ([RecipeItem], [RecipeItem]) {
        let instructions = """
        You are a helpful and knowledgeable chef. Given a food idea, generate a detailed recipe with ingredients followed by concise step-by-step instructions.
        OUTPUT FORMAT (strict):
        - First list all ingredients, ONE per line.
        - Then output a SINGLE delimiter line containing exactly: ---
        - Then list all steps, ONE per line.
        HARD CONSTRAINTS:
        - No introductions, headings, section titles, categories, or notes.
        - No Markdown (no #, *, -, •), no numbering, and no checkboxes.
        - Do not prefix items with punctuation or emojis.
        - Keep each item on one line.
        SAFETY REQUIREMENTS:
        - Only provide benign, non-harmful cooking guidance appropriate for general audiences.
        - Avoid hazardous, violent, or explicit language; keep tone neutral and safety‑conscious.
        - If a requested item is unsafe, substitute a safe culinary alternative.
        """
        #if canImport(FoundationModels)
        return try await request(prompt: idea, instructions: instructions, attempt: 0)
        #else
        throw RecipeGeneratorError.unsupportedPlatform
        #endif
    }

    @available(iOS 18.0, *)
    private static func request(prompt: String, instructions: String, attempt: Int) async throws -> ([RecipeItem], [RecipeItem]) {
        #if canImport(FoundationModels)
        let session = LanguageModelSession(instructions: Instructions(instructions))
        let result = try await session.respond(to: Prompt(prompt))
        let text = result.content
        var (ings, steps) = RecipeParser.parseRecipeSections(from: text)
        if ings.isEmpty, steps.isEmpty {
            let flat = RecipeParser.parseRecipeItems(from: text).map { RecipeItem(text: $0) }
            if flat.isEmpty {
                // Safety-related or empty content: retry once with stricter safety
                if attempt == 0 {
                    let safer = instructions + "\n" + """
                    STRICT SAFETY: Keep content universally safe. Do not include hazardous activities; phrase cutting/slicing as careful, standard culinary technique.
                    """.trimmingCharacters(in: .whitespacesAndNewlines)
                    return try await request(prompt: prompt, instructions: safer, attempt: attempt + 1)
                }
                throw RecipeGeneratorError.emptyResponse
            }
            let mid = max(1, flat.count / 2)
            ings = Array(flat.prefix(mid))
            steps = Array(flat.suffix(from: mid))
        }
        return (ings, steps)
        #else
        throw RecipeGeneratorError.unsupportedPlatform
        #endif
    }
}
