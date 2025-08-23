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
    @State private var recipeItems: [RecipeItem] = []
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
                ForEach($recipeItems) { $item in
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
        .padding()
    }
    
    func generateRecipe() {
        guard !foodIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        recipeItems = []
        
        let instructions = """
        You are a helpful and knowledgeable chef. Given a food idea, generate a detailed, step-by-step recipe with ingredients and instructions. Be informative and comprehensive. Present the recipe as a list, each step or ingredient as a separate item.
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
                    let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty }
                    await MainActor.run {
                        self.recipeItems = lines.map { RecipeItem(text: $0) }
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
