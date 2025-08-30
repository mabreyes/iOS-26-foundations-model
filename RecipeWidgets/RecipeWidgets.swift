import ActivityKit
import SwiftUI
import WidgetKit

// Copy your RecipeActivityAttributes from RecipeActivity.swift
struct RecipeActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var progress: Double
        var currentItem: String?
    }

    var title: String
}

struct RecipeWidgets: WidgetBundle {
    var body: some Widget {
        RecipeActivityWidget()
    }
}

struct RecipeActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecipeActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(.blue)
                    Text(context.state.title.isEmpty ? "Recipe Progress" : context.state.title)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .foregroundColor(.primary)
                }

                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                if let item = context.state.currentItem, !item.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        Text(item)
                            .font(.footnote)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "fork.knife.circle.fill")
                                .foregroundColor(.blue)
                            Text(context.state.title.isEmpty ? "Recipe Progress" : context.state.title)
                                .font(.headline)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(Int(context.state.progress * 100))%")
                                .font(.title3.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .padding(.top, -2)
                        if let item = context.state.currentItem, !item.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text(item)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, -8)
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}
