//
//  InjectGUIApp.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import SwiftUI

let configuration = Configuration.shared
let injectConfiguration = InjectConfiguration.shared
let softwareManager = SoftwareManager.shared
let injector = Injector.shared
let executor = Executor.shared

@main
struct InjectGUIApp: App {
    @AppStorage("showAdminPrivilegeView") private var showAdminPrivilegeView: Bool = true

    init() {
        setupApplicationSupportDirectory()
        checkPassword()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showAdminPrivilegeView) {
                    AdminPrivilegeView()
                }
        }
        .windowResizability(.contentSize)
        .commands { SidebarCommands() }

        Settings {
            SettingsView()
        }
    }

    func checkPassword() {
        showAdminPrivilegeView = true
    }
}
