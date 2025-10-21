//
//  AddHostView.swift
//  SSHClient
//
//  Created on 2025-10-21.
//

import SwiftUI

struct AddHostView: View {
    @EnvironmentObject var hostManager: HostManager
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var hostname: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var authMethod: Host.AuthMethod = .password
    @State private var password: String = ""
    @State private var privateKey: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Hostname or IP", text: $hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("22", text: $port)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Authentication")) {
                    Picker("Method", selection: $authMethod) {
                        Text("Password").tag(Host.AuthMethod.password)
                        Text("Public Key").tag(Host.AuthMethod.publicKey)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if authMethod == .password {
                        SecureField("Password", text: $password)
                    } else {
                        TextEditor(text: $privateKey)
                            .frame(height: 120)
                            .font(.system(.body, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        
                        Text("Paste your private key here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add SSH Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHost()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !hostname.isEmpty && !username.isEmpty &&
        (authMethod == .password ? !password.isEmpty : !privateKey.isEmpty)
    }
    
    private func saveHost() {
        guard let portInt = Int(port) else {
            errorMessage = "Invalid port number"
            showingError = true
            return
        }
        
        let host = Host(
            name: name,
            hostname: hostname,
            port: portInt,
            username: username,
            authMethod: authMethod,
            password: authMethod == .password ? password : nil,
            privateKey: authMethod == .publicKey ? privateKey : nil
        )
        
        hostManager.addHost(host)
        isPresented = false
    }
}
