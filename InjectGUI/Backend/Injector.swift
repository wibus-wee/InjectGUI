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
    case handleInjectLibInject
    case handleDeepCodeSign
    case handleExtraShell
    case handleTccutil
    case handleAutoHandleHelper
    case end
}

extension InjectStage {
    var description: String {
        switch self {
        case .start:
            return String(localized: "Start Injecting")
        case .copyExecutableFileAsBackup:
            return String(localized: "Copying Executable File as Backup")
        case .checkPermissionAndRun:
            return String(localized: "Checking Permission and Run")
        case .handleKeygen:
            return String(localized: "Handling Keygen")
        case .handleDeepCodeSign:
            return String(localized: "Handling Deep Code Sign")
        case .handleAutoHandleHelper:
            return String(localized: "Handling Auto Handle Helper")
        case .handleTccutil:
            return String(localized: "Handling Tccutil")
        case .handleExtraShell:
            return String(localized: "Handling Extra Shell")
        case .handleInjectLibInject:
            return String(localized: "Handling InjectLib Inject")
        case .end:
            return String(localized: "Injecting Finished")
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

    func startInjectApp(package: String) {
        // MARK: - 拦截 Setapp 旗下软件

        if package.contains("com.setapp") {
            let alert = NSAlert()
            alert.messageText = String(localized: "Please read the Setapp inject document first")
            alert.informativeText = String(localized: "It's important to read the Setapp inject document first before using the tool. Please")
            alert.alertStyle = .informational
            alert.addButton(withTitle: String(localized: "I have read the document"))
            alert.addButton(withTitle: String(localized: "Read the document"))
            alert.addButton(withTitle: String(localized: "Cancel"))
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Continue
            } else if response == .alertSecondButtonReturn {
                let url = URL(string: "https://qiuchenlyopensource.github.io/Documentaions/setapp.html")!
                NSWorkspace.shared.open(url)
                return
            } else {
                return
            }
        }
        if self.isRunning {
            return
        }
        if injectConfiguration.allToolsExist() == false {
            let alert = NSAlert()
            alert.messageText = String(localized: "Inject Tools Not Found")
            alert.informativeText = String(localized: "Inject tools not found, it may be caused by network issues or the tools are not available. Please try again later.")
            alert.alertStyle = .warning
            alert.addButton(withTitle: String(localized: "OK"))
            alert.runModal()
            return
        }
        guard let appDetail = softwareManager.appListCache[package] else {
            return
        }
        guard let injectDetail = injectConfiguration.injectDetail(package: package) else {
            return
        }
        print("----------------------------")
        print("[*] Start inject \(package)")
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
                    let alert = NSAlert()
                    alert.messageText = String(localized: "Command Execution Error")

                    // Extracting the AppleScript error message
                    var errorMessage = error.localizedDescription
                    if let appleScriptError = error as NSError? {
                        if let appleScriptErrorMessage = appleScriptError.userInfo["NSAppleScriptErrorMessage"] as? String {
                            errorMessage = appleScriptErrorMessage
                        }
                    }

                    alert.informativeText = String(localized: "\(errorMessage) \n\nPlease check your application integrity and try again.\n\n(Stage: \(stage.description))")
                    alert.alertStyle = .critical
                    // 加一个 Open an issue 按钮，点击后打开 GitHub Issues
                    alert.addButton(withTitle: String(localized: "OK"))
                    alert.addButton(withTitle: String(localized: "Report an issue"))
                    let response = alert.runModal()
                    if response == .alertSecondButtonReturn {
                        // 构建一个 issue 链接
                        let title = "[Bug] Error when injecting \(self.appDetail?.name ?? "")"
                        let body = """
                        ### Error Message
                        
                        ```
                        \(errorMessage)
                        ```

                        ### Info

                        - Name: \(self.appDetail?.name ?? "")
                        - Identifier: \(self.appDetail?.identifier ?? "")
                        - \(self.appDetail?.name ?? "") Version: \(self.appDetail?.version ?? "")
                        - Stage: \(stage.description)
                        - InjectGUI version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")

                        """
                        let url = URL(string: "\(Constants.projectUrl)/issues/new?assignees=&labels=bug&title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
                        NSWorkspace.shared.open(url)
                    }
                    self.updateInjectStage(stage: stage, message: "Error: \(errorMessage)", progress: 1, status: .error, error: InjectRunningError(error: errorMessage, stage: stage))
                    self.isRunning = false
                    self.emergencyStop = true
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
            return self.copyExecutableFileAsBackupCommands()
        case .checkPermissionAndRun:
            return self.checkPermissionAndRunCommands()
        case .handleInjectLibInject:
            return self.handleInjectLibInjectAdminCommands()
        case .handleKeygen:
            return self.handleKeygenCommands()
        case .handleDeepCodeSign:
            return self.handleDeepCodeSignCommands()
        case .handleAutoHandleHelper:
            return self.handleAutoHandleHelperCommands()
        case .handleTccutil:
            return self.handleTccutilCommands()
        case .handleExtraShell:
            return self.handleExtraShellCommands()
        // case .end:
        //     let openApp = "open '\((self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: ""))'"
        //     return [(openApp, false)]
        default:
            return []
        }
    }

    // MARK: - 准备原神之 Generate Source Path

    enum GenScriptType {
        case none
        case appleScript
        case bash
    }

    private func getBridgeDir(executable: Bool? = nil) -> String {
        self.getBridgeDir(executable: executable, injectDetail: self.injectDetail)
    }

    private func getBridgeDir(executable: Bool? = nil, injectDetail: AppList?) -> String {
        if (executable ?? false) || injectDetail?.autoHandleSetapp == true {
           return "/MacOS/"
        } else {
            return injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/Frameworks/"
        }
    }

    func genSourcePath(for type: GenScriptType) -> String {
        let bridgeDir = self.getBridgeDir()
        let source = (self.appDetail?.path ?? "") + bridgeDir + (self.injectDetail?.injectFile ?? self.appDetail?.executable ?? "")
        return self.transformPath(path: source, to: type)
    }

    private func genSourcePath(for type: GenScriptType, executable: Bool) -> String {
        let bridgeDir = self.getBridgeDir(executable: executable)
        let source = (self.appDetail?.path ?? "") + bridgeDir + (executable ? (self.appDetail?.executable ?? "") : (self.injectDetail?.injectFile ?? ""))
        return self.transformPath(path: source, to: type)
    }

    func genSourcePath(for type: GenScriptType, file: String?) -> String {
        self.genSourcePath(for: type, appList: self.injectDetail, file: file)
    }

    func genSourcePath(for type: GenScriptType, appList: AppList?, file: String?) -> String {
        let bridgeDir = self.getBridgeDir(injectDetail: appList)
        let source = (self.appDetail?.path ?? "") + bridgeDir + (file ?? "")
        return self.transformPath(path: source, to: type)
    }

    func genSourcePath(for type: GenScriptType, appList: AppList) -> String {
        let bridgeDir = self.getBridgeDir(injectDetail: appList)
        let source = (self.appDetail?.path ?? "") + bridgeDir + (self.injectDetail?.injectFile ?? self.appDetail?.executable ?? "")
        return self.transformPath(path: source, to: type)
    }

    private func genSourcePath(for type: GenScriptType, path: String?) -> String {
        return self.transformPath(path: path ?? "", to: type)
    }

    private func transformPath(path: String, to type: GenScriptType) -> String {
        switch type {
        case .none:
            return path.replacingOccurrences(of: "%20", with: " ")
        case .appleScript:
           return path.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: " ", with: "\\\\ ")
        case .bash:
            return path.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: " ", with: "\\ ")
        }
    }

    // MARK: - 注入原神之 Copy Executable File as Backup

    func copyExecutableFileAsBackupCommands() -> [(command: String, isAdmin: Bool)] {
        let source = self.genSourcePath(for: .none)
        let destination = source.appending(".backup")

        if !FileManager.default.fileExists(atPath: source) {
            print("[*] Source file not found: \(source)")
            return [("echo Source file not found: \(source.transformTo(to: .bash)) && exit 1", true)] // 借用一下 AppleScript 来弹窗
        }
        if FileManager.default.fileExists(atPath: destination) {
            print("[*] Destination file already exists: \(destination)")
            return []
        }
        return [
            ("sudo cp \(source.transformTo(to: .bash)) \(destination.transformTo(to: .bash))", true)
        ]
    }

    // MARK: - 注入原神之 权限与运行检查

    func checkPermissionAndRunCommands() -> [(command: String, isAdmin: Bool)] {
        var shells: [(command: String, isAdmin: Bool)] = []
        let source = self.genSourcePath(for: .bash)
        shells.append(("sudo xattr -cr \(source)", true))
        shells.append(("sudo chmod -R 777 \(source)", true))

        // 检查是否运行中, 如果运行中则杀掉进程
        let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: self.appDetail?.identifier ?? "").count > 0
        if isRunning {
            shells.append(("sudo pkill -f \(self.genSourcePath(for: .bash, executable: true))", true))
        }
        return shells
    }

    // MARK: - 注入原神之 Keygen

    func handleKeygenCommands() -> [(command: String, isAdmin: Bool)] {
        let userName = NSFullUserName()
        let keygenStarterURL = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "KeygenStarter")?.pathWithFallback())
        let bundleIdentifier = self.appDetail?.identifier ?? ""
        if self.injectDetail?.keygen ?? false {
            return [("\(keygenStarterURL) '\(bundleIdentifier)' '\(userName)'", false)]
        }
        return []
    }

    // MARK: - 注入原神之 InjectLibInject

    func handleInjectLibInjectAdminCommands() -> [(command: String, isAdmin: Bool)] {
        print("[*] Jump in injector:stages:handleInjectLibInjectAdminCommands")
        let source = self.genSourcePath(for: .bash)
        let destination = source.appending(".backup")

        let insert_dylib_URL = injectConfiguration.getInjecToolPath(name: "insert_dylib")?.pathWithFallback().replacingOccurrences(of: "%20", with: " ")
        let QiuchenlyDylib_URL = injectConfiguration.getInjecToolPath(name: "91Qiuchenly.dylib")?.pathWithFallback().replacingOccurrences(of: "%20", with: " ")

        if insert_dylib_URL == nil || QiuchenlyDylib_URL == nil {
            let alert = NSAlert()
            alert.messageText = String(localized: "Inject Tools Path Not Found")
            alert.informativeText = String(localized: "This should not happen here, please report to the developer (Area: MainInject)")
            alert.alertStyle = .warning
            alert.addButton(withTitle: String(localized: "OK"))
            alert.runModal()
            print("[*] Inject Tools Path Not Found.")
            return [("echo Inject Tools Path Not Found && exit 1", true)]
        }

        if self.injectDetail?.needCopyToAppDir == true {
            print("[*] Copying 91Qiuchenly.dylib to app dir")
//            let copyedQiuchenly_URL = (self.appDetail?.path ?? "") + bridgeDir + "91Qiuchenly.dylib"
            let copyedQiuchenly_URL = self.genSourcePath(for: .none, file: "91Qiuchenly.dylib")
            let softLink = ("sudo ln -f -s '\(QiuchenlyDylib_URL!)' '\(copyedQiuchenly_URL)'", true) // 为了防止原神更新后导致的插件失效，这里使用软链接
            let desireApp = [
                source.transformTo(to: .none)
            ]
            let componentAppList = self.injectDetail?.componentApp ?? []
            let appBaseLocate = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "")
            let componentApp = componentAppList.map { appBaseLocate + $0 }
            let componentAppExecutable = componentApp.map { $0 + "/Contents/MacOS/" + (self.readExecutableFile(app: URL(fileURLWithPath: $0)) ?? "") }
            let desireAppList = desireApp + componentAppExecutable
            let insert_dylib_commands = desireAppList.map { "sudo \(self.genSourcePath(for: .bash, path: insert_dylib_URL!)) '\(copyedQiuchenly_URL)' '\(destination.transformTo(to: .none))' '\($0)'" }

            return [softLink] + insert_dylib_commands.map { ($0, true) }
        }

        return [("sudo \(self.genSourcePath(for: .bash, path: insert_dylib_URL!)) '\(QiuchenlyDylib_URL!)' '\(source.transformTo(to: .none))' '\(destination.transformTo(to: .none))'", true)]
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
        if let entitlements {
            let entitlementDownloadURL = injectConfiguration.generateInjectToolDownloadURL(name: entitlements)
            let downloadIntoTmpPath = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: "/"), create: true)
            let entitlementsPath = downloadIntoTmpPath?.appendingPathComponent(entitlements).path
