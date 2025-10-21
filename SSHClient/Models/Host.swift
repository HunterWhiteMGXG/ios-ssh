//
//  Host.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import Foundation

struct Host: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var hostname: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var password: String?
    var privateKey: String?
    var createdAt: Date
    var lastConnected: Date?
    
    enum AuthMethod: String, Codable {
        case password
        case publicKey
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        hostname: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .password,
        password: String? = nil,
        privateKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.password = password
        self.privateKey = privateKey
        self.createdAt = Date()
        self.lastConnected = nil
    }
}
