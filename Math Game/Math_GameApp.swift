//
//  Math_GameApp.swift
//  Math Game
//
//  Created by Jason Terhorst on 12/9/24.
//

import SwiftUI
import SwiftData

@main
struct Math_GameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