//            let downloadCommand = "curl -L -o \(entitlementsPath!) \(entitlementDownloadURL!)"

            let semaphore = DispatchSemaphore(value: 0)
            
            let task = URLSession.shared.downloadTask(with: entitlementDownloadURL!) { (location, response, error) in
                if let location = location {
                    try? FileManager.default.moveItem(at: location, to: URL(fileURLWithPath: entitlementsPath!))
                    print("[*] Download Entitlements Success: \(entitlementDownloadURL!)")
                } else {
                    print("[*] Download Entitlements Failed: \(entitlementDownloadURL!)")
                    shells.append(("echo Download Entitlements Failed: \(entitlementDownloadURL!) && exit 1", false))
                }
                semaphore.signal()
            }

            task.resume()
            semaphore.wait()
            
            sign_prefix_with_deep += " --entitlements \(entitlementsPath!)"
        }

        let dest = self.genSourcePath(for: .none)

        if !(injectDetail?.noSignTarget ?? false) {
            shells.append((sign_prefix_with_deep + " '\(dest)'", true))
        }
//        shells.append((sign_prefix_with_deep + " '\(dest)'", false))

        let deepSignApp = self.injectDetail?.deepSignApp // Bool
        if deepSignApp == true {
            let deepSignAppPath = self.genSourcePath(for: .none, path: (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: ""))
            shells.append((sign_prefix_with_deep + " '\(deepSignAppPath)'", true))
        }

