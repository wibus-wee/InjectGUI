//
//  InjectConfiguration.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import Foundation

struct Package: Identifiable {
    let id: String
    let name: String
}

// MARK: - InjectConfigurationModel
struct InjectConfigurationModel: Codable {
    let project, author: String
    let version: Double
    let description: Description
    let basePublicConfig: BasePublicConfig
    let appList: [AppList]

    enum CodingKeys: String, CodingKey {
        case project
        case author = "Author"
        case version = "Version"
        case description = "Description"
        case basePublicConfig
        case appList = "AppList"
    }
}

// MARK: - AppList
struct AppList: Codable {
    let packageName: PackageName
    let appBaseLocate, bridgeFile, injectFile: String?
    let needCopyToAppDir, noSignTarget, autoHandleHelper: Bool?
    let helperFile: HelperFile?
    let tccutil: Tccutil?
    let forQiuChenly, onlysh: Bool?
    let extraShell, smExtra: String?
    let componentApp: [String]?
    let deepSignApp, noDeep: Bool?
    let entitlements: String?
    let useOptool, autoHandleSetapp: Bool?

    enum CodingKeys: String, CodingKey {
        case packageName, appBaseLocate, bridgeFile, injectFile, needCopyToAppDir, noSignTarget, autoHandleHelper, helperFile, tccutil, forQiuChenly, onlysh, extraShell
        case smExtra = "SMExtra"
        case componentApp, deepSignApp, noDeep, entitlements, useOptool, autoHandleSetapp
    }
}

