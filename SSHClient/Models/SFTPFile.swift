//
//  SFTPFile.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import Foundation

struct SFTPFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    let permissions: String
    let modificationDate: Date
    let owner: String
    let group: String
    
    var sizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
