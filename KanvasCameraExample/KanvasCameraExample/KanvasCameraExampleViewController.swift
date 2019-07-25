//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import KanvasCamera
import Photos
import UIKit

//let applicationViewController = SplitViewController()

/// This class contains a button that launches the camera module
/// It is also the delegate for the camera, and handles saving the exported media
/// The camera can be customized with CameraSettings
final class KanvasCameraExampleViewController: UIViewController {

    private let launchKanvasButton = UIButton(type: .custom)
    private let launchKanvasDashboardButton = UIButton(type: .system)
    private var shouldShowWelcomeTooltip = true
    private var shouldShowColorSelecterTooltip = true
    private var shouldShowStrokeSelectorAnimation = true
    private var firstLaunch = true
    private lazy var featuresTable: FeatureTableView = {
        let featureTableView = FeatureTableView(frame: .zero)
        featureTableView.delegate = self
        return featureTableView
    }()
    private lazy var settings: CameraSettings = {
        return KanvasCameraExampleViewController.customCameraSettings()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(launchKanvasButton)
        view.addSubview(launchKanvasDashboardButton)
        view.addSubview(featuresTable)

        setupLaunchKanvasButton()
        setupLaunchKanvasDashboardButton()
        setupFeaturesTable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showFeaturesTableAfterFirstTime()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        launchCameraFirstTime()
    }

    @objc private func launchKanvasButtonTapped() {
        launchCamera(animated: true)
    }

    @objc private func launchKanvasDashboardTapped() {
        present(SplitViewController(settings: settings), animated: true, completion: .none)
    }

    /// This returns the customized settings for the CameraController
    ///
    /// - Returns: an instance of CameraSettings
    private static func customCameraSettings() -> CameraSettings {
        let settings = CameraSettings()
        settings.enabledModes = [.photo, .gif, .stopMotion]
        settings.defaultMode = .stopMotion
        settings.exportStopMotionPhotoAsVideo = true
        settings.features.ghostFrame = true
        settings.features.openGLPreview = true
        settings.features.openGLCapture = true
        settings.features.cameraFilters = true
        settings.features.editor = true
        settings.features.editorFilters = true
        settings.features.editorMedia = false
        settings.features.editorDrawing = true
        settings.features.mediaPicking = true
        settings.features.editorPosting = true
        return settings
    }

    private func launchCameraFirstTime() {
        if firstLaunch {
            firstLaunch = false
            launchCamera(animated: false)

            launchKanvasButton.addTarget(self, action: #selector(launchKanvasButtonTapped), for: .touchUpInside)
            launchKanvasDashboardButton.addTarget(self, action: #selector(launchKanvasDashboardTapped), for: .touchUpInside)
        }
    }

    private func launchCamera(animated: Bool = true) {
        let controller = CameraController(settings: settings, analyticsProvider: KanvasCameraAnalyticsStub())
        controller.delegate = self
        controller.modalTransitionStyle = .crossDissolve
        self.present(controller, animated: animated, completion: nil)
    }

    private func setupLaunchKanvasButton() {
        launchKanvasButton.isUserInteractionEnabled = false

        // layout
        let buttonOffset: CGFloat = KanvasDevice.belongsToIPhoneXGroup ? 95 : 101
        let buttonWidth: CGFloat = 90
        launchKanvasButton.translatesAutoresizingMaskIntoConstraints = false
        launchKanvasButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        launchKanvasButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -buttonOffset).isActive = true
        launchKanvasButton.widthAnchor.constraint(equalTo: launchKanvasButton.heightAnchor).isActive = true
        launchKanvasButton.heightAnchor.constraint(equalToConstant: buttonWidth).isActive = true

        // background
        launchKanvasButton.setBackgroundImage(UIImage(color: .white), for: .normal)
        launchKanvasButton.setBackgroundImage(UIImage(color: UIColor(hex: 0xEEEEEE)), for: .highlighted)

        // title
        launchKanvasButton.setTitle("", for: .normal)
        launchKanvasButton.setTitleColor(.black, for: .normal)
        launchKanvasButton.setTitleColor(.black, for: .highlighted)
        launchKanvasButton.titleLabel?.font = UIFont.favoritTumblr85(fontSize: 18)
    }

    private func setupLaunchKanvasDashboardButton() {
        launchKanvasDashboardButton.isUserInteractionEnabled = false

        // layout
        launchKanvasDashboardButton.titleLabel?.textAlignment = .center
        launchKanvasDashboardButton.translatesAutoresizingMaskIntoConstraints = false
        launchKanvasDashboardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        launchKanvasDashboardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true

        // text
        launchKanvasDashboardButton.setTitle("", for: .normal)
        launchKanvasDashboardButton.titleLabel?.font = UIFont.favoritTumblr85(fontSize: 18)
        launchKanvasDashboardButton.titleLabel?.textAlignment = .center
        launchKanvasDashboardButton.setTitleColor(.black, for: .normal)
        launchKanvasDashboardButton.setTitleColor(.gray, for: .highlighted)
    }

    private func setupFeaturesTable() {
        // layout
        featuresTable.translatesAutoresizingMaskIntoConstraints = false
        featuresTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        featuresTable.bottomAnchor.constraint(equalTo: launchKanvasButton.topAnchor).isActive = true
        featuresTable.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        featuresTable.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        featuresTable.alpha = 0
    }

    private func showFeaturesTableAfterFirstTime() {
        if !firstLaunch {
            featuresTable.alpha = 1
        }
    }

    private func resetButton() {
        launchKanvasButton.isUserInteractionEnabled = true

        launchKanvasButton.layer.borderColor = UIColor.black.cgColor
        launchKanvasButton.layer.borderWidth = 3
        launchKanvasButton.layer.cornerRadius = launchKanvasButton.bounds.width / 2
        launchKanvasButton.layer.masksToBounds = true

        launchKanvasButton.setTitle("Start", for: .normal)
        
        launchKanvasDashboardButton.isUserInteractionEnabled = true
        launchKanvasDashboardButton.setTitle("Open Kanvas Dashboard", for: .normal)
        launchKanvasDashboardButton.sizeToFit()
    }

}

// MARK: - FeaturesTableViewDelegate

extension KanvasCameraExampleViewController: FeatureTableViewDelegate {
    func featureTableViewLoadFeatures() -> [FeatureTableView.KanvasFeature] {
        return [
            .ghostFrame(settings.features.ghostFrame),
            .openGLPreview(settings.features.openGLPreview),
            .openGLCapture(settings.features.openGLCapture),
            .cameraFilters(settings.features.cameraFilters),
            .experimentalCameraFilters(settings.features.experimentalCameraFilters),
            .editor(settings.features.editor),
            .editorFilters(settings.features.editorFilters),
            .editorMedia(settings.features.editorMedia),
            .editorDrawing(settings.features.editorDrawing),
            .mediaPicking(settings.features.mediaPicking),
            .editorPosting(settings.features.editorPosting),
        ]
    }

