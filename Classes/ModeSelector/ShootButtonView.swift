//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import UIKit

/// Ways in which to trigger a camera mode capture
///
/// - tap: By tapping on the capture button
/// - hold: By holding the capture button pressed
/// - tapAndHold: By doing any of the actions the capture button will react some way
enum CaptureTrigger {
    case tap
    case hold
    case tapAndHold
}

/// Protocol to handle capture button user actions
protocol ShootButtonViewDelegate: class {

    /// Function called when capture button was tapped
    func shootButtonViewDidTap()
    /// Function called when the user started a long press on capture button
    func shootButtonViewDidStartLongPress()
    /// Function called when the user ended a long press on capture button
    func shootButtonViewDidEndLongPress()
    /// Function called when the button was triggered and reached the time limit
    func shootButtonReachedMaximumTime()
    /// Function called when the a clip was dropped on capture button
    func shootButtonDidReceiveDropInteraction()

    /// Function called when the button was panned to zoom
    ///
    /// - Parameters:
    ///   - currentPoint: location of the finger on the screen
    ///   - gesture: the long press gesture recognizer that performs the zoom action.
    func shootButtonDidZoom(currentPoint: CGPoint, gesture: UILongPressGestureRecognizer)
}

private struct ShootButtonViewConstants {
    static let imageWidth: CGFloat = 30
    static let borderWidth: CGFloat = 3
    static let innerCircleImageWidth: CGFloat = 64
    static let outerCircleImageWidth: CGFloat = 95 + borderWidth
    static let longPressMinimumDuration: CFTimeInterval = 0.5
    static let buttonWidth: CGFloat = (imageWidth + 15) * 2
    static let buttonSizeAnimationDuration: TimeInterval = 0.2
    static let buttonImageAnimationInDuration: TimeInterval = 0.5
    static let buttonImageAnimationInSpringDamping: CGFloat = 0.6
    static let buttonImageAnimationOutDuration: TimeInterval = 0.15
    static var buttonMaximumWidth: CGFloat = 100
    static let animationDuration: TimeInterval = 0.5
}

private enum ShootButtonState {
    case neutral
    case animating
    case released
}

/// View for a capture/shoot button.
/// It centers an image in a circle with border
/// and reacts to events by changing color
final class ShootButtonView: IgnoreTouchesView, UIDropInteractionDelegate {

    weak var delegate: ShootButtonViewDelegate?

    private let containerView: UIView
    private let imageView: UIImageView
    private let pressCircleImageView: UIImageView
    private let pressBackgroundImageView: UIImageView
    private let tapRecognizer: UITapGestureRecognizer
    private let longPressRecognizer: UILongPressGestureRecognizer
    private let borderView: UIView
    private let trashView: UIImageView
    private let baseColor: UIColor

    private var containerWidthConstraint: NSLayoutConstraint?
    private var imageWidthConstraint: NSLayoutConstraint?
    private var trigger: CaptureTrigger

    private let timeSegmentLayer: ConicalGradientLayer
    private var maximumTime: TimeInterval?
    private var buttonState: ShootButtonState = .neutral
    private var startingPoint: CGPoint?

    static let buttonMaximumWidth = ShootButtonViewConstants.buttonMaximumWidth

    /// designated initializer for the shoot button view
    ///
    /// - Parameters:
    ///   - baseColor: the color before recording
    init(baseColor: UIColor) {
        pressBackgroundImageView = UIImageView()
        pressCircleImageView = UIImageView()
        containerView = UIView()
        imageView = UIImageView()
        borderView = UIView()
        trashView = UIImageView()
        tapRecognizer = UITapGestureRecognizer()
        longPressRecognizer = UILongPressGestureRecognizer()
        timeSegmentLayer = ConicalGradientLayer()

        self.baseColor = baseColor
        trigger = .tap

        super.init(frame: .zero)
        
        backgroundColor = .clear
        isUserInteractionEnabled = true

        setUpPressBackgroundImage(pressBackgroundImageView)
        setUpPressCircleImage(pressCircleImageView)
        setUpContainerView()
        setUpImageView(imageView)
        setUpBorderView()
        setUpTrashView()
        setUpRecognizers()
        setUpInteractions()
    }

