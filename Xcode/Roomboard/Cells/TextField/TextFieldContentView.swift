//
//  TextFieldContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/19/22.
//

import UIKit

class TextFieldContentView: UIView, UIContentView, UITextFieldDelegate {
    
    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? TextFieldContentConfiguration else { return }
            apply(configuration)
        }
    }
    
    private var prependedText = ""
    
    private var textTransformer: ((String) -> String)?
    
    private var textUpdateHandler: ((String) -> Void)?
    
    private var textFieldSelectionHandler: (() -> Void)?
    
    private var textFieldDismissHandler: (() -> Void)?

    private lazy var listContent: UIListContentView = {
        let config = UIListContentConfiguration.cell()
        let listContent = UIListContentView(configuration: config)
        listContent.setContentHuggingPriority(.required, for: .horizontal)
        return listContent
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .right
        textField.returnKeyType = .done
        textField.delegate = self
        return textField
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [listContent, textField])
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins.leading = 4.0
        contentStack.directionalLayoutMargins.trailing = 16.0
        contentStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return contentStack
    }()
    
    init(configuration: TextFieldContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        sharedTextFieldContentViewInitialization()
        apply(configuration)
    }
    
    required init?(coder: NSCoder) {
        let config = TextFieldContentConfiguration()
        self.configuration = config
        super.init(coder: coder)
        sharedTextFieldContentViewInitialization()
        apply(config)
    }
    
    private func sharedTextFieldContentViewInitialization() {
        addSubview(contentStack)
        
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }
    
    private func apply(_ configuration: TextFieldContentConfiguration) {
        var config = UIListContentConfiguration.cell()
        config.text = configuration.title
        listContent.configuration = config
        if configuration.title.isEmpty {
            listContent.isHidden = true
            contentStack.directionalLayoutMargins.leading = 16.0
        } else {
            listContent.isHidden = false
            contentStack.directionalLayoutMargins.leading = 4.0
        }
        textField.text = configuration.text
        /*
        switch (configuration.textAlignment, textField.textAlignment) {
        case (.left, .left):
            break
        case (.left, _):
            contentStack.subviews.forEach {
                contentStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            contentStack.addArrangedSubview(textField)
            contentStack.addArrangedSubview(listContent)
        case (_, .left):
            contentStack.subviews.forEach {
                contentStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            contentStack.addArrangedSubview(listContent)
            contentStack.addArrangedSubview(textField)
        default:
            break
        }
        */
        textField.textAlignment = configuration.textAlignment
        textField.placeholder = configuration.placeholderText
        textField.font = configuration.font
        textField.autocapitalizationType = configuration.autocapitalizationType
        textField.keyboardType = configuration.keyboardType
        
        if configuration.isEditing {
            textField.becomeFirstResponder()
        }
        self.prependedText = configuration.prependedText
        self.textTransformer = configuration.textTransformer
        self.textUpdateHandler = configuration.textUpdateHandler
        self.textFieldSelectionHandler = configuration.textFieldSelectionHandler
        self.textFieldDismissHandler = configuration.textFieldDismissHandler
    }
    
    @objc
    private func editingChanged(_ sender: UITextField) {
        if let textTransformer, let text = sender.text {
            sender.text = textTransformer(text)
        }
        
        if !prependedText.isEmpty, let text = sender.text {
            if text == prependedText {
                sender.text = ""
            } else if !text.starts(with: prependedText) {
                sender.text = prependedText.appending(text)
            }
        }
        
        /*
        if let text = sender.text {
            if text.starts(with: prependedText) {
                textUpdateHandler?(String(text.dropFirst(prependedText.count)))
            } else {
                textUpdateHandler?(text)
            }
        }
        */
        
        if let text = sender.text {
            textUpdateHandler?(text)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldSelectionHandler?()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldDismissHandler?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
