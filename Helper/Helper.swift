//
//  Helper.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//

import Foundation

// MARK: - Helper

final class Helper: NSObject {
    let listener: NSXPCListener
    
    override init() {
        listener = NSXPCListener(machServiceName: HelperConstants.domain)
        super.init()
        listener.delegate = self
    }
}


extension Helper: HelperProtocol {

    func executeScript(at path: String) async throws -> String {
        NSLog("Executing script at \(path)")
        do {
            return try await ExecutionService.executeScript(at: path)
        } catch {
            NSLog("Error: \(error.localizedDescription)")
            throw error
        }
    }
}

extension Helper {
    func run() {
        listener.resume() // Start the XPC service
        RunLoop.current.run() // Run the XPC service
    }
}

extension Helper: NSXPCListenerDelegate {

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
//        FIX: Something went wrong here?

        do {
            try ConnectionIdentityService.checkConnectionIsValid(connection: newConnection)
        } catch {
            NSLog("🛑 Connection \(newConnection) has not been validated. \(error.localizedDescription)")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.remoteObjectInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        newConnection.exportedObject = self

        newConnection.resume()
        return true
    }
}
