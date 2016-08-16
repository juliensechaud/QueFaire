//
//  ActivityViewController.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 09/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import MDHTMLLabel
import MapKit
import EventKit
import SafariServices
import EventKitUI

class ActivityViewController: UITableViewController, MDHTMLLabelDelegate, CLLocationManagerDelegate, SFSafariViewControllerDelegate, EKEventEditViewDelegate {
    
    var manager: CLLocationManager!
    var location: CLLocation!
    var eventStore = EKEventStore()
    var calendars: [EKCalendar]?
    var idActivity: Int = 0
    var savedEventId : String = ""
    
    let refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

    var occurences: [[String:String]] = []
    var activity: [String:AnyObject] = [:] {
        didSet {
            // Update the tableView.
            let nom = activity["nom"] as? String
            self.title = nom?.htmlToString.htmlToString
            if let occurencesA = activity["occurences"] as? [[String:String]] {
                self.occurences = occurencesA.filter({ (occurence) -> Bool in
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    dateFormatter.locale = NSLocale(localeIdentifier: "fr_FR")
                    
                    guard let date = dateFormatter.dateFromString(occurence["jour"]!) else {
                        assert(false, "no date from string")
                        return false
                    }
                    if date.numberOfDaysUntilDateTime(NSDate()) < 3 && date.numberOfDaysUntilDateTime(NSDate()) > -1000000 {
                        return true
                    } else {
                        return false
                    }
                }).reverse()
            }
            self.tableView.reloadData()
        }
    }
    
