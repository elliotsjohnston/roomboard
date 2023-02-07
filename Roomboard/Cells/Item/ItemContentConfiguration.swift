//
//  ItemContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/1/23.
//

import UIKit

struct ItemContentConfiguration: UIContentConfiguration {
    var image: UIImage?
    var title = ""
    var secondaryTitle = ""
    var tags = [Tag]()
    
    func makeContentView() -> UIView & UIContentView {
        return ItemContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> ItemContentConfiguration {
        return self
    }
}
