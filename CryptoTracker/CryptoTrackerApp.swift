//
//  CryptoTrackerApp.swift
//  CryptoTracker
//
//  Created by Frank Bara on 2/4/22.
//

import SwiftUI

@main
struct CryptoTrackerApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView().frame(width: 100, height: 100)
        }
    }
}
