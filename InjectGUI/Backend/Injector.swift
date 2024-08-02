//
//  Injector.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/30.
//

import Combine
import Foundation
import SwiftUI

enum InjectStatus {
    case none
    case running
    case finished
    case error
}

enum InjectStage: CaseIterable {
    case start
    case copyExecutableFileAsBackup
    case checkPermissionAndRun
    case handleKeygen
    case handleDeepCodeSign
    case handleAutoHandleHelper
    case handleTccutil
    case handleExtraShell
    case handleInjectLibInject
    case end
}

extension InjectStage {
    var description: String {
        switch self {
        case .start:
            return "Start Injecting"
        case .copyExecutableFileAsBackup:
            return "Copying Executable File as Backup"
        case .checkPermissionAndRun:
            return "Checking Permission and Run"
        case .handleKeygen:
            return "Handling Keygen"
        case .handleDeepCodeSign:
            return "Handling Deep Code Sign"
        case .handleAutoHandleHelper:
            return "Handling Auto Handle Helper"
        case .handleTccutil:
            return "Handling Tccutil"
        case .handleExtraShell:
            return "Handling Extra Shell"
        case .handleInjectLibInject:
            return "Handling Inject Lib Inject"
        case .end:
            return "Injecting Finished"
        }
    }
}

struct InjectRunningError {
    var error: String
    var stage: InjectStage
}

struct InjectRunningStage {
    var stage: InjectStage
    var message: String
    var progress: Double
    var error: InjectRunningError?
    var status: InjectStatus
}

struct InjectRunningStatus {
    var appId: String
    var appName: String
    var stages: [InjectRunningStage] = []
    var message: String
    var progress: Double
    var error: InjectRunningError?
}

class Injector: ObservableObject {
    static let shared = Injector()
    
    private let executor = Executor.shared
    
    @Published var shouldShowStatusSheet: Bool = false
    @Published var isRunning: Bool = false
    @Published var stage: InjectRunningStatus = .init(appId: "", appName: "", stages: [], message: "", progress: 0)
    @Published var injectDetail: AppList? = nil
    @Published var appDetail: AppDetail? = nil
    @Published var emergencyStop: Bool = false

    init() {}

    func handleInjectApp() {}

    func startInjectApp(package: String) {
        if self.isRunning {
            return
        }
        guard let appDetail = softwareManager.appListCache[package] else {
            return
        }
        guard let injectDetail = injectConfiguration.injectDetail(package: package) else {
            return
        }
        self.injectDetail = injectDetail
        self.appDetail = appDetail
        self.shouldShowStatusSheet = true
        self.stage = .init(
            appId: appDetail.identifier,
            appName: appDetail.name,
            stages: [],
            message: "Injecting",
            progress: 0
        )
        self.isRunning = true
        self.updateInjectStage(stage: .start, message: InjectStage.start.description, progress: 1, status: .finished)
        // 开始依次执行步骤
        self.executeNextStage(stages: InjectStage.allCases, index: 0)
    }

