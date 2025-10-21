//
//  TerminalView.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI

struct TerminalView: View {
    let session: SSHSession
    let host: Host
    
    @EnvironmentObject var sessionManager: SessionManager
    @State private var command: String = ""
    @State private var showingSessionMenu = false
    @FocusState private var isInputFocused: Bool
    
    var outputs: [CommandOutput] {
        sessionManager.outputs[session.id] ?? []
    }
    
    var currentSession: SSHSession? {
        sessionManager.getSession(by: session.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            StatusBarView(session: currentSession ?? session, host: host)
            
            // Terminal output area with smooth scrolling
            TerminalOutputView(outputs: outputs)
            
            Divider()
            
            // Command input
            CommandInputView(
                command: $command,
                isInputFocused: _isInputFocused,
                onSubmit: executeCommand
            )
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: reconnect) {
                        Label("Reconnect", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: disconnect) {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                    
                    Divider()
                    
                    Button(action: clearOutput) {
                        Label("Clear Output", systemImage: "trash")
                    }
                    
                    Button(role: .destructive, action: deleteSession) {
                        Label("Delete Session", systemImage: "trash.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            sessionManager.setActiveSession(session.id)
            
            if currentSession?.status == .disconnected {
                sessionManager.connectSession(session.id)
            }
            
            // Auto-focus input
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .onDisappear {
            // Don't disconnect, just deactivate
            sessionManager.setActiveSession(nil)
        }
    }
    
    private func executeCommand() {
        guard !command.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        sessionManager.executeCommand(command, in: session.id)
        command = ""
    }
    
    private func reconnect() {
        sessionManager.reconnectSession(session.id)
    }
    
    private func disconnect() {
        sessionManager.disconnectSession(session.id)
    }
    
    private func clearOutput() {
        sessionManager.outputs[session.id] = []
    }
    
    private func deleteSession() {
        sessionManager.deleteSession(session)
    }
}

struct StatusBarView: View {
    let session: SSHSession
    let host: Host
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator with animation
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Divider()
                .frame(height: 16)
            
            // Connection info
            HStack(spacing: 4) {
                Image(systemName: "network")
                    .font(.caption)
                
                Text("\(host.hostname):\(host.port)")
                    .font(.caption)
            }
            
            Spacer()
            
            // Last active time
            Text(session.lastActiveAt.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
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
            return "Error"
        }
    }
}

struct TerminalOutputView: View {
    let outputs: [CommandOutput]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(outputs) { output in
                        OutputLineView(output: output)
                            .id(output.id)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .onChange(of: outputs.count) { _ in
                // Auto-scroll to bottom with smooth animation
                if let lastOutput = outputs.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastOutput.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct OutputLineView: View {
    let output: CommandOutput
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(output.timestamp.formatted(date: .omitted, time: .standard))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            // Content
            Text(output.content)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(contentColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
    
    private var contentColor: Color {
        switch output.type {
        case .command:
            return .blue
        case .output:
            return .primary
        case .error:
            return .red
        case .system:
            return .green
        }
    }
}

struct CommandInputView: View {
    @Binding var command: String
    var isInputFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Prompt
            Text("$")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            // Input field
            TextField("Enter command...", text: $command)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused(isInputFocused)
                .onSubmit(onSubmit)
            
            // Send button
            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(command.isEmpty ? .gray : .blue)
            }
            .disabled(command.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
    }
}
