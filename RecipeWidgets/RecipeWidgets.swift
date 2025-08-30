import ActivityKit
import SwiftUI
import WidgetKit

// Copy your RecipeActivityAttributes from RecipeActivity.swift
struct RecipeActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var progress: Double
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
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.title3.monospacedDigit())
                        .foregroundColor(.primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .padding(.horizontal)
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
