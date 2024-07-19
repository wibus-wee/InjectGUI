//
//  Configuration.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/19.
//

import Foundation
import Combine


class Configuration: NSObject, ObservableObject {
    static let shared = Configuration()
    var cancellable: Set<AnyCancellable> = .init()
    
    override private init() {
        super.init()
        print("[I] Configuration inited.")
        objectWillChange
            .sink { _ in
                self.save()
            }
            .store(in: &cancellable)
    }
    
    @PublishedStorage(key: "\(Constants.appKey).remoteGit", defaultValue: "https://github.com/QiuChenly/InjectLib")
    var remoteGit: String
    
    @PublishedStorage(key: "\(Constants.appKey).remoteGitCommit", defaultValue: nil)
    var remoteGitCommit: String?
    
    @PublishedStorage(key: "\(Constants.appKey).remoteGitBranch", defaultValue: nil)
    var remoteGitBranch: String?
    
    
    
    public func save() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(saveNow), object: nil)
        perform(#selector(saveNow), with: nil, afterDelay: 1)
    }

    @objc func saveNow() {
        DispatchQueue.global().async {
            
        }
    }
}
