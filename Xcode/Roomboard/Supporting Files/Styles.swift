//
//  Styles.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/8/22.
//

import UIKit

enum Styles {
    static let boldBodyFont: UIFont = {
        let fontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .body)
            .withSymbolicTraits(.traitBold)
        
        let boldBodyFont = UIFont(descriptor: fontDescriptor!, size: 0.0)
        return boldBodyFont
    }()
    
    static let boldTitleFont: UIFont = {
        let fontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withSymbolicTraits(.traitBold)
        
        let boldTitleFont = UIFont(descriptor: fontDescriptor!, size: 0.0)
        return boldTitleFont
    }()
    
    static let boldSubheadlineFont: UIFont = {
        let fontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .subheadline)
            .withSymbolicTraits(.traitBold)
        
        let boldSubheadlineFont = UIFont(descriptor: fontDescriptor!, size: 0.0)
        return boldSubheadlineFont
    }()
    
    static let boldTitle2Font: UIFont = {
        let fontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .title2)
            .withSymbolicTraits(.traitBold)
        
        let boldTitle2Font = UIFont(descriptor: fontDescriptor!, size: 0.0)
        return boldTitle2Font
    }()
}
