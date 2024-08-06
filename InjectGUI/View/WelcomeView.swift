//
//  WelcomeView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/20.
//

import SwiftUI

struct WelcomeView: View {
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
        ZStack {
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
                    Text("By wibus. Made with ❤️")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundColor(.secondary)
                } else {
                    Text("Welcome to InjectGUI")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("By wibus. Made with ❤️")
                        .foregroundColor(.secondary)
                }
                

                Spacer().frame(height: 24)
            }
            VStack {
                Spacer()
                Text(version)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .opacity(0.5)
                    .onTapGesture {
                        let alert = NSAlert()
                        alert.messageText = "InjectGUI"
                        alert.informativeText = "You're in \(injectConfiguration.mode == injectConfigurationMode.local ? "Local Mode" : "Remote Mode")."
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
