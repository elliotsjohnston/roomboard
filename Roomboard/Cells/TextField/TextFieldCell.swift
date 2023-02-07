//
//  TextFieldCell.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/19/22.
//

import UIKit

class TextFieldCell: UICollectionViewListCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        contentConfiguration = contentConfiguration?.updated(for: state)
    }
}
