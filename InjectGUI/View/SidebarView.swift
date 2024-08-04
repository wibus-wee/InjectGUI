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

struct SidebarView: View {
    @ObservedObject var injectConfiguration = InjectConfiguration.shared
    @StateObject var softwareManager = SoftwareManager.shared
    @State var searchText: String = ""
    @State var filteredApps: [AppEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search all local app", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // 应用列表或状态信息
            ZStack {
                if softwareManager.isLoading {
                    ProgressView("Scanning apps...")
                } else if filteredApps.isEmpty {
                    Text("No apps found.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else {
                    appList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 280)
        .onReceive(softwareManager.$appListCache) { _ in
            updateFilteredApps()
        }
        .onChange(of: injectConfiguration.remoteConf) { _ in
            updateFilteredApps()
        }
        .onChange(of: searchText) { _ in
            updateFilteredApps()
        }
        .onAppear {
            softwareManager.refreshAppList()
        }
    }

    private var appList: some View {
        List(filteredApps, id: \.id) { app in
            NavigationLink {
                AppDetailView(appId: app.detail.identifier)
            } label: {
                HStack {
                    Image(nsImage: app.detail.icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(4)
                    VStack(alignment: .leading) {
                        Text(app.detail.name)
                            .font(.headline)
                        Text(app.detail.identifier)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Version: \(app.detail.version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .contextMenu {
                Button("Open in Finder") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: app.detail.path)
                }
                Button("Copy Bundle ID") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(app.detail.identifier, forType: .string)
                }
            }
        }
        .listStyle(SidebarListStyle())
    }

    private func updateFilteredApps() {
        filteredApps = getFilteredApps()
    }

    private func getFilteredApps() -> [AppEntry] {
        let apps = softwareManager.appListCache.map { AppEntry(id: $0.key, detail: $0.value) }
        return apps
            .filter { app in
                injectConfiguration.checkPackageIsSupported(package: app.detail.identifier) &&
                (searchText.isEmpty ||
                 app.detail.name.lowercased().contains(searchText.lowercased()) ||
                 app.detail.identifier.lowercased().contains(searchText.lowercased()))
            }
            .sorted { $0.detail.name < $1.detail.name }
    }
}
