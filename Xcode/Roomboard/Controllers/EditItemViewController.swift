//
//  EditItemViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/18/22.
//

import UIKit
import Combine
import CoreData
import Logging
import PhotosUI

class EditItemViewController: UIViewController, UICollectionViewDelegate, UIAdaptivePresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    var isEditingItem = false
    
    var item: Item?
    
    private var presentedTagPicker: TagPickerViewController?
    
    private var presentedPhotoPicker: PHPickerViewController?
    
    private var currentlyEditingIndexPath: IndexPath?
    
    private var bag = Set<AnyCancellable>()
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        parent?.presentationController?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = imagePickerRegistration
        _ = titleFieldRegistration
        _ = datePickerRegistration
        _ = roomPickerRegistration
        _ = tagPickerRegistration
        _ = valueFieldRegistration
        _ = notesFieldRegistration
        
        view.backgroundColor = .secondarySystemBackground
        if isEditingItem {
            title = "Edit Item"
        } else {
            title = "New Item"
        }
        view.addSubview(itemView)
        itemView.frame = view.bounds
        
        if isEditingItem {
            navigationItem.rightBarButtonItem = doneButton
        } else {
            navigationItem.rightBarButtonItem = addButton
        }
        
        fetchRooms()
        configureDataSource()
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [unowned self] notification in
                if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    guard let currentlyEditingIndexPath else { return }
                    itemView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
                    itemView.contentInset.bottom = keyboardFrame.height
                    itemView.scrollToItem(at: currentlyEditingIndexPath, at: .bottom, animated: true)
                }
            }
            .store(in: &bag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { _ in
                UIView.animate(withDuration: 0.21) { [unowned self] in
                    itemView.contentInset.bottom = 0.0
                    itemView.verticalScrollIndicatorInsets.bottom = 0.0
                }
            }
            .store(in: &bag)
    }
    
    private let logger = Logger(label: "com.andyjohnston.roomboard.edit-item-view-controller")
    
    private var rooms = [Room]()
    
    var selectedImage: UIImage?
    
    var itemTitle = ""
    
    var selectedDate = Date.now
    
    var selectedRoom: Room?
    
    var selectedTags = [Tag]()
    
    var selectedValue = ""
    
    var itemNotes = ""
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }()
    
    private lazy var selectPhotosButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "photo")
        config.baseForegroundColor = .white
        
        let selectPhotosButton = UIButton(configuration: config, primaryAction: UIAction { [unowned self] _ in
            dismiss(animated: true) { [unowned self] in
                presentPhotoPicker()
            }
        })
        return selectPhotosButton
    }()
    
    private lazy var cameraOverlayView: UIStackView = {
        let bottomSpacerView = UIView()
        let leadingSpacerView = UIView()
        let selectPhotosStack = UIStackView(arrangedSubviews: [leadingSpacerView, selectPhotosButton])
        let cameraOverlayView = UIStackView(arrangedSubviews: [selectPhotosStack, bottomSpacerView])
        cameraOverlayView.isLayoutMarginsRelativeArrangement = true
        cameraOverlayView.directionalLayoutMargins.top = -4.0
        cameraOverlayView.axis = .vertical
        return cameraOverlayView
    }()
    
    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        cameraOverlayView.frame = imagePicker.cameraOverlayView!.frame
        cameraOverlayView.frame.size.height = 100.0
        imagePicker.cameraOverlayView = cameraOverlayView
        imagePicker.cameraFlashMode = .auto
        imagePicker.delegate = self
        return imagePicker
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        let addButton = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(addItem))
        addButton.isEnabled = false
        return addButton
    }()
    
    private lazy var doneButton: UIBarButtonItem = {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveItem))
        doneButton.isEnabled = false
        return doneButton
    }()
    
    private lazy var activityIndicatorItem: UIBarButtonItem = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        let activityIndicatorItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        return activityIndicatorItem
    }()
    
    private lazy var deleteAlertController: UIAlertController = {
        let deleteAlertController = UIAlertController(title: "Delete Item?",
                                                      message: "Your item will be discarded.",
                                                      preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [unowned self] _ in
            dismiss(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        deleteAlertController.addAction(deleteAction)
        deleteAlertController.addAction(cancelAction)
        deleteAlertController.preferredAction = cancelAction
        return deleteAlertController
    }()
    
    private lazy var discardChangesAlertController: UIAlertController = {
        let discardChangesAlertController = UIAlertController(title: "Discard Changes?",
                                                              message: "Your changes will be discarded.",
                                                              preferredStyle: .actionSheet)
        
        let discardChangesAction = UIAlertAction(title: "Discard Changes", style: .destructive) { [unowned self] _ in
            dismiss(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        discardChangesAlertController.addAction(discardChangesAction)
        discardChangesAlertController.addAction(cancelAction)
        discardChangesAlertController.preferredAction = cancelAction
        return discardChangesAlertController
    }()
    
    private lazy var itemViewLayout: UICollectionViewLayout = {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let itemViewLayout = UICollectionViewCompositionalLayout.list(using: config)
        return itemViewLayout
    }()
    
    private lazy var itemView: UICollectionView = {
        let itemView = UICollectionView(frame: .zero, collectionViewLayout: itemViewLayout)
        itemView.keyboardDismissMode = .onDrag
        itemView.delegate = self
        itemView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return itemView
    }()
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Field>(collectionView: itemView) { [unowned self] collectionView, indexPath, item in
        switch item {
        case .imagePicker:
            return collectionView.dequeueConfiguredReusableCell(using: imagePickerRegistration, for: indexPath, item: item)
        case .titleField:
            return collectionView.dequeueConfiguredReusableCell(using: titleFieldRegistration, for: indexPath, item: item)
        case .datePicker:
            return collectionView.dequeueConfiguredReusableCell(using: datePickerRegistration, for: indexPath, item: item)
        case .roomPicker:
            return collectionView.dequeueConfiguredReusableCell(using: roomPickerRegistration, for: indexPath, item: item)
        case .tagPicker:
            return collectionView.dequeueConfiguredReusableCell(using: tagPickerRegistration, for: indexPath, item: item)
        case .valueField:
            return collectionView.dequeueConfiguredReusableCell(using: valueFieldRegistration, for: indexPath, item: item)
        case .notesField:
            return collectionView.dequeueConfiguredReusableCell(using: notesFieldRegistration, for: indexPath, item: item)
        }
    }
    
    private lazy var imagePickerRegistration = UICollectionView.CellRegistration<ImagePickerCell, Field> { [unowned self] cell, indexPath, item in
        var config = ImagePickerContentConfiguration()
        config.image = selectedImage
        if isEditingItem {
            config.editButtonTitle = "Replace"
        } else {
            config.editButtonTitle = "Retake"
        }
        config.imageEditHandler = { [unowned self] in
            presentCameraImagePicker()
        }
        cell.contentConfiguration = config
    }
    
    private lazy var titleFieldRegistration = UICollectionView.CellRegistration<TextFieldCell, Field> { [unowned self] cell, indexPath, item in
        var config = TextFieldContentConfiguration()
        config.title = "Title"
        config.placeholderText = "Enter Title"
        config.text = itemTitle
        config.textUpdateHandler = { [unowned self] title in
            itemTitle = title
            updateAddButtonState()
            updateDoneButtonState()
        }
        config.textFieldSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        cell.contentConfiguration = config
    }
    
    private lazy var datePickerRegistration = UICollectionView.CellRegistration<DatePickerCell, Field> { [unowned self] cell, indexPath, item in
        var config = DatePickerContentConfiguration()
        
        config.date = selectedDate
        config.dateUpdateHandler = { [unowned self] date in
            selectedDate = date
            updateDoneButtonState()
        }
        cell.contentConfiguration = config
    }
    
    private func makeRoomPickerMenu() -> UIMenu {
        let roomActions = rooms.map { room in
            UIAction(title: room.title ?? "", state: selectedRoom == room ? .on : .off) { [unowned self] action in
                selectedRoom = room
                updateTextForSelectedRoom()
                updateDoneButtonState()
            }
        }
        
        return UIMenu(children: [
            UIAction(title: "None", state: selectedRoom == nil ? .on : .off) { [unowned self] action in
                selectedRoom = nil
                updateTextForSelectedRoom()
                updateDoneButtonState()
            },
            UIMenu(options: [.displayInline], children: roomActions)
        ])
    }
    
    private func updateAddButtonState() {
        addButton.isEnabled = !itemTitle.isEmpty && selectedImage != nil
    }
    
    private func updateDoneButtonState() {
        doneButton.isEnabled = !itemTitle.isEmpty && selectedImage != nil
    }
    
    private func updateTextForSelectedRoom() {
        guard let roomPickerIndex = dataSource.indexPath(for: .roomPicker), let roomPickerCell = itemView.cellForItem(at: roomPickerIndex) else { return }
        guard let roomPickerCell = roomPickerCell as? UICollectionViewListCell else { return }
        guard var config = roomPickerCell.contentConfiguration as? UIListContentConfiguration else { return }
        config.secondaryText = selectedRoom?.title ?? "None"
        roomPickerCell.contentConfiguration = config
    }
    
    private func presentRoomEditor() {
        // TODO: - Implementation
    }
    
    private lazy var roomPickerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Field> { [unowned self] cell, indexPath, item in
        var config = UIListContentConfiguration.valueCell()
        config.text = "Room"
        config.secondaryText = selectedRoom?.title ?? "None"
        cell.contentConfiguration = config
        let cellMenu = makeRoomPickerMenu()
        cell.accessories = [.popUpMenu(cellMenu)]
    }
    
    private lazy var valueFieldRegistration = UICollectionView.CellRegistration<TextFieldCell, Field> { [unowned self] cell, indexPath, item in
        var config = TextFieldContentConfiguration()
        config.title = "Value"
        config.placeholderText = "$5"
        config.text = selectedValue
        config.textTransformer = { text in
            let filteredText = text.filter(\.isWholeNumber)
            return filteredText.isEmpty ? "" : "$" + filteredText
        }
        config.font = .monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)
        config.keyboardType = .numberPad
        config.textUpdateHandler = { [unowned self] value in
            selectedValue = value
            updateDoneButtonState()
        }
        config.textFieldSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        cell.contentConfiguration = config
    }
    
    private lazy var tagPickerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Field> { [unowned self] cell, indexPath, item in
        var config = UIListContentConfiguration.valueCell()
        config.text = "Tags"
        cell.contentConfiguration = config
        cell.accessories = [.disclosureIndicator()]
    }
    
    private lazy var notesFieldRegistration = UICollectionView.CellRegistration<NotesCell, Field> { [unowned self] cell, indexPath, item in
        var config = NotesContentConfiguration()
        config.text = itemNotes
        config.notesUpdateHandler = { [unowned self] notes in
            itemNotes = notes
            updateDoneButtonState()
        }
        config.textViewSelectionHandler = { [unowned self] in
            currentlyEditingIndexPath = indexPath
        }
        cell.contentConfiguration = config
    }
    
    private enum Section: Int {
        case image
        case primaryFields
        case notes
    }

    private enum Field {
        case imagePicker
        case titleField
        case datePicker
        case roomPicker
        case tagPicker
        case valueField
        case notesField
    }
    
    private func fetchRooms() {
        guard let managedContext else { return }
        do {
            let request = Room.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            rooms = try managedContext.fetch(request)
        } catch {
#if DEBUG
            logger.error("Failed to fetch rooms: \(error.localizedDescription)")
#endif
        }
    }
    
    private func configureDataSource() {
        var imageSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Field>()
        imageSectionSnapshot.append([.imagePicker])
        
        var primaryFieldsSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Field>()
        primaryFieldsSectionSnapshot.append([.titleField, .datePicker, .tagPicker, .valueField])
        if !rooms.isEmpty {
            primaryFieldsSectionSnapshot.insert([.roomPicker], after: .datePicker)
        }
        
        var notesSectionSnapshot = NSDiffableDataSourceSectionSnapshot<Field>()
        notesSectionSnapshot.append([.notesField])
        
        dataSource.apply(imageSectionSnapshot, to: .image)
        dataSource.apply(primaryFieldsSectionSnapshot, to: .primaryFields)
        dataSource.apply(notesSectionSnapshot, to: .notes)
    }
    
    private func presentTagPicker() {
        let presentedTagPicker = TagPickerViewController()
        presentedTagPicker.selectedTags = selectedTags
        presentedTagPicker.dismissHandler = { [unowned self] picker in
            updateDoneButtonState()
            selectedTags = picker.selectedTags
            updateTagLabel()
        }
        
        navigationController?.pushViewController(presentedTagPicker, animated: true)
        self.presentedTagPicker = presentedTagPicker
    }
    
    private func updateTagLabel() {
        guard let tagPickerIndexPath = dataSource.indexPath(for: .tagPicker),
              let tagPicker = itemView.cellForItem(at: tagPickerIndexPath) as? UICollectionViewListCell,
              var config = tagPicker.contentConfiguration as? UIListContentConfiguration else { return }
        
        if selectedTags.count == 0 {
            config.secondaryText = ""
        } else if selectedTags.count == 1 {
            config.secondaryText = selectedTags[0].text ?? ""
        } else {
            config.secondaryText = (selectedTags[0].text ?? "") + " + \(selectedTags.count - 1) more"
        }
        
        tagPicker.contentConfiguration = config
    }
    
    private func presentCameraImagePicker() {
        
        #if targetEnvironment(simulator)
        
        presentPhotoPicker()
        
        #else
        
        present(imagePicker, animated: true)
        
        #endif
        
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        
        let photoPicker = PHPickerViewController(configuration: config)
        if let sheet = photoPicker.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        photoPicker.delegate = self
        
        present(photoPicker, animated: true)
        self.presentedPhotoPicker = photoPicker
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = self.itemView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.itemView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.itemView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            } else {
                self.itemView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }
    
    @objc
    private func addItem(_ sender: UIBarButtonItem) {
        guard let managedContext, let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: managedContext) as? Item else { return }
        item.imageData = selectedImage?.pngData()
        item.imageOrientation = Int64(selectedImage?.imageOrientation.rawValue ?? 0)
        item.title = itemTitle
        item.date = selectedDate
        item.room = selectedRoom
        item.addToTags(NSOrderedSet(array: selectedTags))
        item.value = selectedValue
        item.notes = itemNotes
        
#if DEBUG
        let metadata = """
Created an item:
{
    title: \(itemTitle),
    date: \(selectedDate),
    room: \(selectedRoom?.title ?? ""),
    tags: \(selectedTags),
    value: \(selectedValue),
    notes: \(itemNotes)
}
"""
        logger.info(.init(stringLiteral: metadata))
#endif
        
        managedContext.perform { [unowned self] in
            do {
                try managedContext.save()
            } catch {
#if DEBUG
                logger.error("Failed to save item to managed context: \(error.localizedDescription)")
#endif
            }
        }
        
        dismiss(animated: true)
    }
    
    @objc
    private func saveItem(_ sender: UIBarButtonItem) {
        guard let managedContext, let item else { return }
        item.imageData = selectedImage?.pngData()
        item.imageOrientation = Int64(selectedImage?.imageOrientation.rawValue ?? 0)
        item.title = itemTitle
        item.date = selectedDate
        item.room = selectedRoom
        (item.tags?.array as? [Tag])?.forEach {
            item.removeFromTags($0)
        }
        item.addToTags(NSOrderedSet(array: selectedTags))
        item.value = selectedValue
        item.notes = itemNotes
        
#if DEBUG
        let metadata = """
Edited an item:
{
    title: \(itemTitle),
    date: \(selectedDate),
    room: \(selectedRoom?.title ?? ""),
    tags: \(selectedTags),
    value: \(selectedValue),
    notes: \(itemNotes)
}
"""
        logger.info(.init(stringLiteral: metadata))
#endif
        
        navigationItem.rightBarButtonItem = activityIndicatorItem
        
        // FIXME: - Execute this on a background thread
        
        DispatchQueue.main.async { [unowned self] in
            do {
                try managedContext.save()
            } catch {
#if DEBUG
                logger.error("Failed to save item to managed context: \(error.localizedDescription)")
#endif
            }
            
            dismiss(animated: true)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if indexPath == dataSource.indexPath(for: .titleField)
            || indexPath == dataSource.indexPath(for: .roomPicker)
            || indexPath == dataSource.indexPath(for: .tagPicker)
            || indexPath == dataSource.indexPath(for: .valueField)
            || indexPath == dataSource.indexPath(for: .imagePicker){
            return true
        } else {
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if indexPath == dataSource.indexPath(for: .imagePicker), selectedImage != nil {
            return false
        } else {
            return true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath == dataSource.indexPath(for: .tagPicker) {
            presentTagPicker()
        } else {
            if indexPath == dataSource.indexPath(for: .imagePicker) {
                presentCameraImagePicker()
            }
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if isEditingItem {
            return !doneButton.isEnabled
        } else {
            return !addButton.isEnabled
        }
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if isEditingItem {
            present(discardChangesAlertController, animated: true)
        } else {
            present(deleteAlertController, animated: true)
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage else { return }
                DispatchQueue.main.async { [unowned self] in
                    updateSelectedImage(image)
                    updateDoneButtonState()
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage else { return }
        DispatchQueue.main.async { [unowned self] in
            updateSelectedImage(image)
            updateDoneButtonState()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    private func updateSelectedImage(_ image: UIImage) {
        selectedImage = image
        
        guard let imagePickerIndexPath = dataSource.indexPath(for: .imagePicker),
              let imagePickerCell = itemView.cellForItem(at: imagePickerIndexPath) as? ImagePickerCell,
              var config = imagePickerCell.contentConfiguration as? ImagePickerContentConfiguration else { return }
        
        config.image = image
        imagePickerCell.contentConfiguration = config
        
        updateAddButtonState()
        updateDoneButtonState()
    }

}
