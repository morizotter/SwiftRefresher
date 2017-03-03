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
        
        let refresher = Refresher { [weak self] () -> Void in
            self?.updateItems()
        }
        tableView.srf_addRefresher(refresher)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let text = items[indexPath.row]
        let cell: UITableViewCell
        if let dequeueCell = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = dequeueCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        cell.textLabel?.text = text
        return cell
    }
    
    func updateItems() {
        DispatchQueue.global().async { [weak self] in
            // Time spendig task. Ex. Gettings items from server
            Thread.sleep(forTimeInterval: 3.0)
            
            // Task finished:
            DispatchQueue.main.async { [weak self] in
                guard let s = self else { return }
                let text = "\(NSDate())"
                s.items.append(text)
                s.tableView.reloadData()
                s.tableView.srf_endRefreshing()
            }
        }
    }
}

