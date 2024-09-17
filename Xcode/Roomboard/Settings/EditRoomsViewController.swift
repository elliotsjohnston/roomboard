//
//  EditRoomsViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/9/23.
//

import UIKit
import Combine
import CoreData
import Logging

class EditRoomsViewController: UIViewController, UICollectionViewDelegate {
    
    private var bag = Set<AnyCancellable>()
    
    private let logger = Logger(label: "com.andyjohnston.roomboard.edit-rooms-view-controller")
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
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
        roomsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
        config.textUpdateHandler = { text in
            room.title = text
        }
        config.textFieldSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        config.textFieldDismissHandler = { [unowned self] in
            saveContext()
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
    
    private var currentlyEditingIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = roomCellRegistration
        _ = addButtonCellRegistration
        
        title = "Rooms"
        view.addSubview(roomsView)
        roomsView.frame = view.bounds
        view.backgroundColor = .systemGroupedBackground
        
        configureDataSource()
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] notification in
                if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    guard let currentlyEditingIndexPath else { return }
                    roomsView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
                    roomsView.contentInset.bottom = keyboardFrame.height
                    roomsView.scrollToItem(at: currentlyEditingIndexPath, at: .top, animated: true)
                }
            }
            .store(in: &bag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { _ in
                UIView.animate(withDuration: 0.21) { [unowned self] in
                    roomsView.contentInset.bottom = 0.0
                    roomsView.verticalScrollIndicatorInsets.bottom = 0.0
                }
            }
            .store(in: &bag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        filterRooms()
    }
    
    private func filterRooms() {
        guard let managedContext else { return }
        managedContext.perform { [unowned self] in
            do {
                let fetchRequest = Room.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                _ = try managedContext.fetch(fetchRequest)
                    .reduce(Int64(0)) { currentIndex, room in
                        if room.title?.isEmpty == false {
                            room.index = currentIndex
                            return currentIndex + 1
                        } else {
                            managedContext.delete(room)
                            return currentIndex
                        }
                    }
                
                try managedContext.save()
            } catch {
#if DEBUG
                logger.error("Error filtering rooms: \(error.localizedDescription)")
#endif
            }
        }
    }
    
    private func saveContext() {
        guard let managedContext else { return }
        managedContext.perform { [unowned self] in
            do {
                try managedContext.save()
            } catch {
#if DEBUG
                logger.error("Error saving managed context: \(error.localizedDescription)")
#endif
            }
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
    
}
