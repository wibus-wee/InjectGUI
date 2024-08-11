//
//  ContentView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("showAdminPrivilegeView") private var showAdminPrivilegeView: Bool = true
    @StateObject var softwareManager = SoftwareManager.shared
    @StateObject var injector = Injector.shared

    var body: some View {
        NavigationView {
            Group {
                SidebarView()
            }
            .navigationTitle(Constants.appName)

            AboutView()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(
                        #selector(NSSplitViewController.toggleSidebar(_:)),
                        with: nil
                    )
                } label: {
                    Label("Toggle Sidebar", systemImage: "sidebar.leading")
                }
            }


            ToolbarItem {
                Button {
                    executor.password = ""
                    showAdminPrivilegeView = true
                } label: {
                    Label("Enter password again", systemImage: "lock")
                }
            }

            ToolbarItem {
                Button {
                    softwareManager.getList()
                    injectConfiguration.updateRemoteConf()
                } label: {
                    Label("Refresh app list", systemImage: "arrow.clockwise")
                }
            }

            #if DEBUG
            ToolbarItem {
                Button {
                    injector.shouldShowStatusSheet.toggle()
                } label: {
                    Label("Status", systemImage: "list.bullet.rectangle")
                }
            }
            #endif
        }
        .sheet(isPresented: $injector.shouldShowStatusSheet) {
            StatusView()
                .background(.ultraThinMaterial)
                .interactiveDismissDisabled(true) // disable esc to dismiss
        }
    }
}
