//
//  Executor.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/31.
//

import Combine
import Foundation

class Executor: ObservableObject {
    static let shared = Executor()
    
    @Published var password: String = ""
    @Published var output: String = ""
    @Published var isRunning: Bool = false

    private var taskQueue: [() -> Void] = []
    var cancellables = Set<AnyCancellable>()
    private var currentTask: Process?
    private let queue = DispatchQueue(label: "com.executor.taskQueue", attributes: .concurrent)

    // 执行单个命令
    func executeShellCommand(_ command: String) -> Future<String, Error> {
        Future { promise in
            self.runShellCommand(command)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { output in
                    promise(.success(output))
                })
                .store(in: &self.cancellables)
        }
    }

    // 执行多个命令
    func executeShellCommands(_ commands: [(command: String, isAdmin: Bool)]) -> Future<Void, Error> {
        Future { promise in
            self.executeCommandsSequentially(commands, promise: promise)
        }
    }

    private func executeCommandsSequentially(_ commands: [(command: String, isAdmin: Bool)], promise: @escaping (Result<Void, Error>) -> Void) {
        guard !commands.isEmpty else {
            promise(.success(()))
            return
        }

        var remainingCommands = commands
        let (command, isAdmin) = remainingCommands.removeFirst()

        let executeCommand: Future<String, Error> = isAdmin ? self.executeAdminCommand(command) : self.executeShellCommand(command)

        executeCommand
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    promise(.failure(error))
                } else {
                    self.executeCommandsSequentially(remainingCommands, promise: promise)
                }
            }, receiveValue: { _ in })
            .store(in: &self.cancellables)
    }

    // 执行单个需要管理员权限的命令
    func executeAdminCommand(_ command: String) -> Future<String, Error> {
        Future { promise in
            self.runAdminCommand(command)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { output in
                    promise(.success(output))
                })
                .store(in: &self.cancellables)
        }
    }

    private func runShellCommand(_ command: String) -> Future<String, Error> {
        Future { promise in
            self.currentTask = Process()
            guard let task = self.currentTask else { return }

            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", command]
            // task.arguments = ["-c", "echo 123"]
            #if DEBUG
            print("command: \(command)")
            #endif

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            task.terminationHandler = { _ in
                DispatchQueue.main.async {
                    self.isRunning = false
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        promise(.success(output))
                    } else {
                        promise(.failure(NSError(domain: "Executor", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法读取命令输出"])))
                    }
                }
            }

            do {
                try task.run()
                self.isRunning = true
            } catch {
                promise(.failure(error))
            }
        }
    }

    /// 执行需要管理员权限的命令 - 使用 AppleScript
    /// TIPS: 命令可能是有一个 Application\ Support 的，这个地方需要转义：Application\\ Support
    /// 这里懒的搞了，我只想让它能跑起来，麻烦传过来的时候就转义好了。
    /// 否则会爆：NSAppleScriptErrorMessage = Expected \U201c\"\U201d but found unknown token.
    private func runAdminCommand(_ command: String) -> Future<String, Error> {
        Future { promise in
            let username = NSFullUserName()
            let appleScript = """
            do shell script "\(command)" user name "\(username)" password "\(self.password)" with administrator privileges
            """
            // let appleScript = """
            // do shell script "echo testAppleScript" user name "\(username)" password "\(self.password)" with administrator privileges
            // """
            #if DEBUG
            print("Admin Command: \(command)")
            print("Admin AppleScript: \(appleScript)")
            #endif

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let output = scriptObject.executeAndReturnError(&error)
                if let error = error {
                    print("AppleScript Error: \(error)")
                    promise(.failure(NSError(domain: "Executor", code: 2, userInfo: [NSLocalizedDescriptionKey: "\(error)"])))
                } else {
                    promise(.success(output.stringValue ?? ""))
                }
            } else {
                promise(.failure(NSError(domain: "Executor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Can't create NSAppleScript object"])))
            }
        }
    }
}
