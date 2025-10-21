//
//  ContentView.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hostManager: HostManager
    @State private var showingAddHost = false
    
    var body: some View {
        NavigationView {
            HostListView()
                .navigationTitle("SSH Hosts")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddHost = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                .sheet(isPresented: $showingAddHost) {
                    AddHostView(isPresented: $showingAddHost)
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HostManager.shared)
            .environmentObject(SessionManager.shared)
    }
}
