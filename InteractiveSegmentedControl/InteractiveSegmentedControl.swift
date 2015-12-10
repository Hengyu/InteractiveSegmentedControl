//
//  ViewController.swift
//  Test
//
//  Created by hengyu on 15/12/8.
//  Copyright © 2015年 hengyu. All rights reserved.
//
//  Distributed under the MIT License (MIT)
//  Get the latest version from here:
//
//  https://github.com/Hengyu/InteractiveSegmentedControl
//
//  The MIT License (MIT)

//  Copyright (c) 2015 hengyu

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

class ViewController: UIViewController {
    private var seg: InteractiveSegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let swipe = UIPanGestureRecognizer(target: self, action: "swipe:")
        view.addGestureRecognizer(swipe)
        
        seg = InteractiveSegmentedControl(items: ["a", "b", "c"])
        seg.selectedSegmentIndex = 1
        seg.frame = CGRectMake(100, 100, 100, 44)
        seg.interactiveGesture = swipe
        view.addSubview(seg)
    }
    
    func swipe(sender: UIPanGestureRecognizer) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}




// MARK: - InteractiveSegmentedControlScrollDirection
/**
The scroll direction for InteractiveSegmentedControl

- LeftToRight: InteractiveSegmentedControl is scrolling from left to right
- RightToLeft: InteractiveSegmentedControl is scrolling from right to left
- None:        InteractiveSegmentedControl is not scrolling
*/
@objc public enum InteractiveSegmentedControlScrollDirection: Int {
    case LeftToRight
    case RightToLeft
    case None
}

// MARK: - InteractiveSegmentedControlDelegate
/**
*  Inform the delegate when the status of segmented control changes
*/
@objc public protocol InteractiveSegmentedControlDelegate: NSObjectProtocol {
    optional func interactiveSegmentedControl(interactiveSegmentedControl: InteractiveSegmentedControl, didStartTransitionAtIndex startIndex: Int)
    optional func interactiveSegmentedControl(interactiveSegmentedControl: InteractiveSegmentedControl, didUpdateTransitionProgress progress: CGFloat)
    optional func interactiveSegmentedControl(interactiveSegmentedControl: InteractiveSegmentedControl, didFinishTransitionAtIndex destinationIndex: Int)
    optional func interactiveSegmentedControlTransitionCancelled(interactiveSegmentedControl: InteractiveSegmentedControl)
}

// MARK: - InteractiveSegmentedControl
/// An UISegmentedControl subclass which user can interact with it by their pan gesture
@IBDesignable public class InteractiveSegmentedControl: UISegmentedControl {
    
    // MARK: Public properties
    
    /// InteractiveGesture for segmented control, weak reference
    @IBOutlet public weak var interactiveGesture: UIPanGestureRecognizer? {
        willSet {
            interactiveGesture?.removeTarget(self, action: "interactiveGestureTriggered:")
        }
        didSet {
            if let interactiveGesture = interactiveGesture {
                interactiveGesture.addTarget(self, action: "interactiveGestureTriggered:")
            }
        }
    }
    
    /// A progress threshold value to determine if current state can result in a completion transition. If the final condition satifies either transitionCompletionProgressThreshold or transitionCompletionVelocityThreshold, the transition will be completed, otherwise, cancelled.
    @IBInspectable public var transitionCompletionProgressThreshold: CGFloat = 0.5
    
    /// An X-axis velocity threshold value to determine if current state can result in a completion transition. If the final condition satifies either transitionCompletionProgressThreshold or transitionCompletionVelocityThreshold, the transition will be completed, otherwise, cancelled.
    @IBInspectable public var transitionCompletionVelocityThreshold: CGFloat = 400
    
    /// To determing Velocity of the transition progress, ig. progress = horizontol moving delta * transitionProgressPerHorizontalTranslation
    @IBInspectable public var transitionProgressPerHorizontalTranslation: CGFloat {
        set {
            if _currentScrollDirection == .None {
                _transitionProgressPerHorizontalTranslation = newValue
            }
        }
        get {
            return _transitionProgressPerHorizontalTranslation
        }
    }
    
