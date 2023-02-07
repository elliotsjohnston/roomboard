//
//  Item+CoreDataProperties.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/1/23.
//
//

import Foundation
import CoreData
import UIKit


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var date: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var imageOrientation: Int64
    @NSManaged public var notes: String?
    @NSManaged public var title: String?
    @NSManaged public var value: String?
    @NSManaged public var room: Room?
    @NSManaged public var tags: NSOrderedSet?
    
    var correctedImage: UIImage? {
        guard let imageData else { return nil }
        guard let imageOrientation = UIImage.Orientation(rawValue: Int(imageOrientation)) else { return nil }
        guard let image = UIImage(data: imageData) else { return nil }
        let correctedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: imageOrientation)
        
        return correctedImage
    }
    
    var tagsArray: [Tag]? {
        tags?.array as? [Tag]
    }

}

// MARK: Generated accessors for tags
extension Item {

    @objc(insertObject:inTagsAtIndex:)
    @NSManaged public func insertIntoTags(_ value: Tag, at idx: Int)

    @objc(removeObjectFromTagsAtIndex:)
    @NSManaged public func removeFromTags(at idx: Int)

    @objc(insertTags:atIndexes:)
    @NSManaged public func insertIntoTags(_ values: [Tag], at indexes: NSIndexSet)

    @objc(removeTagsAtIndexes:)
    @NSManaged public func removeFromTags(at indexes: NSIndexSet)

    @objc(replaceObjectInTagsAtIndex:withObject:)
    @NSManaged public func replaceTags(at idx: Int, with value: Tag)

    @objc(replaceTagsAtIndexes:withTags:)
    @NSManaged public func replaceTags(at indexes: NSIndexSet, with values: [Tag])

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSOrderedSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSOrderedSet)

}

extension Item : Identifiable {

}
