//
//  SimpleRefresher.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public extension UIScrollView {
    public func smr_addRefresher(refresher: SimpleRefresher) {
        insertSubview(refresher, atIndex: 0)
        refresher.setup(self)
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
    
    private func smr_findRefreshers() -> [SimpleRefresher]? {
        return subviews.filter { $0 is SimpleRefresher }.flatMap { $0 as? SimpleRefresher }
    }
}

public enum SimpleRefresherState {
    case None
    case Loading
}

public enum SimpleRefresherEvent {
    case Pulling(offset: CGPoint, threshold: CGFloat)
    case StartRefreshing
    case EndRefreshing
}

public typealias SimpleRefresherEventHandler = ((event: SimpleRefresherEvent) -> Void)
public typealias SimpleRefresherConfigureHandler = ((refresher: SimpleRefresher) -> Void)

private let DEFAULT_HEIGHT: CGFloat = 44.0

public class SimpleRefresher: UIView {
    
    public var state: SimpleRefresherState { return stateInternal }
    public var useActivityIndicatorView: Bool = true
    public var activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
    public var pullingImageView = UIImageView(frame: CGRect.zero)
    
    private var stateInternal = SimpleRefresherState.None
    private var eventHandler: SimpleRefresherEventHandler?
    private var configureHandler: SimpleRefresherConfigureHandler?
    private var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private var contentOffset = CGPoint.zero
    private var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    private weak var activityIndicatorView: UIActivityIndicatorView!
    private var recoveringInitialState: Bool = false
    
    public var height: CGFloat = DEFAULT_HEIGHT
    
    deinit {
        if let scrollView = superview as? UIScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            scrollView.removeObserver(self, forKeyPath: "contentInset", context: nil)
        }
    }
    
    public func setup(scrollView: UIScrollView?) {
        let origin = CGPoint(x: 0.0, y: -height)
        let size = CGSize(width: UIScreen.mainScreen().bounds.width, height: height)
        frame = CGRect(origin: origin, size: size)
        clipsToBounds = true
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorViewStyle)
        activityIndicatorView.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        activityIndicatorView.hidesWhenStopped = true
        addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        
        let imageSize = CGSize(width: height / 2.0, height: height / 2.0)
        pullingImageView.frame = CGRect(origin: CGPoint.zero, size: imageSize)
        pullingImageView.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        pullingImageView.contentMode = .ScaleAspectFit
        if let imagePath = NSBundle(forClass: SimpleRefresher.self).pathForResource("pull", ofType: "png") {
            pullingImageView.image = UIImage(contentsOfFile: imagePath)
        }
        addSubview(pullingImageView)
        
//        pullingImageView.backgroundColor = .redColor()
//        backgroundColor = .blueColor()
        configureHandler?(refresher: self)
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
            pullingImageView.hidden = true
        case .None:
            if distanceOffset.y >= 0 {
                hidden = true
            } else {
                hidden = false
            }
            
            if recoveringInitialState {
                pullingImageView.hidden = true
            } else {
                pullingImageView.hidden = false
                
                if distanceOffset.y <= 0 {
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
        if useActivityIndicatorView {
            activityIndicatorView.startAnimating()
        }
        pullingImageView.hidden = true
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
    
    public func addEventHandler(handler: SimpleRefresherEventHandler) {
        eventHandler = handler
    }
    
    public func configureRefresher(handler: SimpleRefresherConfigureHandler) {
        configureHandler = handler
    }
}
