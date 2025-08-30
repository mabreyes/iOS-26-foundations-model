import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

struct RecipeActivityAttributes: Codable, Hashable {
    struct ContentState: Codable, Hashable {
        var title: String
        var progress: Double
    }

    var title: String
}

#if canImport(ActivityKit)
extension RecipeActivityAttributes: ActivityAttributes {}
#endif

enum RecipeLiveActivityManager {
    @discardableResult
    static func start(title: String, progress: Double) async -> Any? {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let attributes = RecipeActivityAttributes(title: title)
            let state = RecipeActivityAttributes.ContentState(title: title, progress: progress)
            let content = ActivityContent(state: state, staleDate: nil)
            
            let authInfo = ActivityAuthorizationInfo()
            print("🔴 Live Activity Authorization Status: \(authInfo.areActivitiesEnabled)")
            
            if authInfo.areActivitiesEnabled {
                do {
                    let activity = try Activity<RecipeActivityAttributes>.request(attributes: attributes, content: content, pushType: nil)
                    print("✅ Live Activity started successfully: \(title) - \(Int(progress * 100))%")
                    return activity
                } catch {
                    print("❌ Failed to start Live Activity: \(error)")
                    return nil
                }
            } else {
                print("❌ Live Activities not enabled by user")
                return nil
            }
        } else {
            if #available(iOS 16.1, *) {
                let attributes = RecipeActivityAttributes(title: title)
                let state = RecipeActivityAttributes.ContentState(title: title, progress: progress)
                
                let authInfo = ActivityAuthorizationInfo()
                print("🔴 Live Activity Authorization Status: \(authInfo.areActivitiesEnabled)")
                
                if authInfo.areActivitiesEnabled {
                    do {
                        let activity = try Activity<RecipeActivityAttributes>.request(attributes: attributes, contentState: state)
                        print("✅ Live Activity started successfully: \(title) - \(Int(progress * 100))%")
                        return activity
                    } catch {
                        print("❌ Failed to start Live Activity: \(error)")
                        return nil
                    }
                } else {
                    print("❌ Live Activities not enabled by user")
                    return nil
                }
            }
        }
        #endif
        return nil
    }

    static func update(activity: Any?, title: String, progress: Double) async {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *), let act = activity as? Activity<RecipeActivityAttributes> {
            let state = RecipeActivityAttributes.ContentState(title: title, progress: progress)
            let content = ActivityContent(state: state, staleDate: nil)
            do {
                await act.update(content)
                print("🔄 Live Activity updated: \(title) - \(Int(progress * 100))%")
            } catch {
                print("❌ Failed to update Live Activity: \(error)")
            }
        } else {
            if #available(iOS 16.1, *), let act = activity as? Activity<RecipeActivityAttributes> {
                let state = RecipeActivityAttributes.ContentState(title: title, progress: progress)
                do {
                    await act.update(using: state)
                    print("🔄 Live Activity updated: \(title) - \(Int(progress * 100))%")
                } catch {
                    print("❌ Failed to update Live Activity: \(error)")
                }
            }
        }
        #endif
    }

    static func end(activity: Any?) async {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *), let act = activity as? Activity<RecipeActivityAttributes> {
            let currentTitle = act.content.state.title
            let finalState = RecipeActivityAttributes.ContentState(title: currentTitle, progress: 1)
            let content = ActivityContent(state: finalState, staleDate: nil)
            await act.end(content, dismissalPolicy: .immediate)
        } else {
            if #available(iOS 16.1, *), let act = activity as? Activity<RecipeActivityAttributes> {
                await act.end(dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}

// Widget UI is now handled by the Widget Extension target
