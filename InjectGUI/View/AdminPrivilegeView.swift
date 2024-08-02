//
//  AdminPrivilegeView.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/1.
//

import SwiftUI

struct AdminPrivilegeView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @AppStorage("showAdminPrivilegeView") private var showAdminPrivilegeView: Bool = true
    
    init() {
        let username = NSUserName()
        self.username = username
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 4) {
                Text("Please enter your password to continue.")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("InjectGUI requires your password to perform administrative tasks.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Restarting the app will require your password again.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
                .padding()
            
            Button(action: {
                checkAndSavePassword(password: password)
            }) {
                Text("Submit")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            
        }
        .padding()
        .frame(width: 400, height: 250)
    }
    
    func checkAndSavePassword(password: String) {
        executor.password = password
        executor.executeAdminCommand("sudo -v")
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    let alert = NSAlert()
                    alert.messageText = "Incorrect password"
                    alert.informativeText = "Please try again."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()

                }
            }, receiveValue: { _ in
                showAdminPrivilegeView = false
            })
            .store(in: &executor.cancellables)
    }
}
