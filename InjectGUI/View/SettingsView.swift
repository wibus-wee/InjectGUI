//
//  SettingsView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/20.
//

import Foundation
import SwiftUI


struct SettingsView: View {

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

  private enum Tabs: Hashable {
    case general
  }

  var body: some View {
    return TabView {
      generalView
    }
    .frame(width: 700)
  }

  var generalView: some View {
    VStack (alignment: .leading) {
        
        // Project info
        VStack (alignment: .leading, spacing: 4) {
          Text("InjectGUI")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
          Text("Version: \(version)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()

        Divider()

        VStack (alignment: .leading, spacing: 4) {
          
          VStack (alignment: .leading, spacing: 4) {
            Text("InjectLib")
                  .font(.system(size: 14, weight: .semibold, design: .rounded))
            Text("Information About InjectLib")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }

          Spacer(minLength: 10)
          
          VStack {

            // Setting Item
            HStack {
              Text("Local Version")
              Spacer()
              Text(injectConfiguration.getInjectLibVersion() ?? "Unknown")
                .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .cornerRadius(6)


            HStack {
              Text("GenShineImpartStarter Tool Exist")
              Spacer()
                Text(String(injectConfiguration.isGenShineImpactStarterExist()) )
                .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .cornerRadius(6)
          }
        }
        .padding()

      }
    .padding(20)
    .tabItem {
      Label("General", systemImage: "gear")
    }
    .tag(Tabs.general)
  }
}
