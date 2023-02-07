//
//  ItemDetailViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 1/2/23.
//

import UIKit
import CoreData

class ItemDetailViewController: UIViewController, UICollectionViewDelegate {
    
    var item: Item?
    
    private var editItemNavigationController: UINavigationController?
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }()
    
    private lazy var itemViewLayout: UICollectionViewLayout = {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.itemSeparatorHandler = { itemIndexPath, sectionSeparatorConfiguration in
            var config = sectionSeparatorConfiguration
            if Section(rawValue: itemIndexPath.section) == .image && itemIndexPath.item == 0 {
                config.topSeparatorVisibility = .hidden
                config.bottomSeparatorVisibility = .hidden
            }
            
            return config
        }
        let itemViewLayout = UICollectionViewCompositionalLayout.list(using: config)
        return itemViewLayout
    }()
    
    private lazy var editButton: UIBarButtonItem = {
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editItem))
        return editButton
    }()
    
    private lazy var itemView: UICollectionView = {
        let itemView = UICollectionView(frame: .zero, collectionViewLayout: itemViewLayout)
        itemView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        itemView.delegate = self
        return itemView
    }()
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Field>(collectionView: itemView) { [unowned self] collectionView, indexPath, field in
        switch field {
        case .image:
            return collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: field)
        case .property:
            return collectionView.dequeueConfiguredReusableCell(using: propertyCellRegistration, for: indexPath, item: field)
        case .notes:
            return collectionView.dequeueConfiguredReusableCell(using: notesCellRegistration, for: indexPath, item: field)
        }
    }
    
    private lazy var propertyCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Field> { cell, indexPath, field in
        guard case let .property(title, value) = field else { return }
        var config = UIListContentConfiguration.valueCell()
        config.text = title
        config.secondaryText = value
        cell.contentConfiguration = config
    }
    
    private lazy var notesCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Field> { cell, indexPath, field in
        guard case let .notes(notes) = field else { return }
        var config = UIListContentConfiguration.subtitleCell()
        config.text = "Notes"
        config.secondaryText = notes
        config.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
        config.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = config
    }
    
    private lazy var imageCellRegistration = UICollectionView.CellRegistration<ImageCell, Field> { cell, indexPath, field in
        guard case let .image(image) = field else { return }
        var config = ImageContentConfiguration()
        config.image = image
        cell.contentConfiguration = config
    }
    
    private enum Section: Int {
        case image
        case primaryFields
        case notes
    }
    
    private enum Field: Hashable {
        case property(title: String, value: String)
        case notes(notes: String)
        case image(image: UIImage)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        _ = propertyCellRegistration
        _ = notesCellRegistration
        _ = imageCellRegistration
        
        view.addSubview(itemView)
        itemView.frame = view.bounds
        
        navigationController?.navigationBar.isTranslucent = true
        navigationItem.rightBarButtonItem = editButton
        navigationItem.largeTitleDisplayMode = .never
        
        title = item?.title
        
        if let managedContext {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(managedObjectContextDidSave),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: managedContext)
        }
        
        configureDataSource()
    }
    
    private func configureDataSource() {
        guard let item else { return }
        
        if let correctedImage = item.correctedImage {
            var imageSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Field>()
            imageSectionSnapshot.append([.image(image: correctedImage)])
            dataSource.apply(imageSectionSnapshot, to: .image) { [unowned self] in
                navigationController?.setNavigationBarHidden(true, animated: false)
                navigationController?.setNavigationBarHidden(false, animated: false)
            }
        }
        
        var primaryFieldsSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Field>()
        primaryFieldsSectionSnapshot.append([
            .property(title: "Title", value: item.title ?? ""),
            .property(title: "Date", value: item.date?.formatted(date: .numeric, time: .omitted) ?? "")
        ])
        
        if let room = item.room {
            primaryFieldsSectionSnapshot.append([.property(title: "Room", value: room.title ?? "")])
        }
        
        if let tags = item.tags?.array as? [Tag], !tags.isEmpty {
            primaryFieldsSectionSnapshot.append([.property(title: "Tags", value: makeTagsDescription(tags))])
        }
        
        if let value = item.value, !value.isEmpty {
            primaryFieldsSectionSnapshot.append([.property(title: "Value", value: value)])
        }
        
        dataSource.apply(primaryFieldsSectionSnapshot, to: .primaryFields)

        if let notes = item.notes, !notes.isEmpty {
            var notesSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Field>()
            notesSectionSnapshot.append([.notes(notes: notes)])
            dataSource.apply(notesSectionSnapshot, to: .notes)
        }
    }
    
    private func makeTagsDescription(_ tags: [Tag]) -> String {
        guard !tags.isEmpty else { return "" }
        if tags.isEmpty {
            return ""
        } else if tags.count == 1 {
            return tags[0].text ?? ""
        } else {
            return (tags[0].text ?? "") + " + \(tags.count - 1) more"
        }
    }
    
    @objc
    private func editItem(_ sender: UIBarButtonItem) {
        guard let item else { return }
        let editItemController = EditItemViewController()
        editItemController.isEditingItem = true
        editItemController.item = item
        editItemController.selectedImage = item.correctedImage
        editItemController.itemTitle = item.title ?? ""
        editItemController.selectedDate = item.date ?? .now
        editItemController.selectedRoom = item.room
        if let tags = item.tags?.array as? [Tag] {
            editItemController.selectedTags = tags
        }
        editItemController.selectedValue = item.value ?? ""
        editItemController.itemNotes = item.notes ?? ""
        
        let editItemNavigationController = UINavigationController(rootViewController: editItemController)
        present(editItemNavigationController, animated: true)
        self.editItemNavigationController = editItemNavigationController
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    @objc
    private func managedObjectContextDidSave(_ notification: Notification) {
        configureDataSource()
        title = item?.title
    }

}
