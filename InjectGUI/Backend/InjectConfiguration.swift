//
//  InjectConfiguration.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import Foundation


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

class InjectConfiguration {
    static let shared = InjectConfiguration()
    var remoteConf = nil as InjectConfigurationModel?
    private init() {
        updateRemoteConf()
    }
    
    private func downloadConfig(data: Data?) {
        let decoder = JSONDecoder()
        let conf = try! decoder.decode(InjectConfigurationModel.self, from: data!)
        remoteConf = conf
#if DEBUG
        print("[I] Downloaded config.json")
        print(conf)
#endif
    }
    
    /// 更新远程配置
    func updateRemoteConf() {
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
    func getSupportedPackages() -> [String] {
        guard let conf = remoteConf else {
            return []
        }
        return conf.appList.flatMap { $0.packageName.allStrings }
    }
    
    func downloadInjectLib() {
        
    }
    
    func updateInjectLib() {
        
    }
    
    func update() {
        updateInjectLib()
        updateRemoteConf()
    }
    
}

// injectConfiguration.getSupportedPackages()
// injectConfiguration.injectDetail(package: "com.xxx.xxx")
// injectConfiguration.customRemoteConf(url: "", commit: nil)
// injectConfiguration.updateRemoteConf()
// injectConfiguration.downloadInjectLib()
// injectConfiguration.updateInjectLib()
// injectConfiguration.update()
