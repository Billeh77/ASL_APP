//
//  RealtimeASLApp.swift
//  RealtimeASL
//
//  Created by Emile Billeh on 22/02/2025.
//

import SwiftUI

@main
struct RealtimeASLApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
