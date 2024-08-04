//
//  Extension+Font.swift
//  InjectGUI
//
//  Created by wibus on 2024/8/4.
//

import Foundation
import SwiftUI

extension Text {
    func fontDesignAndWeight(font: Font.Design, weight: Font.Weight) -> Text {
        if #available(macOS 13.0, *) {
            return self
                .fontDesign(font)
                .fontWeight(weight)
        } else {
            return self
        }
    }
}
