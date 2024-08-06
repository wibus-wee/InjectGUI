//
//  InjectGUIApp.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import SwiftUI
import Sparkle

let configuration = Configuration.shared
let injectConfiguration = InjectConfiguration.shared
let softwareManager = SoftwareManager.shared
let injector = Injector.shared
let executor = Executor.shared

@main
struct InjectGUIApp: App {
    @AppStorage("showAdminPrivilegeView") private var showAdminPrivilegeView: Bool = true
    private let updaterController: SPUStandardUpdaterController

    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
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
        .commands {
            SidebarCommands()
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        .contentSizedWindowResizability()

        Settings {
            SettingsView()
        }
    }

    func checkPassword() {
        showAdminPrivilegeView = true
    }
}
