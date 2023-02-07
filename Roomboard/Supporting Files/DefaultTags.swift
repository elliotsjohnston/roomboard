//
//  DefaultTags.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/23/22.
//

import UIKit
import CoreData
import Logging

struct DefaultTag {
    var text: String
    var color: UIColor
}

extension DefaultTag {
    static let defaultTags: [DefaultTag] = [
        .init(text: "Driving", color: #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1)),
        .init(text: "Finance", color: #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)),
        .init(text: "Personal", color: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)),
        .init(text: "School", color: #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1))
    ]
    
    static private let logger = Logger(label: "com.andyjohnston.roomboard.default-tags")
    
    static func installDefaultTags(with context: NSManagedObjectContext) {
        let batchDelete = NSBatchDeleteRequest(fetchRequest: Tag.fetchRequest())
        do {
            try context.execute(batchDelete)
        } catch {
#if DEBUG
            logger.error("Failed to install default tags: \(error.localizedDescription)")
#endif
            return
        }
        
        defaultTags.forEach { defaultTag in
            guard let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: context) as? Tag else { return }
            tag.text = defaultTag.text
            tag.color = defaultTag.color
        }
        
        do {
            try context.save()
        } catch {
#if DEBUG
            logger.error("Failed to save context after installing \(defaultTags.count) default tags: \(error.localizedDescription)")
#endif
        }
    }
}
