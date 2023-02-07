//
//  ImageContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/4/23.
//

import UIKit

struct ImageContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return ImageContentView(self)
    }
    
    func updated(for state: UIConfigurationState) -> ImageContentConfiguration {
        return self
    }
    
    var image: UIImage?
}
