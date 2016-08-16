//
//  MasterViewController.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 15/05/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import MDHTMLLabel
import MapKit
import Kingfisher


class MasterViewController: UITableViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var timeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleButton: UIButton!
    struct Activities {
        var name: String?
        var description: String?
        
    }
    let refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    var timeRefreshing: Bool = false
    var daysToAdd: Double = 7.0;
    var objects = [AnyObject]()
    var loadingData = false
    var refreshPage:Int = 0
    var univers: (id: Int, name: String, type: String) = (1, "Enfant", "tag")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let split = self.splitViewController {
            _ = split.viewControllers
        }
        
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.fetchData), forControlEvents: UIControlEvents.ValueChanged)

        self.titleButton.transform = CGAffineTransformScale(self.titleButton.transform, -1.0, 1.0);
        self.titleButton.titleLabel!.transform = CGAffineTransformScale(self.titleButton.titleLabel!.transform, -1.0, 1.0);
        self.titleButton.imageView!.transform = CGAffineTransformScale(self.titleButton.imageView!.transform, -1.0, 1.0);

        self.tableView.tableHeaderView = headerView
        timeSegmentedControl.tintColor = UIColorFromRGB(0xEFEFF4)
        timeSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGrayColor()], forState: .Normal)
        timeSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.blackColor()], forState: .Selected)
        
        self.fetchData()
        
        self.tableView.backgroundView = refreshActivity
        refreshActivity.startAnimating()

    }
    
    func fetchData() -> Void {
        let otherType = self.univers.type == "cid" ? "tag" : "cid"
        let start = NSDate().timeIntervalSince1970
        let end = NSDate().dateByAddingTimeInterval(60*60*24*daysToAdd).timeIntervalSince1970

        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&\(otherType)=&\(self.univers.type)=\(String(self.univers.id))&created=&start=\(start)&end=\(end)&offset=\(self.refreshPage)&limit=10"
        
        print(stringRequest)
        
        Alamofire.request(.GET, stringRequest, parameters: nil)
            .responseJSON { response in
                if let JSON = response.result.value {
                    guard let data = JSON.objectForKey("data") as? [AnyObject] else {
                        return
                    }
                    self.objects += data
                    self.refreshPage += 10
                    self.loadingData = false
                    dispatch_async(dispatch_get_main_queue()) {
                        if self.timeRefreshing {
                            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
                            self.timeRefreshing = false
                        } else {
                            self.tableView.reloadData()
                        }
                        self.refreshControl?.endRefreshing()
                    }
                } else {
                    
                }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let aVariable = appDelegate.deeplink
        if aVariable == true {
            self.performSegueWithIdentifier("showDetail", sender: appDelegate)
        }

    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]["idactivites"]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ActivityViewController
                controller.detailItem = object as? Int
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed

//            } else if let indexPath = Int((sender?.annotation!?.subtitle)!) {
//                let object = objects[indexPath]["idactivites"]
//                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ActivityViewController
//                controller.detailItem = object as? Int
//                let backItem = UIBarButtonItem()
//                backItem.title = ""
//                navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
//                
            } else if sender is AppDelegate {
                let object = Int((sender as! AppDelegate).idDeeplink)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ActivityViewController
                controller.detailItem = object
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
            }
        } else if segue.identifier == "showMap" {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! MapViewController
            controller.objects = self.objects
            controller.context = (self.univers, self.objects)
        } else if segue.identifier == "TimeChoice" {
            let controller = segue.destinationViewController
            controller.popoverPresentationController?.sourceRect = self.titleButton.frame
            controller.popoverPresentationController?.sourceView = self.titleButton
            controller.popoverPresentationController?.permittedArrowDirections = .Up
            controller.popoverPresentationController?.delegate = self
        }
    }
    
    func prepareActivitySegue() {
        
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let object = objects[indexPath.row]
        var nom = object["nom"] as! String
        nom.capitalizeFirstLetter()
        let lieu = object["lieu"] as! String
        let nomLabel = (cell.contentView.viewWithTag(102) as! MDHTMLLabel)
        nomLabel.htmlText = nom.htmlToString.htmlToString
        
        let hasFee = object["hasFee"] as? String
        (cell.contentView.viewWithTag(103) as! MDHTMLLabel).textInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        if hasFee == "0" {
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Gratuit".htmlToString.htmlToString
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).backgroundColor = UIColorFromRGB(0xbdf5c8)
        } else {
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Payant".htmlToString.htmlToString
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).backgroundColor = UIColor.whiteColor()
        }
        
        (cell.contentView.viewWithTag(104) as! MDHTMLLabel).htmlText = lieu.htmlToString.htmlToString

        let files = object["files"] as? [[String:String]] ?? object["media"] as? [[String:String]]
        _ = "file"
        var surl: String = ""
        if files != nil {
            for file in files! {
                let url: String = file["file"] ?? file["path"]!
                if (url.containsString("quefaire/fiches"))  {
                    surl = url
                }
            }
            let link = surl
            if let name = link.componentsSeparatedByString("/").last {
                _ = "original__\(name)"
                let optiUrl = "x\(Int(self.tableView.frame.size.width))_\(name)"
                let urlWithoutName = link.stringByReplacingOccurrencesOfString(name, withString: "")
                _ = "http://filer.paris.fr/\(urlWithoutName)\(optiUrl)"
            }
            
            let URL = NSURL(string: "http://filer.paris.fr/\(surl)")!
            let placeholderImage = UIImage(named: "placeholder")!
            (cell.contentView.viewWithTag(101) as! UIImageView).kf_setImageWithURL(NSURL(string: "http://filer.paris.fr/\(surl)")!, placeholderImage: placeholderImage)
        }
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if !loadingData && indexPath.row == refreshPage - 1 {
            loadingData = true
            refreshResults2()
        }
    }
    
    @IBAction func timeChoice(sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: "Quelle période ?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cette semaine", style: .Default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Ajourd'hui", style: .Default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Ce week-end", style: .Default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Annuler", style: .Destructive, handler: { (action) in
            
        }))

        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func refreshResults2() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            // this runs on the background queue
            // here the query starts to add new 40 rows of data to arrays
            
            dispatch_async(dispatch_get_main_queue()) {
                // this runs on the main queue
                self.fetchData()
            }
        }
    }
    
    @IBAction func cancelToMaster(segue:UIStoryboardSegue) {
    }
    
    @IBAction func filterMaster(segue:UIStoryboardSegue) {
        if let universViewController = segue.sourceViewController as? UniversViewController {
            guard universViewController.univers != nil else { return }
            self.univers = universViewController.univers!
            self.title = "\(self.univers.1)"
            self.refreshPage = 0
            self.objects.removeAll()
            self.tableView.reloadData()
            self.fetchData()
        }
        guard let container = self.parentViewController as? ContainerViewController else { return }
        container.buildTitleView()
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func refreshTime(time: Double) {
        self.daysToAdd = time
        self.refreshPage = 0
        self.objects.removeAll()
        self.tableView.reloadData()
        timeRefreshing = true
        self.fetchData()
    }
    @IBAction func timeSelected(sender: AnyObject) {
        switch sender.selectedSegmentIndex {
        case 0:
            refreshTime(7)
        case 1:
            refreshTime(0)
        case 2:
            refreshTime(2)
        default:
            break;
        }
    }
    
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

}


extension String {
    var htmlToString:String {
        do {
            let string = try NSAttributedString(data: dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
            return string.string
        } catch {
            print("Error while parsing")
            return String()
        }
    }
    var htmlToNSAttributedString:NSAttributedString {
        do {
            let string = try NSAttributedString(data: dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
            return string
        } catch {
            print("Error while parsing")
            return NSAttributedString()
        }
    }
}

