//
//  SettingsViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/7/23.
//

import UIKit
import Combine

class SettingsViewController: UIViewController, UICollectionViewDelegate {
    
    private var cancellable: AnyCancellable?
    
    private lazy var doneButton: UIBarButtonItem = {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(dismissSettings))
        return doneButton
    }()
    
    private lazy var settingsLayout: UICollectionViewLayout = {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let settingsLayout = UICollectionViewCompositionalLayout.list(using: config)
        return settingsLayout
    }()
    
    private lazy var settingsView: UICollectionView = {
        let settingsView = UICollectionView(frame: .zero, collectionViewLayout: settingsLayout)
        settingsView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        settingsView.delegate = self
        return settingsView
    }()
    
    private enum Destination {
        case appearance
        case rooms
        case tags
    }
    
    private enum Section {
        case disclosureItems
        case toggles
    }
    
    private enum SettingsItem: Hashable {
        case disclosureCell(title: String, currentValue: String, destination: Destination)
        case toggle(title: String, userDefaultsKey: String)
    }
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, SettingsItem>(collectionView: settingsView) { [unowned self] collectionView, indexPath, item in
        switch item {
        case .disclosureCell:
            return collectionView.dequeueConfiguredReusableCell(using: disclosureCellRegistration, for: indexPath, item: item)
        case .toggle:
            return collectionView.dequeueConfiguredReusableCell(using: toggleCellRegistration, for: indexPath, item: item)
        }
    }
    
    private lazy var disclosureCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingsItem> { cell, indexPath, item in
        guard case let .disclosureCell(title, currentValue, destination) = item else { return }
        
        var config = UIListContentConfiguration.valueCell()
        config.text = title
        config.secondaryText = currentValue
        
        cell.contentConfiguration = config
        cell.accessories = [.disclosureIndicator()]
    }
    
    private lazy var toggleCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingsItem> { cell, indexPath, item in
        guard case let .toggle(title, userDefaultsKey) = item else { return }
        
        var config = UIListContentConfiguration.cell()
        config.text = title
        
        let toggle = UISwitch()
        toggle.isOn = UserDefaults.standard.bool(forKey: userDefaultsKey)
        toggle.addAction(UIAction { _ in
            UserDefaults.standard.set(toggle.isOn, forKey: userDefaultsKey)
        }, for: .valueChanged)
        
        cell.contentConfiguration = config
        cell.accessories = [.customView(configuration: .init(customView: toggle, placement: .trailing()))]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = disclosureCellRegistration
        _ = toggleCellRegistration
        
        title = "Settings"
        
        navigationItem.rightBarButtonItem = doneButton
        
        view.backgroundColor = .systemBackground
        view.addSubview(settingsView)
        settingsView.frame = view.bounds
        
        cancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [unowned self] _ in
                configureDataSource()
            }

        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = self.settingsView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.settingsView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.settingsView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            } else {
                self.settingsView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }
    
    private func configureDataSource() {
        var disclosureItemsSnapshot = NSDiffableDataSourceSectionSnapshot<SettingsItem>()
//        disclosureItemsSnapshot.append([.disclosureCell(title: "Appearance", currentValue: UserDefaults.standard.selectedAppearance.description, destination: .appearance),
//                                        .disclosureCell(title: "Rooms", currentValue: "None", destination: .rooms),
//                                        .disclosureCell(title: "Tags", currentValue: "None", destination: .tags)])
        
        disclosureItemsSnapshot.append([.disclosureCell(title: "Appearance", currentValue: UserDefaults.standard.selectedAppearance.description, destination: .appearance)])
        // TODO: - Implement
        
//        var togglesSnapshot = NSDiffableDataSourceSectionSnapshot<SettingsItem>()
//        togglesSnapshot.append([.toggle(title: "Persist Filters", userDefaultsKey: "com.roomboard.persist-filters")])
        
        dataSource.apply(disclosureItemsSnapshot, to: .disclosureItems)
//        dataSource.apply(togglesSnapshot, to: .toggles)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .disclosureCell(_, _, destination) = item else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        switch destination {
        case .appearance:
            navigationController?.pushViewController(AppearanceSelectionViewController(), animated: true)
        case .rooms:
            break
        case .tags:
            break
        }
        
    }
    
    @objc
    func dismissSettings(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

}
