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

                Text("Welcome to InjectGUI")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("By wibus")
                    .font(.system(.body, design: .rounded))

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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
