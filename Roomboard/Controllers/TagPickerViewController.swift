//
//  TagPickerViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/24/22.
//

import UIKit
import CoreData
import Logging

class TagPickerViewController: UIViewController, UICollectionViewDelegate, UIColorPickerViewControllerDelegate {
    
    private var tags = [Tag]()
    
    private var currentlyEditingTag: Tag?
    
    private var currentlyEditingIndexPath: IndexPath?
    
    var selectedTags = [Tag]()
    
    var dismissHandler: ((TagPickerViewController) -> Void)?
    
    private let logger = Logger(label: "com.andyjohnston.roomboard.tag-picker-view-controller")
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }()
    
    private lazy var tagsViewLayout: UICollectionViewLayout = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath -> UISwipeActionsConfiguration? in
            guard indexPath != dataSource.indexPath(for: .addButton) else { return nil }
            let action = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] action, sourceView, completionHandler in
                var actionPerformed = false
                defer { completionHandler(actionPerformed) }
                
                if let item = dataSource.itemIdentifier(for: indexPath), case let .tag(tag) = item {
                    managedContext?.delete(tag)
                    selectedTags.removeAll { $0 == tag }
                    managedContext?.perform { [unowned self] in
                        do {
                            try managedContext?.save()
                        } catch {
                            logger.error("Failed to delete tag: \(error.localizedDescription)")
                        }
                    }
                    var sectionSnapshot = dataSource.snapshot(for: .main)
                    sectionSnapshot.delete([item])
                    dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true)
                    actionPerformed = true
                }
            }
            return UISwipeActionsConfiguration(actions: [action])
        }
        let tagsViewLayout = UICollectionViewCompositionalLayout.list(using: config)
        return tagsViewLayout
    }()
    
    private lazy var tagsView: UICollectionView = {
        let tagsView = UICollectionView(frame: .zero, collectionViewLayout: tagsViewLayout)
        tagsView.delegate = self
        tagsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tagsView
    }()
    
    private enum Section {
        case main
    }
    
    private enum TagControl: Hashable {
        case tag(tag: Tag)
        case addButton
    }
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, TagControl>(collectionView: tagsView) { [unowned self] collectionView, indexPath, item in
        switch item {
        case .tag(let tag):
            return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)
        case .addButton:
            return collectionView.dequeueConfiguredReusableCell(using: addButtonCellRegistration, for: indexPath, item: Void())
        }
    }
    
    private func makeEditColorButton(_ action: UIAction) -> UIButton {
        var config = UIButton.Configuration.gray()
        config.title = "Edit Color..."
        config.image = UIImage(systemName: "paintpalette.fill")
        config.preferredSymbolConfigurationForImage = .init(scale: .small)
        config.buttonSize = .small
        config.cornerStyle = .large
        config.imagePadding = 10.0
        let editColorButton = UIButton(configuration: config, primaryAction: action)
        return editColorButton
    }
    
    private lazy var tagCellRegistration = UICollectionView.CellRegistration<TagCell, Tag> { [unowned self] cell, indexPath, tag in
        var config = TagContentConfiguration()
        config.tag = tag
        config.isEditable = isEditing
        config.textFieldSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        config.textUpdateHandler = { [unowned self] text in
            tag.text = text
            
            managedContext?.perform { [unowned self] in
                do {
                    try managedContext?.save()
                } catch {
                    logger.error("Failed to update tag: \(error.localizedDescription)")
                }
            }
        }
        cell.contentConfiguration = config
        updateAccessoriesForCell(cell, with: tag)
    }
    
    private lazy var addButtonCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Void> { [unowned self] cell, indexPath, _ in
        var config = UIListContentConfiguration.cell()
        config.text = "Add Tag"
        config.textProperties.color = .systemBlue
        config.imageToTextPadding = 5.0
        config.directionalLayoutMargins.leading = 42.0
        cell.contentConfiguration = config
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tags"
        
        _ = tagCellRegistration
        _ = addButtonCellRegistration
        
        view.backgroundColor = .secondarySystemBackground
        view.addSubview(tagsView)
        tagsView.frame = view.bounds
        
        navigationItem.rightBarButtonItem = editButtonItem

        populateTags()
        configureDataSource()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        dismissHandler?(self)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.main])
        if isEditing {
            snapshot.appendItems([.addButton])
        } else {
            snapshot.deleteItems([.addButton])
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func populateTags() {
        guard let managedContext else { return }
        do {
            let fetchRequest = Tag.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true)]
            tags = try managedContext.fetch(fetchRequest)
        } catch {
#if DEBUG
            logger.error("Failed to fetch tags: \(error.localizedDescription)")
#endif
        }
    }
    
    private func configureDataSource() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<TagControl>()
        sectionSnapshot.append(tags.map {
            TagControl.tag(tag: $0)
        })
        dataSource.apply(sectionSnapshot, to: .main)
    }
    
    private func updateAccessoriesForCell(_ cell: UICollectionViewListCell, with tag: Tag) {
        var accessories = [UICellAccessory]()
        
        if isEditing {
            let editColorButton = makeEditColorButton(UIAction { [unowned self] _ in
                currentlyEditingTag = tag
                let colorPicker = UIColorPickerViewController()
                colorPicker.supportsAlpha = false
                colorPicker.delegate = self
                present(colorPicker, animated: true)
            })
            accessories.append(.customView(configuration: .init(customView: editColorButton, placement: .trailing())))
        }
        
        if selectedTags.contains(tag) {
            accessories.append(.checkmark())
        }
        
        cell.accessories = accessories
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagControl = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .tag(let tag) = tagControl {
            if selectedTags.contains(tag) {
                selectedTags.removeAll { $0 == tag }
            } else {
                selectedTags.append(tag)
            }
            selectedTags.sort { dataSource.indexPath(for: TagControl.tag(tag: $0))?.item ?? 0 < dataSource.indexPath(for: TagControl.tag(tag: $1))?.item ?? 0 }
            if let cell = collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell {
                updateAccessoriesForCell(cell, with: tag)
            }
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            guard let managedContext else { return }
            guard let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as? Tag else { return }
            newTag.text = "New Tag"
            newTag.color = .gray
            tags.append(newTag)
            collectionView.deselectItem(at: indexPath, animated: true)
            var snapshot = dataSource.snapshot()
            snapshot.insertItems([.tag(tag: newTag)], beforeItem: .addButton)
            dataSource.apply(snapshot, animatingDifferences: true)
            
            managedContext.perform { [unowned self] in
                do {
                    try managedContext.save()
                } catch {
                    logger.error("Failed to save tag: \(error.localizedDescription)")
                }
            }
        }
        
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        guard let currentlyEditingTag else { return }
        currentlyEditingTag.color = viewController.selectedColor
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems([TagControl.tag(tag: currentlyEditingTag)])
        dataSource.apply(snapshot)
        
        managedContext?.perform { [unowned self] in
            do {
                try managedContext?.save()
            } catch {
                logger.error("Failed to update tag: \(error.localizedDescription)")
            }
        }
    }
    
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            guard let currentlyEditingIndexPath else { return }
            tagsView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
            tagsView.contentInset.bottom = keyboardFrame.height
            tagsView.scrollToItem(at: currentlyEditingIndexPath, at: .top, animated: true)
        }
    }
    
    @objc
    private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.21) { [unowned self] in
            tagsView.contentInset.bottom = 0.0
            tagsView.verticalScrollIndicatorInsets.bottom = 0.0
        }
    }

}
