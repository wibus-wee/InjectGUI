//
//  SettingsView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/20.
//

import Foundation
import SwiftUI


struct SettingsView: View {

    @State var isGenShineImpactStarterExist = false

    @StateObject var configuration = Configuration.shared

    init() {
        self.isGenShineImpactStarterExist = injectConfiguration.isGenShineImpactStarterExist()
    }

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
    case about
  }

  var body: some View {
    return TabView {
      generalView
      aboutView
    }

    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

  var generalView: some View {
    ScrollView {
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
            
            VStack (alignment: .leading, spacing: 4) {

              SettingItemView("Local Version") {
                Text(injectConfiguration.getInjectLibVersion() ?? "Unknown")
                  .foregroundColor(.secondary)
              }

              SettingItemView("Is GenShineImpactStarter Exist") {
                Text(String(isGenShineImpactStarterExist) )
                  .foregroundColor(.secondary)
              }


              SettingItemView("Download GenShineImpactStarter") {
                Button(action: {
                  injectConfiguration.downloadGenShineImpactStarter()
                }) {
                  Text(isGenShineImpactStarterExist ? "Downloaded" : "Download")
                }
                .disabled(isGenShineImpactStarterExist)
              }
            }

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

          VStack (alignment: .leading, spacing: 4) {
            
            VStack (alignment: .leading, spacing: 4) {
              Text("Settings")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
              Text("Settings About InjectGUI")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Spacer(minLength: 10)
            
            VStack (alignment: .leading, spacing: 4) {

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
                Button(action: {
                  injectConfiguration.updateRemoteConf()
                }) {
                  Text("Update Remote Conf")
                }
                .disabled(configuration.remoteGit.isEmpty)
                  

                Spacer()

                Button(action: {
                  injectConfiguration.updateInjectLib()
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
    .tag(Tabs.general)
  }

  var aboutView: some View {
    ZStack {
            VStack(spacing: 4) {
                Image("Avatar")
                    .antialiased(true)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)

                Spacer().frame(height: 16)

                Text("InjectGUI")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("By wibus. Made with ❤️")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(.secondary)

                Spacer().frame(height: 24)
            }
            VStack {
                Spacer()
                Text("Released under GPLv3. Based on Qiuchenly/InjectLib.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .opacity(0.5)
            }
            .padding()
    }
    .tabItem {
        Label("About", systemImage: "info.circle")
      }
    .tag(Tabs.about)
  }
}
