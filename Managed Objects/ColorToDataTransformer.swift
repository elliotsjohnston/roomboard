//
//  ColorToDataTransformer.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/31/22.
//

import UIKit

class ColorToDataTransformer: NSSecureUnarchiveFromDataTransformer {
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return UIColor.self
    }
    
    override class var allowedTopLevelClasses: [AnyClass] {
        return [UIColor.self]
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(data)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else {
            fatalError("Wrong data type: value must be a UIColor object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(color)
    }
}

extension NSValueTransformerName {
    static let colorToDataTransformer = NSValueTransformerName(rawValue: "ColorToDataTransformer")
}
