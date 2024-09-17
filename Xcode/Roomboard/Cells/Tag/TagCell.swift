//
//  TagCell.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/3/23.
//

import UIKit

class TagCell: UICollectionViewListCell {
    private var separatorConstraint: NSLayoutConstraint?
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        guard let contentView = contentView as? TagContentView else { return }
        guard separatorConstraint == nil else { return }
        
        let separatorConstraint = separatorLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingTextAnchor)
        separatorConstraint.isActive = true
        self.separatorConstraint = separatorConstraint
    }
}
