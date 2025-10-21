//
//  SessionManager.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var sessions: [SSHSession] = []
    @Published var outputs: [UUID: [CommandOutput]] = [:]
    @Published var activeSessionId: UUID?
    
    private var sshConnections: [UUID: SSHConnectionHandler] = [:]
    private let sessionsKey = "ssh_sessions"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSessions()
        startReconnectionMonitor()
    }
    
    func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([SSHSession].self, from: data) {
            sessions = decoded
            
            // Initialize outputs for each session
            for session in sessions {
                if outputs[session.id] == nil {
                    outputs[session.id] = []
                }
            }
        }
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    func createSession(for hostId: UUID, name: String) -> SSHSession {
        let session = SSHSession(hostId: hostId, name: name)
        sessions.append(session)
        outputs[session.id] = []
        saveSessions()
        return session
    }
    
    func deleteSession(_ session: SSHSession) {
        // Disconnect first
        disconnectSession(session.id)
        
        // Remove from lists
        sessions.removeAll { $0.id == session.id }
        outputs.removeValue(forKey: session.id)
        sshConnections.removeValue(forKey: session.id)
        
        if activeSessionId == session.id {
            activeSessionId = nil
        }
        
        saveSessions()
    }
    
    func deleteSessionsForHost(_ hostId: UUID) {
        let hostSessions = sessions.filter { $0.hostId == hostId }
        for session in hostSessions {
            deleteSession(session)
        }
    }
    
    func connectSession(_ sessionId: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }),
              let host = HostManager.shared.getHost(by: sessions[index].hostId) else {
            return
        }
        
        sessions[index].status = .connecting
        sessions[index].lastActiveAt = Date()
        
        let handler = SSHConnectionHandler(session: sessions[index], host: host)
        sshConnections[sessionId] = handler
        
        handler.connect { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let index = self.sessions.firstIndex(where: { $0.id == sessionId }) else {
                    return
                }
                
                if success {
                    self.sessions[index].status = .connected
                    self.addOutput(to: sessionId, content: "✓ Connected to \(host.hostname)", type: .system)
                } else {
                    self.sessions[index].status = .error
                    self.addOutput(to: sessionId, content: "✗ Connection failed: \(error ?? "Unknown error")", type: .error)
                }
                
                self.saveSessions()
            }
        }
    }
    
    func disconnectSession(_ sessionId: UUID) {
        if let handler = sshConnections[sessionId] {
            handler.disconnect()
            sshConnections.removeValue(forKey: sessionId)
        }
        
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[index].status = .disconnected
            saveSessions()
        }
    }
    
    func reconnectSession(_ sessionId: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
            return
        }
        
        sessions[index].status = .reconnecting
        addOutput(to: sessionId, content: "⟳ Reconnecting...", type: .system)
        
        // Disconnect and reconnect
        disconnectSession(sessionId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.connectSession(sessionId)
        }
    }
    
    func executeCommand(_ command: String, in sessionId: UUID) {
        guard let handler = sshConnections[sessionId] else {
            addOutput(to: sessionId, content: "✗ Not connected", type: .error)
            return
        }
        
        addOutput(to: sessionId, content: "$ \(command)", type: .command)
        
        handler.executeCommand(command) { [weak self] output, error in
            DispatchQueue.main.async {
                if let output = output {
                    self?.addOutput(to: sessionId, content: output, type: .output)
                }
                if let error = error {
                    self?.addOutput(to: sessionId, content: error, type: .error)
                }
            }
        }
    }
    
    func addOutput(to sessionId: UUID, content: String, type: CommandOutput.OutputType) {
        let output = CommandOutput(sessionId: sessionId, content: content, type: type)
        
        if outputs[sessionId] == nil {
            outputs[sessionId] = []
        }
        
        outputs[sessionId]?.append(output)
    }
    
    func getSession(by id: UUID) -> SSHSession? {
        return sessions.first { $0.id == id }
    }
    
    func getSessions(for hostId: UUID) -> [SSHSession] {
        return sessions.filter { $0.hostId == hostId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func setActiveSession(_ sessionId: UUID?) {
        activeSessionId = sessionId
        
        if let id = sessionId,
           let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].isActive = true
            sessions[index].lastActiveAt = Date()
            saveSessions()
        }
        
        // Deactivate other sessions
        for i in 0..<sessions.count {
            if sessions[i].id != sessionId && sessions[i].isActive {
                sessions[i].isActive = false
            }
        }
        saveSessions()
    }
    
    private func startReconnectionMonitor() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkConnections()
        }
    }
    
    private func checkConnections() {
        for session in sessions {
            if session.status == .connected,
               let handler = sshConnections[session.id],
               !handler.isConnected() {
                reconnectSession(session.id)
            }
        }
    }
}
