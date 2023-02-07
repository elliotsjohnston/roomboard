//
//  ImagePickerContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/29/22.
//

import UIKit

struct ImagePickerContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return ImagePickerContentView(self)
    }
    
    func updated(for state: UIConfigurationState) -> ImagePickerContentConfiguration {
        return self
    }
    
    var image: UIImage?
    var editButtonTitle = ""
    var imageEditHandler: (() -> Void)?
}
