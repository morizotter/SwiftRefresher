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
        refresher.setup()
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

public typealias SmartRefresherRefreshHandler = ((refresher: SmartRefresher) -> Void)

private let DEFAULT_THRESHOLD: CGFloat = 44.0

public class SmartRefresher: UIView {
    public var state = SmartRefresherState.None
    private var refreshedHandler: SmartRefresherRefreshHandler?
    private var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private var contentOffset = CGPoint.zero
    private var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    
    public var threshold: CGFloat = DEFAULT_THRESHOLD
    
    deinit {
        guard let superview = superview else { return }
        superview.removeObserver(self, forKeyPath: "contentOffset")
        superview.removeObserver(self, forKeyPath: "contentInset")
    }
    
    public func setup() {
        guard let superview = superview else { return }
        let options: NSKeyValueObservingOptions = [.Initial, .New]
        superview.addObserver(self, forKeyPath: "contentOffset", options: options, context: nil)
        superview.addObserver(self, forKeyPath: "contentInset", options: options, context: nil)
        
        let origin = CGPoint.zero
        let size = CGSize(width: UIScreen.mainScreen().bounds.width, height: 44.0)
        frame = CGRect(origin: origin, size: size)
        backgroundColor = .redColor()
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard let keyPath = keyPath else { return }
        guard let change = change else { return }
        guard let object = object else { return }
        
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
        
        frame.origin.y = -contentInset.top + UIApplication.sharedApplication().statusBarFrame.size.height
        
        if distanceOffset.y < -threshold {
            startRefresh()
        }
        
        print("keyPath: \(keyPath)")
        print("object: \(object)")
        print("change: \(change)")
        print("END-------")
        print("distanceOffset: \(distanceOffset)")
    }
    
    private func startRefresh() {
        if state == .Loading { return }
        state = .Loading
        refreshedHandler?(refresher: self)
    }
    
    private func endRefresh() {
        if state == .None { return }
        state = .None
        refreshedHandler?(refresher: self)
    }
    
    public func addRefreshHandler(handler: SmartRefresherRefreshHandler) {
        refreshedHandler = handler
    }
}
