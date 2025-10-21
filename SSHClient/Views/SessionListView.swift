//
//  SessionListView.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI

struct SessionListView: View {
    let host: Host
    
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingAddSession = false
    @State private var newSessionName = ""
    @State private var showingSFTP = false
    
    var sessions: [SSHSession] {
        sessionManager.getSessions(for: host.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Host info banner
            HostInfoBanner(host: host)
            
            // Sessions list
            if sessions.isEmpty {
                EmptySessionView()
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: TerminalView(session: session, host: host)) {
                            SessionRowView(session: session)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle(host.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddSession = true }) {
                        Label("New Session", systemImage: "plus.rectangle")
                    }
                    
                    Button(action: { showingSFTP = true }) {
                        Label("SFTP Browser", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            AddSessionView(host: host, isPresented: $showingAddSession)
        }
        .sheet(isPresented: $showingSFTP) {
            SFTPBrowserView(host: host, isPresented: $showingSFTP)
        }
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            sessionManager.deleteSession(sessions[index])
        }
    }
}

struct HostInfoBanner: View {
    let host: Host
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.white)
                
                Text("\(host.username)@\(host.hostname):\(host.port)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct SessionRowView: View {
    let session: SSHSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                if session.status == .connecting || session.status == .reconnecting {
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .opacity(0.5)
                }
            }
            .frame(width: 20)
            
            // Session info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.name)
                        .font(.headline)
                    
                    if session.isActive {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 4) {
                    statusIcon
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Last active: \(session.lastActiveAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch session.status {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
    
    private var statusIcon: Image {
        switch session.status {
        case .connected:
            return Image(systemName: "checkmark.circle.fill")
        case .connecting, .reconnecting:
            return Image(systemName: "arrow.triangle.2.circlepath")
        case .disconnected:
            return Image(systemName: "circle")
        case .error:
            return Image(systemName: "exclamationmark.triangle.fill")
        }
    }
    
    private var statusText: String {
        switch session.status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting:
            return "Reconnecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
        }
    }
}

struct EmptySessionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "terminal")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
            
            Text("No Sessions")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Create a new session to start working")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct AddSessionView: View {
    let host: Host
    @Binding var isPresented: Bool
    
    @EnvironmentObject var sessionManager: SessionManager
    @State private var sessionName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Session Name", text: $sessionName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Session Details")
                } footer: {
                    Text("Give this session a memorable name, e.g., 'Backend Server', 'Database Admin'")
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createSession()
                    }
                    .fontWeight(.semibold)
                    .disabled(sessionName.isEmpty)
                }
            }
        }
    }
    
    private func createSession() {
        let session = sessionManager.createSession(for: host.id, name: sessionName)
        sessionManager.connectSession(session.id)
        isPresented = false
    }
}
