//
//  SoftwareManager.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import AppKit
import Foundation

struct AppDetail {
    let name: String // -> CFBundleName
    let identifier: String // -> CFBundleIdentifier
    let version: String // -> CFBundleVersion
    let path: String // -> path
    let executable: String // -> CFBundleExecutable
    let icon: NSImage
}

class SoftwareManager: ObservableObject {
    static let shared = SoftwareManager()

    @Published var appListCache: [String: AppDetail] = [:]
       @Published var isLoading = false

       private init() {
           refreshAppList()
       }
    func refreshAppList() {
           DispatchQueue.main.async {
               self.isLoading = true
           }
           
           DispatchQueue.global(qos: .userInitiated).async { [weak self] in
               self?.getList()
               DispatchQueue.main.async {
                   self?.isLoading = false
               }
           }
       }
    private func loadAppInfo(
        from plistPath: String
    ) -> AppDetail? {
        let url = URL(
            fileURLWithPath: plistPath
        )
        guard let data = try? Data(
            contentsOf: url
        ),
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any],
            let bundleName = plist["CFBundleName"] as? String,
            let bundleIdentifier = plist["CFBundleIdentifier"] as? String,
            let bundleVersion = plist["CFBundleVersion"] as? String,
            let bundleExecutable = plist["CFBundleExecutable"] as? String,
            let bundleShortVersion = plist["CFBundleShortVersionString"] as? String
        else {
            return nil
        }

        // 获取图标文件名
        let iconFileRaw = plist["CFBundleIconFile"] as? String ?? plist["CFBundleIconName"] as? String

        // 检查文件名并添加扩展名（如果需要）
        let iconFile: String?
        if let iconFileRaw = iconFileRaw {
            iconFile = iconFileRaw.hasSuffix(
                ".icns"
            ) ? iconFileRaw : iconFileRaw.appending(
                ".icns"
            )
        } else {
            iconFile = nil
        }

        // 检查 iconFile 是否为 nil
        guard let finalIconFile = iconFile else {
            return nil
        }

        let path = url.deletingLastPathComponent().path
        let iconPath = URL(
            fileURLWithPath: plistPath
        ).deletingLastPathComponent().appendingPathComponent(
            "Resources"
        ).appendingPathComponent(
            finalIconFile
        ).path
        let icon = NSImage(
            contentsOfFile: iconPath
        )
        if icon == nil {
            print(
                "[W] Failed to load icon from path: \(iconPath)"
            )
        }
        return AppDetail(
            name: bundleName,
            identifier: bundleIdentifier,
            version: bundleVersion,
            path: path,
            executable: bundleExecutable,
            icon: icon ?? NSImage()
        )
    }

    func getList() {
         print("[*] Getting app list...")
         let applicationDirectories = [
             "/Applications",
             "/Applications/Setapp",
         ]
         let fileManager = FileManager.default

         var newAppListCache: [String: AppDetail] = [:]

         for directory in applicationDirectories {
             guard let appPaths = try? fileManager.contentsOfDirectory(atPath: directory) else {
                 continue
             }

             for appPath in appPaths {
                 let fullPath = "\(directory)/\(appPath)"
                 let infoPlistPath = "\(fullPath)/Contents/Info.plist"
                 if let appInfo = loadAppInfo(from: infoPlistPath) {
                     newAppListCache[appInfo.identifier] = appInfo
                 }
             }
         }

         DispatchQueue.main.async { [weak self] in
             self?.appListCache = newAppListCache
         }
     }

    func addAnMaybeExistAppToList(appBaseLocate: String) {
//        print("[*] try to add \(appBaseLocate) to list...")
        // "appBaseLocate": "/Applications/Setapp/AirBuddy.app/Contents/Library/LoginItems/AirBuddyHelper.app",
        let infoPlistPath = "\(appBaseLocate)/Contents/Info.plist"
        if let appInfo = loadAppInfo(from: infoPlistPath) {
            print("[*] Add app to list: \(appInfo.name) [\(appInfo.identifier)]")
            appListCache[appInfo.identifier] = appInfo
        }
    }

    /// 检查某个软件是否存在于系统中
    func checkSoftwareIsInstalled(package: String) -> Bool {
        print("[*] Checking if \(package) is installed...")
        return appListCache[package] != nil
    }
}
