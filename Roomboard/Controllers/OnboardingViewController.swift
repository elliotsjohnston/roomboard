//
//  OnboardingViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/8/22.
//

import UIKit

class OnboardingViewController: UIViewController, UICollectionViewDelegate {
    
    private lazy var titleGroup: UIStackView = {
        let iconView = UIImageView(image: UIImage(named: "AppIcon"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 84.0),
            iconView.heightAnchor.constraint(equalToConstant: 84.0)
        ])
        iconView.layer.cornerCurve = .continuous
        iconView.layer.cornerRadius = 84.0 * 0.2237
        iconView.clipsToBounds = true
        
        let welcomeLabel = UILabel()
        welcomeLabel.text = "Welcome to Roomboard"
        welcomeLabel.font = Styles.boldTitleFont
        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .center
        welcomeLabel.lineBreakStrategy = []
        
        let titleGroup = UIStackView(arrangedSubviews: [iconView, welcomeLabel])
        titleGroup.axis = .vertical
        titleGroup.spacing = 20.0
        titleGroup.alignment = .center
        
        NSLayoutConstraint.activate([
            titleGroup.layoutMarginsGuide.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            titleGroup.layoutMarginsGuide.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor)
        ])
        
        return titleGroup
    }()
    
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
            navigationController?.pushViewController(RoomSelectionViewController(), animated: true)
        })
        nextButton.role = .primary
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        return nextButton
    }()
    
    private lazy var featureLayout: UICollectionViewLayout = {
        let featureLayout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .plain)
            config.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            section.interGroupSpacing = 32.0
            return section
        }
        return featureLayout
    }()
    
    private lazy var featureView: UICollectionView = {
        let featureView = UICollectionView(frame: .zero, collectionViewLayout: featureLayout)
        featureView.alwaysBounceVertical = false
//        featureView.isUserInteractionEnabled = false
        featureView.backgroundColor = .clear
        featureView.delegate = self
        return featureView
    }()
    
    private enum Section {
        case main
    }
    
    private struct Feature: Hashable {
        var imageName: String
        var imageColor: UIColor
        var title: String
        var description: String
    }
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Feature>(collectionView: featureView) { [unowned self] collectionView, indexPath, feature in
        return collectionView.dequeueConfiguredReusableCell(using: featureCellRegistration, for: indexPath, item: feature)
    }
    
    private lazy var featureCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Feature> { cell, indexPath, feature in
        let imageConfig = UIImage.SymbolConfiguration(textStyle: .largeTitle)
        var config = UIListContentConfiguration.subtitleCell()
        config.image = UIImage(systemName: feature.imageName)
        config.imageProperties.tintColor = feature.imageColor
        config.imageProperties.preferredSymbolConfiguration = imageConfig
        config.text = feature.title
        config.textProperties.font = Styles.boldSubheadlineFont
        config.secondaryText = feature.description
        config.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
        config.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = config
    }
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [titleGroup, featureView])
        contentStack.axis = .vertical
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20.0, leading: 30.0, bottom: 50.0, trailing: 30.0)
        contentStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentStack.setCustomSpacing(50.0, after: titleGroup)
        return contentStack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = featureCellRegistration
        
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

        view.backgroundColor = .systemBackground
        view.addSubview(contentStack)
        contentStack.frame = view.bounds
        
        view.bringSubviewToFront(materialView)
        
        configureDataSource()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        featureView.contentInset.bottom = materialView.frame.height - contentStack.directionalLayoutMargins.bottom
        featureView.verticalScrollIndicatorInsets.bottom = materialView.frame.height - contentStack.directionalLayoutMargins.bottom
        
        UIView.animate(withDuration: 0.21) { [unowned self] in
            updateMaterialEffect()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.21) { [unowned self] in
            updateMaterialEffect()
        }
    }
    
    private func updateMaterialEffect() {
        if featureView.collectionViewLayout.collectionViewContentSize.height - featureView.contentOffset.y - contentStack.directionalLayoutMargins.bottom - 1.0 > featureView.frame.height - materialView.frame.height {
            materialView.effect = UIBlurEffect(style: .regular)
        } else {
            materialView.effect = nil
        }
    }
    
    private func configureDataSource() {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Feature>()
        let features = [
            Feature(imageName: "backpack.fill",
                    imageColor: .systemBlue,
                    title: "Catalog Your Items",
                    description: "With Roomboard, your personal belongings are always just a few taps away."),
            
            Feature(imageName: "tag.fill",
                    imageColor: .systemGreen,
                    title: "Stay Organized",
                    description: "View your items by room, and use tags to keep track of important belongings."),
            
            Feature(imageName: "line.3.horizontal.decrease.circle.fill",
                    imageColor: .systemPurple,
                    title: "Sort & Filter",
                    description: "Quickly find what you’re looking for using intuitive sort controls.")
        ]
        sectionSnapshot.append(features)
        dataSource.apply(sectionSnapshot, to: .main, animatingDifferences: false)
    }

}
