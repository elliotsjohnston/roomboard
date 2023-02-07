//
//  Defaults.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/8/22.
//

import Foundation

enum Defaults {
    static var finishedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "com.roomboard.finished-onboarding")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "com.roomboard.finished-onboarding")
        }
    }
    
    static var installedDefaultTags: Bool {
        get {
            UserDefaults.standard.bool(forKey: "com.roomboard.installed-default-tags")
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "com.roomboard.installed-default-tags")
        }
    }
}
