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
    
    let refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    var occurences: [[String:String]] = []
    var activity: [String:AnyObject] = [:] {
        didSet {
            // Update the tableView.
            let nom = activity["nom"] as? String
            self.title = nom?.html2String.html2String
            if let occurencesA = activity["occurences"] as? [[String:String]] {
                self.occurences = occurencesA.filter({ (occurence) -> Bool in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = TimeZone(identifier: "UTC")
                    dateFormatter.locale = Locale(identifier: "fr_FR")
                    
                    guard let date = dateFormatter.date(from: occurence["jour"]!) else {
                        assert(false, "no date from string")
                        return false
                    }
                    if date.numberOfDaysUntilDateTime(Date()) < 60 && date.numberOfDaysUntilDateTime(Date()) > -1 {
                        return true
                    } else {
                        return false
                    }
                }).reversed()
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
        self.refreshControl?.addTarget(self, action: #selector(ActivityViewController.fetchActivity(_:)), for: UIControlEvents.valueChanged)
        
        self.tableView.backgroundView = refreshActivity
        refreshActivity.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
        
    func insertEvent(_ dateS: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        let calendar = Calendar.current
        let date = dateFormatter.date(from: dateS)
        let components = (calendar as NSCalendar).components([.year, .month, .day], from: date!)
        
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
            try self.eventStore.save(reminder, commit: true)
            dismiss(animated: true, completion: nil)
        }catch{
            print("Error creating and saving new reminder : \(error)")
        }
    }
    
    
    func fetchActivity(_ id: Int) {
        let idF = id 
        let stringRequest = "https://api.paris.fr/api/data/1.5/QueFaire/get_activity/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&id=\(String(idF))"
        print(stringRequest)
        Alamofire.request(stringRequest, headers: nil)
            .responseJSON { response in
                    if let JSON = response.result.value as? [String:AnyObject] {
                        let data = JSON["data"] as! [[String:AnyObject]]
                        if data.count > 0 {
                            DispatchQueue.main.async {
                                self.activity = self.make(forModel: data[0])
                                self.refreshControl?.endRefreshing()
                            }
                        }
                    }
        }
    }
    
    func make(forModel model: [String: AnyObject]) -> [String: AnyObject] {
        var temp = model
        for key in ["nom", "lieu", "description", "metro", "price", "accessType", "description", "adresse", "zipcode", "city"] {
            if var value = model[key] as? String {
                value.capitalizeFirstLetter()
                value = value.html2String.html2String
                temp[key] = value as AnyObject?
            }
            temp["surl"] = buildPicUrl(forModel: model) as AnyObject?
        }
//            if let files = object["files"] as? [[String:String]] ?? object["media"] as? [[String:String]] {
//                _ = "file"
//                var surl: String = ""
//                for file in files {
//                    let url: String = file["file"] ?? file["path"]!
//                    if (url.contains("quefaire/fiches"))  {
//                        surl = url
//                    }
//                }
//                let link = surl
//                if let name = link.components(separatedBy: "/").last {
//                    _ = "original__\(name)"
//                    let optiUrl = "x\(Int(self.tableView.frame.size.width))_\(name)"
//                    let urlWithoutName = link.replacingOccurrences(of: name, with: "")
//                    _ = "http://filer.paris.fr/\(urlWithoutName)\(optiUrl)"
//                }
//                temp2["surl"] = surl as AnyObject?
//            }
            
        return temp
    }
    
    func buildPicUrl(forModel model: [String: AnyObject]) -> String {
        var files = model["media"] as? [[String:String]]
        var path = "path"
        var finalUrl = ""
        var surl: String = ""
        
        if files == nil {
            files = model["files"] as? [[String:String]]
            path = "file"
        }
        
        if files != nil {
            for file in files! {
                if file[path] != nil {
                    let url: String = file[path]!
                    if (url.contains("quefaire/fiches"))  {
                        surl = url
                    }
                }
            }
            let link = surl
            if let name = link.components(separatedBy: "/").last {
                let optiUrl = "x\(Int(self.tableView.frame.size.width))_\(name)"
                let urlWithoutName = link.replacingOccurrences(of: name, with: "")
                finalUrl = "\(urlWithoutName)\(optiUrl)"
            }
        }
        
        return finalUrl

    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + (self.occurences.count > 0 ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 4 {
            let nom = (self.activity["nom"] as! String)+"+"+(self.activity["lieu"] as! String)
            let search = nom.replacingOccurrences(of: " ", with: "+")
            
            guard let url = URL(string: "https://www.google.fr/search?q=\(search)") else { return }
            let sf = SFSafariViewController(url: url)
            sf.delegate = self
            
            self.present(sf, animated: true, completion: nil)
            
        } else if (indexPath.section == 1) {
            addEvent(self.occurences[indexPath.row-1])
        }
    }
    
    func addEvent(_ occurence: [String:String]) {
        let eventStore = EKEventStore()
        
        guard occurence["jour"] != nil &&
            occurence["hour_start"] != nil &&
            occurence["hour_end"] != nil else { return }
        
        let start = occurence["jour"]?.replacingOccurrences(of: "00:00:00", with: occurence["hour_start"]!)
        let end = occurence["jour"]?.replacingOccurrences(of: "00:00:00", with: occurence["hour_end"]!)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.locale = Locale.current
        let startDate = dateFormatter.date(from: start!)
        let endDate = dateFormatter.date(from: end!)
        
        let nom = activity["nom"] as? String

        if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: {
                granted, error in
                self.createEvent(eventStore, title: nom!.html2String, startDate: startDate!, endDate: endDate!)
            })
        } else {
            createEvent(eventStore, title: nom!.html2String, startDate: startDate!, endDate: endDate!)
        }
    }
    
    // Creates an event in the EKEventStore. The method assumes the eventStore is created and
    // accessible
    func createEvent(_ eventStore: EKEventStore, title: String, startDate: Date, endDate: Date) {
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
        self.present(ev, animated: true, completion: nil)
//        do {
//            try eventStore.saveEvent(event, span: .ThisEvent)
//            savedEventId = event.eventIdentifier
//        } catch {
//            print("Bad things happened")
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        if indexPath.section == 0 {
            let hasFee = self.activity["hasFee"] as! String
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath)
                cell.selectionStyle = .none
                if let surl = self.activity["surl"] as? String, URL(string: surl) != nil {
                    (cell.contentView.viewWithTag(101) as! UIImageView).af_setImage(withURL: URL(string: surl)!, placeholderImage: UIImage(named: "placeholder")!)
                }
                break
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath)
                cell.selectionStyle = .none
                var nom = self.activity["nom"] as! String
                nom.capitalizeFirstLetter()
                var lieu = self.activity["lieu"] as! String
                lieu.capitalizeFirstLetter()
                (cell.contentView.viewWithTag(101) as! MDHTMLLabel).htmlText = nom
                (cell.contentView.viewWithTag(102) as! MDHTMLLabel).htmlText = lieu
                (cell.contentView.viewWithTag(103) as! MDHTMLLabel).textInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
                if hasFee == "0" {
                    (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Gratuit"
                } else {
                    (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Payant"
                    (cell.contentView.viewWithTag(103) as! MDHTMLLabel).backgroundColor = UIColor.white
                }
                break
            case 2:
                cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
                cell.selectionStyle = .none
                let lat : CLLocationDegrees = self.activity["lat"] as! Double
                let lon : CLLocationDegrees = self.activity["lon"] as! Double
                let location = self.location ?? CLLocation(latitude: lat, longitude: lon)
                let distance = location.distance(from: CLLocation(latitude: lat, longitude: lon))/1000
                (cell.contentView.viewWithTag(101) as! MDHTMLLabel).htmlText = String(format:"%.1f km", distance)
                if hasFee == "1" {
                    if let prix = self.activity["prix"] as? String {
                        (cell.contentView.viewWithTag(102) as! MDHTMLLabel).htmlText = prix.capitalized
                    } else {
                        (cell.contentView.viewWithTag(102) as! MDHTMLLabel).htmlText = "Prix NC"
                    }
                }
                
                if self.activity["metro"] != nil {
                    let metro = self.activity["metro"] as! String
                    let label: MDHTMLLabel = (cell.contentView.viewWithTag(103) as! MDHTMLLabel)
                    label.htmlText = metro.capitalized
                }
                break
            case 3:
                cell = tableView.dequeueReusableCell(withIdentifier: "descriptionCell", for: indexPath)
                cell.selectionStyle = .none
                var description = ""
                if let ac = self.activity["accessType"] as? String {
                    description += ac
                }
                if let ac = self.activity["description"] as? String {
                    description += ac
                }
                if let ac = self.activity["price"] as? String {
                    description += ac
                }
                let label: MDHTMLLabel = (cell.contentView.viewWithTag(101) as! MDHTMLLabel)
                label.highlightedShadowColor = UIColor.gray
                
                label.activeLinkAttributes = [NSBackgroundColorAttributeName:UIColor.gray]

                label.delegate = self
                label.htmlText = description
                break
            case 4:
                cell = tableView.dequeueReusableCell(withIdentifier: "googleCell", for: indexPath)
                cell.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
                cell.textLabel?.text = "Lancer une recherche sur le sujet"
                break
            case 5:
                cell = tableView.dequeueReusableCell(withIdentifier: "mapCell", for: indexPath)
                cell.selectionStyle = .none
                let mapView = (cell.contentView.viewWithTag(101) as! MKMapView)
                DispatchQueue.main.async {
                    self.createMap(mapView)
                }
                let address = self.activity["adresse"] as! String
                let zipcode = String(self.activity["zipcode"] as! Int)
                let city = self.activity["city"] as! String
                let addressLabel = (cell.contentView.viewWithTag(102) as! MDHTMLLabel)
                addressLabel.htmlText = "\(address) \(zipcode) \(city)"
                
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
                let start = self.occurences[indexPath.row-1]["hour_start"]!.replacingOccurrences(of: ":00:00", with: "h").replacingOccurrences(of: ":00", with: "").replacingOccurrences(of: ":", with: "h")
                let end = self.occurences[indexPath.row-1]["hour_end"]!.replacingOccurrences(of: ":00:00", with: "h").replacingOccurrences(of: ":00", with: "").replacingOccurrences(of: ":", with: "h")
                if today {
                    cell.backgroundColor = UIColor.groupTableViewBackground
                }
                cell.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
                cell.textLabel?.text = "\(jour) de \(start) à \(end)"

            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    func createMap(_ mapView: MKMapView) {
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
    
    func htmlLabel(_ label: MDHTMLLabel!, didSelectLinkWith URL: Foundation.URL!) {
        guard let url = URL else { return }
        let sf = SFSafariViewController(url: url)
        sf.delegate = self
        
        self.present(sf, animated: true, completion: nil)
    }
    
    func convertDateFormater(_ date: String) -> (String, Bool) {
        let dateFormatter = DateFormatter()
        var today: Bool = false
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        guard let date = dateFormatter.date(from: date) else {
            assert(false, "no date from string")
            return ("", today)
        }
        
        if date.numberOfDaysUntilDateTime() < 7 && Date().numberOfDaysUntilDateTime() > -1 {
            today = true
        }
        
        dateFormatter.dateFormat = "EE dd MMM yyyy"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let timeStamp = dateFormatter.string(from: date)
        
        return (timeStamp, today)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations[0]
    }
    
    //MARK: EKEventEditViewDelegate
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: {
            if action == .saved {
                let nom = self.activity["nom"] as? String
                let alert = UIAlertController(title: nom, message: "L'événement a bien été ajouté à votre calendrier", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func shareActivity(_ sender: Any) {
        let activityViewController = KidsActivityViewController(
            activityItems: ["https://itunes.apple.com/fr/app/kids-love-paris-le-meilleur/id1143821447?mt=8"],
            applicationActivities: nil)
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.barButtonItem = (sender as! UIBarButtonItem)
        }
        present(activityViewController, animated: true, completion: nil)
    }
}

extension Date {
    func numberOfDaysUntilDateTime(_ toDateTime: Date? = nil, inTimeZone timeZone: TimeZone? = nil) -> Int {
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: self)
        return components.day!
    }
}


