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
class Executor: ObservableObject {
    // 使用 Combine 来处理异步任务的取消
    private var cancellable: AnyCancellable?
    
    // 发布执行状态和错误信息
    @Published var isExecuting: Bool = false
    @Published var output: String = ""
    @Published var errorMessage: String? = nil
    
    // 执行命令的方法
    func execute(command: @escaping () -> Void) {
        // 如果已经在执行，则不进行新的任务
        guard !isExecuting else { return }
        
        // 标记开始执行
        isExecuting = true
        errorMessage = nil
        
        // 创建一个任务，可以随时取消
        let subject = PassthroughSubject<Void, Never>()
        
        cancellable = subject
            .handleEvents(receiveCancel: { [weak self] in
                // 标记任务取消
                self?.isExecuting = false
            })
            .sink { [weak self] in
                // 执行命令
                command()
                // 标记任务完成
                self?.isExecuting = false
            }
        
        // 发送事件以启动任务
        subject.send()
    }
    
    // 终止执行中的命令
    func cancel() {
        cancellable?.cancel()
    }
    
    // 执行二进制文件的方法
    func executeBinary(at path: String, arguments: [String] = [], completion: @escaping (String?, Error?) -> Void) {
        execute {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            process.terminationHandler = { _ in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let outputString = String(data: outputData, encoding: .utf8)
                let errorString = String(data: errorData, encoding: .utf8)
                
                DispatchQueue.main.async {
                    if let errorString = errorString, !errorString.isEmpty {
                        completion(outputString, NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: errorString]))
                    } else {
                        completion(outputString, nil)
                    }
                    self.isExecuting = false
                }
            }
            
            do {
                try process.run()
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                    self.isExecuting = false
                }
            }
        }
    }
}
