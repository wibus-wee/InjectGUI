//
//  Injector.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/30.
//

import Foundation
import Combine
import SwiftUI

enum InjectStatus {
    case none
    case running
    case finished
    case error
}

enum InjectStage {
    case start
    case checkVersionIsSupported
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
    static var allCases: [InjectStage] {
        return [.start, .checkVersionIsSupported, .handleKeygen, .handleDeepCodeSign, .handleAutoHandleHelper, .handleSubApps, .handleTccutil, .handleExtraShell, .handleInjectLibInject, .end]
    }

    var description: String {
        switch self {
        case .start:
            return "Start Injecting"
        case .checkVersionIsSupported:
            return "Checking Version is supported"
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
    
    private let executor = Executor()

    @Published var shouldShowStatusSheet: Bool = false
    @Published var isRunning: Bool = false
    @Published var stage: InjectRunningStatus = .init(appId: "", appName: "", stages: [], message: "", progress: 0)
    @State var injectDetail: AppList? = nil
    @State var emegencyStop: Bool = false

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
        self.executeNextStep(steps: [
            self.handleKeygen,
            self.handleDeepCodeSign,
            self.handleAutoHandleHelper,
            self.handleSubApps,
            self.handleTccutil,
            self.handleExtraShell,
            self.handleInjectLibInject
        ])
    }

    func executeNextStep(steps: [() -> Void], index: Int = 0) {
        guard index < steps.count else {
            self.updateInjectStage(stage: .end, message: InjectStage.end.description, progress: 1, status: .finished)
            return
        }
        steps[index]()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.executeNextStep(steps: steps, index: index + 1)
        }
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
        // 算一下总进度
        self.stage.progress = self.stage.stages.reduce(0) { $0 + $1.progress } / Double(self.stage.stages.count)
    }

    func stopInjectApp() {
        self.stage = .init(appId: "", appName: "", stages: [], message: "", progress: 0)
        self.injectDetail = nil
        self.isRunning = false
        self.emegencyStop = true
    }

    // MARK: - 注入原神之检查注入工具还在不在
    func checkToolIsExistOrInstall() {
        
    }

    // MARK: - 注入原神之 Keygen
    func handleKeygen() {
        let stage = InjectStage.handleKeygen
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/keygen") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }

    // MARK: - 注入原神之 DeepCodeSign
    func handleDeepCodeSign() {
        let stage = InjectStage.handleDeepCodeSign
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/deepcodesign") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }

    // MARK: - 注入原神之 AutoHandleHelper
    func handleAutoHandleHelper() {
        let stage = InjectStage.handleAutoHandleHelper
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/autohandlehelper") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }

    // MARK: - 注入原神之 SubApps
    func handleSubApps() {
        let stage = InjectStage.handleSubApps
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/subapps") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }

    // MARK: - 注入原神之 Tccutil
    func handleTccutil() {
        let stage = InjectStage.handleTccutil
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/tccutil") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }

    // MARK: - 注入原神之 ExtraShell
    func handleExtraShell() {
        let stage = InjectStage.handleExtraShell
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/extrashell") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }

    // MARK: - 注入原神之 InjectLibInject
    func handleInjectLibInject() {
        let stage = InjectStage.handleInjectLibInject
        self.updateInjectStage(stage: stage, message: stage.description, progress: 0, status: .running)

        self.executor.executeBinary(at: "/path/to/injectlibinject") { [weak self] output, error in
            if let error = error {
                self?.updateInjectStage(stage: stage, message: error.localizedDescription, progress: 1, status: .error, error: InjectRunningError(error: error.localizedDescription, stage: stage))
            } else {
                self?.updateInjectStage(stage: stage, message: stage.description, progress: 1, status: .finished)
            }
        }
    }
}
