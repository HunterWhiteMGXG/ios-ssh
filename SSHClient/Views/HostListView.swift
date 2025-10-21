//
//  HostListView.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI

struct HostListView: View {
    @EnvironmentObject var hostManager: HostManager
    @State private var selectedHost: Host?
    
    var body: some View {
        Group {
            if hostManager.hosts.isEmpty {
                EmptyHostView()
            } else {
                List {
                    ForEach(hostManager.hosts) { host in
                        NavigationLink(destination: SessionListView(host: host)) {
                            HostRowView(host: host)
                        }
                    }
                    .onDelete(perform: deleteHosts)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    private func deleteHosts(at offsets: IndexSet) {
        for index in offsets {
            hostManager.deleteHost(hostManager.hosts[index])
        }
    }
}

struct HostRowView: View {
    let host: Host
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "server.rack")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Host Info
            VStack(alignment: .leading, spacing: 4) {
                Text(host.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(host.username)@\(host.hostname)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let lastConnected = host.lastConnected {
                    Text("Last: \(lastConnected.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Port indicator
            VStack {
                Text(":\(host.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EmptyHostView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No SSH Hosts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first SSH host")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