    /// Current scroll direction, you can register an observer to get informed when the scroll direction changes
    public dynamic var currentScrollDirection: InteractiveSegmentedControlScrollDirection {
        return _currentScrollDirection
    }
    
    /// Current interactive progress, you can register an observer to get informed when the progress changes
    public dynamic var currentInteractiveProgress: CGFloat {
        return _currentInteractiveProgress
    }
    
    /// Get informed when the status changed
    @IBOutlet weak var delegate: InteractiveSegmentedControlDelegate?
    
    // MARK: Private properties
    
    /// Transition progress / Horizontal translation
    private lazy var _transitionProgressPerHorizontalTranslation: CGFloat = 1.0 / self.bounds.width
    /// Mask image view for start segment
    private lazy var _startMaskImageView: UIImageView = {
        let v = UIImageView(image: nil)
        v.backgroundColor = self.tintColor
        return v
    }()
    /// Mask image view for destination segment
    private lazy var _destinationMaskImageView: UIImageView = {
        let v = UIImageView(image: nil)
        v.backgroundColor = self.tintColor
        return v
    }()
    /// Current scroll direction
    private var _currentScrollDirection: InteractiveSegmentedControlScrollDirection = .None
    /// Previous selected segment index, for restoring status if the interactive transition fails
    private var _previousSelectedSegmentIndex: Int = 0
    /// Current interactive progress
    private var _currentInteractiveProgress: CGFloat = 0
    /// The start point for the given pan gesture, used for computing the gesture moving delta
    private var _startPoint: CGPoint = CGPointZero
    private var _currentGestureVelocityInXAxis: CGFloat = 0
    /// The 'cornerRadius' of the default UISegmentedControl (while the default implementation of rounded rect effect doesn't use the layer's cornerRadius property, however, by drawing its rounded rect boundary)
    private let _cornerRadius: CGFloat = 5.0
    /// Original text color for segment's label
    private var _originalSegmentLabelTextColor: UIColor!
    /// Temporary destination segment
    private var _tmpDestinationSegment: UIView?
    /// Used to compute the left time for the completion animation
    private let _transitionFinishingProgressingTranslation: CGFloat = 10
    
    // MARK: Private methods
    
