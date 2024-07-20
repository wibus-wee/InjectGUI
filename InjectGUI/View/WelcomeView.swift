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
                Text("Welcome to InjectGUI")
                    .font(.system(.title, design: .rounded, weight: .black))
                Text("By wibus. Based on Qiuchenly/InjectLib")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer().frame(height: 24)
            }
            VStack {
                Spacer()
                Text(version)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .opacity(0.5)
            }
            .padding()
    }
  }
}
