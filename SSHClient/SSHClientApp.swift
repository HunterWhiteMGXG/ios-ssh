//
//  SSHClientApp.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI

@main
struct SSHClientApp: App {
    @StateObject private var hostManager = HostManager.shared
    @StateObject private var sessionManager = SessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hostManager)
                .environmentObject(sessionManager)
        }
    }
}