//        let disableLibraryValidate = self.injectDetail?.dis
//        if let disableLibraryValidate = disableLibraryValidate {
//            shells.append(("sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true", true))
//        }

        return shells
    }

    // MARK: - 注入原神之 ExtraShell

    func handleExtraShellCommands() -> [(command: String, isAdmin: Bool)] {
        var shells: [(command: String, isAdmin: Bool)] = []
        guard let extraShell = self.injectDetail?.extraShell else {
            return []
        }
        guard let getToolDownloadURL = injectConfiguration.generateInjectToolDownloadURL(name: extraShell) else {
            return [("echo Tool Download URL Not Found && exit 1", true)]
        }
        guard let downloadIntoTmpPath = try? FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: URL(fileURLWithPath: "/"), create: true) else {
            return [("echo Download Path Not Found && exit 1", true)]
        }
        // extraShell 有可能是 Setapp/setapp.sh，这种情况下会导致下载的文件名有问题，所以需要处理一下，模仿它建立一个文件夹吧，比如 Setapp/setapp.sh -> Create Setapp Directory -> Setapp.sh
        let extraShellComponents = extraShell.split(separator: "/")
        if extraShellComponents.count > 1 {
            let extraShellDir = downloadIntoTmpPath.appendingPathComponent(String(extraShellComponents[0]))
            try? FileManager.default.createDirectory(at: extraShellDir, withIntermediateDirectories: true, attributes: nil)
        }
        let downloadPath = downloadIntoTmpPath.appendingPathComponent(extraShell).path
