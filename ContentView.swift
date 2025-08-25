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
    @State private var showDeleteConfirm: Bool = false
    @State private var showDeleteItemConfirm: Bool = false
    @State private var pendingDelete: (kind: SectionKind, id: UUID)?

    private enum SectionKind { case ingredient, step }

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
                    Button(role: .destructive) { showDeleteConfirm = true } label: { Image(systemName: "trash") }
                        .disabled(ingredientItems.isEmpty && stepItems.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete all items?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all generated ingredients and steps.")
            }
            .confirmationDialog(
                "Delete this item?",
                isPresented: $showDeleteItemConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deletePendingItem() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This will remove the selected item from the list.")
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
        AIPillTabs<ViewFilter>(selection: $filter)
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
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button("Delete", role: .destructive) {
                                                pendingDelete = (.ingredient, item.id)
                                                showDeleteItemConfirm = true
                                            }
                                        }
                                }
                            }
                        }
                    }
                    if filter == .both || filter == .steps {
                        if !stepItems.isEmpty {
                            Section("Steps") {
                                ForEach($stepItems) { $item in
                                    ChecklistRow(item: $item)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button("Delete", role: .destructive) {
                                                pendingDelete = (.step, item.id)
                                                showDeleteItemConfirm = true
                                            }
                                        }
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

    private func deletePendingItem() {
        guard let pending = pendingDelete else { return }
        switch pending.kind {
        case .ingredient:
            if let idx = ingredientItems.firstIndex(where: { $0.id == pending.id }) {
                ingredientItems.remove(at: idx)
            }
        case .step:
            if let idx = stepItems.firstIndex(where: { $0.id == pending.id }) {
                stepItems.remove(at: idx)
            }
        }
        pendingDelete = nil
    }
}

#Preview {
    ContentView()
}

// Components moved to Components.swift
