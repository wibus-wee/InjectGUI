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
    case handleSubApps
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
        case .handleSubApps:
            return "Handling Sub Apps"
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
        case .handleKeygen:
            return handleKeygenCommands()
        case .handleDeepCodeSign:
            return handleDeepCodeSignCommands()
        case .handleAutoHandleHelper:
            return handleAutoHandleHelperCommands()
        case .handleSubApps:
            return handleSubAppsCommands()
        case .handleTccutil:
            return handleTccutilCommands()
        case .handleExtraShell:
            return handleExtraShellCommands()
        case .handleInjectLibInject:
            return handleInjectLibInjectAdminCommands()
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
        return [("cp \(source) \(destination)", true)]
    }

    // MARK: - 注入原神之 权限与运行检查
    func checkPermissionAndRunCommands() -> [(command: String, isAdmin: Bool)] {
        let bridgeDir = self.injectDetail?.bridgeFile?.replacingOccurrences(of: "/Contents", with: "") ?? "/MacOS"
        let source = self.appDetail?.path ?? "" + bridgeDir + (self.injectDetail?.bridgeFile ?? "")
        let appBaseLocate = (self.appDetail?.path ?? "").replacingOccurrences(of: "/Contents", with: "")
        return [
            ("sudo chmod -R 777 \(appBaseLocate)", true),
            ("sudo xattr -cr \(appBaseLocate)", true),
            ("sudo pkill -f \(source)", true)
        ]
    }

    // MARK: - 注入原神之 Keygen

    func handleKeygenCommands() -> [(command: String, isAdmin: Bool)] {
        return [("echo 'Keygen not needed'", false)]
    }

    // MARK: - 注入原神之 DeepCodeSign

    func handleDeepCodeSignCommands() -> [(command: String, isAdmin: Bool)] {
        // Add actual deep code sign commands here
        return []
    }

    // MARK: - 注入原神之 AutoHandleHelper

    func handleAutoHandleHelperCommands() -> [(command: String, isAdmin: Bool)] {
        // Add actual auto handle helper commands here
        return []
    }

    // MARK: - 注入原神之 SubApps

    func handleSubAppsCommands() -> [(command: String, isAdmin: Bool)] {
        // Add actual sub apps handling commands here
        return []
    }

    // MARK: - 注入原神之 Tccutil

    func handleTccutilCommands() -> [(command: String, isAdmin: Bool)] {
        // Add actual tccutil commands here
        return []
    }

    // MARK: - 注入原神之 ExtraShell

    func handleExtraShellCommands() -> [(command: String, isAdmin: Bool)] {
        // Add actual extra shell commands here
        return []
    }

    // MARK: - 注入原神之 InjectLibInject

    func handleInjectLibInjectAdminCommands() -> [(command: String, isAdmin: Bool)] {
        return [("injectlib <your_inject_lib_parameters>", true)]
    }
}
