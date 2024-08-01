//
//  Executor.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/31.
//

import Combine
import Foundation
import SwiftUI

// 一个支持立即终止的命令执行器，同时有错误兜底机制，可以在执行过程中随时终止
// 同时还有队列机制，可以保证任务按照顺序执行，在任务执行过程中，可以随时取消
// 支持通过输入 shell 命令来执行二进制文件，并获取输出
// 同时还支持通过一个弹窗来获取用户输入的管理员密码，以此来使用管理员权限执行 shell 命令，同时将密码加密储存在一个重启后会被清空的 tmp 目录
class Executor: ObservableObject {
    @Published var output: String = ""  // 用于存储命令的输出
    @Published var isRunning: Bool = false  // 标志是否有任务在运行
    
    private var taskQueue: [() -> Void] = []  // 任务队列
    var cancellables = Set<AnyCancellable>()  // 用于管理异步任务的取消
    private var currentTask: Process?  // 当前正在执行的任务
    
    /// 执行 shell 命令
    func executeShellCommand(_ command: String) {
        let task = {
            self.runShellCommand(command)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.handle(error)
                    }
                }, receiveValue: { output in
                    self.output += output
                })
                .store(in: &self.cancellables)
        }
        addTaskToQueue(task)
    }
    
    /// 使用 AppleScript 执行具有管理员权限的命令
    func executeAdminCommand(_ command: String) {
        let task = {
            self.runAdminCommand(command)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.handle(error)
                    }
                }, receiveValue: { output in
                    self.output += output
                })
                .store(in: &self.cancellables)
        }
        addTaskToQueue(task)
    }
    
    /// 终止当前正在执行的任务
    func terminateCurrentTask() {
        currentTask?.terminate()
        isRunning = false
    }
    
    // MARK: - Private methods
    
    /// 将任务添加到队列中
    private func addTaskToQueue(_ task: @escaping () -> Void) {
        taskQueue.append(task)
        if !isRunning {
            runNextTask()
        }
    }
    
    /// 执行队列中的下一个任务
    private func runNextTask() {
        guard !taskQueue.isEmpty else { return }
        isRunning = true
        let nextTask = taskQueue.removeFirst()
        nextTask()
    }
    
    /// 执行 shell 命令
    private func runShellCommand(_ command: String) -> Future<String, Error> {
        Future { promise in
            self.currentTask = Process()
            guard let task = self.currentTask else { return }
            
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", command]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.terminationHandler = { _ in
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.runNextTask()  // 继续执行队列中的下一个任务
                }
            }
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    promise(.success(output))
                } else {
                    promise(.failure(NSError(domain: "Executor", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法读取命令输出"])))
                }
            } catch {
                promise(.failure(error))
            }
        }
    }
    
    /// 使用 AppleScript 执行具有管理员权限的命令
    func runAdminCommand(_ command: String) -> Future<String, Error> {
        Future { promise in
            let appleScript = """
            do shell script "\(command)" with administrator privileges
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let output = scriptObject.executeAndReturnError(&error)
                if let error = error {
                    promise(.failure(NSError(domain: "Executor", code: 2, userInfo: [NSLocalizedDescriptionKey: "AppleScript 执行错误: \(error)"])))
                } else {
                    promise(.success(output.stringValue ?? ""))
                }
            } else {
                promise(.failure(NSError(domain: "Executor", code: 3, userInfo: [NSLocalizedDescriptionKey: "无法创建 AppleScript 脚本"])))
            }
        }
    }
    
    /// 错误处理
    private func handle(_ error: Error) {
        DispatchQueue.main.async {
            self.output += "\n错误: \(error.localizedDescription)"
            self.isRunning = false
            self.runNextTask()  // 继续执行队列中的下一个任务
        }
    }
}
