//
//  AboutView.swift
//  InjectGUI
//
//  Created by Licardo on 2024/8/9.
//

import SwiftUI

struct AboutView: View {
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
        VStack {
            Spacer()
            VStack(spacing: 4) {
                Image("Avatar")
                    .antialiased(true)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)

                Spacer().frame(height: 16)

                if #available(macOS 13.0, *) {
                    Text("Welcome to InjectGUI")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    HStack(spacing: 2) {
                        Text("Made with")
                            .foregroundColor(.secondary)
                        if #available(macOS 14.0, *) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .symbolEffect(.pulse, options: .speed(1))
                        } else {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                        Text("by wibus")
                            .foregroundColor(.secondary)
                    }
                    .font(.system(.body, design: .rounded, weight: .bold))
                } else {
                    Text("Welcome to InjectGUI")
                        .font(.title)
                        .fontWeight(.bold)
                    HStack(spacing: 2) {
                        Text("Made with")
                            .foregroundColor(.secondary)
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("by wibus")
                            .foregroundColor(.secondary)
                    }
                }

                Spacer().frame(height: 24)
            }
            Spacer()
            VStack {
                Text(version)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .opacity(0.5)
                Text("Released under GPLv3. Based on QiuChenly/InjectLib.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .opacity(0.5)
            }
            .onTapGesture {
                let alert = NSAlert()
                alert.messageText = "InjectGUI"
                alert.informativeText = String(localized: "You're in") + (injectConfiguration.mode == injectConfigurationMode.local ? String(localized: "Local Mode") : String(localized: "Remote Mode"))
                alert.addButton(withTitle: String(localized: "OK"))
                alert.runModal()
            }
            .padding()
            
            
        }
        .tabItem {
            Label("About", systemImage: "info.circle")
        }
    }
}
