//
//  SSHSession.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import Foundation

struct SSHSession: Identifiable, Codable {
    let id: UUID
    let hostId: UUID
    var name: String
    var createdAt: Date
    var lastActiveAt: Date
    var isActive: Bool
    var status: SessionStatus
    
    enum SessionStatus: String, Codable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error
    }
    
    init(
        id: UUID = UUID(),
        hostId: UUID,
        name: String,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        isActive: Bool = false,
        status: SessionStatus = .disconnected
    ) {
        self.id = id
        self.hostId = hostId
        self.name = name
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.isActive = isActive
        self.status = status
    }
}

struct CommandOutput: Identifiable {
    let id: UUID
    let sessionId: UUID
    let content: String
    let timestamp: Date
    let type: OutputType
    
    enum OutputType {
        case command
        case output
        case error
        case system
    }
    
    init(
        id: UUID = UUID(),
        sessionId: UUID,
        content: String,
        timestamp: Date = Date(),
        type: OutputType = .output
    ) {
        self.id = id
        self.sessionId = sessionId
        self.content = content
        self.timestamp = timestamp
        self.type = type
    }
}
