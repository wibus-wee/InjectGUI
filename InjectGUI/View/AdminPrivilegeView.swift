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
                savePassword(password: password)
                showAdminPrivilegeView = false
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
    
    func savePassword(password: String) {
        executor.password = password
    }
}
