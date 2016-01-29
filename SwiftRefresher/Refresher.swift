//
//  Refresher.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public extension UIScrollView {
    public func srf_addRefresher(refresher: Refresher) {
        insertSubview(refresher, atIndex: 0)
        refresher.setup()
    }
    
    public func srf_removeRefresher() {
        guard let refreshers = srf_findRefreshers() where refreshers.count > 0 else { return }
        refreshers.forEach {
            $0.removeFromSuperview()
        }
    }
    
    public func srf_endRefreshing() {
        srf_findRefreshers()?.forEach {
            $0.endRefresh()
        }
    }
    
    private func srf_findRefreshers() -> [Refresher]? {
        return subviews.filter { $0 is Refresher }.flatMap { $0 as? Refresher }
    }
}

public protocol SwfitRefresherEventReceivable {
    func didReceiveEvent(event: SwiftRefresherEvent)
}

public enum SwiftRefresherState {
    case None
    case Pulling
    case Refreshing
    case RecoveringInitialState
}

public enum SwiftRefresherEvent {
    case Pull(offset: CGPoint, threshold: CGFloat)
    case StartRefreshing
    case EndRefreshing
    case RecoveredToInitialState
}

public typealias SwiftRefresherStartRefreshingHandler = (() -> Void)
public typealias SwiftRefresherEventHandler = ((event: SwiftRefresherEvent) -> Void)
public typealias SwiftRefresherCustomRefreshViewCreator = (() -> SwfitRefresherEventReceivable)

private let DEFAULT_HEIGHT: CGFloat = 44.0

public class Refresher: UIView {
    private var stateInternal = SwiftRefresherState.None
    private var eventHandler: SwiftRefresherEventHandler?
    private var startRefreshingHandler: SwiftRefresherStartRefreshingHandler?
    private var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private var contentOffset = CGPoint.zero
    private var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    private var recoveringInitialState: Bool = false
    private var refreshView: SwfitRefresherEventReceivable!
    private var customRefreshViewCreator: SwiftRefresherCustomRefreshViewCreator?
    
    public var state: SwiftRefresherState { return stateInternal }
    public var height: CGFloat = DEFAULT_HEIGHT
    
    deinit {
        if let scrollView = superview as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            scrollView.removeObserver(self, forKeyPath: "contentInset", context: nil)
        }
    }
    
    convenience public init(eventHandler: SwiftRefresherEventHandler) {
        self.init()
        self.eventHandler = eventHandler
    }
    
    convenience public init(startRefreshingHandler: SwiftRefresherStartRefreshingHandler) {
        self.init()
        self.startRefreshingHandler = startRefreshingHandler
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        
        if let newSuperview = newSuperview {
            if let scrollView = newSuperview as? UIScrollView {
                let options: NSKeyValueObservingOptions = [.Initial, .New]
                scrollView.addObserver(self, forKeyPath: "contentOffset", options: options, context: nil)
                scrollView.addObserver(self, forKeyPath: "contentInset", options: options, context: nil)
            }
        } else {
            if let scrollView = superview as? UIScrollView {
                scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
                scrollView.removeObserver(self, forKeyPath: "contentInset", context: nil)
            }
        }
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard let scrollView = superview as? UIScrollView else { return }
        guard let keyPath = keyPath else { return }
        guard let change = change else { return }
        guard let _ = object else { return }
        
        if keyPath == "contentInset" {
            if let value = change["new"] as? NSValue {
                contentInset = value.UIEdgeInsetsValue()
            }
        }
        
        if keyPath == "contentOffset" {
            if let value = change["new"] as? NSValue {
                contentOffset = value.CGPointValue()
            }
        }
        
        switch state {
        case .None:
            if distanceOffset.y <= 0 {
                fireEvent(.Pull(offset: distanceOffset, threshold: -height))
            }
        case .Pulling:
            if distanceOffset.y >= 0 {
                hidden = true
            } else {
                hidden = false
            }
            
            if distanceOffset.y <= 0 {
                fireEvent(.Pull(offset: distanceOffset, threshold: -height))
            }
            
            if scrollView.decelerating && distanceOffset.y < -height {
                startRefresh()
            }
        case .RecoveringInitialState:
            break
        case .Refreshing:
            break
        }
    }
    
    public func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        let selfConstraints = [
            NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: superview, attribute: .Top, multiplier: 1.0, constant: -height),
            NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: superview, attribute: .Width, multiplier: 1.0, constant: 0.0)
        ]
        superview?.addConstraints(selfConstraints)
        addConstraint(
            NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: height)
        )
        
        clipsToBounds = true
        
        refreshView = customRefreshViewCreator?() ?? SimpleRefreshView(activityIndicatorViewStyle: .Gray)
        guard let r = refreshView as? UIView else {
            fatalError("CustomRefreshView must be a subclass of UIView")
        }
        addSubview(r)
        r.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            NSLayoutConstraint(item: r, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: r, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: r, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: r, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0),
        ]
        addConstraints(constraints)
    }
    
    public func createCustomRefreshView(creator: SwiftRefresherCustomRefreshViewCreator) {
        self.customRefreshViewCreator = creator
    }
    
    private func startRefresh() {
        guard let scrollView = superview as? UIScrollView else { return }
        if state == .Refreshing { return }
        stateInternal = .Refreshing
        UIView.animateWithDuration(0.25) { [weak self] () -> Void in
            guard let s = self else { return }
            scrollView.contentInset.top = scrollView.contentInset.top + s.height
        }
        
        fireEvent(.StartRefreshing)
    }
    
    private func endRefresh() {
        guard let scrollView = superview as? UIScrollView else { return }
        if state == .None { return }
        fireEvent(.EndRefreshing)
        scrollView.contentInset.top = scrollView.contentInset.top - height
        scrollView.contentOffset.y = scrollView.contentOffset.y - height
        let initialPoint = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + height)
        scrollView.setContentOffset(initialPoint, animated: true)

        let delay = 0.25 * Double(NSEC_PER_SEC)
        let when  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(when, dispatch_get_main_queue()) { [weak self] () -> Void in
            guard let s = self else { return }
            s.fireEvent(.RecoveredToInitialState)
        }
    }
    
    private func fireEvent(event: SwiftRefresherEvent) {
        switch event {
        case .Pull:
            stateInternal = .Pulling
        case .StartRefreshing:
            stateInternal = .Refreshing
            startRefreshingHandler?()
        case .EndRefreshing:
            stateInternal = .RecoveringInitialState
        case .RecoveredToInitialState:
            stateInternal = .None
        }
        eventHandler?(event: event)
        refreshView.didReceiveEvent(event)
    }
}
