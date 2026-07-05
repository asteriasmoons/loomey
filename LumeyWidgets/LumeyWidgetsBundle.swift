//
//  LumeyWidgetsBundle.swift
//  LumeyWidgets
//
//  Created by Asteria Moon on 5/23/26.
//

import WidgetKit
import SwiftUI

@main
struct LumeyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LumeyWidgets()
        LumeyWidgetsControl()
        LumeyWidgetsLiveActivity()
    }
}
