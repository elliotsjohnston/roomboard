//
//  InventoryViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/8/22.
//

import UIKit
import CoreData
import Logging

class InventoryViewController: UIViewController, UICollectionViewDelegate, UISearchResultsUpdating {
    private let logger = Logger(label: "com.andyjohnston.roomboard.inventory-view-controller")
    
    private var sortMode = SortMode.title
    
    private var items = [Item]()
    
    private var valueFilters = Set<ValueFilter>()
    
    private var searchProperties: Set<SearchProperty> = [.title]
    
    private var onboardingNavigationController: UINavigationController?
    
    private var editItemNavigationController: UINavigationController?
    
    private var settingsNavigationController: UINavigationController?
    
    private lazy var settingsButton: UIBarButtonItem = {
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(showSettingsScreen))
        return settingsButton
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                        target: self,
                                        action: #selector(addItem))
        return addButton
    }()
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        return searchController
    }()
    
    private lazy var filterButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.cornerStyle = .capsule
        config.buttonSize = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 6.0, leading: 8.0, bottom: 6.0, trailing: 8.0)
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 13.0)
        config.preferredSymbolConfigurationForImage = imageConfig
        var attributedTitle: AttributedString = "Filter"
        attributedTitle.font = .preferredFont(forTextStyle: .subheadline)
        config.attributedTitle = attributedTitle
        config.image = UIImage(systemName: "line.3.horizontal.decrease.circle")
        config.imagePadding = 6.0
        
        let filterButton = UIButton(configuration: config)
        filterButton.showsMenuAsPrimaryAction = true
        filterButton.menu = makeFilterMenu()
        saveFilterOptions()
        filterButton.preferredMenuElementOrder = .fixed
        filterButton.configurationUpdateHandler = { button in
            guard var config = button.configuration else { return }
            button.configuration = config
        }
        
        return filterButton
    }()
    
    /*
    private lazy var filterButton: UIBarButtonItem = {
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), menu: makeFilterMenu())
        return filterButton
    }()
     */
    
    private enum Section {
        case main
    }
    
    private lazy var placeholderLabel: UILabel = {
        let placeholderLabel = UILabel()
        placeholderLabel.font = Styles.boldTitle2Font
        placeholderLabel.text = "No Items"
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        return placeholderLabel
    }()
    
    private lazy var itemViewLayout: UICollectionViewLayout = {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.trailingSwipeActionsConfigurationProvider = { indexPath in
            let action = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, completion in
                var sectionSnapshot = dataSource.snapshot(for: .main)
                if let item = dataSource.itemIdentifier(for: indexPath) {
                    managedContext?.delete(item)
                    do {
                        try managedContext?.save()
                    } catch {
                        logger.error("Error deleting item \(item.title ?? ""): \(error.localizedDescription)")
                    }
                    sectionSnapshot.delete([item])
                }
                dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: true)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [action])
        }
        let collectionViewLayout = UICollectionViewCompositionalLayout.list(using: config)
        return collectionViewLayout
    }()

    private lazy var itemView: UICollectionView = {
        let itemView = UICollectionView(frame: .zero, collectionViewLayout: itemViewLayout)
        itemView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        itemView.delegate = self
        return itemView
    }()
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: itemView) { [unowned self] collectionView, indexPath, item in
        return itemView.dequeueConfiguredReusableCell(using: itemCellRegistration, for: indexPath, item: item)
    }
    
    private lazy var itemCellRegistration = UICollectionView.CellRegistration<ItemCell, Item> { cell, indexPath, item in
        var config = ItemContentConfiguration()
        config.image = item.correctedImage
        config.title = item.title ?? ""
        config.secondaryTitle = item.room?.title ?? ""
        cell.contentConfiguration = config
        config.tags = item.tagsArray ?? []
        cell.contentConfiguration = config
        cell.accessories = [.disclosureIndicator()]
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = itemCellRegistration
        
        // TODO: - Add progress indicator while loading the collection view
        
        view.backgroundColor = .systemBackground
        title = "Inventory"
        
        if UserDefaults.standard.preserveFilters {
            sortMode = UserDefaults.standard.savedSortMode
            valueFilters = Set(UserDefaults.standard.savedValueFilters)
            searchProperties = Set(UserDefaults.standard.savedSearchProperties)
        }
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.isToolbarHidden = false
        toolbarItems = [.flexibleSpace(), UIBarButtonItem(customView: filterButton), .flexibleSpace()]
        
        navigationItem.leftBarButtonItem = settingsButton
        navigationItem.rightBarButtonItem = addButton
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        if !UserDefaults.standard.finishedOnboarding {
            let onboardingNavigationController = UINavigationController(rootViewController: OnboardingViewController())
            onboardingNavigationController.isModalInPresentation = true
            parent?.present(onboardingNavigationController, animated: true)
            self.onboardingNavigationController = onboardingNavigationController
        } else {
            populateInventoryItems()
        }
        
        if !UserDefaults.standard.installedDefaultTags, let managedContext {
            DefaultTag.installDefaultTags(with: managedContext)
            UserDefaults.standard.installedDefaultTags = true
        }
        
        if let managedContext {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(managedObjectContextDidSave),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: managedContext)
        }
        
        sortItems(animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if itemView.superview == nil {
            view.addSubview(itemView)
            itemView.addSubview(placeholderLabel)
            itemView.frame = view.bounds
            NSLayoutConstraint.activate([
                placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            
            view.layoutIfNeeded()
        }
    }
    
    private func sortItems(animated: Bool = true) {
        switch sortMode {
        case .title:
            items.sort { $0.title ?? "" < $1.title ?? "" }
        case .room:
            items.sort { $0.room?.title ?? "" < $1.room?.title ?? "" }
        case .date:
            items.sort { $0.date ?? Date() < $1.date ?? Date() }
//        case .recentlyViewed:
//            break
            // TODO: - Implement
        }
        
        updateItems(animated: animated)
    }
    
    private func makeFilterMenu() -> UIMenu {
        let searchPropertyActions = SearchProperty.allCases.map { property in
            UIAction(title: property.displayName,
                     attributes: searchProperties.contains(property) && searchProperties.count == 1 ? [.disabled] : [],
                     state: searchProperties.contains(property) ? .on : .off) { [unowned self] action in
                searchProperties.formSymmetricDifference([property])
                filterButton.menu = makeFilterMenu()
                saveFilterOptions()
                sortItems()
            }
        }
        
        let valueFilterActions = ValueFilter.allCases.map { filter in
            UIAction(title: filter.displayName,
                     state: valueFilters.contains(filter) ? .on : .off) { [unowned self] action in
                valueFilters.formSymmetricDifference([filter])
                filterButton.menu = makeFilterMenu()
                saveFilterOptions()
                sortItems()
            }
        }
        
        let sortModeActions = SortMode.allCases.map { sortMode in
            UIAction(title: sortMode.displayName,
                     state: self.sortMode == sortMode ? .on : .off) { [unowned self] action in
                self.sortMode = sortMode
                filterButton.menu = makeFilterMenu()
                saveFilterOptions()
                sortItems()
            }
        }
        
        return UIMenu(children: [
            UIMenu(options: .displayInline, children: [
                UIMenu(title: "Search In",
                       subtitle: makeSearchPropertiesString(),
                       image: UIImage(systemName: "doc.text.magnifyingglass"),
                       children: searchPropertyActions),
                
                UIMenu(title: "Value",
                       subtitle: makeValueFilterString(),
                       image: UIImage(systemName: "dollarsign"),
                       children: valueFilterActions),
                
                UIMenu(title: "Sort By",
                       subtitle: sortMode.displayName,
                       image: UIImage(systemName:"arrow.up.arrow.down"),
                       children: sortModeActions)
            ]),
            
            UIAction(title: "Restore Defaults") { [unowned self] action in
                sortMode = .title
                valueFilters = []
                searchProperties = [.title]
                filterButton.menu = makeFilterMenu()
                saveFilterOptions()
                sortItems()
            }
        ])
    }
    
    private func makeValueFilterString() -> String {
        if valueFilters.isEmpty || valueFilters == Set(ValueFilter.allCases) {
            return "All Values"
        }
        
        let sortedFilters = ValueFilter.allCases
            .filter {
                valueFilters.contains($0)
            }
        
        return sortedFilters
            .map(\.minMaxRange)
            .reduce(into: [(min: Int, max: Int)]()) { ranges, nextRange in
                if var lastRange = ranges.last, lastRange.max == nextRange.min {
                    lastRange.max = nextRange.max
                    ranges.removeLast()
                    ranges.append(lastRange)
                } else {
                    ranges.append(nextRange)
                }
            }
            .map { tuple in
                if tuple.max == -1 {
                    return "$\(tuple.min)+"
                } else if tuple == ValueFilter.none.minMaxRange {
                    return "No Value"
                } else {
                    return "$\(tuple.min) - $\(tuple.max)"
                }
            }
            .joined(separator: ", ")
    }
    
    private func makeSearchPropertiesString() -> String {
        if searchProperties.count <= 2 {
            return searchProperties
                .map(\.displayName)
                .joined(separator: " & ")
        } else {
            return searchProperties
                .map(\.displayName)
                .joined(separator: ", ")
        }
    }
    
    private func saveFilterOptions() {
        UserDefaults.standard.savedSortMode = sortMode
        UserDefaults.standard.savedValueFilters = Array(valueFilters)
        UserDefaults.standard.savedSearchProperties = Array(searchProperties)
    }
    
    private func populateInventoryItems() {
        guard let managedContext else { return }
        let request = Item.fetchRequest()
        switch sortMode {
        case .title:
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        case .room:
            request.sortDescriptors = [NSSortDescriptor(key: "room.title", ascending: true)]
        case .date:
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
//        case .recentlyViewed:
//            break
            // TODO: - Implement Recently Viewed
        }
        
        do {
            items = try managedContext.fetch(request)
        } catch {
            logger.error("Error fetching items: \(error.localizedDescription)")
        }
        
        if items.isEmpty {
            filterButton.isEnabled = false
            placeholderLabel.isHidden = false
            itemView.isScrollEnabled = false
        } else {
            filterButton.isEnabled = true
            placeholderLabel.isHidden = true
            itemView.isScrollEnabled = true
        }
        
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        sectionSnapshot.append(items)
        
        /*
        dataSource.apply(sectionSnapshot, to: .main) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.animate(withDuration: 0.4) { [unowned self] in
                    itemView.alpha = 1.0
                }
            }
        }
         */
        
        let selectedIndexPath = itemView.indexPathsForSelectedItems?.first
        
        dataSource.apply(sectionSnapshot, to: .main)
        if let selectedIndexPath, let item = dataSource.itemIdentifier(for: selectedIndexPath) {
            itemView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
            var snapshot = dataSource.snapshot()
            snapshot.reloadItems([item])
            dataSource.apply(snapshot)
        }
    }
    
    func updateItems(animated: Bool) {
        let searchText = searchController.searchBar.text ?? ""
        
        var filteredItems = items.filter { item in
            let value = Int(item.value?.filter(\.isWholeNumber) ?? "")
            return valueFiltersContainValue(value)
        }
        
        if !searchText.isEmpty {
            filteredItems = filteredItems.filter { item in
                if let title = item.title, searchProperties.contains(.title), title.localizedCaseInsensitiveContains(searchText) {
                    return true
                } else if let notes = item.notes, searchProperties.contains(.notes), notes.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                return false
            }
        }
        
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        sectionSnapshot.append(filteredItems)
        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: animated)
    }
    
    @objc
    private func addItem(_ sender: UIBarButtonItem) {
        let editItemNavigationController = UINavigationController(rootViewController: EditItemViewController())
        present(editItemNavigationController, animated: true)
        self.editItemNavigationController = editItemNavigationController
    }
    
    @objc
    private func showSettingsScreen(_ sender: UIBarButtonItem) {
        let settingsNavigationController = UINavigationController(rootViewController: SettingsViewController())
        present(settingsNavigationController, animated: true)
        self.settingsNavigationController
    }
    
    enum ValueFilter: String, CaseIterable {
        case f1
        case f2
        case f3
        case f4
        case f5
        case f6
        case f7
        case f8
        case f9
        case none
        
        var displayName: String {
            switch self {
            case .f1:
                return "$1 - $5"
            case .f2:
                return "$5 - $10"
            case .f3:
                return "$10 - $20"
            case .f4:
                return "$20 - $50"
            case .f5:
                return "$50 - $100"
            case .f6:
                return "$100 - $200"
            case .f7:
                return "$200 - $500"
            case .f8:
                return "$500 - $1000"
            case .f9:
                return "$1000+"
            case .none:
                return "No Value"
            }
        }
        
        var minMaxRange: (min: Int, max: Int) {
            switch self {
            case .f1:
                return (min: 1, max: 5)
            case .f2:
                return (min: 5, max: 10)
            case .f3:
                return (min: 10, max: 20)
            case .f4:
                return (min: 20, max: 50)
            case .f5:
                return (min: 50, max: 100)
            case .f6:
                return (min: 100, max: 200)
            case .f7:
                return (min: 200, max: 500)
            case .f8:
                return (min: 500, max: 1000)
            case .f9:
                return (min: 1000, max: -1)
            case .none:
                return (min: -2, max: -2)
            }
        }
    }
    
    enum SortMode: String, CaseIterable {
        case title
        case room
        case date
     /* case recentlyViewed */
        
        var displayName: String {
            switch self {
            case .title:
                return "Title"
            case .room:
                return "Room"
            case .date:
                return "Date"
         /* case .recentlyViewed: */
             /* return "Recently Viewed" */
                // TODO: - Implement Recently Viewed
            }
        }
    }
    
    enum SearchProperty: String, CaseIterable {
        case title
        case notes
        
        var displayName: String {
            switch self {
            case .title:
                return "Title"
            case .notes:
                return "Notes"
            }
        }
    }
    
    private func valueFiltersContainValue(_ value: Int?) -> Bool {
        if valueFilters.isEmpty {
            return true
        } else if let value {
            return !valueFilters.allSatisfy { $0.minMaxRange.min > value || $0.minMaxRange.max < value }
        } else {
            return valueFilters.contains(.none)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        updateItems(animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let itemDetailController = ItemDetailViewController()
        itemDetailController.item = item
        navigationController?.pushViewController(itemDetailController, animated: true)
    }
    
    @objc
    private func managedObjectContextDidSave(_ notification: Notification) {
        populateInventoryItems()
    }
    
}
