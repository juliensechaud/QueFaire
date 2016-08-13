//
//  UniversViewController.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 10/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit
import Alamofire

class UniversViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var univers: (Int, String, String)?
    var refreshControl: UIRefreshControl?
    var objects = [[String: AnyObject]]()
    var type: String = "get_univers"
    
    let refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    var selectedIndexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = UIColor.darkGrayColor()
        cancelButton.setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir-Roman", size: 14)!], forState: .Normal)
        filterButton.setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir-Roman", size: 14)!], forState: .Normal)
        self.fetchData(type)
        self.tableView.tableFooterView = UIView()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(self.fetchData(_:)), forControlEvents: UIControlEvents.ValueChanged)
//        self.tableView.addSubview(self.refreshControl!)
        
        self.tableView.backgroundView = refreshActivity
        refreshActivity.startAnimating()

    }
    
    
    func fetchData(type: String) -> Void {
        let _ = type ?? self.type
        let stringRequest = "https://api.paris.fr/api/data/1.0/QueFaire/\(type)/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914"
        print(stringRequest)
        Alamofire.request(.GET, stringRequest, parameters: nil)
            .responseJSON { response in
                if let JSON = response.result.value {
                    guard let data = JSON.objectForKey("data") as? [[String: AnyObject]] else {return}
                    self.objects.append(["id":0,"name":"Tous"])
                    self.objects += data
                    self.tableView.reloadData()
                }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.objects.count > 0 ? self.objects.count : 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
        cell.textLabel?.text = self.objects[indexPath.row]["name"] as? String
        if self.objects[indexPath.row]["id"] as? Int == univers?.0 {
            selectedIndexPath = indexPath
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let object = self.objects[indexPath.row]
        let type = self.segmentedControl.selectedSegmentIndex == 0 ? "tag" : "cid"
        self.univers = (object["id"] as! Int, object["name"] as! String, type)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.selectRowAtIndexPath(self.selectedIndexPath, animated: true, scrollPosition: .None)
    }

    @IBAction func changeListing(sender: AnyObject) {
        let seg = sender as! UISegmentedControl
        switch seg.selectedSegmentIndex {
        case 0:
            self.type = "get_univers"
        default:
            self.type = "get_categories"
        }
        self.fetchData(self.type)
        self.objects.removeAll()
    }
    
    
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "FilterMaster" {
//            player = Player(name: nameTextField.text!, game: "Chess", rating: 1)
//        }
//    }
}
