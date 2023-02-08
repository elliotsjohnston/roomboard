//
//  Defaults.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/8/22.
//

import Foundation
import UIKit

enum Appearance: String, CaseIterable {
    case system
    case light
    case dark
    
    var description: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension UserDefaults {
    @objc dynamic var finishedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "com.roomboard.finished-onboarding")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "com.roomboard.finished-onboarding")
        }
    }
    
    @objc dynamic var installedDefaultTags: Bool {
        get {
            UserDefaults.standard.bool(forKey: "com.roomboard.installed-default-tags")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "com.roomboard.installed-default-tags")
        }
    }
    
    @objc dynamic var selectedAppearanceString: String? {
        get {
            UserDefaults.standard.string(forKey: "com.roomboard.selected-appearance")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "com.roomboard.selected-appearance")
        }
    }
    
    var selectedAppearance: Appearance {
        get {
            if let selectedAppearanceString {
                return Appearance(rawValue: selectedAppearanceString) ?? .system
            } else {
                return .system
            }
        }
        
        set {
            selectedAppearanceString = newValue.rawValue
        }
    }
}
