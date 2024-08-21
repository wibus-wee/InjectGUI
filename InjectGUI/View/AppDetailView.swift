//
//  AppDetailView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/20.
//

import Foundation
import SwiftUI

extension AppDetailView {
    enum CompatibilityIcon: String {
        case compatible = "checkmark.circle.fill"
        case incompatible = "xmark.circle.fill"
        case unknown = "exclamationmark.circle.fill"
    }

    struct Compatibility: Identifiable {
        let id: String
        let inInjectLibList: Bool
    }
}

struct AppDetailView: View {
    @State var appId: String
    @State var appDetail: AppDetail
    @State var compatibility: Compatibility
    @State var appInjectConfDetail: AppList?

    init(appId: String) {
        self.appId = appId
        let appInjectConfDetail = injectConfiguration.injectDetail(package: appId)
        self.appInjectConfDetail = appInjectConfDetail
        let getAppDetailFromSoftwareManager = softwareManager.appListCache[appId]
        if getAppDetailFromSoftwareManager != nil {
            self.appDetail = SoftwareManager.shared.appListCache[appId]!
        } else {
            print("[*] Can't find app detail in SoftwareManager, it's a abnormal situation, please report to developer. appId: \(appId)")
            self.appDetail = AppDetail(name: appInjectConfDetail?.packageName.allStrings.first ?? "", identifier: appInjectConfDetail?.packageName.allStrings.first ?? "", version: "", path: "", executable: "", icon: NSImage())
        }
        // self._appDetail = State(wrappedValue: SoftwareManager.shared.appListCache[appId] ?? AppDetail(name: "", identifier: "", version: "", path: "", icon: NSImage()))
        self._compatibility = State(wrappedValue: Compatibility(id: appId, inInjectLibList: false))
        self._appInjectConfDetail = State(wrappedValue: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoView

            Divider()

            configurationView
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            let inInjectLibList = injectConfiguration.checkPackageIsSupported(package: appId)
            compatibility = Compatibility(
                id: appId,
                inInjectLibList: inInjectLibList
            )
            let appInjectConfDetail = injectConfiguration.injectDetail(package: appId)
            self.appInjectConfDetail = appInjectConfDetail
        }
    }

    var infoView: some View {
        HStack {
            Image(nsImage: appDetail.icon)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(appDetail.name)
                        .font(.headline)

                    Label("Injected", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .opacity(appDetail.isInjected ? 1 : 0)
                }
                Text(appDetail.identifier)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Version: \(appDetail.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()

            Button(action: {
                if compatibility.inInjectLibList {
                    if !injector.isRunning {
                        injector.startInjectApp(package: appId)
                    } else {
                        let alert = NSAlert()
                        alert.messageText = String(localized: "Inject is running")
                        alert.informativeText = String(localized: "It's a abnormal situation, it shouldn't be running, please report to developer.")
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: String(localized: "OK"))
                        alert.runModal()
                    }
                }
            }) {
                Text("Inject")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!compatibility.inInjectLibList)
        }
    }

    var configurationView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Inject Configurations")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: compatibility.inInjectLibList ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor(compatibility.inInjectLibList ? .green : .red)
                    Text("This app is supported by InjectLib.")
                        .font(.subheadline)
                }

                // if compatibility.inInjectLibList {
                HStack {
                    Image(systemName: CompatibilityIcon.compatible.rawValue)
                        .foregroundColor(.green)
                    HStack {
                        Text("Compatible Version")
                            .font(.subheadline)
                        Text("Universal Version (? Maybe)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                // }

                HStack {
                    Image(systemName: appInjectConfDetail?.deepSignApp ?? false ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor(appInjectConfDetail?.deepSignApp ?? false ? .green : .red)
                    Text("This app need deep codesign")
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: appInjectConfDetail?.autoHandleHelper ?? false ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor(appInjectConfDetail?.autoHandleHelper ?? false ? .green : .red)
                    Text("This app need auto handle helper")
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: !(appInjectConfDetail?.componentApp ?? []).isEmpty ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor(!(appInjectConfDetail?.componentApp ?? []).isEmpty ? .green : .red)

                    HStack {
                        Text("This app has sub app")
                            .font(.subheadline)
                        Text(appInjectConfDetail?.componentApp?.joined(separator: ", ") ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: appInjectConfDetail?.keygen ?? false ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor(appInjectConfDetail?.keygen ?? false ? .green : .red)
                    Text("This app can use keygen to generate key")
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: !(appInjectConfDetail?.tccutil?.allStrings ?? []).isEmpty ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor(!(appInjectConfDetail?.tccutil?.allStrings ?? []).isEmpty ? .green : .red)

                    HStack {
                        Text("This app needs to use tccutil to reset")
                            .font(.subheadline)
                        Text(appInjectConfDetail?.tccutil?.allStrings.joined(separator: ", ") ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Image(systemName: (appInjectConfDetail?.extraShell != nil) ? CompatibilityIcon.compatible.rawValue : CompatibilityIcon.incompatible.rawValue)
                        .foregroundColor((appInjectConfDetail?.extraShell != nil) ? .green : .red)
                    if let extraShell = appInjectConfDetail?.extraShell {
                        Text("This app has extraShell")
                            .font(.subheadline)
                        Text(extraShell)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("This app does not have extraShell")
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
