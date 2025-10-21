//
//  SFTPBrowserView.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI
import UniformTypeIdentifiers

struct SFTPBrowserView: View {
    let host: Host
    @Binding var isPresented: Bool
    
    @StateObject private var sftpManager = SFTPManager()
    @EnvironmentObject var sessionManager: SessionManager
    
    @State private var showingUploadSheet = false
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var selectedFile: SFTPFile?
    @State private var showingActionSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Path bar
                PathBarView(path: sftpManager.currentPath)
                
                Divider()
                
                // File list
                if sftpManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sftpManager.files.isEmpty {
                    EmptyFileListView()
                } else {
                    FileListView(
                        files: sftpManager.files,
                        onSelect: selectFile,
                        onNavigate: navigateToDirectory
                    )
                }
            }
            .navigationTitle("SFTP - \(host.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        sftpManager.disconnect()
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingUploadSheet = true }) {
                            Label("Upload File", systemImage: "arrow.up.doc")
                        }
                        
                        Button(action: { showingNewFolderAlert = true }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        
                        Button(action: refreshFiles) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    createFolder()
                }
            } message: {
                Text("Enter a name for the new folder")
            }
            .confirmationDialog(
                selectedFile?.name ?? "",
                isPresented: $showingActionSheet,
                presenting: selectedFile
            ) { file in
                Button("Download") {
                    downloadFile(file)
                }
                
                Button("Delete", role: .destructive) {
                    deleteFile(file)
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                connectSFTP()
            }
        }
    }
    
    private func connectSFTP() {
        // Use existing session or create temporary one
        let sessions = sessionManager.getSessions(for: host.id)
        let sessionId = sessions.first?.id ?? UUID()
        
        sftpManager.connect(sessionId: sessionId) { success in
            if !success {
                print("SFTP connection failed")
            }
        }
    }
    
    private func selectFile(_ file: SFTPFile) {
        selectedFile = file
        showingActionSheet = true
    }
    
    private func navigateToDirectory(_ file: SFTPFile) {
        if file.isDirectory {
            sftpManager.listFiles(at: file.path)
        }
    }
    
    private func refreshFiles() {
        sftpManager.listFiles(at: sftpManager.currentPath)
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        
        sftpManager.createDirectory(at: sftpManager.currentPath, name: newFolderName) { success, error in
            if success {
                refreshFiles()
                newFolderName = ""
            }
        }
    }
    
    private func downloadFile(_ file: SFTPFile) {
        // In a real implementation, this would download to device
        print("Downloading: \(file.name)")
    }
    
    private func deleteFile(_ file: SFTPFile) {
        sftpManager.deleteFile(at: file.path) { success, error in
            if success {
                refreshFiles()
            }
        }
    }
}

struct PathBarView: View {
    let path: String
    
    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
            
            Text(path)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct FileListView: View {
    let files: [SFTPFile]
    let onSelect: (SFTPFile) -> Void
    let onNavigate: (SFTPFile) -> Void
    
    var body: some View {
        List(files) { file in
            Button(action: {
                if file.isDirectory {
                    onNavigate(file)
                } else {
                    onSelect(file)
                }
            }) {
                FileRowView(file: file)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(PlainListStyle())
    }
}

struct FileRowView: View {
    let file: SFTPFile
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: file.isDirectory ? "folder.fill" : fileIcon)
                .font(.title2)
                .foregroundColor(file.isDirectory ? .blue : .secondary)
                .frame(width: 30)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if !file.isDirectory {
                        Text(file.sizeFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(file.permissions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(file.modificationDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if file.isDirectory && file.name != ".." {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
    
    private var fileIcon: String {
        let ext = (file.name as NSString).pathExtension.lowercased()
        
        switch ext {
        case "txt", "md", "log":
            return "doc.text"
        case "pdf":
            return "doc.fill"
        case "jpg", "jpeg", "png", "gif":
            return "photo"
        case "zip", "tar", "gz":
            return "doc.zipper"
        case "sh", "py", "js", "swift":
            return "terminal"
        default:
            return "doc"
        }
    }
}

struct EmptyFileListView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Empty Directory")
                .font(.headline)
            
            Text("This directory contains no files")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
