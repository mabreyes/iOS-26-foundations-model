import Foundation
import SwiftUI

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
    @State private var pendingDelete: (kind: RecipeSectionKind, id: UUID)?
    @State private var liveActivity: Any?

    var body: some View {
        NavigationStack {
            List {
                Section { header }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)

                Section { inputCard }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)

                Section { filterPicker }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)

                Section { progressCard }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)

                if isLoading {
                    Section("Ingredients") {
                        ForEach(0 ..< 4, id: \.self) { _ in
                            SkeletonChecklistRow()
                        }
                    }
                    Section("Steps") {
                        ForEach(0 ..< 4, id: \.self) { _ in
                            SkeletonChecklistRow()
                        }
                    }
                } else if ingredientItems.isEmpty, stepItems.isEmpty {
                    Section { EmptyStateView() }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                } else {
                    if filter == .both || filter == .ingredients {
                        if !ingredientItems.isEmpty {
                            Section("Ingredients") {
                                ForEach($ingredientItems) { $item in
                                    DeletableChecklistRow(item: $item, kind: .ingredient, onRequestDelete: { kind, id in
                                        pendingDelete = (kind, id)
                                        showDeleteItemConfirm = true
                                    }, onToggle: {
                                        updateProgressAndLiveActivity()
                                    })
                                }
                            }
                        }
                    }
                    if filter == .both || filter == .steps {
                        if !stepItems.isEmpty {
                            Section("Steps") {
                                ForEach($stepItems) { $item in
                                    DeletableChecklistRow(item: $item, kind: .step, onRequestDelete: { kind, id in
                                        pendingDelete = (kind, id)
                                        showDeleteItemConfirm = true
                                    }, onToggle: {
                                        updateProgressAndLiveActivity()
                                    })
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(20))
            .scrollContentBackground(.hidden)
            .navigationTitle("Recipe Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) { showDeleteConfirm = true } label: { Image(systemName: "trash") }
                        .disabled(ingredientItems.isEmpty && stepItems.isEmpty)
                }
            }
            .overlay(alignment: .bottom) {
                if inputFocused {
                    floatingDoneButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
            .animation(.easeInOut, value: inputFocused)
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

    private var progressCard: some View {
        let visibleItems: [RecipeItem] = {
            if filter == .ingredients { return ingredientItems }
            if filter == .steps { return stepItems }
            return ingredientItems + stepItems
        }()
        let total = visibleItems.count
        let completed = visibleItems.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.isChecked }.count
        let pct = total > 0 ? Double(completed) / Double(total) : 0
        let pctText = total > 0 ? "\(Int(pct * 100))%" : "0%"
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(pctText)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            AIProgressBar(progress: pct)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
                .fill(Color.accentColor.opacity(0.12))
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
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Generating")
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text("Generate Recipe")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GradientButtonStyle(isAnimating: isLoading))
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

    private var floatingDoneButton: some View {
        Button("Done") { inputFocused = false }
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    func generateRecipe() {
        guard !foodIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        ingredientItems = []
        stepItems = []

        Task {
            do {
                if #available(iOS 16.1, *) {
                    await startLiveActivityIfNeeded()
                    let (ings, steps) = try await RecipeGenerator.generate(for: foodIdea)
                    await MainActor.run {
                        self.ingredientItems = ings
                        self.stepItems = steps
                        self.isLoading = false
                    }
                    // Start Live Activity with 0% progress once recipe is loaded
                    await startLiveActivityForRecipe()
                } else {
                    await MainActor.run {
                        self.errorMessage = "This feature requires iOS 16.1 or later and a supported device."
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate recipe: \(error.localizedDescription)"
                    self.isLoading = false
                }
                await endLiveActivityIfNeeded()
            }
        }
    }

    private func clearAll() {
        ingredientItems = []
        stepItems = []
        errorMessage = nil
        Task {
            await endLiveActivityIfNeeded()
        }
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

    private func startLiveActivityIfNeeded() async {
        // This is used during generation phase - temporary activity
        guard liveActivity == nil else { return }
        liveActivity = await RecipeLiveActivityManager.start(title: foodIdea.isEmpty ? "Generating Recipe..." : "Generating \(foodIdea)", progress: 0)
    }
    
    private func startLiveActivityForRecipe() async {
        // End the generation activity and start the recipe progress activity
        await endLiveActivityIfNeeded()
        liveActivity = await RecipeLiveActivityManager.start(title: foodIdea.isEmpty ? "Recipe Progress" : foodIdea, progress: 0)
    }

    private func updateLiveActivityIfNeeded(pct: Double, title: String) async {
        guard liveActivity != nil else { return }
        await RecipeLiveActivityManager.update(activity: liveActivity, title: title.isEmpty ? "Recipe Progress" : title, progress: pct)
    }

    private func endLiveActivityIfNeeded() async {
        guard liveActivity != nil else { return }
        await RecipeLiveActivityManager.end(activity: liveActivity)
        liveActivity = nil
    }
    
    private func updateProgressAndLiveActivity() {
        let allItems = ingredientItems + stepItems
        let total = allItems.count
        let completed = allItems.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.isChecked }.count
        let pct = total > 0 ? Double(completed) / Double(total) : 0
        
        Task {
            await updateLiveActivityIfNeeded(pct: pct, title: foodIdea)
            
            // End the Live Activity when recipe is completed (100%)
            if pct >= 1.0 && total > 0 {
                // Wait a moment to show 100% completion
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await endLiveActivityIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
}
