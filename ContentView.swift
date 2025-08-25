//
//  ContentView.swift
//  ios-foundations
//
//  Created by Marc on 7/23/25.
//

import Foundation
import SwiftUI

// Models moved to Models.swift

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
                .fill(AITheme.gradient.opacity(0.20))
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
                Label(isLoading ? "Generating" : "Generate Recipe", systemImage: isLoading ? "hourglass" : "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GradientButtonStyle())
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
            if isLoading {
                LoadingListPlaceholder()
            } else if ingredientItems.isEmpty, stepItems.isEmpty {
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

        // Generate via service
        Task {
            do {
                if #available(iOS 18.0, *) {
                    let (ings, steps) = try await RecipeGenerator.generate(for: foodIdea)
                    await MainActor.run {
                        self.ingredientItems = ings
                        self.stepItems = steps
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "This feature requires iOS 18 or later and a supported device."
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate recipe: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
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

// Components moved to Components.swift
