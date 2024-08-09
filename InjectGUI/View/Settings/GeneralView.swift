//
//  GeneralView.swift
//  InjectGUI
//
//  Created by Licardo on 2024/8/9.
//

import SwiftUI

struct GeneralView: View {
    @StateObject var configuration = Configuration.shared
    
    var version: String {
        var ret = "Version: " +
            (Constants.appVersion)
            + " Build: " +
            (Constants.appBuildVersion)
        #if DEBUG
            ret = "👾 \(ret) 👾"
        #endif
        return ret
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    Text("InjectGUI")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text("Version: \(version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("InjectLib")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text("Information About InjectLib")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Spacer(minLength: 10)

                    // 这里有个问题，就是，很难去拿到InjectLib的版本号，不然就需要去访问 GitHub API 了，但是这样一来很容易会达到 Rate Limit
                    // 暂时先不做这个功能了
                    // VStack(alignment: .leading, spacing: 4) {
                    //     ForEach(injectConfiguration.injectTools, id: \.self) { tool in
                    //         SettingItemView("\(tool) Version") {
                    //             Text(injectConfiguration.getInjectToolVersion(name: tool) ?? "Non Exist")
                    //                 .foregroundColor(.secondary)
                    //         }
                    //     }
                    // }

                    Spacer(minLength: 10)

                    Button(action: {
                        let getApplicationSupportDirectory = getApplicationSupportDirectory()
                        NSWorkspace.shared.open(getApplicationSupportDirectory)
                    }) {
                        Text("Open Support Folder")
                    }
                }
                .padding()

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text("Settings About InjectGUI")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 10)

                    VStack(alignment: .leading, spacing: 4) {
                        SettingItemView("Remote InjectLib Git URL") {
                            Group {
                                if !configuration.remoteGit.isEmpty {
                                    Button(action: {
                                        configuration.remoteGit = "https://github.com/QiuChenly/InjectLib"
                                    }) {
                                        Image(systemName: "xmark.circle")
                                    }
                                }

                                TextField("URL", text: $configuration.remoteGit)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 300)
                                    .padding(4)
                            }
                        }

                        SettingItemView("Remote InjectLib Branch") {
                            Group {
                                if !configuration.remoteGitBranch.isEmpty {
                                    Button(action: {
                                        configuration.remoteGitBranch = ""
                                    }) {
                                        Image(systemName: "xmark.circle")
                                    }
                                }

                                TextField("Branch", text: $configuration.remoteGitBranch)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 300)
                                    .padding(4)
                            }
                        }

                        SettingItemView("Remote InjectLib Commit") {
                            Group {
                                if !configuration.remoteGitCommit.isEmpty {
                                    Button(action: {
                                        configuration.remoteGitCommit = ""
                                    }) {
                                        Image(systemName: "xmark.circle")
                                    }
                                }

                                TextField("Commit", text: $configuration.remoteGitCommit)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 300)
                                    .padding(4)
                            }
                        }
                    }

                    Spacer(minLength: 10)

                    HStack {
                        Spacer()

                        Button(action: {
                            injectConfiguration.update()
                        }) {
                            Text("Update InjectLib & Tools")
                        }
                    }
                }
                .padding()
            }
            .padding(20)
        }
        .tabItem {
            Label("General", systemImage: "gear")
        }
    }
    
    func SettingItemView(_ title: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.1))
        .cornerRadius(6)
    }
}
