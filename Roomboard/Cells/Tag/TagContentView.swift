//
//  TagContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/3/23.
//

import UIKit

class TagContentView: UIView, UIContentView, UITextFieldDelegate {

    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? TagContentConfiguration else { return }
            apply(configuration)
        }
    }
    
    private var textUpdateHandler: ((String) -> Void)?
    
    var leadingTextAnchor: NSLayoutXAxisAnchor {
        tagField.leadingAnchor
    }
    
    private lazy var tagIcon: UIImageView = {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 12.0)
        let tagImage = UIImage(systemName: "circle.fill", withConfiguration: imageConfig)
        let tagIcon = UIImageView(image: tagImage)
        return tagIcon
    }()
    
    private lazy var tagField: UITextField = {
        let tagField = UITextField()
        tagField.returnKeyType = .done
        tagField.delegate = self
        return tagField
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [tagIcon, tagField])
        contentStack.alignment = .center
        contentStack.axis = .horizontal
        contentStack.spacing = 11.0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        return contentStack
    }()
    
    init(_ configuration: TagContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        
        sharedTagContentViewInitialization()
        apply(configuration)
    }
    
    required init?(coder: NSCoder) {
        let configuration = TagContentConfiguration()
        self.configuration = configuration
        
        super.init(coder: coder)
        
        sharedTagContentViewInitialization()
        apply(configuration)
    }
    
    private func sharedTagContentViewInitialization() {
        addSubview(contentStack)
        
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0.0, leading: 17.0, bottom: 0.0, trailing: 0.0)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44.0),
            contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        
        tagField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }
    
    @objc
    private func editingChanged(_ sender: UITextField) {
        if let text = sender.text {
            textUpdateHandler?(text)
        }
    }
    
    private func apply(_ configuration: TagContentConfiguration) {
        tagIcon.tintColor = configuration.tag?.color
        tagField.text = configuration.tag?.text
        tagField.isEnabled = configuration.isEditable
        textUpdateHandler = configuration.textUpdateHandler
    }

}
