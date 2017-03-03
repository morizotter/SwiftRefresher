# SwiftRefresher

[![Version](https://img.shields.io/cocoapods/v/SwiftRefresher.svg?style=flat)](http://cocoadocs.org/docsets/SwiftRefresher) [![License](https://img.shields.io/cocoapods/l/SwiftRefresher.svg?style=flat)](http://cocoadocs.org/docsets/SwiftRefresher) [![Platform](https://img.shields.io/cocoapods/p/SwiftRefresher.svg?style=flat)](http://cocoadocs.org/docsets/SwiftRefresher)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/morizotter/SwiftRefresher)

**SwiftRefresher** solves your problem on UIRefreshControl on UITableView in UIViewController!  **SwiftRefresher** is one of the alternatives of UIRefreshControl. Moreover, it is very customizable!

![refresher.gif](refresher.gif)

##Features

- Simple and easy to use.
- Customize loading view whatever you want.

## Usage

### Basic

Add codes below and add it to UITableView with `srf_addRefresher`. The closure will be called when refresh starts.

```Swift
let refresher = RefresherView { [weak self] () -> Void in
    self?.updateItems()
}
tableView.srf_addRefresher(refresher)
```

And call `srf_endRefreshing()` whenever/wherever your refreshing task finished.

```Swift
s.tableView.srf_endRefreshing()
```

### Use with a little Customize

The view of SwiftRefresher is independent from its main system. The only requirement is to conform to `SwfitRefresherEventReceivable` protocol. Default view is `SimpleRefreshView`. You can use it with a little customization like this below:

```Swift
let refresher = Refresher { [weak self] () -> Void in
    self?.updateItems()
}
refresher.createCustomRefreshView { () -> SwfitRefresherEventReceivable in
    return SimpleRefreshView(activityIndicatorViewStyle: .White)
}
tableView.srf_addRefresher(refresher)
```

In this example, I changed SimpleRefreshView's activityIndicatorViewStyle to .White. But you can customize more with create your own refreh view!

### Customize!!!

Just create a view with conforming to `SwfitRefresherEventReceivable`. `SwfitRefresherEventReceivable` has one required function `func didReceiveEvent(event: SwiftRefresherEvent)`. Through this function, refresher send the view the events. The events are below:

```Swift
public enum SwiftRefresherEvent {
    case Pull(offset: CGPoint, threshold: CGFloat)
    case StartRefreshing
    case EndRefreshing
    case RecoveredToInitialState
}
```

For example, preset SimpleRefreshView has this easy codes.

```Swift
public func didReceiveEvent(event: SwiftRefresherEvent) {
    switch event {
    case .Pull:
        pullingImageView.hidden = false
    case .StartRefreshing:
        pullingImageView.hidden = true
        activityIndicatorView.startAnimating()
    case .EndRefreshing:
        activityIndicatorView.stopAnimating()
    case .RecoveredToInitialState:
        break
    }
}
```

`RecoveredToInitialState` means that after EndRefreshing, the view will go back to initial state. And then the state becamed to the initial, this event will be called.

##Runtime Requirements

- iOS8.1 or later
- Xcode 8.0 or later
- Swift 3.0 or later

## Installation and Setup

### Installing with Carthage

Just add to your Cartfile:

```ogdl
github "morizotter/SwiftRefresher"
```

###Installing with CocoaPods

[CocoaPods](http://cocoapods.org) is a centralised dependency manager that automates the process of adding libraries to your Cocoa application. You can install it with the following command:

```bash
$ gem update
$ gem install cocoapods
$ pods --version
```

To integrate SwiftRefresher into your Xcode project using CocoaPods, specify it in your `Podfile` and run `pod install`.

```bash
platform :ios, '8.1'
use_frameworks!
pod "SwiftRefresher", '~>0.9.0'
```

### Manual Installation

To install SwiftRefresher without a dependency manager, please add all of the files in `/SwiftRefresher` to your Xcode Project.

## Contribution

Please file issues or submit pull requests for anything you’d like to see! We're waiting! :)

## License
SwiftRefresher is released under the MIT license. Go read the LICENSE file for more information.
