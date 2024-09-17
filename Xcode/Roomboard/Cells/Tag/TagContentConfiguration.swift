//
//  TagContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/3/23.
//

import UIKit

struct TagContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return TagContentView(self)
    }
    
    func updated(for state: UIConfigurationState) -> TagContentConfiguration {
        return self
    }
    
    var tag: Tag?
    var isEditable = false
    var isEditing = false
    var textUpdateHandler: ((String) -> Void)?
    var textFieldSelectionHandler: (() -> Void)?
    var textFieldDismissHandler: (() -> Void)?
}