    @objc private func interactiveGestureTriggered(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            if selectedSegmentIndex == UISegmentedControlNoSegment {
                selectedSegmentIndex = 0
            }
            _startPoint = gesture.locationInView(gesture.view)
            _currentGestureVelocityInXAxis = gesture.velocityInView(gesture.view).x
            if _currentGestureVelocityInXAxis > 0 && (selectedSegmentIndex - 1 >= 0) {
                _currentScrollDirection = .RightToLeft
                startInteractiveTransition()
            } else if _currentGestureVelocityInXAxis < 0 && (selectedSegmentIndex + 1 < numberOfSegments) {
                _currentScrollDirection = .LeftToRight
                startInteractiveTransition()
            }
        case .Changed:
            _currentGestureVelocityInXAxis = gesture.velocityInView(gesture.view).x
            if _currentScrollDirection == .None {
                _startPoint = gesture.locationInView(gesture.view)
                if _currentGestureVelocityInXAxis > 0 && (selectedSegmentIndex - 1 >= 0) {
                    _currentScrollDirection = .RightToLeft
                    startInteractiveTransition()
                } else if _currentGestureVelocityInXAxis < 0 && (selectedSegmentIndex + 1 < numberOfSegments) {
                    _currentScrollDirection = .LeftToRight
                    startInteractiveTransition()
                }
            } else {
                let offset: CGFloat
                if _currentScrollDirection == .LeftToRight {
                    offset = _startPoint.x - gesture.locationInView(gesture.view).x
                } else {
                    offset = gesture.locationInView(gesture.view).x - _startPoint.x
                }
                if offset < 0 {
                    return ()
                }
                _currentInteractiveProgress = transitionProgressPerHorizontalTranslation * offset
                if _currentInteractiveProgress <= 1 {
                    updateInteractiveTransition(_currentInteractiveProgress)
                }
            }
        case .Ended: fallthrough
        case .Cancelled: fallthrough
        case .Failed:
            _currentGestureVelocityInXAxis = gesture.velocityInView(gesture.view).x
            if _currentScrollDirection != .None {
                configureFinishingInteractiveTransition()
            }
        default:return ()
        }
    }
    
    private func startInteractiveTransition() {
        guard _currentScrollDirection != .None else {return ()}
        
        _previousSelectedSegmentIndex = selectedSegmentIndex
        
        // get all segments
        let segmentVs = orderedSegmentViews()
        // determing the destination selected segment index by the given scroll direction
        let destinationSelectedSegmentIndex = _previousSelectedSegmentIndex + ((_currentScrollDirection == .LeftToRight) ? 1 : -1)
        // get the start segment
        let startSegment = segmentVs[_previousSelectedSegmentIndex]
        // get the destination segment
        let destinationSegment = segmentVs[destinationSelectedSegmentIndex]
        _tmpDestinationSegment = destinationSegment
        _originalSegmentLabelTextColor = segmentLabelForSegment(startSegment).textColor
        
        let startMaskImageViewFrame = startSegment.bounds
        let destinationMaskImageViewFrame = destinationSegment.bounds
        
        _startMaskImageView.frame = startMaskImageViewFrame
        _destinationMaskImageView.frame = destinationMaskImageViewFrame
        
        _startMaskImageView.alpha = 1
        _destinationMaskImageView.alpha = 0
        
        if _previousSelectedSegmentIndex == 0 {
            _startMaskImageView.configureRoundedRectByRoundingCorners([.TopLeft, .BottomLeft], cornerRadii: CGSizeMake(_cornerRadius, _cornerRadius))
        } else if _previousSelectedSegmentIndex == numberOfSegments - 1 {
            _startMaskImageView.configureRoundedRectByRoundingCorners([.TopRight, .BottomRight], cornerRadii: CGSizeMake(_cornerRadius, _cornerRadius))
        } else {
            _startMaskImageView.configureRoundedRectByRoundingCorners([], cornerRadii: CGSizeMake(_cornerRadius, _cornerRadius))
        }
        
        if destinationSelectedSegmentIndex == 0 {
            _destinationMaskImageView.configureRoundedRectByRoundingCorners([.TopLeft, .BottomLeft], cornerRadii: CGSizeMake(_cornerRadius, _cornerRadius))
        } else if destinationSelectedSegmentIndex == numberOfSegments - 1 {
            _destinationMaskImageView.configureRoundedRectByRoundingCorners([.TopRight, .BottomRight], cornerRadii: CGSizeMake(_cornerRadius, _cornerRadius))
        } else {
            _destinationMaskImageView.configureRoundedRectByRoundingCorners([], cornerRadii: CGSizeMake(_cornerRadius, _cornerRadius))
        }
        
        startSegment.insertSubview(_startMaskImageView, atIndex: 0)
        destinationSegment.insertSubview(_destinationMaskImageView, atIndex: 0)
        selectedSegmentIndex = UISegmentedControlNoSegment
        
        delegate?.interactiveSegmentedControl?(self, didStartTransitionAtIndex: _previousSelectedSegmentIndex)
    }
    
    private func updateInteractiveTransition(percentComplete: CGFloat) {
        guard percentComplete >= 0 && percentComplete <= 1 else {return ()}
        _startMaskImageView.alpha = 1 - percentComplete
        _destinationMaskImageView.alpha = percentComplete
        
        if percentComplete > 0.5 {
            if let _tmpDestinationSegment = _tmpDestinationSegment {
                let label = segmentLabelForSegment(_tmpDestinationSegment)
                label.textColor = UIColor.whiteColor()
            }
        } else {
            if let _tmpDestinationSegment = _tmpDestinationSegment {
                let label = segmentLabelForSegment(_tmpDestinationSegment)
                label.textColor = _originalSegmentLabelTextColor
            }
        }
        
        delegate?.interactiveSegmentedControl?(self, didUpdateTransitionProgress: percentComplete)
    }
    
    private func finishInteractiveTransition() {
        let progressLeft = 1 - _currentInteractiveProgress
        let duration: NSTimeInterval = NSTimeInterval(progressLeft / abs(_currentGestureVelocityInXAxis) * _transitionFinishingProgressingTranslation)
        UIView.animateWithDuration(duration, animations: {
            self._startMaskImageView.alpha = 0
            self._destinationMaskImageView.alpha = 1
            }, completion: {finished in
                self._startMaskImageView.removeFromSuperview()
                self._destinationMaskImageView.removeFromSuperview()
                self.selectedSegmentIndex = self._previousSelectedSegmentIndex + ((self._currentScrollDirection == .LeftToRight) ? 1 : -1)
                self._currentScrollDirection = .None
                self._previousSelectedSegmentIndex = UISegmentedControlNoSegment
                self._tmpDestinationSegment = nil
                self.delegate?.interactiveSegmentedControl?(self, didFinishTransitionAtIndex: self.selectedSegmentIndex)
        })
    }
    
    private func cancelInteractiveTransition() {
        UIView.animateWithDuration(0.3, animations: {
            self._startMaskImageView.alpha = 1
            self._destinationMaskImageView.alpha = 0
            }, completion: {finished in
                self._startMaskImageView.removeFromSuperview()
                self._destinationMaskImageView.removeFromSuperview()
                self.selectedSegmentIndex = self._previousSelectedSegmentIndex
                self._currentScrollDirection = .None
                self._previousSelectedSegmentIndex = UISegmentedControlNoSegment
                self._tmpDestinationSegment = nil
                self.delegate?.interactiveSegmentedControlTransitionCancelled?(self)
        })
    }
    
    private func configureFinishingInteractiveTransition() {
        if _currentInteractiveProgress >= transitionCompletionProgressThreshold || abs(_currentGestureVelocityInXAxis) >= transitionCompletionVelocityThreshold {
            finishInteractiveTransition()
        } else {
            cancelInteractiveTransition()
        }
    }
    
    private func orderedSegmentViews() -> [UIView] {
//        // determine the order by comparing the item in each views
//        var items: [AnyObject] = []
//        for var i = 0; i < numberOfSegments; i++ {
//            if let str = titleForSegmentAtIndex(i) {
//                items.append(str)
//            } else {
//                let img = imageForSegmentAtIndex(i)!
//                items.append(img)
//            }
//        }
        let segmentV = segmentViews()
        return segmentV.sort{(lhs: UIView, rhs: UIView) in return lhs.frame.origin.x < rhs.frame.origin.x}
    }
    
    private func segmentViews() -> [UIView] {
        var views = [UIView]()
        let segClass = NSClassFromString("UISegment")!.self
        for v in subviews {
            let vType = v.dynamicType
            if vType == segClass {
                views.append(v)
            }
        }
        return views
    }
    
    private func segmentImageViewForSegment(segment: UIView) -> UIImageView {
        for subV in segment.subviews {
            if subV is UIImageView {
                return subV as! UIImageView
            }
        }
        fatalError("imageView for segment \(segment) not found, may be the structure  of segment is changed")
    }
    
    private func segmentLabelForSegment(segment: UIView) -> UILabel {
        for subV in segment.subviews {
            if subV is UILabel {
                return subV as! UILabel
            }
        }
        fatalError("imageView for segment \(segment) not found, may be the structure  of segment is changed")
    }
}

// MARK: - UIView rounded rect method
extension UIView {
    private func configureRoundedRectByRoundingCorners(corners: UIRectCorner, cornerRadii: CGSize) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: cornerRadii)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.CGPath
        layer.mask = maskLayer
    }
}


