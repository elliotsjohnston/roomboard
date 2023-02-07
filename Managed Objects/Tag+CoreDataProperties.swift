//
//  Tag+CoreDataProperties.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/30/22.
//
//

import Foundation
import CoreData
import UIKit


extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var text: String?
    @NSManaged public var color: UIColor?

}

extension Tag : Identifiable {

}
