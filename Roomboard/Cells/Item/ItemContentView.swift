//
//  ItemCellContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/1/23.
//

import UIKit

class ItemContentView: UIView, UIContentView {
    
    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? ItemContentConfiguration else { return }
            apply(configuration, oldConfiguration: oldValue as? ItemContentConfiguration)
        }
    }
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = 5.0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = Styles.boldBodyFont
        return titleLabel
    }()
    
    private lazy var secondaryTitleLabel: UILabel = {
        let secondaryTitleLabel = UILabel()
        secondaryTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        secondaryTitleLabel.textColor = .secondaryLabel
        return secondaryTitleLabel
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView()
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6.0, leading: 0.0, bottom: 6.0, trailing: 0.0)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.spacing = 13.0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.alignment = .center
        return contentStack
    }()
    
    private lazy var imageStackView = UIStackView()
    
    private lazy var secondaryContentStack: UIStackView = {
        let secondaryContentStack = UIStackView()
        secondaryContentStack.axis = .vertical
        secondaryContentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8.0, leading: 0.0, bottom: 9.0, trailing: 16.0)
        secondaryContentStack.isLayoutMarginsRelativeArrangement = true
        secondaryContentStack.spacing = 0.0
        secondaryContentStack.alignment = .leading
        return secondaryContentStack
    }()
    
    private lazy var tagContentStack: UIStackView = {
        let tagContentStack = UIStackView()
        tagContentStack.spacing = 6.0
        return tagContentStack
    }()
    
    init(configuration: ItemContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        
        sharedItemCellContentViewInitialization()
        apply(configuration, oldConfiguration: nil)
    }
    
    required init?(coder: NSCoder) {
        self.configuration = ItemContentConfiguration()
        super.init(coder: coder)
        
        sharedItemCellContentViewInitialization()
    }
    
    func sharedItemCellContentViewInitialization() {
        addSubview(contentStack)
        contentStack.addArrangedSubview(imageStackView)
        contentStack.addArrangedSubview(secondaryContentStack)
        imageStackView.addArrangedSubview(imageView)
        secondaryContentStack.addArrangedSubview(titleLabel)
        secondaryContentStack.addArrangedSubview(secondaryTitleLabel)
        secondaryContentStack.addArrangedSubview(tagContentStack)
        secondaryContentStack.spacing = 2.0
        secondaryContentStack.setCustomSpacing(5.0, after: secondaryTitleLabel)
        
        let bottomConstraint = contentStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            bottomConstraint,
            imageView.heightAnchor.constraint(equalToConstant: 50.0),
            imageView.widthAnchor.constraint(equalToConstant: 75.0)
        ])
        
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0.0, leading: 20.0, bottom: 0.0, trailing: 0.0)
    }
    
    private func apply(_ configuration: ItemContentConfiguration, oldConfiguration: ItemContentConfiguration?) {
        imageView.image = configuration.image
        titleLabel.text = configuration.title
        secondaryTitleLabel.text = configuration.secondaryTitle
        if oldConfiguration?.tags != configuration.tags {
            tagContentStack.arrangedSubviews.forEach {
                tagContentStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            
            /*
            if configuration.tags.count >= 1 {
                var firstTagConfig = TagView.Configuration()
                firstTagConfig.text = configuration.tags[0].text ?? ""
                firstTagConfig.color = configuration.tags[0].color
                firstTagConfig.tagSize = .small
                
                let firstTag = TagView(configuration: firstTagConfig)
                firstTag.backgroundColor = .secondarySystemBackground
                tagContentStack.addArrangedSubview(firstTag)
                
                if configuration.tags.count >= 2 {
                    var placeholderConfig = TagView.Configuration()
                    placeholderConfig.text = "+ \(configuration.tags.count - 1) more"
                    placeholderConfig.textColor = .secondaryLabel
                    placeholderConfig.tagSize = .small
                    
                    let placeholderTag = TagView(configuration: placeholderConfig)
                    placeholderTag.backgroundColor = .secondarySystemBackground
                    tagContentStack.addArrangedSubview(placeholderTag)
                }
            }
             */
            
            configuration.tags.map { tag in
                var config = TagView.Configuration()
                config.text = tag.text ?? ""
                config.color = tag.color
                config.tagSize = .small
                let tagView = TagView(configuration: config)
                tagView.backgroundColor = .secondarySystemBackground
                return tagView
            }.forEach {
                tagContentStack.addArrangedSubview($0)
                // TODO: - Add placeholder for large number of tags
            }
        }
        
        imageView.isHidden = configuration.image == nil
        titleLabel.isHidden = configuration.title.isEmpty
        secondaryTitleLabel.isHidden = configuration.secondaryTitle.isEmpty
        tagContentStack.isHidden = configuration.tags.isEmpty
    }

}
