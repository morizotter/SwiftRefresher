# SimpleRefresher

:seedling: This is Experimental. Breaking change will be done.

![refresher.gif](refresher.gif)

```Swift
let refresher = RefresherView { [weak self] () -> Void in
    self?.updateItems()
}
tableView.smr_addRefresher(refresher)
```
