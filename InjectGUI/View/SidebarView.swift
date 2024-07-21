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

extension SidebarView {
    func handleApps(
        apps: [AppEntry]
    ) {
        if searchText.isEmpty {
            filteredApps = apps
        } else {
            filteredApps = apps.filter {
                $0.detail.name.lowercased().contains(
                    searchText.lowercased()
                ) ||
                $0.detail.identifier.lowercased().contains(
                    searchText.lowercased()
                )
            }
        }
    }
}

struct SidebarView: View {
    @State var displayMode: DisplayMode = .local
    @State var searchText: String = ""
    
    @StateObject var softwareManager = SoftwareManager.shared
    
    @State var filteredApps: [AppEntry] = []

    private func onDisplayModeChanged() {
        if displayMode == .local {
            let apps = softwareManager.appListCache.map {
                AppEntry(
                    id: $0.key,
                    detail: $0.value
                )
            }
            handleApps(
                apps: apps
            )
        } else {
            let packages = injectConfiguration.getSupportedPackages()
            let apps = packages.map {
                AppEntry(
                    id: $0.id,
                    detail: AppDetail(
                        name: $0.name,
                        identifier: $0.id,
                        version: "",
                        path: "",
                        icon: NSImage()
                    )
                )
            }
            handleApps(
                apps: apps
            )
        }
    }

    var body: some View {
        VStack {
            Picker(
                "",
                selection: $displayMode
            ) {
                Text(
                    "Local"
                ).tag(
                    DisplayMode.local
                )
                Text(
                    "Remote"
                ).tag(
                    DisplayMode.remote
                )
            }
            .pickerStyle(
                .segmented
            )
            .padding(
                .horizontal
            )
            
            HStack {
                Image(
                    systemName: "magnifyingglass"
                ) // 添加放大镜图标
                .foregroundColor(
                    .secondary
                )
                TextField(
                    "Search",
                    text: $searchText
                ) // 添加搜索栏
                .textFieldStyle(
                    PlainTextFieldStyle()
                )
            }
            .padding(
                8
            )
            .cornerRadius(
                8
            )
            .padding(
                .horizontal
            )
            
            Divider() // 添加分隔线
            
            
            Group {
                List(
                    filteredApps,
                    id: \.id
                ) { app in
                    NavigationLink {
                        AppDetailView(
                            appId: app.detail.identifier
                        )
                    } label: {
                        HStack {
                            Image(
                                nsImage: app.detail.icon
                            )
                            .resizable()
                            .frame(
                                width: 32,
                                height: 32
                            )
                            .cornerRadius(
                                4
                            )
                            VStack (
                                alignment: .leading
                            ) {
                                Text(
                                    app.detail.name
                                )
                                .font(
                                    .headline
                                )
                                VStack (
                                    alignment: .leading
                                ) {
                                    Text(
                                        app.detail.identifier
                                    )
                                    .font(
                                        .subheadline
                                    )
                                    .foregroundColor(
                                        .secondary
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    
                                    Text(
                                        "Version: \(app.detail.version)"
                                    )
                                    .font(
                                        .caption
                                    )
                                    .foregroundColor(
                                        .secondary
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                }
                            }
                        }
                        .padding(
                            .horizontal,
                            8
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .contentShape(
                            Rectangle()
                        )
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .listStyle(
                SidebarListStyle()
            )
        }
        .onAppear() {
            onDisplayModeChanged()
        }
        .onChange(
            of: displayMode
        ) { _ in
            onDisplayModeChanged()
        }
        .onChange(
            of: searchText
        ) { _ in
            onDisplayModeChanged()
        }
    }
}

//
//struct SidebarView_Previews: PreviewProvider {
//    static var previews: some View {
//        SidebarView()
//    }
//}
