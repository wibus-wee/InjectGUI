//
//  ContentView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//
import SwiftUI

struct ContentView: View {
    @StateObject var softwareManager = SoftwareManager.shared

    var body: some View {
        NavigationView {
            Group {
                SidebarView()
            }
            .navigationTitle(Constants.appName)

            WelcomeView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}