    func featureTableView(didUpdateFeature feature: FeatureTableView.KanvasFeature, withValue value: Bool) {
        switch feature {
        case .ghostFrame(_):
            settings.features.ghostFrame = value
        case .openGLPreview(_):
            settings.features.openGLPreview = value
        case .openGLCapture(_):
            settings.features.openGLCapture = value
        case .cameraFilters(_):
            settings.features.cameraFilters = value
        case .experimentalCameraFilters(_):
            settings.features.experimentalCameraFilters = value
        case .editor(_):
            settings.features.editor = value
        case .editorFilters(_):
            settings.features.editorFilters = value
        case .editorMedia(_):
            settings.features.editorMedia = value
        case .editorDrawing(_):
            settings.features.editorDrawing = value
        case .mediaPicking(_):
            settings.features.mediaPicking = value
        case .editorPosting(_):
            settings.features.editorPosting = value
        }
    }
}

// MARK: - CameraControllerDelegate

extension KanvasCameraExampleViewController: CameraControllerDelegate {

    func cameraShouldShowWelcomeTooltip() -> Bool {
        return shouldShowWelcomeTooltip
    }

    func didDismissWelcomeTooltip() {
        shouldShowWelcomeTooltip = false
    }
    
    func editorShouldShowColorSelecterTooltip() -> Bool {
        return shouldShowColorSelecterTooltip
    }
    
    func didDismissColorSelecterTooltip() {
        shouldShowColorSelecterTooltip = false
    }
    
    func didEndStrokeSelectorAnimation() {
        shouldShowStrokeSelectorAnimation = false
    }
    
    func editorShouldShowStrokeSelectorAnimation() -> Bool {
        return shouldShowStrokeSelectorAnimation
    }

    func didCreateMedia(media: KanvasCameraMedia?, error: Error?) {
        if let media = media {
            save(media: media)
        }
        else {
            assertionFailure("Failed to create media")
        }
        dismissCamera()
    }

    func dismissButtonPressed() {
        dismissCamera()
    }

    func provideMediaPickerThumbnail(targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        // Providing nil signals CameraController to load the thumbnail itself
        completion(nil)
    }

    private func save(media: KanvasCameraMedia) {
        PHPhotoLibrary.requestAuthorization { authorizationStatus in
            switch authorizationStatus {
            case .notDetermined:
                print("Photo Library Authorization: Not Determined... not saving!!")
                return
            case .restricted:
                print("Photo Library Authorization: Restricted... not saving!!")
                return
            case .denied:
                print("Photo Library Authorization: Denied... not saving!!")
                return
            case .authorized:
                print("Photo Library Authorization: Authorized")
            }
        }
        switch media {
        case let .image(url):
            moveToLibrary(url: url, resourceType: .photo)
        case let .video(url):
            moveToLibrary(url: url, resourceType: .video)
        }
    }

    private func moveToLibrary(url: URL, resourceType: PHAssetResourceType) {
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            req.addResource(with: resourceType, fileURL: url, options: options)
        }) { (success, error) in
            guard success else {
                guard let err = error else {
                    assertionFailure("Neigher a success or failure!")
                    return
                }
                print("\(err)")
                return
            }
        }
    }

    private func dismissCamera() {
        resetButton()
        dismiss(animated: true, completion: .none)
    }
}
