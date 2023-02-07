//
//  EnableCameraAccessViewController.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/16/22.
//

import UIKit
import AVFoundation
import CoreData
import Logging

class EnableCameraAccessViewController: UIViewController {
    
    private let logger = Logger(label: "com.andyjohnston.roomboard.enable-camera-access-view-controller")
    
    private lazy var cameraIcon: UIImageView = {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 64.0)
        let cameraImage = UIImage(systemName: "camera")
        let cameraIcon = UIImageView(image: cameraImage)
        cameraIcon.preferredSymbolConfiguration = symbolConfig
        cameraIcon.tintColor = UIColor(named: "AccentColor")
        return cameraIcon
    }()
    
    private lazy var enableCameraLabel: UILabel = {
        let enableCameraLabel = UILabel()
        enableCameraLabel.text = "Enable Camera Access"
        enableCameraLabel.font = Styles.boldTitleFont
        enableCameraLabel.numberOfLines = 0
        enableCameraLabel.textAlignment = .center
        return enableCameraLabel
    }()
    
    private lazy var infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.text = "Roomboard uses the camera to capture photos of the items you add to your catalog."
        infoLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        return infoLabel
    }()
    
    private lazy var managedContext: NSManagedObjectContext? = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.persistentContainer.viewContext
    }()
    
    private lazy var titleGroup: UIStackView = {
        let titleGroup = UIStackView(arrangedSubviews: [cameraIcon, enableCameraLabel, infoLabel])
        titleGroup.spacing = 10.0
        titleGroup.axis = .vertical
        titleGroup.alignment = .center
        return titleGroup
    }()
    
    private lazy var skipButton: UIBarButtonItem = {
        let skipButton = UIBarButtonItem(title: "Skip",
                                         style: .plain,
                                         target: self,
                                         action: #selector(skipCameraAccess))
        return skipButton
    }()
    
    private lazy var cameraButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.buttonSize = .large
        config.cornerStyle = .large
        config.imagePadding = 10.0
        let cameraButton = UIButton(configuration: config, primaryAction: UIAction { [unowned self] _ in
            
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                finishOnboarding()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { authorized in
                    DispatchQueue.main.async { [unowned self] in
                        if authorized {
                            finishOnboarding()
                        } else {
                            self.cameraButton.setNeedsUpdateConfiguration()
                        }
                    }
                }
            case .restricted, .denied:
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { break }
                if UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                }
            @unknown default:
                break
            }
        })
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.configurationUpdateHandler = { button in
            guard var config = button.configuration else { return }
            config.title = "Enable Camera"
            config.image = UIImage(systemName: "camera")
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized, .notDetermined:
                config.title = "Enable Camera"
                config.image = UIImage(systemName: "camera")
            case .restricted, .denied:
                config.title = "Open Settings"
                config.image = UIImage(systemName: "gear")
            @unknown default:
                break
            }
            button.configuration = config
        }
        return cameraButton
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [titleGroup, cameraButton])
        contentStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentStack.alignment = .center
        contentStack.axis = .vertical
        contentStack.distribution = .equalCentering
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10.0, leading: 10.0, bottom: 50.0, trailing: 10.0)
        return contentStack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.addSubview(contentStack)
        contentStack.frame = view.bounds
        
        navigationItem.rightBarButtonItem = skipButton
        
        NSLayoutConstraint.activate([
            cameraButton.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor, constant: 30.0),
            contentStack.trailingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 30.0)
        ])
    }
    
    @objc
    private func skipCameraAccess(_ sender: UIBarButtonItem) {
        finishOnboarding()
    }
    
    private func finishOnboarding() {
        filterRooms()
        presentingViewController?.dismiss(animated: true)
        Defaults.finishedOnboarding = true
    }
    
    private func filterRooms() {
        guard let managedContext else { return }
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
