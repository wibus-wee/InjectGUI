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

@main
struct InjectGUIApp: App {

    init() {
        setupApplicationSupportDirectory()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands { SidebarCommands() }
    }
}
