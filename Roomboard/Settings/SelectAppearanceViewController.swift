//
//  SelectAppearanceViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 2/7/23.
//

import UIKit

class SelectAppearanceViewController: UIViewController, UICollectionViewDelegate {
    
    private lazy var listLayout: UICollectionViewLayout = {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: config)
        return listLayout
    }()
    
    private lazy var listView: UICollectionView = {
        let listView = UICollectionView(frame: .zero, collectionViewLayout: listLayout)
        listView.delegate = self
        return listView
    }()
    
    private enum Section {
        case main
    }
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Appearance>(collectionView: listView) { [unowned self] collectionView, indexPath, item in
        return collectionView.dequeueConfiguredReusableCell(using: itemCellRegistration, for: indexPath, item: item)
    }
    
    private lazy var itemCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Appearance> { cell, indexPath, appearance in
        var config = UIListContentConfiguration.cell()
        config.text = appearance.description
        
        cell.contentConfiguration = config
        
        if UserDefaults.standard.selectedAppearance == appearance {
            cell.accessories = [.checkmark()]
        } else {
            cell.accessories = []
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = itemCellRegistration
        
        title = "Appearance"
        view.addSubview(listView)
        listView.frame = view.bounds
        
        configureDataSource()
    }
    
    private func configureDataSource() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Appearance>()
        sectionSnapshot.append(Appearance.allCases)
        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let appearance = dataSource.itemIdentifier(for: indexPath) else { return }
        UserDefaults.standard.selectedAppearance = appearance
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
        collectionView.deselectItem(at: indexPath, animated: true)
    }

}
