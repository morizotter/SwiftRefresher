//
//  SmartRefresher.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public extension UIScrollView {
    public func smr_addSmartRefresher(refresher: SmartRefresher) {
        insertSubview(refresher, atIndex: 0)
        refresher.setup(self)
    }
    
    public func smr_removeSmatrRefresher() {
        guard let refreshers = findRefreshers() where refreshers.count > 0 else { return }
        refreshers.forEach {
                $0.removeFromSuperview()
        }
    }
    
    public func smr_endRefreshing() {
        findRefreshers()?.forEach {
            $0.endRefresh()
        }
    }
    
    private func findRefreshers() -> [SmartRefresher]? {
        return subviews.filter { $0 is SmartRefresher }.flatMap { $0 as? SmartRefresher }
    }
}

public enum SmartRefresherState {
    case None
    case Loading
}

public enum SmartRefresherEvent {
    case Pulling(offset: CGPoint, threshold: CGFloat)
    case StartRefreshing
    case EndRefreshing
}

public typealias SmartRefresherEventHandler = ((event: SmartRefresherEvent) -> Void)

private let DEFAULT_HEIGHT: CGFloat = 44.0

public class SmartRefresher: UIView {
    
    public var state: SmartRefresherState { return stateInternal }
    public var useActivityIndicatorView: Bool = true
    public var activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
    
    private weak var scrollView: UIScrollView?
    private var stateInternal = SmartRefresherState.None
    private var eventHandler: SmartRefresherEventHandler?
    private var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private var contentOffset = CGPoint.zero
    private var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    private weak var activityIndicatorView: UIActivityIndicatorView!
    private var recoveringInitialState: Bool = false
    
    public var height: CGFloat = DEFAULT_HEIGHT
    
    deinit {
        guard let scrollView = scrollView else { return }
        scrollView.removeObserver(self, forKeyPath: "contentOffset")
        scrollView.removeObserver(self, forKeyPath: "contentInset")
    }
    
    public func setup(scrollView: UIScrollView?) {
        guard let scrollView = scrollView else { return }
        self.scrollView = scrollView
        let options: NSKeyValueObservingOptions = [.Initial, .New]
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: options, context: nil)
        scrollView.addObserver(self, forKeyPath: "contentInset", options: options, context: nil)
        
        let origin = CGPoint(x: 0.0, y: -height)
        let size = CGSize(width: UIScreen.mainScreen().bounds.width, height: height)
        frame = CGRect(origin: origin, size: size)
        clipsToBounds = true
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorViewStyle)
        activityIndicatorView.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        activityIndicatorView.hidesWhenStopped = true
        addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard let scrollView = scrollView else { return }
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
            if distanceOffset.y <= 0 {
                eventHandler?(event: .Pulling(offset: distanceOffset, threshold: -height))
            }
            if scrollView.decelerating && distanceOffset.y < -height {
                startRefresh()
            }
        }
    }
    
    private func startRefresh() {
        guard let scrollView = scrollView else { return }
        if state == .Loading { return }
        stateInternal = .Loading
        UIView.animateWithDuration(0.25) { [weak self] () -> Void in
            guard let s = self else { return }
            scrollView.contentInset.top = scrollView.contentInset.top + s.height
        }
        if useActivityIndicatorView {
            activityIndicatorView.startAnimating()
        }
        eventHandler?(event: .StartRefreshing)
    }
    
    private func endRefresh() {
        guard let scrollView = scrollView else { return }
        if state == .None { return }
        stateInternal = .None
        recoveringInitialState = true
        scrollView.contentInset.top = scrollView.contentInset.top - height
        scrollView.contentOffset.y = scrollView.contentOffset.y - height
        let initialPoint = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + height)
        scrollView.setContentOffset(initialPoint, animated: true)
        if useActivityIndicatorView {
            activityIndicatorView.stopAnimating()
        }
        let delay = 0.25 * Double(NSEC_PER_SEC)
        let when  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(when, dispatch_get_main_queue()) { [weak self] () -> Void in
            self?.recoveringInitialState = false
            self?.eventHandler?(event: .EndRefreshing)
        }
    }
    
    public func addEventHandler(handler: SmartRefresherEventHandler) {
        eventHandler = handler
    }
}