enum HelperFile: Codable {
    case string(String)
    case stringArray([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([String].self) {
            self = .stringArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(HelperFile.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for HelperFile"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .stringArray(let x):
            try container.encode(x)
        }
    }
}

enum PackageName: Codable {
    case string(String)
    case stringArray([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([String].self) {
            self = .stringArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(PackageName.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for PackageName"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .stringArray(let x):
            try container.encode(x)
        }
    }
    
    
    var allStrings: [String] {
        switch self {
        case .string(let x):
            return [x]
        case .stringArray(let x):
            return x
        }
    }
}

enum Tccutil: Codable {
    case bool(Bool)
    case stringArray([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode([String].self) {
            self = .stringArray(x)
            return
        }
        throw DecodingError.typeMismatch(Tccutil.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Tccutil"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .stringArray(let x):
            try container.encode(x)
        }
    }
}

// MARK: - BasePublicConfig
struct BasePublicConfig: Codable {
    let bridgeFile: String
}

// MARK: - Description
struct Description: Codable {
    let desc, bridgeFile, packageName, injectFile: String
    let supportVersion, supportSubVersion, extraShell, needCopyToAppDir: String
    let deepSignApp, disableLibraryValidate, entitlements, noSignTarget: String
    let noDeep, tccutil, autoHandleSetapp, autoHandleHelper: String
    let helperFile, componentApp, forQiuChenly: String
}

class InjectConfiguration: ObservableObject {
    static let shared = InjectConfiguration()
    
    var remoteConf = nil as InjectConfigurationModel?
    
    private init() {
        updateRemoteConf()
//        let _ = getSupportedPackages()
    }
    
    private func downloadConfig(data: Data?) {
        let decoder = JSONDecoder()
        let conf = try! decoder.decode(InjectConfigurationModel.self, from: data!)
        remoteConf = conf
        print("[I] Downloaded config.json")
    }
    
    /// 更新远程配置
    func updateRemoteConf() {
        print("[*] Downloading config.json...")
        let url = configuration.remoteGit
        let commit = configuration.remoteGitCommit
        let branch = configuration.remoteGitBranch
        // <url>/raw/<branch or commit>/config.json
        let _url = "\(url)/raw/\(branch ?? commit ?? "main")/config.json"
        let dataUrl = URL(string: _url)!
        
        let task = URLSession.shared.dataTask(with: dataUrl) { data, response, error in
            if let error = error {
                print("[W] Failed to download config.json: \(error.localizedDescription)")
                return
            }
            self.downloadConfig(data: data)
        }
        task.resume()
    }
    
    /// 设置远程配置来源
    func customRemoteConf(url: String, commit: String?, branch: String?) {
        configuration.remoteGit = url
        configuration.remoteGitBranch = branch
        configuration.remoteGitCommit = commit
        updateRemoteConf()
    }

    /// 获取当前配置支持的 Package
    func getSupportedPackages() -> [Package] {
        guard let conf = remoteConf else {
            return []
        }

        var packages = [Package]()
        for app in conf.appList {
            for name in app.packageName.allStrings {
                if !packages.contains(where: { $0.name == name }) {
                    packages.append(Package(id: name, name: name))
                }
            }
        }
        
        return packages
    }
    
    func downloadInjectLib() {
        print("[*] Downloading 91QiuChenly.dylib...")
        // <url>/raw/<branch or commit>/tool/91QiuChenly.dylib
        let url = configuration.remoteGit
        let commit = configuration.remoteGitCommit
        let branch = configuration.remoteGitBranch
        // <url>/raw/<branch or commit>/config.json
        let _url = "\(url)/raw/\(branch ?? commit ?? "main")/tool/91QiuChenly.dylib"
        let dataUrl = URL(string: _url)!
        
        let version = commit ?? "\(branch ?? "main")/latest"

        let task = URLSession.shared.downloadTask(with: dataUrl) { url, response, error in
            if let error = error {
                print("[W] Failed to download 91QiuChenly.dylib: \(error.localizedDescription)")
                return
            }
            guard let url = url else {
                return
            }
            do {
                let data = try Data(contentsOf: url)
                let path = getApplicationSupportDirectory().path
                let _url = URL(fileURLWithPath: path).appendingPathComponent("91QiuChenly.dylib")
                print("[*] Downloaded 91QiuChenly.dylib, save to \(path)")
                try data.write(to: _url)

                self.writeVersionMetadataIntoInjectLib(url: _url, version: version)

            } catch {
                print("[E] Failed to write 91QiuChenly.dylib: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    func updateInjectLib() {
        print("[*] Updating 91QiuChenly.dylib")
        let path = getApplicationSupportDirectory().path
        let _url = URL(fileURLWithPath: path).appendingPathComponent("91QiuChenly.dylib")
        if FileManager.default.fileExists(atPath: _url.path) {
            do {
                try FileManager.default.removeItem(at: _url)
                print("[*] Removed 91QiuChenly.dylib")
            } catch {
                print("[E] Failed to remove 91QiuChenly.dylib: \(error.localizedDescription)")
            }
        }
        downloadInjectLib()
    }
    
    func update() {
        updateInjectLib()
        updateRemoteConf()
    }

    private func writeVersionMetadataIntoInjectLib(url: URL, version: String) -> Int32 {
        // 向 91QiuChenly.dylib 的元数据中写入版本信息
        print("[*] Writing version metadata into 91QiuChenly.dylib...")
        let attributeName = "org.91QiuChenly.version"
        let attributeValue = version.data(using: .utf8)
        let res = setxattr(url.path, attributeName, (attributeValue! as NSData).bytes.bindMemory(to: CChar.self, capacity: attributeValue!.count), attributeValue!.count, 0, 0)
        if res != 0 {
            print("[E] Failed to write version metadata into 91QiuChenly.dylib: \(String(cString: strerror(errno)))")
            return 0
        }
        print("[I] Wrote version metadata into 91QiuChenly.dylib")
        return 1
    }


    func getInjectLibVersion() -> String? {
        let attributeName = "org.91QiuChenly.version"
        let path = getApplicationSupportDirectory().path
        let _url = URL(fileURLWithPath: path).appendingPathComponent("91QiuChenly.dylib")
        
        if FileManager.default.fileExists(atPath: _url.path) {
            // Prepare the buffer to receive the attribute value
            let bufferLength = getxattr(_url.path, attributeName, nil, 0, 0, 0)
            if bufferLength == -1 {
                print("[E] Failed to get the size of version metadata from 91QiuChenly.dylib: \(String(cString: strerror(errno)))")
                return nil
            }

            var buffer = [CChar](repeating: 0, count: bufferLength + 1)  // +1 for the null terminator
            let result = getxattr(_url.path, attributeName, &buffer, bufferLength, 0, 0)
            if result == -1 {
                print("[E] Failed to get version metadata from 91QiuChenly.dylib: \(String(cString: strerror(errno)))")
                return nil
            }

            buffer[bufferLength] = 0  // Ensure null termination
            let version = String(cString: buffer)
            return version
        } else {
            print("[E] 91QiuChenly.dylib does not exist at path: \(_url.path)")
        }
        
        return nil
    }
    
    /// 获取注入 package 的详细信息
    func injectDetail(package: String) -> AppList? {
        guard let conf = remoteConf else {
            return nil
        }
        let app = conf.appList.first { $0.packageName.allStrings.contains(package) }
        guard let app = app else {
            return nil
        }
        return app
    }

}

// injectConfiguration.getSupportedPackages()
// injectConfiguration.injectDetail(package: "com.xxx.xxx")
// injectConfiguration.customRemoteConf(url: "", commit: nil)
// injectConfiguration.updateRemoteConf()
// injectConfiguration.downloadInjectLib()
// injectConfiguration.updateInjectLib()
// injectConfiguration.update()
