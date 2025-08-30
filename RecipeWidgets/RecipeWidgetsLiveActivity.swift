//
//  RecipeWidgetsLiveActivity.swift
//  RecipeWidgets
//
//  Created by Marc on 8/30/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct RecipeWidgetsAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RecipeWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecipeWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

private extension RecipeWidgetsAttributes {
    static var preview: RecipeWidgetsAttributes {
        RecipeWidgetsAttributes(name: "World")
    }
}

private extension RecipeWidgetsAttributes.ContentState {
    static var smiley: RecipeWidgetsAttributes.ContentState {
        RecipeWidgetsAttributes.ContentState(emoji: "😀")
    }

    static var starEyes: RecipeWidgetsAttributes.ContentState {
        RecipeWidgetsAttributes.ContentState(emoji: "🤩")
    }
}

#Preview("Notification", as: .content, using: RecipeWidgetsAttributes.preview) {
    RecipeWidgetsLiveActivity()
} contentStates: {
    RecipeWidgetsAttributes.ContentState.smiley
    RecipeWidgetsAttributes.ContentState.starEyes
}
