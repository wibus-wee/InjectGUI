//
//  ContentView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//
import SwiftUI

struct ContentView: View {
    @State private var executor = Executor()
    
    @StateObject var softwareManager = SoftwareManager.shared
    @StateObject var injector = Injector.shared

    func exe() {
        executor.runAdminCommand("sudo -v")
//        executor.executeAdminCommand("sudo -v")
//        // executor.output 改变时，自动输出
//        executor.$output
//            .sink { output in
//                print(output)
//            }
//            .store(in: &executor.cancellables)
    }

    var body: some View {
        NavigationView {
            Group {
                SidebarView()
            }
            .navigationTitle(Constants.appName)

            WelcomeView()
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

            ToolbarItem() {
                Button {
                    exe()    
                } label: {
                    Label("Test", systemImage: "info.circle")
                }
            }

            ToolbarItem {
                Button {
                    injector.shouldShowStatusSheet.toggle()
                } label: {
                    Label("Status", systemImage: "list.bullet.rectangle")
                }
            }
        }
        .sheet(isPresented: $injector.shouldShowStatusSheet) { 
            StatusView()
                .background(.ultraThinMaterial)
                .interactiveDismissDisabled(true) // disable esc to dismiss
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
