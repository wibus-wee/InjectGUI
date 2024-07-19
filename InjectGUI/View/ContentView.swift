//
//  ContentView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import SwiftUI

struct ContentView: View {
    

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
            Button("update") {
                injectConfiguration.update()
            }

            
        }
        .padding()
    }
}
