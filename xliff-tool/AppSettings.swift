//
//  AppSettings.swift
//  XLIFFTool
//
//  Created by Remus Lazar on 17.11.18.
//  Copyright © 2018 Remus Lazar. All rights reserved.
//

import Foundation

class AppSettings {
    
    private struct Keys {
        static let defaultFontSize = "defaultFontSize"
        static let adjustFontSizeFactor = "adjustFontSizeFactor"
        static let minFontScale = "minFontScale"
        static let maxFontScale = "maxFontScale"
    }
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.adjustFontSizeFactor: 1.15,
            Keys.defaultFontSize: 12.0,
            Keys.minFontScale: 0.5,
            Keys.maxFontScale: 2.0,
            ])
    }
    
    static var defaultFontSize: CGFloat {
        return CGFloat(UserDefaults.standard.double(forKey: Keys.defaultFontSize))
    }

    static var adjustFontSizeFactor: CGFloat {
        return CGFloat(UserDefaults.standard.double(forKey: Keys.adjustFontSizeFactor))
    }

    static var minFontScale: CGFloat {
        return CGFloat(UserDefaults.standard.double(forKey: Keys.minFontScale))
    }

    static var maxFontScale: CGFloat {
        return CGFloat(UserDefaults.standard.double(forKey: Keys.maxFontScale))
    }

}
