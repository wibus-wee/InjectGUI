//
//  ContentView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//
import SwiftUI

struct AppEntry: Identifiable {
    let id = UUID()
    let key: String
    let value: AppDetail
}

struct ContentView: View {
    @StateObject var softwareManager = SoftwareManager.shared

    var body: some View {
        VStack {
            VStack {
                Text("InjectGUI")
                    .font(.largeTitle)
                
                Text("remoteGit: \(configuration.remoteGit)")
                Text("remoteGitBranch: \(configuration.remoteGitBranch ?? "nil")")
                Text("remoteGitCommit: \(configuration.remoteGitCommit ?? "nil")")
            }

            Spacer()

            Group {
                Button("updateRemoteConf") {
                    injectConfiguration.updateRemoteConf()
                }
                Button("getSupportedPackages") {
                    print(injectConfiguration.getSupportedPackages())
                }
                
                Button("downloadInjectLib") {
                    injectConfiguration.downloadInjectLib()
                }
                Button("updateInjectLib") {
                    injectConfiguration.updateInjectLib()
                }
                Button("getInjectLibVersion") {
                     print(injectConfiguration.getInjectLibVersion())
                }
                Button("update") {
                    injectConfiguration.update()
                }
            }

            Spacer()

//            VStack(alignment: .leading, spacing: 10) {
//                Text("SupportedPackages")
//                    .font(.headline)
//                List(packages) { package in
//                    Text(package.name)
//                }
//            }
//
//            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("Local Application List /Application")
                    .font(.headline)
                List(softwareManager.appListCache.map { AppEntry(key: $0.key, value: $0.value) }) { app in
                    HStack {
                        Text(app.value.name)
                        Text(app.key)
                    }
                }
            }
        }
        .padding()
    }
}
