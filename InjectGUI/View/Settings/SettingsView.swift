//
//  SettingsView.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/20.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
        case about
    }

    var body: some View {
        return TabView {
            GeneralView().tag(Tabs.general)
            AboutView().tag(Tabs.about)
        }

        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
