//
//  HelperRemoteProvider.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/6.
//


import Foundation
import ServiceManagement

// MARK: - HelperRemoteProvider

/// Provide a `HelperProtocol` object to request the helper.
enum HelperRemoteProvider {

    // MARK: Computed

    private static var isHelperInstalled: Bool { FileManager.default.fileExists(atPath: HelperConstants.helperPath) }
}

// MARK: - Remote

extension HelperRemoteProvider {

    static func remote() async throws -> some HelperProtocol {
        let connection = try connection()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<any HelperProtocol, Error>) in let continuationResume = ContinuationResume()
            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                // an error arrived
                guard continuationResume.shouldResume() else { return }
                // 1st error to arrive, it will be the one thrown
                continuation.resume(throwing: error)
            }

            if let unwrappedHelper = helper as? HelperProtocol {
                guard continuationResume.shouldResume() else {
                  // an error occurred even though the helper was retrieved
                  return
                }
                continuation.resume(returning: unwrappedHelper)
            } else {
                if continuationResume.shouldResume() {
                    // 1st error to arrive, it will be the one thrown
                    let error = InjectError.helperConnection("Unable to get a valid 'HelperProtocol' object for an unknown reason")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Install helper

extension HelperRemoteProvider {

    /// Install the Helper in the privileged helper tools folder and load the daemon
    private static func installHelper() throws {

        // try to get a valid empty authorization
        var authRef: AuthorizationRef?
        try AuthorizationCreate(nil, nil, [.preAuthorize], &authRef).checkError("AuthorizationCreate")
        defer {
            if let authRef {
                AuthorizationFree(authRef, [])
            }
        }

        // create an AuthorizationItem to specify we want to bless a privileged Helper
        let authStatus = kSMRightBlessPrivilegedHelper.withCString { authorizationString in
            var authItem = AuthorizationItem(name: authorizationString, valueLength: 0, value: nil, flags: 0)

            return withUnsafeMutablePointer(to: &authItem) { pointer in
                var authRights = AuthorizationRights(count: 1, items: pointer)
                let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
                return AuthorizationCreate(&authRights, nil, flags, &authRef)
            }
        }

        guard authStatus == errAuthorizationSuccess else {
           throw InjectError.helperInstallation("Unable to get a valid loading authorization reference to load Helper daemon")
        }

        var blessErrorPointer: Unmanaged<CFError>?
        let wasBlessed = SMJobBless(kSMDomainSystemLaunchd, HelperConstants.domain as CFString, authRef, &blessErrorPointer)

        guard !wasBlessed else { return }
        // throw error since authorization was not blessed
//        let blessError: Error ==  if let blessErrorPointer {
//            blessErrorPointer.takeRetainedValue() as Error
//        } else {
//            InjectError.unknown
//        }
        let blessError = blessErrorPointer?.takeRetainedValue() as Error? ?? InjectError.unknown
        
        throw InjectError.helperInstallation("Error while installing the Helper: \(blessError.localizedDescription)")
    }
}

// MARK: - Connection

extension HelperRemoteProvider {

    static private func connection() throws -> NSXPCConnection {
        if !isHelperInstalled {
            try installHelper()
        }
        return createConnection()
    }

    private static func createConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(machServiceName: HelperConstants.domain, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        connection.exportedObject = self

        connection.invalidationHandler = {
            if isHelperInstalled {
                print("Unable to connect to Helper although it is installed")
            } else {
                print("Helper is not installed")
            }
        }

        connection.resume()

        return connection
    }
}

// MARK: - ContinuationResume

extension HelperRemoteProvider {

    /// Helper class to safely access a boolean when using a continuation to get the remote.
    private final class ContinuationResume: @unchecked Sendable {

        // MARK: Properties

        private let unfairLockPointer: UnsafeMutablePointer<os_unfair_lock_s>
        private var alreadyResumed = false

        // MARK: Computed

        /// `true` if the continuation should resume.
        func shouldResume() -> Bool {
            os_unfair_lock_lock(unfairLockPointer)
            defer { os_unfair_lock_unlock(unfairLockPointer) }

            if alreadyResumed {
                return false
            } else {
                alreadyResumed = true
                return true
            }
        }

        // MARK: Init

        init() {
            unfairLockPointer = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
            unfairLockPointer.initialize(to: os_unfair_lock())
        }

        deinit {
            unfairLockPointer.deallocate()
        }
    }
}
