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
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
            // .listStyle(.sidebar)
            .navigationTitle(Constants.appName)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}