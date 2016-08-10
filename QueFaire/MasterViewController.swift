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

class MasterViewController: UITableViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var titleButton: UIButton!
//    var detailViewController: DetailViewController? = nil
    struct Activities {
        var name: String?
        var description: String?
        
    }
    var objects = [AnyObject]()
    var loadingData = false
    var refreshPage:Int = 0
    var univers: (id: Int, name: String, type: String) = (0, "Tous", "tag")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.navigationItem.leftBarButtonItem = self.editButtonItem()
//
//        let addButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: #selector(insertNewObject(_:)))
//        self.navigationItem.rightBarButtonItem = addButton
//        self.title = "Cette semaine"
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
//            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.fetchData), forControlEvents: UIControlEvents.ValueChanged)

        self.titleButton.transform = CGAffineTransformScale(self.titleButton.transform, -1.0, 1.0);
        self.titleButton.titleLabel!.transform = CGAffineTransformScale(self.titleButton.titleLabel!.transform, -1.0, 1.0);
        self.titleButton.imageView!.transform = CGAffineTransformScale(self.titleButton.imageView!.transform, -1.0, 1.0);

        
        self.fetchData()
        
    }
    
    
    
    func fetchData() -> Void {
        let otherType = self.univers.type == "cid" ? "tag" : "cid"
        let start = NSDate().timeIntervalSince1970
        let daysToAdd: Double = 7.0;
        let end = NSDate().dateByAddingTimeInterval(60*60*24*daysToAdd).timeIntervalSince1970

//        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&cid=0&tag=1&created=0&start=1463402576&end=1463402576&offset=0&limit=10&created=1468091400"
        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&\(otherType)=&\(self.univers.type)=\(String(self.univers.id))&created=&start=\(start)&end=\(end)&offset=\(self.refreshPage)&limit=10"
//        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&cid=0&tag=1&created=0&start=1483228800&end=1483228800&offset=0&limit=10"
        print(stringRequest)
        Alamofire.request(.GET, stringRequest, parameters: nil)
            .responseJSON { response in
                if let JSON = response.result.value {
                    self.objects += JSON.objectForKey("data") as! [AnyObject]
                    self.refreshPage += 10
                    self.loadingData = false
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
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
    
    
    func insertNewObject(sender: AnyObject) {
        //self.presentViewController(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: <#T##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
//        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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

//                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
//                controller.navigationItem.leftItemsSupplementBackButton = true
            } else if let indexPath = Int((sender?.annotation!?.subtitle)!) {
                let object = objects[indexPath]["idactivites"]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ActivityViewController
                controller.detailItem = object as? Int
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
        let small_description = object["small_description"] as? String
        var discipline: String = ""
        if (object["discipline"] == nil) {
            discipline = object["discipline"] as! String
        }
        var nomLabel = (cell.contentView.viewWithTag(102) as! MDHTMLLabel)
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

        var files = object["files"] as? [[String:String]] ?? object["media"] as? [[String:String]]
        var path = "file"
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
                let originalUrl = "original__\(name)"
                let optiUrl = "x\(Int(self.tableView.frame.size.width))_\(name)"
                let urlWithoutName = link.stringByReplacingOccurrencesOfString(name, withString: "")
                let finalUrl = "http://filer.paris.fr/\(urlWithoutName)\(optiUrl)"
            }
            
            let URL = NSURL(string: "http://filer.paris.fr/\(surl)")!
            let placeholderImage = UIImage(named: "placeholder")!
            (cell.contentView.viewWithTag(101) as! UIImageView).af_setImageWithURL(URL, placeholderImage: placeholderImage)
            //http://filer.paris.fr/quefaire/fiches/6/2/4/d/original__624d-viktor2010-27ph--jochen-viehoff.jpg
        }
        
        
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if !loadingData && indexPath.row == refreshPage - 1 {
//            spinner.startAnimating()
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
//                self.spinner.stopAnimating()
            }
        }
    }
    
    @IBAction func cancelToMaster(segue:UIStoryboardSegue) {
    }
    
    @IBAction func filterMaster(segue:UIStoryboardSegue) {
        if let universViewController = segue.sourceViewController as? UniversViewController {
            guard universViewController.univers != nil else { return }
            self.univers = universViewController.univers!
            self.title = "Cette semaine > \(self.univers.1)"
            self.refreshPage = 0
            self.objects.removeAll()
            self.tableView.reloadData()
            self.fetchData()
        }
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

}