    var detailItem: Int? {
        didSet {
            // Fetch data
            self.tableView.estimatedRowHeight = 44
            self.tableView.rowHeight = UITableViewAutomaticDimension
//            self.tableView.allowsSelection = false
            self.idActivity = detailItem!
            self.fetchActivity(detailItem!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CLLocationManager()
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(ActivityViewController.fetchActivity(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView.backgroundView = refreshActivity
        refreshActivity.startAnimating()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
        
    func insertEvent(dateS: String) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.locale = NSLocale(localeIdentifier: "fr_FR")
        
        let calendar = NSCalendar.currentCalendar()
        let date = dateFormatter.dateFromString(dateS)
        let components = calendar.components([.Year, .Month, .Day], fromDate: date!)
        
        let reminder = EKReminder(eventStore: self.eventStore)
        reminder.title = self.activity["nom"] as! String
        let address = self.activity["adresse"] as! String
        let zipcode = String(self.activity["zipcode"] as! Int)
        let city = self.activity["city"] as! String
        reminder.location = "\(address) \(zipcode) \(city)"
        let dueDateComponents = components
        reminder.dueDateComponents = dueDateComponents
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        // 2
        do {
            try self.eventStore.saveReminder(reminder, commit: true)
            dismissViewControllerAnimated(true, completion: nil)
        }catch{
            print("Error creating and saving new reminder : \(error)")
        }
    }
    
    
    func fetchActivity(id: Int) {
        let idF = id ?? self.idActivity
        let stringRequest = "https://api.paris.fr/api/data/1.5/QueFaire/get_activity/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&id=\(String(idF))"
        print(stringRequest)
        Alamofire.request(.GET, stringRequest, parameters: nil)
            .responseJSON { response in
                    if let JSON = response.result.value {
                        let data = JSON["data"] as! [[String:AnyObject]]
                        if data.count > 0 {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.activity = data[0]
                                self.refreshControl?.endRefreshing()
                            }
                        }
                    }
        }
    }
    
    func buildPicUrl() -> NSURL {
        var files = self.activity["media"] as? [[String:String]]
        var path = "path"
        var finalUrl = ""
        var surl: String = ""
        
        if files == nil {
            files = self.activity["files"] as? [[String:String]]
            path = "file"
        }
        
        if files != nil {
            for file in files! {
                if file[path] != nil {
                    let url: String = file[path]!
                    if (url.containsString("quefaire/fiches"))  {
                        surl = url
                    }
                }
            }
            let link = surl
            if let name = link.componentsSeparatedByString("/").last {
                let optiUrl = "x\(Int(self.tableView.frame.size.width))_\(name)"
                let urlWithoutName = link.stringByReplacingOccurrencesOfString(name, withString: "")
                finalUrl = "\(urlWithoutName)\(optiUrl)"
            }
        }
        
        return NSURL(string: finalUrl)!

    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 + (self.occurences.count > 0 ? 1 : 0)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var number: Int = 0
        switch section {
        case 0:
            number = self.activity.count != 0 ? 6 : 0
        case 1:
            number = self.occurences.count != 0 ? self.occurences.count+1 : 0
        default:
            0
        }
        return number
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 4 {
            let nom = (self.activity["nom"] as! String)+"+"+(self.activity["lieu"] as! String)
            let search = nom.stringByReplacingOccurrencesOfString(" ", withString: "+")
            
            guard let url = NSURL(string: "https://www.google.fr/search?q=\(search)") else { return }
            let sf = SFSafariViewController(URL: url)
            sf.delegate = self
            
            self.presentViewController(sf, animated: true, completion: nil)
            
        } else if (indexPath.section == 1) {
            addEvent(self.occurences[indexPath.row-1])
        }
    }
    
    func addEvent(occurence: [String:String]) {
        let eventStore = EKEventStore()
        
        guard occurence["jour"] != nil &&
            occurence["hour_start"] != nil &&
            occurence["hour_end"] != nil else { return }
        
        let start = occurence["jour"]?.stringByReplacingOccurrencesOfString("00:00:00", withString: occurence["hour_start"]!)
        let end = occurence["jour"]?.stringByReplacingOccurrencesOfString("00:00:00", withString: occurence["hour_end"]!)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.locale = NSLocale.currentLocale()
        let startDate = dateFormatter.dateFromString(start!)
        let endDate = dateFormatter.dateFromString(end!)
        
        let nom = activity["nom"] as? String

        if (EKEventStore.authorizationStatusForEntityType(.Event) != EKAuthorizationStatus.Authorized) {
            eventStore.requestAccessToEntityType(.Event, completion: {
                granted, error in
                self.createEvent(eventStore, title: nom!.htmlToString, startDate: startDate!, endDate: endDate!)
            })
        } else {
            createEvent(eventStore, title: nom!.htmlToString, startDate: startDate!, endDate: endDate!)
        }
    }
    
    // Creates an event in the EKEventStore. The method assumes the eventStore is created and
    // accessible
    func createEvent(eventStore: EKEventStore, title: String, startDate: NSDate, endDate: NSDate) {
        let event = EKEvent(eventStore: eventStore)
        let nom = self.activity["nom"] as? String
        event.title = nom!
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents

        let ev = EKEventEditViewController()
        ev.editViewDelegate = self
        ev.eventStore = eventStore
        ev.event = event
        self.presentViewController(ev, animated: true, completion: nil)
//        do {
//            try eventStore.saveEvent(event, span: .ThisEvent)
//            savedEventId = event.eventIdentifier
//        } catch {
//            print("Bad things happened")
//        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        if indexPath.section == 0 {
            let hasFee = self.activity["hasFee"] as! String
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCellWithIdentifier("imageCell", forIndexPath: indexPath)
                cell.selectionStyle = .None
                (cell.contentView.viewWithTag(101) as! UIImageView).af_setImageWithURL(self.buildPicUrl(), placeholderImage: UIImage(named: "placeholder")!)
                break
            case 1:
                cell = tableView.dequeueReusableCellWithIdentifier("titleCell", forIndexPath: indexPath)
                cell.selectionStyle = .None
                var nom = self.activity["nom"] as! String
                nom.capitalizeFirstLetter()
                var lieu = self.activity["lieu"] as! String
                lieu.capitalizeFirstLetter()
                (cell.contentView.viewWithTag(101) as! MDHTMLLabel).htmlText = nom.htmlToString.htmlToString
                (cell.contentView.viewWithTag(102) as! MDHTMLLabel).htmlText = lieu.htmlToString.htmlToString
                (cell.contentView.viewWithTag(103) as! MDHTMLLabel).textInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
                if hasFee == "0" {
                    (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Gratuit".htmlToString.htmlToString
                } else {
                    (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Payant".htmlToString.htmlToString
                    (cell.contentView.viewWithTag(103) as! MDHTMLLabel).backgroundColor = UIColor.whiteColor()
                }
                break
            case 2:
                cell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath)
                cell.selectionStyle = .None
                let lat : CLLocationDegrees = self.activity["lat"] as! Double
                let lon : CLLocationDegrees = self.activity["lon"] as! Double
                let location = self.location ?? CLLocation(latitude: lat, longitude: lon)
                let distance = location.distanceFromLocation(CLLocation(latitude: lat, longitude: lon))/1000
                (cell.contentView.viewWithTag(101) as! MDHTMLLabel).htmlText = String(format:"%.1f km", distance)
                if hasFee == "1" {
                    if let prix = self.activity["prix"] as? String {
                        (cell.contentView.viewWithTag(102) as! MDHTMLLabel).htmlText = prix.htmlToString.htmlToString.capitalizedString
                    } else {
                        (cell.contentView.viewWithTag(102) as! MDHTMLLabel).htmlText = "Prix NC"
                    }
                }
                
                if self.activity["metro"] != nil {
                    let metro = self.activity["metro"] as! String
                    let label: MDHTMLLabel = (cell.contentView.viewWithTag(103) as! MDHTMLLabel)
                    label.htmlText = metro.htmlToString.htmlToString.capitalizedString
                }
                break
            case 3:
                cell = tableView.dequeueReusableCellWithIdentifier("descriptionCell", forIndexPath: indexPath)
                cell.selectionStyle = .None
                var description = ""
                if self.activity["accessType"] != nil {
                    description += self.activity["accessType"] as! String
                }
                if self.activity["description"] != nil {
                    description += self.activity["description"] as! String
                }
                if self.activity["price"] != nil {
                    description += self.activity["price"] as! String
                }
                let label: MDHTMLLabel = (cell.contentView.viewWithTag(101) as! MDHTMLLabel)
                label.highlightedShadowColor = UIColor.grayColor()
                
                label.activeLinkAttributes = [NSBackgroundColorAttributeName:UIColor.grayColor()]

                label.delegate = self
                label.htmlText = description.htmlToString.htmlToString
                break
            case 4:
                cell = tableView.dequeueReusableCellWithIdentifier("googleCell", forIndexPath: indexPath)
                cell.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
                cell.textLabel?.text = "Lancer une recherche sur le sujet"
                break
            case 5:
                cell = tableView.dequeueReusableCellWithIdentifier("mapCell", forIndexPath: indexPath)
                cell.selectionStyle = .None
                let mapView = (cell.contentView.viewWithTag(101) as! MKMapView)
                self.createMap(mapView)
                let address = self.activity["adresse"] as! String
                let zipcode = String(self.activity["zipcode"] as! Int)
                let city = self.activity["city"] as! String
                let addressLabel = (cell.contentView.viewWithTag(102) as! MDHTMLLabel)
                addressLabel.htmlText = "\(address) \(zipcode) \(city)".htmlToString.htmlToString
                
                break
            default:
                break
                
            }
        } else {
            if indexPath.row == 0 {
                cell.textLabel?.font = UIFont(name: "Avenir-Black", size: 14)
                cell.textLabel?.text = "Horaires"
            } else {
                let (jour, today) = self.convertDateFormater(self.occurences[indexPath.row-1]["jour"]!)
                let start = self.occurences[indexPath.row-1]["hour_start"]!.stringByReplacingOccurrencesOfString(":00:00", withString: "h").stringByReplacingOccurrencesOfString(":00", withString: "").stringByReplacingOccurrencesOfString(":", withString: "h")
                let end = self.occurences[indexPath.row-1]["hour_end"]!.stringByReplacingOccurrencesOfString(":00:00", withString: "h").stringByReplacingOccurrencesOfString(":00", withString: "").stringByReplacingOccurrencesOfString(":", withString: "h")
                if today {
                    cell.backgroundColor = UIColor.groupTableViewBackgroundColor()
                }
                cell.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
                cell.textLabel?.text = "\(jour) de \(start) à \(end)"

            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    func createMap(mapView: MKMapView) {
        let location = CLLocationCoordinate2DMake((self.activity["lat"] as? Double)!, (self.activity["lon"] as? Double)!)
        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = location
        dropPin.title = self.activity["lieu"] as? String
        mapView.addAnnotation(dropPin)
        mapView.centerCoordinate = location

        let viewRegion: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(location, 500, 500);
        let adjustedRegion: MKCoordinateRegion = mapView.regionThatFits(viewRegion)
        mapView.setRegion(adjustedRegion, animated: true)
    }
    
    func HTMLLabel(label: MDHTMLLabel!, didSelectLinkWithURL URL: NSURL!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        vc.url = URL
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func convertDateFormater(date: String) -> (String, Bool) {
        let dateFormatter = NSDateFormatter()
        var today: Bool = false
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.locale = NSLocale(localeIdentifier: "fr_FR")
        
        guard let date = dateFormatter.dateFromString(date) else {
            assert(false, "no date from string")
            return ("", today)
        }
        
        if NSDate().numberOfDaysUntilDateTime(date) < 7 && NSDate().numberOfDaysUntilDateTime(date) > -1 {
            today = true
        }
        
        dateFormatter.dateFormat = "EE dd MMM yyyy"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        let timeStamp = dateFormatter.stringFromDate(date)
        
        return (timeStamp, today)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations[0]
    }
    
    //MARK: EKEventEditViewDelegate
    
    func eventEditViewController(controller: EKEventEditViewController, didCompleteWithAction action: EKEventEditViewAction) {
        controller.dismissViewControllerAnimated(true, completion: {
            if action == .Saved {
                let nom = self.activity["nom"] as? String
                let alert = UIAlertController(title: nom, message: "L'événement a bien été ajouté à votre calendrier", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Destructive, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
}

extension NSDate {
    func numberOfDaysUntilDateTime(toDateTime: NSDate, inTimeZone timeZone: NSTimeZone? = nil) -> Int {
        let calendar = NSCalendar.currentCalendar()
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        
        var fromDate: NSDate?, toDate: NSDate?
        
        calendar.rangeOfUnit(.Day, startDate: &fromDate, interval: nil, forDate: self)
        calendar.rangeOfUnit(.Day, startDate: &toDate, interval: nil, forDate: toDateTime)
        
        let difference = calendar.components(.Day, fromDate: fromDate!, toDate: toDate!, options: [])
        return difference.day
    }
}


