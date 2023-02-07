//
//  ImagePickerContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/29/22.
//

import UIKit

class ImagePickerContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? ImagePickerContentConfiguration else { return }
            apply(configuration)
        }
    }
    
    private var editButtonTitle = ""
    
    private var imageEditHandler: (() -> Void)?
    
    private lazy var cameraIcon: UIImageView = {
        let cameraImage = UIImage(systemName: "camera.fill")
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 64.0)
        let cameraIcon = UIImageView(image: cameraImage)
        cameraIcon.tintColor = .secondaryLabel
        cameraIcon.preferredSymbolConfiguration = symbolConfig
        return cameraIcon
    }()
    
    private lazy var photoLabel: UILabel = {
        let photoLabel = UILabel()
        photoLabel.text = "Tap to add a photo"
        photoLabel.font = .preferredFont(forTextStyle: .title3)
        photoLabel.textColor = .secondaryLabel
        photoLabel.textAlignment = .center
        return photoLabel
    }()
    
    private lazy var placeholderContentStack: UIStackView = {
        let placeholderContentStack = UIStackView(arrangedSubviews: [cameraIcon, photoLabel])
        placeholderContentStack.spacing = 10.0
        placeholderContentStack.axis = .vertical
        placeholderContentStack.alignment = .center
        placeholderContentStack.translatesAutoresizingMaskIntoConstraints = false
        return placeholderContentStack
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    
    private lazy var editButton = {
        var config = UIButton.Configuration.gray()
        config.contentInsets = NSDirectionalEdgeInsets(top: 10.0, leading: 12.0, bottom: 10.0, trailing: 12.0)
        config.background.visualEffect = UIBlurEffect(style: .extraLight)
        config.background.cornerRadius = 10.0
        
        let editButton = UIButton(configuration: config, primaryAction: UIAction { [unowned self] _ in
            imageEditHandler?()
        })
        
        editButton.configurationUpdateHandler = { [unowned self] button in
            guard var config = button.configuration else { return }
            config.title = editButtonTitle
            button.configuration = config
        }
        editButton.translatesAutoresizingMaskIntoConstraints = false
        return editButton
    }()
    
    init(_ configuration: ImagePickerContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        
        sharedImagePickerContentViewInitialization()
        apply(configuration)
    }
    
    required init?(coder: NSCoder) {
        let configuration = ImagePickerContentConfiguration()
        self.configuration = configuration
        
        super.init(coder: coder)
        
        sharedImagePickerContentViewInitialization()
        apply(configuration)
    }
    
    private func sharedImagePickerContentViewInitialization() {
        addSubview(placeholderContentStack)
        addSubview(imageView)
        addSubview(editButton)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 250.0),
            placeholderContentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderContentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderContentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 10.0),
            bottomAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 10.0)
        ])
    }
    
    private func apply(_ configuration: ImagePickerContentConfiguration) {
        if let image = configuration.image {
            placeholderContentStack.isHidden = true
            imageView.isHidden = false
            editButton.isHidden = false
            UIView.transition(with: imageView, duration: 0.15, options: .transitionCrossDissolve) { [unowned self] in
                imageView.image = image
            }
        } else {
            placeholderContentStack.isHidden = false
            imageView.isHidden = true
            editButton.isHidden = true
        }
        
        editButtonTitle = configuration.editButtonTitle
        imageEditHandler = configuration.imageEditHandler
        editButton.setNeedsUpdateConfiguration()
    }

}
