//
//  ImageContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/4/23.
//

import UIKit

class ImageContentView: UIView, UIContentView {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return imageView
    }()
    
    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? ImageContentConfiguration else { return }
            apply(configuration)
        }
    }
    
    init(_ configuration: ImageContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        
        sharedImageContentViewInitialization()
        apply(configuration)
    }
    
    required init?(coder: NSCoder) {
        let configuration = ImageContentConfiguration()
        self.configuration = configuration
        
        super.init(coder: coder)
        
        sharedImageContentViewInitialization()
        apply(configuration)
    }
    
    private func sharedImageContentViewInitialization() {
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 250.0)
        ])
    }

    private func apply(_ configuration: ImageContentConfiguration) {
        imageView.image = configuration.image
    }

}
