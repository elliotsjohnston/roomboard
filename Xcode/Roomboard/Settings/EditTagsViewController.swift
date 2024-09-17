//
//  EditTagsViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/9/23.
//

import UIKit
import Combine
import CoreData
import Logging

class EditTagsViewController: UIViewController, UICollectionViewDelegate, UIColorPickerViewControllerDelegate {

    private var tags = [Tag]()
    
    private var currentlyEditingTag: Tag?
    
    private var currentlyEditingIndexPath: IndexPath?
    
    private var bag = Set<AnyCancellable>()
    
    private let logger = Logger(label: "com.andyjohnston.roomboard.edit-tags-view-controller")
    
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
        config.isEditable = true
        config.textFieldSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        config.textFieldDismissHandler = { [unowned self] in
            managedContext?.perform { [unowned self] in
                do {
                    try managedContext?.save()
                } catch {
                    logger.error("Failed to update tag: \(error.localizedDescription)")
                }
            }
        }
        config.textUpdateHandler = { text in
            tag.text = text
        }
        cell.contentConfiguration = config
        let editColorButton = makeEditColorButton(UIAction { [unowned self] _ in
            currentlyEditingTag = tag
            let colorPicker = UIColorPickerViewController()
            colorPicker.supportsAlpha = false
            colorPicker.delegate = self
            present(colorPicker, animated: true)
        })
        cell.accessories = [.customView(configuration: .init(customView: editColorButton, placement: .trailing()))]
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

        populateTags()
        configureDataSource()
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] notification in
                if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    guard let currentlyEditingIndexPath else { return }
                    tagsView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
                    tagsView.contentInset.bottom = keyboardFrame.height
                    tagsView.scrollToItem(at: currentlyEditingIndexPath, at: .top, animated: true)
                }
            }
            .store(in: &bag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                UIView.animate(withDuration: 0.21) { [unowned self] in
                    tagsView.contentInset.bottom = 0.0
                    tagsView.verticalScrollIndicatorInsets.bottom = 0.0
                }
            }
            .store(in: &bag)
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
        sectionSnapshot.append([.addButton])
        dataSource.apply(sectionSnapshot, to: .main)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagControl = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .addButton = tagControl {
            guard let managedContext else { return }
            guard let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: managedContext) as? Tag else { return }
            newTag.text = "New Tag"
            newTag.color = .gray
            tags.append(newTag)
            collectionView.deselectItem(at: indexPath, animated: true)
            var snapshot = dataSource.snapshot()
            snapshot.insertItems([.tag(tag: newTag)], beforeItem: .addButton)
            dataSource.apply(snapshot, animatingDifferences: true) { [unowned self] in
                guard let newTagFieldIndexPath = dataSource.indexPath(for: .tag(tag: newTag)),
                      let newTagField = collectionView.cellForItem(at: newTagFieldIndexPath) as? TagCell,
                      var config = newTagField.contentConfiguration as? TagContentConfiguration else { return }
                
                config.isEditing = true
                newTagField.contentConfiguration = config
            }
            
            managedContext.perform { [unowned self] in
                do {
                    try managedContext.save()
                } catch {
                    logger.error("Failed to save tag: \(error.localizedDescription)")
                }
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        
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

}
