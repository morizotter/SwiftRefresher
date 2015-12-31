//
//  SimpleRefresher.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public extension UIScrollView {
    public func smr_addRefresher(refresher: RefresherView) {
        insertSubview(refresher, atIndex: 0)
        refresher.setup()
    }
    
    public func smr_removeRefresher() {
        guard let refreshers = smr_findRefreshers() where refreshers.count > 0 else { return }
        refreshers.forEach {
            $0.removeFromSuperview()
        }
    }
    
    public func smr_endRefreshing() {
        smr_findRefreshers()?.forEach {
            $0.endRefresh()
        }
    }
    
    private func smr_findRefreshers() -> [RefresherView]? {
        return subviews.filter { $0 is RefresherView }.flatMap { $0 as? RefresherView }
    }
}

public protocol RefresherEventReceivable {
    func didReceiveEvent(event: RefresherEvent)
}

public enum RefresherState {
    case None
    case Loading
}

public enum RefresherEvent {
    case Pulling(offset: CGPoint, threshold: CGFloat)
    case StartRefreshing
    case EndRefreshing
}

public typealias RefresherStartLoadingHandler = (() -> Void)
public typealias RefresherEventHandler = ((event: RefresherEvent) -> Void)
public typealias RefresherCreateCustomRefreshView = (() -> RefresherEventReceivable)

private let DEFAULT_HEIGHT: CGFloat = 44.0

public class RefresherView: UIView {
    private var stateInternal = RefresherState.None
    private var eventHandler: RefresherEventHandler?
    private var startLoadingHandler: RefresherStartLoadingHandler?
    private var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private var contentOffset = CGPoint.zero
    private var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    private var recoveringInitialState: Bool = false
    private var refreshView: RefresherEventReceivable!
    private var createCustomRefreshView: RefresherCreateCustomRefreshView?
    
    public var state: RefresherState { return stateInternal }
    public var height: CGFloat = DEFAULT_HEIGHT
    
    deinit {
        if let scrollView = superview as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            scrollView.removeObserver(self, forKeyPath: "contentInset", context: nil)
        }
    }
    
    convenience public init(eventHandler: RefresherEventHandler) {
        self.init()
        self.eventHandler = eventHandler
    }
    
    convenience public init(startLoadingHandler: RefresherStartLoadingHandler) {
        self.init()
        self.startLoadingHandler = startLoadingHandler
    }
    
    public func setup() {
        let origin = CGPoint(x: 0.0, y: -height)
        let size = CGSize(width: UIScreen.mainScreen().bounds.width, height: height)
        frame = CGRect(origin: origin, size: size)
        clipsToBounds = true
        
        refreshView = createCustomRefreshView?() ?? SimpleRefreshView(frame: CGRect.zero)
        
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
        case .Loading:
            break
        case .None:
            if distanceOffset.y >= 0 {
                hidden = true
            } else {
                hidden = false
            }
            
            if !recoveringInitialState {
                if distanceOffset.y <= 0 {
                    refreshView.didReceiveEvent(.Pulling(offset: distanceOffset, threshold: -height))
                    eventHandler?(event: .Pulling(offset: distanceOffset, threshold: -height))
                }
            }
            
            if scrollView.decelerating && distanceOffset.y < -height {
                startRefresh()
            }
        }
        
//        print("keyPath: \(keyPath)")
//        print("object: \(object)")
//        print("change: \(change)")
//        print("distanceOffset: \(distanceOffset)")
//        print("y: \(frame.origin.y)")
    }
    
    private func startRefresh() {
        guard let scrollView = superview as? UIScrollView else { return }
        if state == .Loading { return }
        stateInternal = .Loading
        UIView.animateWithDuration(0.25) { [weak self] () -> Void in
            guard let s = self else { return }
            scrollView.contentInset.top = scrollView.contentInset.top + s.height
        }
        
        refreshView.didReceiveEvent(.StartRefreshing)
        startLoadingHandler?()
        eventHandler?(event: .StartRefreshing)
    }
    
    private func endRefresh() {
        guard let scrollView = superview as? UIScrollView else { return }
        if state == .None { return }
        stateInternal = .None
        recoveringInitialState = true
        scrollView.contentInset.top = scrollView.contentInset.top - height
        scrollView.contentOffset.y = scrollView.contentOffset.y - height
        let initialPoint = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + height)
        scrollView.setContentOffset(initialPoint, animated: true)

        let delay = 0.25 * Double(NSEC_PER_SEC)
        let when  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(when, dispatch_get_main_queue()) { [weak self] () -> Void in
            guard let s = self else { return }
            s.recoveringInitialState = false
            s.refreshView.didReceiveEvent(.EndRefreshing)
            s.eventHandler?(event: .EndRefreshing)
        }
    }
}
