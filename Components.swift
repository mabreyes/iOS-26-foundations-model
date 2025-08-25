import SwiftUI

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

struct LoadingListPlaceholder: View {
    var body: some View {
        List {
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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

struct SkeletonChecklistRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.18))
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.22))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 220, height: 12)
            }
        }
        .redacted(reason: .placeholder)
    }
}

struct AIPillTabs<T: Hashable & CaseIterable & Identifiable & CustomStringConvertible>: View {
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(T.allCases)) { tab in
                let isSelected = tab == selection
                Button(action: { selection = tab }) {
                    Text(tab.description)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.background)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AITheme.gradient.opacity(0.15))
        )
    }
}
