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
        .commands { SidebarCommands() }
        .contentSizedWindowResizability()

        #if DEBUG
        // 没写好，初期的 Release 不打算放出来了
        Settings {
            SettingsView()
        }
        #endif
    }

    func checkPassword() {
        showAdminPrivilegeView = true
    }
}
