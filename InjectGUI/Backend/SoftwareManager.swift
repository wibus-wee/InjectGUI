//
//  SoftwareManager.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import Foundation
import AppKit


struct AppDetail: Codable {
  let name: String // -> CFBundleName
  let identifier: String // -> CFBundleIdentifier
  let version: String // -> CFBundleVersion
  let path: String // -> path
  let icon: String
}


class SoftwareManager: ObservableObject {
  static let shared = SoftwareManager()

  @Published var appListCache: [String: AppDetail] = [:]

  init() {
    getList()
  }

  private func loadAppInfo(from plistPath: String) -> AppDetail? {
        let url = URL(fileURLWithPath: plistPath)
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let bundleName = plist["CFBundleName"] as? String,
              let bundleIdentifier = plist["CFBundleIdentifier"] as? String,
              let bundleVersion = plist["CFBundleVersion"] as? String,
              let bundleShortVersion = plist["CFBundleShortVersionString"] as? String,
              let iconFile = (plist["CFBundleIconFile"] as? String ?? plist["CFBundleIconName"] as? String)?.appending(".icns") else {
            return nil
        }

        let path = url.deletingLastPathComponent().path
        let iconPath = URL(fileURLWithPath: plistPath).deletingLastPathComponent().appendingPathComponent("Resources").appendingPathComponent(iconFile).path
        let icon = NSImage(contentsOfFile: iconPath)

        return AppDetail(name: bundleName, identifier: bundleIdentifier, version: bundleVersion, path: path, icon: icon?.tiffRepresentation?.base64EncodedString() ?? "")
  }

  func getList() {
    let applicationDirectory = "/Applications"
    let fileManager = FileManager.default

    guard let appPaths = try? fileManager.contentsOfDirectory(atPath: applicationDirectory) else {
        return
    }

    for appPath in appPaths {
        let fullPath = "\(applicationDirectory)/\(appPath)"
        let infoPlistPath = "\(fullPath)/Contents/Info.plist"
        if let appInfo = loadAppInfo(from: infoPlistPath) {
            appListCache[appInfo.identifier] = appInfo
        }
    }
  }
}
