//
//  ViewController.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

final class ViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var items = ["initial"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        
        let refresher = SmartRefresher()
        refresher.addEventHandler { [weak self] (event) -> Void in
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
        tableView.smr_addSmartRefresher(refresher)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let text = items[indexPath.row]
        let cell: UITableViewCell
        if let dequeueCell = tableView.dequeueReusableCellWithIdentifier("Cell") {
            cell = dequeueCell
        } else {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        cell.textLabel?.text = text
        return cell
    }
    
    func updateItems() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] () -> Void in
            
            // Time spendig task. Ex. Gettings items from server
            NSThread.sleepForTimeInterval(3.0)
            
            // Task finished:
            dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
                guard let s = self else { return }
                let text = "\(NSDate())"
                s.items.append(text)
                s.tableView.reloadData()
                s.tableView.smr_endRefreshing()
            }
        }
    }
}

