//
//  SFTPManager.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import Foundation

class SFTPManager: ObservableObject {
    @Published var currentPath: String = "/"
    @Published var files: [SFTPFile] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var sessionId: UUID?
    
    func connect(sessionId: UUID, completion: @escaping (Bool) -> Void) {
        self.sessionId = sessionId
        
        // 模拟连接
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            completion(true)
            self?.listFiles(at: "/")
        }
    }
    
    func disconnect() {
        sessionId = nil
        files = []
        currentPath = "/"
    }
    
    func listFiles(at path: String) {
        guard sessionId != nil else { return }
        
        isLoading = true
        currentPath = path
        
        // 模拟文件列表
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // 在实际实现中，这里应该通过SFTP协议获取文件列表
            self.files = self.generateSimulatedFiles(for: path)
            self.isLoading = false
        }
    }
    
    func uploadFile(localPath: URL, remotePath: String, completion: @escaping (Bool, String?) -> Void) {
        guard sessionId != nil else {
            completion(false, "Not connected")
            return
        }
        
        // 模拟上传
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            completion(true, nil)
        }
    }
    
    func downloadFile(remotePath: String, localPath: URL, completion: @escaping (Bool, String?) -> Void) {
        guard sessionId != nil else {
            completion(false, "Not connected")
            return
        }
        
        // 模拟下载
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            completion(true, nil)
        }
    }
    
    func deleteFile(at path: String, completion: @escaping (Bool, String?) -> Void) {
        guard sessionId != nil else {
            completion(false, "Not connected")
            return
        }
        
        // 模拟删除
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            completion(true, nil)
        }
    }
    
    func createDirectory(at path: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        guard sessionId != nil else {
            completion(false, "Not connected")
            return
        }
        
        // 模拟创建目录
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            completion(true, nil)
        }
    }
    
    // 模拟数据生成
    private func generateSimulatedFiles(for path: String) -> [SFTPFile] {
        let now = Date()
        
        if path == "/" {
            return [
                SFTPFile(name: "..", path: "/", size: 0, isDirectory: true, permissions: "drwxr-xr-x", modificationDate: now, owner: "root", group: "root"),
                SFTPFile(name: "home", path: "/home", size: 4096, isDirectory: true, permissions: "drwxr-xr-x", modificationDate: now, owner: "root", group: "root"),
                SFTPFile(name: "var", path: "/var", size: 4096, isDirectory: true, permissions: "drwxr-xr-x", modificationDate: now, owner: "root", group: "root"),
                SFTPFile(name: "etc", path: "/etc", size: 4096, isDirectory: true, permissions: "drwxr-xr-x", modificationDate: now, owner: "root", group: "root"),
                SFTPFile(name: "tmp", path: "/tmp", size: 4096, isDirectory: true, permissions: "drwxrwxrwx", modificationDate: now, owner: "root", group: "root"),
            ]
        } else {
            return [
                SFTPFile(name: "..", path: "/", size: 0, isDirectory: true, permissions: "drwxr-xr-x", modificationDate: now, owner: "root", group: "root"),
                SFTPFile(name: "document.txt", path: "\(path)/document.txt", size: 1024, isDirectory: false, permissions: "-rw-r--r--", modificationDate: now, owner: "user", group: "user"),
                SFTPFile(name: "script.sh", path: "\(path)/script.sh", size: 512, isDirectory: false, permissions: "-rwxr-xr-x", modificationDate: now, owner: "user", group: "user"),
                SFTPFile(name: "data", path: "\(path)/data", size: 4096, isDirectory: true, permissions: "drwxr-xr-x", modificationDate: now, owner: "user", group: "user"),
            ]
        }
    }
}