    func executeNextStage(stages: [InjectStage], index: Int) {
        guard index < stages.count else {
            self.updateInjectStage(stage: .end, message: InjectStage.end.description, progress: 1, status: .finished)
            return
        }

        let stage = stages[index]
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        let commands = self.commandsForStage(stage)
        self.executor.executeShellCommands(commands)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.updateInjectStage(stage: stage, message: "Error: \(error.localizedDescription)", progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
                } else {
                    self.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
                    self.executeNextStage(stages: stages, index: index + 1)
                }
            }, receiveValue: { _ in })
            .store(in: &self.executor.cancellables)
    }

    func updateInjectStage(stage: InjectStage, message: String, progress: Double, status: InjectStatus, error: InjectRunningError? = nil) {
        guard self.isRunning else {
            return
        }

        if let index = self.stage.stages.firstIndex(where: { $0.stage == stage }) {
            self.stage.stages[index].message = message
            self.stage.stages[index].progress = progress
            self.stage.stages[index].status = status
            self.stage.stages[index].error = error
        } else {
            self.stage.stages.append(
                .init(
                    stage: stage,
                    message: message,
                    progress: progress,
                    error: error,
                    status: status
                )
            )
        }
        self.stage.progress = self.stage.stages.reduce(0) { $0 + $1.progress } / Double(self.stage.stages.count)
    }

    func stopInjectApp() {
        self.stage = .init(appId: "", appName: "", stages: [], message: "", progress: 0)
        self.injectDetail = nil
        self.isRunning = false
        self.emergencyStop = true
    }

    func commandsForStage(_ stage: InjectStage) -> [(command: String, isAdmin: Bool)] {
        switch stage {
        case .copyExecutableFileAsBackup:
            return copyExecutableFileAsBackupCommands()
        case .checkPermissionAndRun:
            return checkPermissionAndRunCommands()
        case .handleInjectLibInject:
            return handleInjectLibInjectAdminCommands()
        case .handleKeygen:
            return handleKeygenCommands()
        case .handleDeepCodeSign:
            return handleDeepCodeSignCommands()
        case .handleAutoHandleHelper:
            return handleAutoHandleHelperCommands()
        case .handleTccutil:
            return handleTccutilCommands()
        case .handleExtraShell:
            return handleExtraShellCommands()
        default:
            return []
        }
    }

    // MARK: - 注入原神之 Copy Executable File as Backup

    func copyExecutableFileAsBackupCommands() -> [(command: String, isAdmin: Bool)] {
        let bridgeDir = self.injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/MacOS"
        let source = (self.appDetail?.path ?? "") + bridgeDir + "/" + (self.injectDetail?.bridgeFile ?? self.appDetail?.executable ?? "")
        let destination = source.appending(".backup")
        print("Source: \(source). bridgeDir: \(bridgeDir). bridgeFile: \(self.injectDetail?.bridgeFile ?? ""). executable: \(self.appDetail?.executable ?? "")")
        if !FileManager.default.fileExists(atPath: source) {
            print("Source file not found: \(source)")
            return []
        }
        if FileManager.default.fileExists(atPath: destination) {
            print("Destination file already exists: \(destination)")
            return []
        }
        return [("sudo cp \(source) \(destination)", true)]
    }

    // MARK: - 注入原神之 权限与运行检查
    func checkPermissionAndRunCommands() -> [(command: String, isAdmin: Bool)] {
        let bridgeDir = self.injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/MacOS"
        let source = (self.appDetail?.path ?? "") + bridgeDir + (self.injectDetail?.bridgeFile ?? self.appDetail?.executable ?? "")
        let appBaseLocate = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "")
        return [
            ("sudo chmod -R 777 \(appBaseLocate)", true),
            ("sudo xattr -cr \(appBaseLocate)", true),
            ("sudo pkill -f \(source)", true)
        ]
    }

    // MARK: - 注入原神之 Keygen

    func handleKeygenCommands() -> [(command: String, isAdmin: Bool)] {
        let userName = NSFullUserName()
        let keygenStarterURL = injectConfiguration.getInjecToolPath(name: "KeygenStarter")
        guard keygenStarterURL != nil else {
            return []
        }
        return [("\(keygenStarterURL!) '\(bundleIdentifier)' '\(userName)'", false)]
    }

    // MARK: - 注入原神之 InjectLibInject

    func handleInjectLibInjectAdminCommands() -> [(command: String, isAdmin: Bool)] {
        let bridgeDir = self.injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/MacOS"
        let source = (self.appDetail?.path ?? "") + bridgeDir + "/" + (self.injectDetail?.bridgeFile ?? self.appDetail?.executable ?? "")
        let destination = source.appending(".backup")

        let insert_dylib_URL = injectConfiguration.getInjecToolPath(name: "insert_dylib")
        let QiuchenlyDylib_URL = injectConfiguration.getInjecToolPath(name: "91Qiuchenly.dylib")
        
        if insert_dylib_URL == nil || QiuchenlyDylib_URL == nil {
            return []
        }
        
        if !FileManager.default.fileExists(atPath: insert_dylib_URL?.path() ?? "") {
            return []
        }
        if !FileManager.default.fileExists(atPath: QiuchenlyDylib_URL?.path() ?? "") {
            return []
        }

        if injectDetail?.needCopyToAppDir == true {
            let copyedQiuchenly_URL = (self.appDetail?.path ?? "") + bridgeDir + "/91Qiuchenly.dylib"
            let softLink = ("ln -f -s '\(QiuchenlyDylib_URL)' '\(copyedQiuchenly_URL)'", true) // 为了防止原神更新后导致的插件失效，这里使用软链接
            let desireApp = [
                source
            ]
            let componentAppList = self.injectDetail?.componentApp ?? []
            let appBaseLocate = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "")
            let componentApp = componentAppList.map { appBaseLocate + $0 }
            let componentAppExecutable = componentApp.map { $0 + "/Contents/MacOS/" + (self.readExecutableFile(app: URL(fileURLWithPath: $0)) ?? "") }
            let desireAppList = desireApp + componentAppExecutable
            let insert_dylib_commands = desireAppList.map { "sudo \(insert_dylib_URL) '\(copyedQiuchenly_URL)' '\(destination)' '\($0)'" }
            
            return [softLink] + insert_dylib_commands.map { ($0, true) }
        }

        return [("sudo \(insert_dylib_URL) '\(QiuchenlyDylib_URL)' '\(source)' '\(destination)'", true)]
    }

    // MARK: - 注入原神之 DeepCodeSign

    func handleDeepCodeSignCommands() -> [(command: String, isAdmin: Bool)] {
        var shells: [(command: String, isAdmin: Bool)] = []
        
        let sign_prefix = "/usr/bin/codesign -f -s - --timestamp=none --all-architectures"
        let no_deep = self.injectDetail?.noDeep
        var sign_prefix_with_deep = sign_prefix
        if no_deep == nil {
            sign_prefix_with_deep += " --deep"
        }

        let entitlements = self.injectDetail?.entitlements
        if let entitlements = entitlements {
            sign_prefix_with_deep += " --entitlements \(entitlements)"
        }

        let bridgeDir = self.injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/MacOS"
        let dest = (self.appDetail?.path ?? "") + bridgeDir + "/" + (self.injectDetail?.bridgeFile ?? self.appDetail?.executable ?? "")
        
        shells.append((sign_prefix_with_deep + " '\(dest)'", false))
        
        let deepSignApp = self.injectDetail?.deepSignApp // Bool
        if deepSignApp == true {
            let deepSignAppPath = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "")
            shells.append((sign_prefix_with_deep + " '\(deepSignAppPath)'", false))
        }
        
