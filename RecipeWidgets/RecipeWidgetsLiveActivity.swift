//
//  RecipeWidgetsLiveActivity.swift
//  RecipeWidgets
//
//  Created by Marc on 8/30/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RecipeWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
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

extension RecipeWidgetsAttributes {
    fileprivate static var preview: RecipeWidgetsAttributes {
        RecipeWidgetsAttributes(name: "World")
    }
}

extension RecipeWidgetsAttributes.ContentState {
    fileprivate static var smiley: RecipeWidgetsAttributes.ContentState {
        RecipeWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RecipeWidgetsAttributes.ContentState {
         RecipeWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RecipeWidgetsAttributes.preview) {
   RecipeWidgetsLiveActivity()
} contentStates: {
    RecipeWidgetsAttributes.ContentState.smiley
    RecipeWidgetsAttributes.ContentState.starEyes
}
