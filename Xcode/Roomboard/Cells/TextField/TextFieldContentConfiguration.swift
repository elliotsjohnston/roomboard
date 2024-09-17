//
//  TextFieldContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/19/22.
//

import UIKit

struct TextFieldContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return TextFieldContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> TextFieldContentConfiguration {
        guard let state = state as? UICellConfigurationState else {
            return self
        }
        
        var updatedConfiguration = self
        if state.isSelected {
            updatedConfiguration.isEditing = true
        }
        return updatedConfiguration
    }
    
    var isEditing = false
    var title = ""
    var text = ""
    var textAlignment = NSTextAlignment.right
    var placeholderText = ""
    var prependedText = ""
    var font = UIFont.preferredFont(forTextStyle: .body)
    var autocapitalizationType = UITextAutocapitalizationType.sentences
    var keyboardType = UIKeyboardType.default
    var textTransformer: ((String) -> String)?
    var textUpdateHandler: ((String) -> Void)?
    var textFieldSelectionHandler: (() -> Void)?
    var textFieldDismissHandler: (() -> Void)?
}