//        let downloadCommand = "curl -L -o \(downloadPath) \(getToolDownloadURL)"
        // 创建信号量，等待下载完成

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.downloadTask(with: getToolDownloadURL) { (location, response, error) in
            if let location = location {
                try? FileManager.default.moveItem(at: location, to: URL(fileURLWithPath: downloadPath))
                print("[*] Download Extra Shell Success: \(getToolDownloadURL)")
            } else {
                print("[*] Download Extra Shell Failed: \(getToolDownloadURL)")
                shells.append(("echo Download Extra Shell Failed: \(getToolDownloadURL) && exit 1", false))
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        let dest = self.genSourcePath(for: .bash)

        // MARK: - Sub: 对某些 shell 脚本进行内容替换

        var replaceSpecialShell: [(String, String)] = [] // (from, to)

        // tool/optool
        let optoolPath = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "optool")?.pathWithFallback())
        replaceSpecialShell.append(("tool/optool", optoolPath))
        replaceSpecialShell.append(("./tool/optool", optoolPath))

        // tool/insert_dylib
        let insert_dylibPath = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "insert_dylib")?.pathWithFallback())
        replaceSpecialShell.append(("tool/insert_dylib", insert_dylibPath))
        replaceSpecialShell.append(("./tool/insert_dylib", insert_dylibPath))

        // tool/91QiuChenly.dylib
        let dylibPath = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "91Qiuchenly.dylib")?.pathWithFallback())
        replaceSpecialShell.append(("tool/91QiuChenly.dylib", dylibPath))
        replaceSpecialShell.append(("./tool/91QiuChenly.dylib", dylibPath))

        // tool/GenShineImpactStarter
        let genShineImpactStarterPath = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "GenShineImpactStarter")?.pathWithFallback())
        replaceSpecialShell.append(("tool/GenShineImpactStarter", genShineImpactStarterPath))
        replaceSpecialShell.append(("./tool/GenShineImpactStarter", genShineImpactStarterPath))

        // 把 [0] 替换为 [1] 的内容
        let replaceCommands = replaceSpecialShell.map { from, to in
            "sed -i '' 's|\(from)|\"\(to)\"|g' \(downloadPath)"
        }

        // shells.append((downloadCommand, false))
        shells.append(("sudo chmod -R 777 \(downloadPath)", true))
        shells.append(("chmod +x \(downloadPath)", true))
        if !replaceCommands.isEmpty {
            shells.append(contentsOf: replaceCommands.map { ($0, false) })
        }
        shells.append(("sudo sh \(downloadPath)", true))
        shells.append(("sudo xattr -cr \(dest)", true))
        return shells
    }

    // MARK: - 注入原神之 AutoHandleHelper

    func handleAutoHandleHelperCommands() -> [(command: String, isAdmin: Bool)] {
        var shells: [(command: String, isAdmin: Bool)] = []
        let helperFile = self.injectDetail?.helperFile?.allStrings // [String]?
        let autoHandleHelper = self.injectDetail?.autoHandleHelper // Bool?
        if let helperFile, let autoHandleHelper {
            var helpers: [String] = []
            if autoHandleHelper {
                helpers = helperFile

                for helper in helpers {
                    let genShineImpactStarterURL = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "GenShineImpactStarter")?.pathWithFallback())
                    var targetHelper = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + helper
                    let bridgeFile = (self.appDetail?.path ?? "") + (self.getBridgeDir())
                    let insertDylibURL = self.genSourcePath(for: .bash, path: injectConfiguration.getInjecToolPath(name: "insert_dylib")?.pathWithFallback())
                    let helperName = targetHelper.split(separator: "/").last
                    let target = self.genSourcePath(for: .bash, path: "/Library/LaunchDaemons/\(helperName!).plist")

                    var srcInfo = [(self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + "/Contents/Info.plist"]
                    if let componentApps = self.injectDetail?.componentApp {
                        srcInfo.append(contentsOf: componentApps.map { (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "") + $0 + "/Contents/Info.plist" })
                    }

                    guard FileManager.default.fileExists(atPath: targetHelper) else {
                        return [("echo Helper file not found: \(targetHelper) && exit 1", true)]
                    }

                    targetHelper = self.genSourcePath(for: .bash, path: targetHelper)

                    let genShineInjectCommand = "\(genShineImpactStarterURL) '\(targetHelper)' \(self.injectDetail?.smExtra ?? "")"
                    let insertDylibCommand = "\(insertDylibURL) '\(bridgeFile)91QiuChenly.dylib' '\(targetHelper)' '\(targetHelper)'"
                    let unloadLaunchctlCommand = ("sudo /bin/launchctl unload \(target)", true)
                    let killAllCommand = ("sudo /usr/bin/killall -u root -9 \(helperName!)", true)
                    let rmCommand = ("sudo /bin/rm \(target)", true)
                    let rmPrivilegedHelper = "sudo /bin/rm /Library/PrivilegedHelperTools/\(helperName!)"
                    let xattrCommand = "sudo xattr -c '\((self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: ""))'"

                    let codeSignHelperCommand = "/usr/bin/codesign -f -s - --all-architectures --deep '\(targetHelper)'"
                    let codeSignAppCommand = "/usr/bin/codesign -f -s - --all-architectures --deep '\((self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: ""))'"

                    shells.append((genShineInjectCommand, false))
                    shells.append((insertDylibCommand, false))
                    if FileManager.default.fileExists(atPath: target) {
                        shells.append(unloadLaunchctlCommand)
                        let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: helperName!.description).count > 0
                        if isRunning {
                            shells.append(killAllCommand)
                        }
                        shells.append(rmCommand)
                        shells.append((rmPrivilegedHelper, true))
                    }
                    shells.append((xattrCommand, true))
                    srcInfo.forEach { shells.append(("/usr/libexec/PlistBuddy -c 'Set :SMPrivilegedExecutables:\(helperName!) identifier \\\"\(helperName!)\\\"' \($0)", true)) }
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
        if let tccutil {
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
