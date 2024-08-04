//
//  Extension+URL.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/4.
//

import Foundation

extension URL {
    func pathWithFallback(percentEncoded: Bool = true) -> String {
        if #available(macOS 13.0, *) {
            return self.path(percentEncoded: percentEncoded)
        } else {
            return self.path
        }
    }
}
