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
            bool(forKey: "com.roomboard.finished-onboarding")
        }
        
        set {
            set(newValue, forKey: "com.roomboard.finished-onboarding")
        }
    }
    
    @objc dynamic var installedDefaultTags: Bool {
        get {
            bool(forKey: "com.roomboard.installed-default-tags")
        }
        
        set {
            set(newValue, forKey: "com.roomboard.installed-default-tags")
        }
    }
    
    @objc dynamic var selectedAppearanceString: String? {
        get {
            string(forKey: "com.roomboard.selected-appearance")
        }
        
        set {
            set(newValue, forKey: "com.roomboard.selected-appearance")
        }
    }
    
    @objc dynamic var preserveFilters: Bool {
        get {
            bool(forKey: "com.roomboard.preserve-filters")
        }
        
        set {
            set(newValue, forKey: "com.roomboard.preserve-filters")
        }
    }
    
    var savedSearchProperties: [InventoryViewController.SearchProperty] {
        get {
            guard let searchPropertiesStringArray = stringArray(forKey: "com.roomboard.saved-search-properties") else { return [.title] }
            let searchProperties = searchPropertiesStringArray.compactMap { InventoryViewController.SearchProperty(rawValue: $0) }
            return searchProperties.isEmpty ? [.title] : searchProperties
        }
        
        set {
            set(newValue.map(\.rawValue), forKey: "com.roomboard.saved-search-properties")
        }
    }
    
    var savedValueFilters: [InventoryViewController.ValueFilter] {
        get {
            guard let valueFiltersStringArray = stringArray(forKey: "com.roomboard.saved-value-filters") else { return [] }
            return valueFiltersStringArray.compactMap { InventoryViewController.ValueFilter(rawValue: $0) }
        }
        
        set {
            set(newValue.map(\.rawValue), forKey: "com.roomboard.saved-value-filters")
        }
    }
    
    var savedSortMode: InventoryViewController.SortMode {
        get {
            guard let sortModeString = string(forKey: "com.roomboard.saved-sort-mode") else { return .title }
            guard let sortMode = InventoryViewController.SortMode(rawValue: sortModeString) else { return .title }
            return sortMode
        }
        
        set {
            set(newValue.rawValue, forKey: "com.roomboard.saved-sort-mode")
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