//        let disableLibraryValidate = self.injectDetail?.dis
//        if let disableLibraryValidate = disableLibraryValidate {
//            shells.append(("sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true", true))
//        }

        return shells
    }
    
    // MARK: - 注入原神之 ExtraShell

    func handleExtraShellCommands() -> [(command: String, isAdmin: Bool)] {
        let extraShell = self.injectDetail?.extraShell // String?
        if extraShell == nil {
            return []
        }
        let getToolDownloadURL = injectConfiguration.generateInjectToolDownloadURL(name: extraShell!)
        guard getToolDownloadURL != nil else {
            return []
        }
        let downloadIntoTmpPath = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: "/"), create: true)
        let downloadPath = downloadIntoTmpPath?.appendingPathComponent(extraShell!)
        let downloadCommand = "curl -L -o \(downloadPath?.path ?? "") \(getToolDownloadURL!)"

        let bridgeDir = self.injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/MacOS"
        let dest = (self.appDetail?.path ?? "") + bridgeDir + "/" + (self.injectDetail?.bridgeFile ?? self.appDetail?.executable ?? "")

        return [
            (downloadCommand, false),
            ("sudo sh \(downloadPath?.path ?? "")", true),
            ("sudo xattr -cr \(dest)", true)
        ]
    }

    // MARK: - 注入原神之 AutoHandleHelper

    func handleAutoHandleHelperCommands() -> [(command: String, isAdmin: Bool)] {
        var shells: [(command: String, isAdmin: Bool)] = []
        let helperFile = self.injectDetail?.helperFile?.allStrings // [String]?
        let autoHandleHelper = self.injectDetail?.autoHandleHelper // Bool?
        if let helperFile = helperFile, let autoHandleHelper = autoHandleHelper {
            var helpers: [String] = []
            if autoHandleHelper {
                helpers = helperFile

                for helper in helpers {
                    let genShineImpactStarterURL = injectConfiguration.getInjecToolPath(name: "GenShineImpactStarter")
                    let targetHelper = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + helper
                    let bridgeFile = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + (self.injectDetail?.bridgeFile ?? "")
                    let insertDylibURL = injectConfiguration.getInjecToolPath(name: "insert_dylib")
                    let helperName = targetHelper.split(separator: "/").last
                    let target = "/Library/LaunchDaemons/\(helperName!).plist"
                    
                    var srcInfo = [(self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + "/Contents/Info.plist"]
                    if let componentApps = self.injectDetail?.componentApp {
                        srcInfo.append(contentsOf: componentApps.map { (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + $0 + "/Contents/Info.plist" })
                    }
                    
                    let plistBuddy = "/usr/libexec/PlistBuddy"
                    
                    guard FileManager.default.fileExists(atPath: genShineImpactStarterURL?.path() ?? "") else {
                        return []
                    }
                    guard FileManager.default.fileExists(atPath: insertDylibURL?.path() ?? "") else {
                        return []
                    }
                    guard FileManager.default.fileExists(atPath: targetHelper) else {
                        return []
                    }
                    
                    let genShineInjectCommand = ("\(genShineImpactStarterURL!) '\(targetHelper)' \(self.injectDetail?.smExtra ?? "")")
                    let insertDylibCommand = "\(insertDylibURL!) '\(bridgeFile)91QiuChenly.dylib' '\(targetHelper)' '\(targetHelper)'"
                    let unloadLaunchctlCommand = ("sudo /bin/launchctl unload \(target)", true)
                    let killAllCommand = ("sudo /usr/bin/killall -u root -9 \(helperName!)", true)
                    let rmCommand = ("sudo /bin/rm \(target)", true)
                    let rmPrivilegedHelper = "sudo /bin/rm /Library/PrivilegedHelperTools/\(helperName!)"
                    let xattrCommand = "sudo xattr -c '\(self.appDetail?.path ?? "")'"
                    let plistBuddyCommand = "\(plistBuddy) -c 'Set :SMPrivilegedExecutables:\(helperName!) 'identifier \\\"\(helperName!)\\\"'' \(srcInfo.joined(separator: " "))"
                    let codeSignHelperCommand = "/usr/bin/codesign -f -s - --all-architectures --deep '\(targetHelper)'"
                    let codeSignAppCommand = "/usr/bin/codesign -f -s - --all-architectures --deep '\(self.appDetail?.path ?? "".replacingOccurrences(of: "/Contents", with: ""))'"
                    
                    shells.append((genShineInjectCommand, true))
                    shells.append((insertDylibCommand, true))
                    if FileManager.default.fileExists(atPath: target) {
                        shells.append(unloadLaunchctlCommand)
                        shells.append(killAllCommand)
                        shells.append(rmCommand)
                        shells.append((rmPrivilegedHelper, true))
                    }
                    shells.append((xattrCommand, true))
                    shells.append((plistBuddyCommand, true))
                    shells.append((codeSignHelperCommand, true))
                    shells.append((codeSignAppCommand, true))
                    
                    return shells
                }
            }
        }
        
        return []
    }

    // MARK: - 注入原神之 Tccutil

    func handleTccutilCommands() -> [(command: String, isAdmin: Bool)] {
        let tccutil = self.injectDetail?.tccutil?.allStrings // [String]?
        if let tccutil = tccutil {
            var ids = [self.appDetail?.identifier]
            if let componentApp = self.injectDetail?.componentApp {
                ids.append(contentsOf: componentApp.map { self.readBundleID(app: URL(fileURLWithPath: (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + $0)) })
            }
            // Use compactMap to filter out nil values and ensure ids is [String]
            let nonOptionalIds = ids.compactMap { $0 }
            return tccutil.map { "sudo /usr/bin/tccutil reset \($0) \(nonOptionalIds.joined(separator: " "))" }.map { ($0, true) }
        }
        return []
    }


    
    // MARK: - 额外原神之 临时读取 Executable
    
    func readExecutableFile(app: URL) -> String? {
        let infoPlist = app.appendingPathComponent("Contents/Info.plist")
        let appInfo = NSDictionary(contentsOf: infoPlist)
        let executable = appInfo?["CFBundleExecutable"] as? String
        return executable
    }
    
    // MARK: - 额外原神之 临时读取 BundleID
    
    func readBundleID(app: URL) -> String? {
        let infoPlist = app.appendingPathComponent("Contents/Info.plist")
        let appInfo = NSDictionary(contentsOf: infoPlist)
        let bundleID = appInfo?["CFBundleIdentifier"] as? String
        return bundleID
    }
}
