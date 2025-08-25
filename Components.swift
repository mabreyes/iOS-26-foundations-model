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
            ForEach(0 ..< 3, id: \.self) { _ in
                Section("") {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 12)
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 180, height: 12)
                                    .opacity(0.8)
                            }
                        }
                        .redacted(reason: .placeholder)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