    @available(*, unavailable, message: "use init(baseColor:, timeLimit:) instead")
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    @available(*, unavailable, message: "use init(baseColor:, timeLimit:) instead")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The main function to set the current record type and current image
    ///
    /// - Parameters:
    ///   - trigger: The type of trigger for the button (tap, hold)
    ///   - image: the image to display in the button
    ///   - timeLimit: the animation duration of the ring
    func configureFor(trigger: CaptureTrigger, image: UIImage?, timeLimit: TimeInterval?) {
        self.trigger = trigger
        maximumTime = timeLimit
        animateImageChange(image)
    }

    // MARK: - Layout

    // Needed for corner radius being correctly set when view is shown for the first time.
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = containerView.bounds.width / 2
        borderView.layer.cornerRadius = containerView.bounds.width / 2
    }
    
    private func setUpPressBackgroundImage(_ imageView: UIImageView) {
        imageView.accessibilityIdentifier = "Camera Shoot Button Press Background Circle Image"
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        addSubview(imageView)
        imageView.image = KanvasCameraImages.circleImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let distanceToCenter = ShootButtonViewConstants.outerCircleImageWidth
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: distanceToCenter),
            imageView.widthAnchor.constraint(equalToConstant: distanceToCenter),
            imageView.centerXAnchor.constraint(equalTo: safeLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: safeLayoutGuide.centerYAnchor)
            ])
        showPressBackgroundCircle(show: false)
    }
    
    private func setUpPressCircleImage(_ imageView: UIImageView) {
        imageView.accessibilityIdentifier = "Camera Shoot Button Press Inner Circle Image"
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        addSubview(imageView)
        imageView.image = KanvasCameraImages.circleImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: ShootButtonViewConstants.innerCircleImageWidth)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            widthConstraint,
            imageView.centerXAnchor.constraint(equalTo: safeLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: safeLayoutGuide.centerYAnchor)
            ])
        showPressInnerCircle(show: false)
    }
    
    private func setUpContainerView() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstaint = containerView.widthAnchor.constraint(equalToConstant: ShootButtonViewConstants.buttonWidth)
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor),
            widthConstaint
        ])
        containerWidthConstraint = widthConstaint
    }

    private func setUpImageView(_ imageView: UIImageView) {
        imageView.accessibilityIdentifier = "Camera Shoot Button ImageView"
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        containerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: ShootButtonViewConstants.imageWidth)
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            widthConstraint,
            imageView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        ])
        imageWidthConstraint = widthConstraint
    }
    
    private func setUpBorderView() {
        borderView.accessibilityIdentifier = "Camera Shoot Button Border View"
        borderView.layer.masksToBounds = true
        borderView.layer.borderWidth = ShootButtonViewConstants.borderWidth
        borderView.layer.borderColor = baseColor.cgColor
        borderView.isUserInteractionEnabled = false

        borderView.add(into: containerView)

        borderView.layer.cornerRadius = borderView.bounds.width / 2
    }
    
    private func setUpTrashView() {
        trashView.add(into: containerView)
        trashView.translatesAutoresizingMaskIntoConstraints = false
        trashView.image = KanvasCameraImages.deleteImage
        showTrashView(false)
    }

    private func setUpRecognizers() {
        configureTapRecognizer()
        configureLongPressRecognizer()
        containerView.addGestureRecognizer(tapRecognizer)
        containerView.addGestureRecognizer(longPressRecognizer)
    }
    
    private func setUpInteractions() {
        containerView.addInteraction(UIDropInteraction(delegate: self))
    }
    
    // MARK: - Gesture Recognizers

    private func configureTapRecognizer() {
        tapRecognizer.addTarget(self, action: #selector(handleTap(recognizer:)))
    }

    private func configureLongPressRecognizer() {
        longPressRecognizer.minimumPressDuration = ShootButtonViewConstants.longPressMinimumDuration
        longPressRecognizer.addTarget(self, action: #selector(handleLongPress(recognizer:)))
    }

    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        switch trigger {
        case .tap:
            if let timeLimit = maximumTime {
                animateCircle(for: timeLimit, completion: { [unowned self] in self.circleAnimationCallback() })
            }
        case .tapAndHold:
            showBorderView(show: false, animated: false)
            showShutterButtonPressed(show: true, animated: false)
            performUIUpdateAfter(deadline: .now() + 0.1) { [unowned self] in
                self.showBorderView(show: true, animated: false)
                self.showShutterButtonPressed(show: false, animated: true)
            }
        case .hold: return // Do nothing on tap
        }
        delegate?.shootButtonViewDidTap()
    }

    @objc private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        guard trigger == .hold || trigger == .tapAndHold else { return }
        switch recognizer.state {
        case .began:
            updateForLongPress(started: true)
            updateZoom(recognizer: recognizer)
        case .ended, .cancelled, .failed:
            updateForLongPress(started: false)
        default:
            updateZoom(recognizer: recognizer)
        }
    }

    private func updateZoom(recognizer: UILongPressGestureRecognizer) {
        let currentPoint = recognizer.location(in: containerView)
        delegate?.shootButtonDidZoom(currentPoint: currentPoint, gesture: recognizer)
    }

    private func updateForLongPress(started: Bool) {
        showBorderView(show: !started)
        showPressInnerCircle(show: started)
        showPressBackgroundCircle(show: started)
        if started {
            buttonState = .animating
            if let timeLimit = maximumTime {
                animateCircle(for: timeLimit, completion: { [unowned self] in self.circleAnimationCallback() })
            }
            delegate?.shootButtonViewDidStartLongPress()
        }
        else {
            buttonState = .released
            terminateCircleAnimation()
            containerView.layer.removeAllAnimations()
            borderView.layer.removeAllAnimations()
            delegate?.shootButtonViewDidEndLongPress()
        }
    }

    // MARK: - Animations

    private func circleAnimationCallback() {
        terminateCircleAnimation()
        switch buttonState {
            case .animating:
                delegate?.shootButtonReachedMaximumTime()
            default: break
        }
        buttonState = .neutral
    }

    private func animateCircle(for time: TimeInterval, completion: @escaping () -> ()) {
        let shape = CAShapeLayer()
        shape.path = createPathForCircle()
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.white.cgColor
        shape.lineWidth = ShootButtonViewConstants.borderWidth
        shape.strokeStart = 0
        shape.strokeEnd = 1
        shape.lineCap = CAShapeLayerLineCap.butt
        shape.lineJoin = CAShapeLayerLineJoin.bevel
        
        timeSegmentLayer.frame = containerView.bounds
        timeSegmentLayer.colors = [.tumblrBrightOrange,
                                   .tumblrBrightYellow,
                                   .tumblrBrightGreen,
                                   .tumblrBrightBlue,
                                   .tumblrBrightPurple,
                                   .tumblrBrightRed,
                                   .tumblrBrightPink,
                                   .tumblrBrightOrange,
                                   .tumblrBrightYellow,
                                   .tumblrBrightGreen,
                                   .tumblrBrightBlue,
                                   .tumblrBrightPurple,
                                   .tumblrBrightRed,
                                   .tumblrBrightPink,
                                   .tumblrBrightOrange]
        timeSegmentLayer.mask = shape
        containerView.layer.addSublayer(timeSegmentLayer)
        
        let animateStrokeEnd = CABasicAnimation(keyPath: "strokeEnd")
        animateStrokeEnd.duration = time
        animateStrokeEnd.fromValue = 0
        animateStrokeEnd.toValue = 1
        CATransaction.setCompletionBlock(completion)
        shape.add(animateStrokeEnd, forKey: .none)
        CATransaction.commit()
        shape.strokeEnd = 1
    }

    private func createPathForCircle() -> CGPath {
        let arcPath = UIBezierPath()
        arcPath.lineWidth = ShootButtonViewConstants.borderWidth
        arcPath.lineCapStyle = .butt
        arcPath.lineJoinStyle = .bevel
        arcPath.addArc(withCenter: containerView.bounds.center,
                       // Different from UIView's border, this isn't inner to the coordinate, but centered in it.
                       // So we need to subtract half the width to make it match the view's border.
                       radius: ShootButtonViewConstants.buttonWidth / 2 - ShootButtonViewConstants.borderWidth / 2,
                       startAngle: -.pi / 2,
                       endAngle: 3/2 * .pi,
                       clockwise: true)
        return arcPath.cgPath
    }

    private func terminateCircleAnimation() {
        timeSegmentLayer.removeAllAnimations()
        timeSegmentLayer.removeFromSuperlayer()
    }

    private func animateImageChange(_ image: UIImage?) {
        isUserInteractionEnabled = false
        if self.imageView.image != nil {
            UIView.animate(withDuration: ShootButtonViewConstants.buttonImageAnimationOutDuration, animations: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.imageWidthConstraint?.constant = 0
                strongSelf.setNeedsLayout()
                strongSelf.layoutIfNeeded()
            }, completion: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.animateNewImageShowing(image)
            })
        }
        else {
            self.imageWidthConstraint?.constant = 0
            self.setNeedsLayout()
            self.layoutIfNeeded()
            animateNewImageShowing(image)
        }
    }

    private func animateNewImageShowing(_ image: UIImage?) {
        self.imageView.image = image
        UIView.animate(withDuration: ShootButtonViewConstants.buttonImageAnimationInDuration,
                       delay: 0,
                       usingSpringWithDamping: ShootButtonViewConstants.buttonImageAnimationInSpringDamping,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                           self.imageWidthConstraint?.constant = ShootButtonViewConstants.imageWidth
                           self.setNeedsLayout()
                           self.layoutIfNeeded()
        }, completion: { _ in
            self.isUserInteractionEnabled = true
        })
    }
    
    // MARK: - Public interface
    
    /// enables or disables the user interation on the shutter button
    ///
    /// - Parameter enabled: true to enable, false to disable
    func enableUserInteraction(_ enabled: Bool) {
        containerView.isUserInteractionEnabled = enabled
    }

    /// shows or hides the press effect on the shutter button
    ///
    /// - Parameter show: true to show, false to hide
    /// - Parameter animated: true to enable fade in/out, false to disable it. Default is true
    func showShutterButtonPressed(show: Bool, animated: Bool = true) {
        showPressInnerCircle(show: show, animated: animated)
        showPressBackgroundCircle(show: show, animated: animated)
    }
    
    /// shows or hides the inner circle used for the press effect
    ///
    /// - Parameter show: true to show, false to hide
    /// - Parameter animated: true to enable fade in/out, false to disable it. Default is true
    func showPressInnerCircle(show: Bool, animated: Bool = true) {
        let animationDuration = animated ? ShootButtonViewConstants.buttonSizeAnimationDuration : 0
        UIView.animate(withDuration: animationDuration) { [weak self] in
            self?.pressCircleImageView.alpha = show ? 1 : 0
        }
    }
    
    /// shows or hides the outer translucent circle used for the press effect
    ///
    /// - Parameter show: true to show, false to hide
    /// - Parameter animated: true to enable fade in/out, false to disable it. Default is true
    func showPressBackgroundCircle(show: Bool, animated: Bool = true) {
        let animationDuration = animated ? ShootButtonViewConstants.buttonSizeAnimationDuration : 0
        UIView.animate(withDuration: animationDuration) { [weak self] in
            self?.pressBackgroundImageView.alpha = show ? 0.25 : 0
        }
    }
    
    /// shows or hides the border of the shutter button
    ///
    /// - Parameter show: true to show, false to hide
    /// - Parameter animated: true to enable fade in/out, false to disable it. Default is true
    func showBorderView(show: Bool, animated: Bool = true) {
        let animationDuration = animated ? ShootButtonViewConstants.buttonSizeAnimationDuration : 0
        UIView.animate(withDuration: animationDuration) { [weak self] in
            self?.borderView.alpha = show ? 1 : 0
        }
    }

    /// Updates UI for the next button
    ///
    /// - Parameter enabled: whether to enable the next button or not
    func showTrashView(_ show: Bool) {
        UIView.animate(withDuration: ShootButtonViewConstants.animationDuration) {
            self.trashView.alpha = show ? 1 : 0
        }
    }
    
    // MARK: - UIDropInteractionDelegate
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        delegate?.shootButtonDidReceiveDropInteraction()
    }
}
