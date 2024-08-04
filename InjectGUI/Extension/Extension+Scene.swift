//
//  Extension+Scene.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/4.
//

import Foundation
import SwiftUI

extension Scene {
    func contentSizedWindowResizability() -> some Scene {
        if #available(macOS 13.0, *) {
            return self.windowResizability(.contentSize)
        } else {
            return self
        }
    }
}
