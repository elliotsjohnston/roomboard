//
//  ImageCell.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/4/23.
//

import UIKit

class ImageCell: UICollectionViewListCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.autoresizingMask = .flexibleHeight
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        contentView.autoresizingMask = .flexibleHeight
    }
}
