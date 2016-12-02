//
//  Refresher.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public extension UIScrollView {
    public func srf_addRefresher(_ refresher: Refresher) {
        insertSubview(refresher, at: 0)
        refresher.setup()
    }
    
    public func srf_removeRefresher() {
        guard let refreshers = srf_findRefreshers(), refreshers.count > 0 else { return }
        refreshers.forEach {
            $0.removeFromSuperview()
        }
    }
    
    public func srf_endRefreshing() {
        srf_findRefreshers()?.forEach {
            $0.endRefresh()
        }
    }
    
    fileprivate func srf_findRefreshers() -> [Refresher]? {
        return subviews.filter { $0 is Refresher }.flatMap { $0 as? Refresher }
    }
}

public protocol SwfitRefresherEventReceivable {
    func didReceiveEvent(_ event: SwiftRefresherEvent)
}

public enum SwiftRefresherState {
    case none
    case pulling
    case refreshing
    case recoveringInitialState
}

public enum SwiftRefresherEvent {
    case pull(offset: CGPoint, threshold: CGFloat)
    case startRefreshing
    case endRefreshing
    case recoveredToInitialState
}

public typealias SwiftRefresherStartRefreshingHandler = (() -> Void)
public typealias SwiftRefresherEventHandler = ((_ event: SwiftRefresherEvent) -> Void)
public typealias SwiftRefresherCustomRefreshViewCreator = (() -> SwfitRefresherEventReceivable)

private let DEFAULT_HEIGHT: CGFloat = 44.0

open class Refresher: UIView {
    fileprivate var stateInternal = SwiftRefresherState.none
    fileprivate var eventHandler: SwiftRefresherEventHandler?
    fileprivate var startRefreshingHandler: SwiftRefresherStartRefreshingHandler?
    fileprivate var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    fileprivate var contentOffset = CGPoint.zero
    fileprivate var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    fileprivate var recoveringInitialState: Bool = false
    fileprivate var refreshView: SwfitRefresherEventReceivable!
    fileprivate var customRefreshViewCreator: SwiftRefresherCustomRefreshViewCreator?
    
    open var state: SwiftRefresherState { return stateInternal }
    open var height: CGFloat = DEFAULT_HEIGHT
    
    deinit {
        if let scrollView = superview as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            scrollView.removeObserver(self, forKeyPath: "contentInset", context: nil)
        }
    }
    
    convenience public init(eventHandler: @escaping SwiftRefresherEventHandler) {
        self.init()
        self.eventHandler = eventHandler
    }
    
    convenience public init(startRefreshingHandler: @escaping SwiftRefresherStartRefreshingHandler) {
        self.init()
        self.startRefreshingHandler = startRefreshingHandler
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let newSuperview = newSuperview {
            if let scrollView = newSuperview as? UIScrollView {
                let options: NSKeyValueObservingOptions = [.initial, .new]
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
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let scrollView = superview as? UIScrollView else { return }
        guard let keyPath = keyPath else { return }
        guard let change = change else { return }
        guard let _ = object else { return }
        
        if keyPath == "contentInset" {
            if let value: NSValue = change[NSKeyValueChangeKey.newKey] as? NSValue {
                contentInset = value.uiEdgeInsetsValue
            }
        }
        
        if keyPath == "contentOffset" {
            if let value: NSValue = change[NSKeyValueChangeKey.newKey] as? NSValue {
                contentOffset = value.cgPointValue
            }
        }
        
        switch state {
        case .none:
            if distanceOffset.y <= 0 {
                fireEvent(.pull(offset: distanceOffset, threshold: -height))
            }
        case .pulling:
            if distanceOffset.y >= 0 {
                isHidden = true
            } else {
                isHidden = false
            }
            
            if distanceOffset.y <= 0 {
                fireEvent(.pull(offset: distanceOffset, threshold: -height))
            }
            
            if scrollView.isDecelerating && distanceOffset.y < -height {
                startRefresh()
            }
        case .recoveringInitialState:
            break
        case .refreshing:
            break
        }
    }
    
    open func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        let selfConstraints = [
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1.0, constant: -height),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superview, attribute: .width, multiplier: 1.0, constant: 0.0)
        ]
        superview?.addConstraints(selfConstraints)
        addConstraint(
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: height)
        )
        
        clipsToBounds = true
        
        refreshView = customRefreshViewCreator?() ?? SimpleRefreshView(activityIndicatorViewStyle: .gray)
        guard let r = refreshView as? UIView else {
            fatalError("CustomRefreshView must be a subclass of UIView")
        }
        addSubview(r)
        r.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            NSLayoutConstraint(item: r, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: r, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: r, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: r, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0),
        ]
        addConstraints(constraints)
    }
    
    open func createCustomRefreshView(_ creator: @escaping SwiftRefresherCustomRefreshViewCreator) {
        self.customRefreshViewCreator = creator
    }
    
    fileprivate func startRefresh() {
        guard let scrollView = superview as? UIScrollView else { return }
        if state == .refreshing { return }
        stateInternal = .refreshing
        UIView.animate(withDuration: 0.25, animations: { [weak self] () -> Void in
            guard let s = self else { return }
            scrollView.contentInset.top = scrollView.contentInset.top + s.height
        }) 
        
        fireEvent(.startRefreshing)
    }
    
    fileprivate func endRefresh() {
        guard let scrollView = superview as? UIScrollView else { return }
        if state == .none { return }
        fireEvent(.endRefreshing)
        scrollView.contentInset.top = scrollView.contentInset.top - height
        scrollView.contentOffset.y = scrollView.contentOffset.y - height
        let initialPoint = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + height)
        scrollView.setContentOffset(initialPoint, animated: true)

        let delay = 0.25 * Double(NSEC_PER_SEC)
        let when  = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: when) { [weak self] () -> Void in
            guard let s = self else { return }
            s.fireEvent(.recoveredToInitialState)
        }
    }
    
    fileprivate func fireEvent(_ event: SwiftRefresherEvent) {
        switch event {
        case .pull:
            stateInternal = .pulling
        case .startRefreshing:
            stateInternal = .refreshing
            startRefreshingHandler?()
        case .endRefreshing:
            stateInternal = .recoveringInitialState
        case .recoveredToInitialState:
            stateInternal = .none
        }
        eventHandler?(event)
        refreshView.didReceiveEvent(event)
    }
}
