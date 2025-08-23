//
//  ContentView.swift
//  ios-foundations
//
//  Created by Marc on 7/23/25.
//

import SwiftUI
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct RecipeItem: Identifiable {
    let id = UUID()
    let text: String
    var isChecked: Bool = false
}

struct ContentView: View {
    @State private var foodIdea: String = ""
    @State private var ingredientItems: [RecipeItem] = []
    @State private var stepItems: [RecipeItem] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Recipe Generator")
                .font(.title)
                .bold()
            TextField("Enter a food idea (e.g., create recipe for pinakbet)", text: $foodIdea)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 8)
            Button(action: generateRecipe) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Generate Recipe")
                }
            }
            .disabled(foodIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            List {
                if !ingredientItems.isEmpty {
                    Section("Ingredients") {
                        ForEach($ingredientItems) { $item in
                            HStack {
                                Button(action: { item.isChecked.toggle() }) {
                                    Image(systemName: item.isChecked ? "checkmark.square" : "square")
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text(item.text)
                            }
                        }
                    }
                }
                if !stepItems.isEmpty {
                    Section("Steps") {
                        ForEach($stepItems) { $item in
                            HStack {
                                Button(action: { item.isChecked.toggle() }) {
                                    Image(systemName: item.isChecked ? "checkmark.square" : "square")
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text(item.text)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func parseRecipeItems(from text: String) -> [RecipeItem] {
        let separators = CharacterSet.newlines
        let rawLines = text.components(separatedBy: separators)
        let cleaned: [String] = rawLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                var l = line
                // Strip common markdown bullets and numbering
                let patterns: [String] = [
                    "^[-*•‣◦]\\s+",            // bullets: -, *, •, ‣, ◦
                    "^\\d+\\.\\s+",           // 1. item
                    "^\\(\\d+\\)\\s+",       // (1) item
                    "^#+\\s+",                 // markdown headings
                    "^[☐✅❌]\\s*"              // checkboxes and marks
                ]
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                        l = regex.stringByReplacingMatches(in: l, options: [], range: NSRange(location: 0, length: l.utf16.count), withTemplate: "")
                    }
                }
                return l.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Remove generic intro lines and section titles
            .filter { line in
                let lower = line.lowercased()
                let bannedPrefixes = [
                    "sure!", "here's", "here is", "recipe:",
                    "ingredients", "for the cupcakes", "instructions", "directions"
                ]
                if bannedPrefixes.contains(where: { lower.hasPrefix($0) }) { return false }
                // Remove bare section headers
                if ["ingredients", "instructions", "directions"].contains(lower) { return false }
                return true
            }
        return cleaned.map { RecipeItem(text: $0) }
    }

    private func parseRecipeSections(from text: String) -> ([RecipeItem], [RecipeItem]) {
        // Collapse wrapped lines: if a line ends with a comma or semicolon, keep as is; otherwise, treat each line as an item.
        // Split sections by strict delimiter `---`. If missing, fall back to heuristic split.
        let parts = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n---\n")

        let ingredientsBlock: String
        let stepsBlock: String

        if parts.count >= 2 {
            ingredientsBlock = parts[0]
            stepsBlock = parts[1...].joined(separator: "\n")
        } else {
            // Heuristic: try to find a transition line like "instructions" or "directions"
            let lines = text.components(separatedBy: .newlines)
            if let idx = lines.firstIndex(where: { $0.lowercased().trimmingCharacters(in: .whitespaces).hasPrefix("instruction") || $0.lowercased().trimmingCharacters(in: .whitespaces).hasPrefix("direction") }) {
                ingredientsBlock = lines[..<idx].joined(separator: "\n")
                stepsBlock = lines[idx...].joined(separator: "\n")
            } else {
                // If no clue, treat entire text as a single list
                let items = parseRecipeItems(from: text)
                return (items, [])
            }
        }

        let ingredientItems = parseRecipeItems(from: ingredientsBlock)
        let stepItems = parseRecipeItems(from: stepsBlock)
        return (ingredientItems, stepItems)
    }

    func generateRecipe() {
        guard !foodIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        ingredientItems = []
        stepItems = []
        
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
        """
        let prompt = foodIdea
        
        // Use Foundation Models API (iOS 18+)
        if #available(iOS 18.0, *) {
            #if canImport(FoundationModels)
            Task {
                do {
                    let session = LanguageModelSession(instructions: Instructions(instructions))
                    let result = try await session.respond(to: Prompt(prompt))
                    let text = result.content
                    let (ings, steps) = self.parseRecipeSections(from: text)
                    await MainActor.run {
                        self.ingredientItems = ings
                        self.stepItems = steps
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate recipe: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
            #else
            self.errorMessage = "This feature requires the FoundationModels framework (iOS 18+)."
            self.isLoading = false
            #endif
        } else {
            self.errorMessage = "This feature requires iOS 18 or later and a supported device."
            self.isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
