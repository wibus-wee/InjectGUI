//
//  SidebarView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/20.
//

import SwiftUI

struct AppEntry: Identifiable {
    let id: String
    let detail: AppDetail
}

enum DisplayMode {
    case local
    case remote
}

struct SidebarView: View {
    @State var displayMode: DisplayMode = .local

    @StateObject var softwareManager = SoftwareManager.shared
    
    var body: some View {
        VStack {
            Picker("", selection: $displayMode) {
                Text("Local").tag(DisplayMode.local)
                Text("Remote").tag(DisplayMode.remote)
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                List(softwareManager.appListCache.map { AppEntry(id: $0.key, detail: $0.value) }) { app in
                    HStack {
                        Image(nsImage: app.detail.icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .cornerRadius(4)
                        VStack (alignment: .leading) {
                            Text(app.detail.name)
                                .font(.headline)
                            VStack (alignment: .leading) {
                                Text(app.detail.identifier)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Version: \(app.detail.version)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .listStyle(SidebarListStyle())
        }
    }
    
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
    }
}
