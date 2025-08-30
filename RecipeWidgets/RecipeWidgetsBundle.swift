//
//  RecipeWidgetsBundle.swift
//  RecipeWidgets
//
//  Created by Marc on 8/30/25.
//

import SwiftUI
import WidgetKit

@main
struct RecipeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RecipeActivityWidget()
        RecipeWidgetsControl()
        RecipeWidgetsLiveActivity()
    }
}
