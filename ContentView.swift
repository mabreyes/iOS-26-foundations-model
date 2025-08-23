//
//  ContentView.swift
//  ios-foundations
//
//  Created by Marc on 7/23/25.
//

import Foundation
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

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

struct ContentView: View {
    @State private var foodIdea: String = ""
    @State private var ingredientItems: [RecipeItem] = []
    @State private var stepItems: [RecipeItem] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var filter: ViewFilter = .both
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header
                inputCard
                filterPicker
                checklistCard
            }
            .padding()
            .navigationTitle("AI Recipe Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { inputFocused = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) { clearAll() } label: { Image(systemName: "trash") }
                        .disabled(ingredientItems.isEmpty && stepItems.isEmpty)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundStyle(.blue)
                Text("Recipe Assistant")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                if isLoading { ProgressView().scaleEffect(0.8) }
            }
            Text("Generate ingredients and step-by-step directions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.18), .purple.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05))
        )
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food idea")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TextField("e.g. create recipe for pinakbet", text: $foodIdea)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .focused($inputFocused)
                Button(action: { foodIdea = "" }) { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .opacity(foodIdea.isEmpty ? 0 : 1)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            Button(action: generateRecipe) {
                Label("Generate Recipe", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(foodIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
    }

    private var filterPicker: some View {
        Picker("View", selection: $filter) {
            ForEach(ViewFilter.allCases) { f in
                Text(f.rawValue).tag(f)
            }
        }
        .pickerStyle(.segmented)
    }

    private var checklistCard: some View {
        Group {
            if ingredientItems.isEmpty, stepItems.isEmpty {
                EmptyStateView()
            } else {
                List {
                    if filter == .both || filter == .ingredients {
                        if !ingredientItems.isEmpty {
                            Section("Ingredients") {
                                ForEach($ingredientItems) { $item in
                                    ChecklistRow(item: $item)
                                }
                            }
                        }
                    }
                    if filter == .both || filter == .steps {
                        if !stepItems.isEmpty {
                            Section("Steps") {
                                ForEach($stepItems) { $item in
                                    ChecklistRow(item: $item)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)
            }
        }
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
                    var (ings, steps) = RecipeParser.parseRecipeSections(from: text)
                    if ings.isEmpty, steps.isEmpty {
                        // Fallback: treat the whole text as flat list to show something meaningful
                        let flat = RecipeParser.parseRecipeItems(from: text).map { RecipeItem(text: $0) }
                        if flat.isEmpty {
                            throw NSError(domain: "Recipe", code: -1, userInfo: [NSLocalizedDescriptionKey: "No items returned by model"])
                        }
                        // Heuristically split: first half ingredients, second half steps
                        let mid = max(1, flat.count / 2)
                        ings = Array(flat.prefix(mid))
                        steps = Array(flat.suffix(from: mid))
                    }
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

    private func clearAll() {
        ingredientItems = []
        stepItems = []
        errorMessage = nil
    }
}

#Preview {
    ContentView()
}

// MARK: - Components

struct ChecklistRow: View {
    @Binding var item: RecipeItem
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { item.isChecked.toggle() }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)
            Text(item.text)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Your recipe will appear here")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
