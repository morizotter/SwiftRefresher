# SimpleRefresher
Experimental

![refresher.gif](refresher.gif)

```Swift
let refresher = SimpleRefresher { [weak self] (event) -> Void in
    switch event {
    case .StartRefreshing:
        print("REFRESH: START")
        self?.updateItems()
    case .EndRefreshing:
        print("REFRESH: END")
    case .Pulling(let offset, let threshold):
        print("pulling\(offset), threshold: \(threshold)")
        break
    }
}
tableView.smr_addRefresher(refresher)
```
