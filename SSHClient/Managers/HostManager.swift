//
//  HostManager.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import Foundation
import Combine

class HostManager: ObservableObject {
    static let shared = HostManager()
    
    @Published var hosts: [Host] = []
    
    private let hostsKey = "ssh_hosts"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadHosts()
    }
    
    func loadHosts() {
        if let data = userDefaults.data(forKey: hostsKey),
           let decoded = try? JSONDecoder().decode([Host].self, from: data) {
            hosts = decoded
        }
    }
    
    func saveHosts() {
        if let encoded = try? JSONEncoder().encode(hosts) {
            userDefaults.set(encoded, forKey: hostsKey)
        }
    }
    
    func addHost(_ host: Host) {
        hosts.append(host)
        saveHosts()
    }
    
    func updateHost(_ host: Host) {
        if let index = hosts.firstIndex(where: { $0.id == host.id }) {
            hosts[index] = host
            saveHosts()
        }
    }
    
    func deleteHost(_ host: Host) {
        hosts.removeAll { $0.id == host.id }
        saveHosts()
        
        // Delete all sessions for this host
        SessionManager.shared.deleteSessionsForHost(host.id)
    }
    
    func getHost(by id: UUID) -> Host? {
        return hosts.first { $0.id == id }
    }
}
