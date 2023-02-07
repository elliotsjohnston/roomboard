//
//  RoomSelectionViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/10/22.
//

import UIKit
import CoreData
import Logging

class RoomSelectionViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate {
    
    private let logger = Logger(label: "com.andyjohnston.roomboard.room-selection-view-controller")
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }()
    
    private lazy var titleGroup: UIStackView = {
        let selectRoomsLabel = UILabel()
        selectRoomsLabel.text = "Add Rooms"
        selectRoomsLabel.font = Styles.boldTitleFont
        selectRoomsLabel.numberOfLines = 0
        selectRoomsLabel.textAlignment = .center
        
        let infoLabel = UILabel()
        infoLabel.text = "When you catalog an item, you can include the room that it's being kept in."
        infoLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        
        let titleGroup = UIStackView(arrangedSubviews: [selectRoomsLabel, infoLabel])
        titleGroup.axis = .vertical
        titleGroup.spacing = 10.0
        titleGroup.alignment = .center
        
        NSLayoutConstraint.activate([
            titleGroup.layoutMarginsGuide.leadingAnchor.constraint(equalTo: selectRoomsLabel.leadingAnchor),
            titleGroup.layoutMarginsGuide.trailingAnchor.constraint(equalTo: selectRoomsLabel.trailingAnchor)
        ])
        
        return titleGroup
    }()
    
    private lazy var roomsLayout: UICollectionViewLayout = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath -> UISwipeActionsConfiguration? in
            guard indexPath != dataSource.indexPath(for: .addButton) else { return nil }
            let action = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] action, sourceView, completionHandler in
                var actionPerformed = false
                defer { completionHandler(actionPerformed) }
                
                if let item = dataSource.itemIdentifier(for: indexPath), case let .roomField(room) = item {
                    managedContext?.delete(room)
                    saveContext()
                    var sectionSnapshot = dataSource.snapshot(for: .main)
                    sectionSnapshot.delete([item])
                    addRoomIfNecessary(&sectionSnapshot)
                    dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true)
                    updateRoomIndices()
                    actionPerformed = true
                }
            }
            return UISwipeActionsConfiguration(actions: [action])
        }
        let roomsLayout = UICollectionViewCompositionalLayout.list(using: config)
        return roomsLayout
    }()
    
    private func addRoomIfNecessary(_ sectionSnapshot: inout NSDiffableDataSourceSectionSnapshot<RoomControl>) {
        if sectionSnapshot.items.count == 1, let managedContext, let room = NSEntityDescription.insertNewObject(forEntityName: "Room", into: managedContext) as? Room {
            sectionSnapshot.insert([.roomField(room: room)], before: .addButton)
        }
    }
    
    private lazy var roomsView: UICollectionView = {
        let roomsView = UICollectionView(frame: .zero, collectionViewLayout: roomsLayout)
        roomsView.alwaysBounceVertical = false
        roomsView.delegate = self
        
        return roomsView
    }()
    
    private enum Section {
        case main
    }
    
    private enum RoomControl: Hashable {
        case roomField(room: Room)
        case addButton
    }
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, RoomControl>(collectionView: roomsView) { [unowned self] collectionView, indexPath, control in
        switch control {
        case .roomField(let room):
            return collectionView.dequeueConfiguredReusableCell(using: roomCellRegistration, for: indexPath, item: room)
        case .addButton:
            return collectionView.dequeueConfiguredReusableCell(using: addButtonCellRegistration, for: indexPath, item: Void())
        }
    }
    
    private lazy var roomCellRegistration = UICollectionView.CellRegistration<TextFieldCell, Room> { cell, indexPath, room in
        var config = TextFieldContentConfiguration()
        config.textUpdateHandler = { [unowned self] text in
            room.title = text
            saveContext()
        }
        config.textFieldSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        config.text = room.title ?? ""
        config.textAlignment = .left
        config.autocapitalizationType = .words
        config.placeholderText = "Enter Room Name..."
        cell.contentConfiguration = config
        cell.accessories = [.delete(displayed: .always), .reorder(displayed: .always)]
    }
    
    private lazy var addIcon: UIImageView = {
        let symbolConfig = UIImage.SymbolConfiguration(textStyle: .body, scale: .large)
        let addImage = UIImage(systemName: "plus.circle.fill")
        let addIcon = UIImageView(image: addImage)
        addIcon.preferredSymbolConfiguration = symbolConfig
        addIcon.tintColor = .systemBlue
        return addIcon
    }()
    
    private lazy var addButtonCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Void> { [unowned self] cell, indexPath, _ in
        var config = UIListContentConfiguration.cell()
        config.text = "Add Room"
        config.textProperties.color = .systemBlue
        cell.contentConfiguration = config
        cell.accessories = [.customView(configuration: .init(customView: addIcon, placement: .leading()))]
    }
    
    private lazy var materialView: MaterialView = {
        let materialView = MaterialView()
        materialView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 35.0, leading: 30.0, bottom: 50.0, trailing: 30.0)
        materialView.translatesAutoresizingMaskIntoConstraints = false
        return materialView
    }()
    
    private lazy var nextButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .large
        config.title = "Next"
        
        let nextButton = UIButton(configuration: config, primaryAction: UIAction { [unowned self] _ in
            navigationController?.pushViewController(EnableCameraAccessViewController(), animated: true)
        })
        nextButton.role = .primary
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        return nextButton
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [titleGroup, roomsView])
        contentStack.spacing = 10.0
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10.0, leading: 10.0, bottom: 50.0, trailing: 10.0)
        contentStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return contentStack
    }()
    
    private var currentlyEditingIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = roomCellRegistration
        _ = addButtonCellRegistration
        
        view.addSubview(materialView)
        materialView.addSubview(nextButton)
        NSLayoutConstraint.activate([
            materialView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            materialView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            nextButton.topAnchor.constraint(equalTo: materialView.layoutMarginsGuide.topAnchor),
            nextButton.leadingAnchor.constraint(equalTo: materialView.layoutMarginsGuide.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: materialView.layoutMarginsGuide.trailingAnchor),
            nextButton.bottomAnchor.constraint(equalTo: materialView.layoutMarginsGuide.bottomAnchor)
        ])

        view.addSubview(contentStack)
        view.backgroundColor = .systemGroupedBackground
        contentStack.frame = view.bounds
        
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor, constant: 30.0),
            contentStack.trailingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: 30.0),
            roomsView.leadingAnchor.constraint(equalTo: contentStack.layoutMarginsGuide.leadingAnchor),
            contentStack.layoutMarginsGuide.trailingAnchor.constraint(equalTo: roomsView.trailingAnchor)
        ])
        
        view.bringSubviewToFront(materialView)
        
        configureDataSource()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        roomsView.contentInset.bottom = materialView.frame.height - contentStack.directionalLayoutMargins.bottom
        roomsView.verticalScrollIndicatorInsets.bottom = materialView.frame.height - contentStack.directionalLayoutMargins.bottom
        
        UIView.animate(withDuration: 0.21) { [unowned self] in
            updateMaterialEffect()
        }
    }
    
    private func saveContext() {
        guard let managedContext else { return }
        do {
            try managedContext.save()
        } catch {
#if DEBUG
            logger.error("Error saving managed context: \(error.localizedDescription)")
#endif
        }
    }
    
    private func updateRoomIndices() {
        dataSource.snapshot(for: .main).items.forEach { control in
            guard case .roomField(let room) = control, let indexPath = dataSource.indexPath(for: control) else { return }
            room.index = Int64(indexPath.item)
            saveContext()
        }
    }
    
    private func configureDataSource() {
        guard let managedContext else { return }
        var currentRooms = [Room]()
        do {
            let request = Room.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            currentRooms = try managedContext.fetch(request)
        } catch {
#if DEBUG
            logger.error("Error fetching rooms: \(error.localizedDescription)")
#endif
        }
        let controls: [RoomControl]
        if currentRooms.isEmpty {
            guard let room = NSEntityDescription.insertNewObject(forEntityName: "Room", into: managedContext) as? Room else { return }
            room.index = 0
            controls = [.roomField(room: room),
                        .addButton]
        } else {
            controls = currentRooms.map { RoomControl.roomField(room: $0) } + [.addButton]
        }
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<RoomControl>()
        sectionSnapshot.append(controls)
        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: false)
        
        dataSource.reorderingHandlers.canReorderItem = { control in
            return control != .addButton
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath == dataSource.indexPath(for: .addButton), let managedContext, let room = NSEntityDescription.insertNewObject(forEntityName: "Room", into: managedContext) as? Room {
            var sectionSnapshot = dataSource.snapshot(for: .main)
            if let lastCellIndex = sectionSnapshot.index(of: .addButton) {
                room.index = Int64(lastCellIndex)
            }
            let control = RoomControl.roomField(room: room)
            sectionSnapshot.insert([control], before: .addButton)
            dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true) { [unowned self] in
                guard let newRoomFieldIndexPath = dataSource.indexPath(for: control),
                      let newRoomField = collectionView.cellForItem(at: newRoomFieldIndexPath) as? TextFieldCell,
                      var config = newRoomField.contentConfiguration as? TextFieldContentConfiguration else { return }
                
                config.isEditing = true
                newRoomField.contentConfiguration = config
            }
        }
        UIView.animate(withDuration: 0.21) { [unowned self] in
            updateMaterialEffect()
        }
        saveContext()
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        guard let addButtonIndexPath = dataSource.indexPath(for: .addButton) else { return currentIndexPath }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
            updateRoomIndices()
        }
        if proposedIndexPath == addButtonIndexPath {
            return IndexPath(item: addButtonIndexPath.item - 1, section: addButtonIndexPath.section)
        } else {
            return proposedIndexPath
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.21) { [unowned self] in
            updateMaterialEffect()
        }
    }
    
    private func updateMaterialEffect() {
        if roomsView.collectionViewLayout.collectionViewContentSize.height - roomsView.contentOffset.y - contentStack.directionalLayoutMargins.bottom - 1.0 > roomsView.frame.height - materialView.frame.height {
            materialView.effect = UIBlurEffect(style: .regular)
        } else {
            materialView.effect = nil
        }
    }
    
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            guard let currentlyEditingIndexPath else { return }
            roomsView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height - contentStack.directionalLayoutMargins.bottom
            roomsView.contentInset.bottom = keyboardFrame.height - contentStack.directionalLayoutMargins.bottom
            roomsView.scrollToItem(at: currentlyEditingIndexPath, at: .top, animated: true)
        }
    }
    
    @objc
    func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.21) { [unowned self] in
            roomsView.contentInset.bottom = materialView.frame.height - contentStack.directionalLayoutMargins.bottom
            roomsView.verticalScrollIndicatorInsets.bottom = materialView.frame.height - contentStack.directionalLayoutMargins.bottom
        }
    }

}
