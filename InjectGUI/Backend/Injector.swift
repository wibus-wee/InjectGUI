//
//  Injector.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/30.
//

import Foundation
import Combine 

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

    @Published var shouldShowStatusSheet: Bool = false
    @Published var isRunning: Bool = false
    @Published var stage: InjectRunningStatus = .init(appId: "", appName: "", stages: [], message: "", progress: 0)

    init() {
        // For testing
        self.stage = InjectRunningStatus(
            appId: "pl.maketheweb.cleanshotx",
            appName: "CleanShot X",
            stages: [
                .init(stage: .start, message: InjectStage.start.description, progress: 1, status: .finished),
                .init(stage: .checkVersionIsSupported, message: InjectStage.checkVersionIsSupported.description, progress: 1, error: .init(error: "Version is not supported", stage: .checkVersionIsSupported), status: .error),
                .init(stage: .handleKeygen, message: InjectStage.handleKeygen.description, progress: 1, status: .finished),
                .init(stage: .handleDeepCodeSign, message: InjectStage.handleDeepCodeSign.description, progress: 0.6, status: .running),
            ],
            message: "Injecting",
            progress: 0.6
        )
    }

    func handleInjectApp() {

    }

    func startInjectApp(package: String) {
        if self.isRunning {
            return
        }
        guard let appDetail = softwareManager.appListCache[package] else {
            return
        }
        self.shouldShowStatusSheet = true
        self.stage = .init(
            appId: appDetail.identifier, 
            appName: appDetail.name, 
            stages: [], 
            message: "Injecting",
            progress: 0
        )
        self.isRunning = true
    }

    func updateInjectStage(stage: InjectStage, message: String, progress: Double, status: InjectStatus, error: InjectRunningError? = nil) {
        guard self.isRunning else {
            return
        }
        self.stage.stages.append(
            .init(
                stage: stage,
                message: message,
                progress: progress,
                error: error,
                status: status
            )
        )
        self.stage.progress = progress
    }

    func stopInjectApp() {
        self.stage = .init(appId: "", appName: "", stages: [], message: "", progress: 0)
        self.isRunning = false
    }
}
