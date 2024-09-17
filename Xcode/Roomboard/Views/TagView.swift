//
//  TagView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/23/22.
//

import UIKit

class TagView: UIView {
    
    var configuration: Configuration {
        didSet {
            apply(configuration)
        }
    }
    
    private var dotHeightConstraint: NSLayoutConstraint?
    
    private lazy var dot: UIView = {
        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        return dot
    }()
    
    private lazy var tagLabel: UILabel = {
        let tagLabel = UILabel()
        return tagLabel
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [dot, tagLabel])
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        return contentStack
    }()
    
    struct Configuration {
        var text = ""
        var tagSize = Size.regular
        var color: UIColor?
        var textColor = UIColor.label
        
        enum Size {
            case small
            case regular
        }
    }
    
    init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        sharedTagViewInitialization()
    }

    override init(frame: CGRect) {
        configuration = .init()
        super.init(frame: frame)
        sharedTagViewInitialization()
    }
    
    required init?(coder: NSCoder) {
        configuration = .init()
        super.init(coder: coder)
        sharedTagViewInitialization()
    }
    
    private func sharedTagViewInitialization() {
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
        ])
        let dotHeightConstraint = dot.heightAnchor.constraint(equalToConstant: 0.0)
        let dotWidthConstraint = dot.widthAnchor.constraint(equalTo: dot.heightAnchor)
        NSLayoutConstraint.activate([
            dotHeightConstraint,
            dotWidthConstraint
        ])
        self.dotHeightConstraint = dotHeightConstraint
        layer.cornerCurve = .continuous
        apply(configuration)
    }
    
    private func apply(_ configuration: Configuration) {
        if let color = configuration.color {
            dot.isHidden = false
            dot.backgroundColor = color
        } else {
            dot.isHidden = true
        }
        tagLabel.text = configuration.text
        tagLabel.textColor = configuration.textColor
        switch configuration.tagSize {
        case .small:
            dotHeightConstraint?.constant = 9.0
            dot.layer.cornerRadius = 4.5
            tagLabel.font = .preferredFont(forTextStyle: .caption1)
            contentStack.spacing = 5.0
            contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2.0, leading: 4.0, bottom: 2.0, trailing: 4.0)
            layer.cornerRadius = 4.0
        case .regular:
            dotHeightConstraint?.constant = 12.0
            dot.layer.cornerRadius = 6.0
            tagLabel.font = .preferredFont(forTextStyle: .body)
            contentStack.spacing = 10.0
            contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0)
            layer.cornerRadius = 8.0
        }
    }
    

}
