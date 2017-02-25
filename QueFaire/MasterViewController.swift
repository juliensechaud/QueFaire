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
    let refreshActivity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
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
        
        self.refreshControl?.addTarget(self, action: #selector(MasterViewController.fetchData), for: UIControlEvents.valueChanged)

        self.titleButton.transform = self.titleButton.transform.scaledBy(x: -1.0, y: 1.0);
        self.titleButton.titleLabel!.transform = self.titleButton.titleLabel!.transform.scaledBy(x: -1.0, y: 1.0);
        self.titleButton.imageView!.transform = self.titleButton.imageView!.transform.scaledBy(x: -1.0, y: 1.0);

        self.tableView.tableHeaderView = headerView
        timeSegmentedControl.tintColor = UIColorFromRGB(0xEFEFF4)
        timeSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.lightGray], for: UIControlState())
        timeSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.black], for: .selected)
        
        self.fetchData()
        
        self.tableView.backgroundView = refreshActivity
        refreshActivity.startAnimating()

    }
    
    func fetchData() -> Void {
        let otherType = self.univers.type == "cid" ? "tag" : "cid"
        let start = Date().timeIntervalSince1970
        let end = Date().addingTimeInterval(60*60*24*daysToAdd).timeIntervalSince1970

        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&\(otherType)=&\(self.univers.type)=\(String(self.univers.id))&created=&start=\(start)&end=\(end)&offset=\(self.refreshPage)&limit=10"
        
        print(stringRequest)
        
        Alamofire.request(stringRequest, headers: nil)
            .responseJSON { response in
                DispatchQueue.global(qos: .userInitiated).async {
                    if let JSON = response.result.value as? [String: AnyObject] {
                        guard let data = JSON["data"] as? [[String: AnyObject]] else {return}
                        self.objects += self.make(forModel: data)
                        self.refreshPage += 10
                        self.loadingData = false
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.refreshControl?.endRefreshing()
                        }
                    } else {
                        let warning = "TODO"
                    }
                }
        }
    }
    
    func make(forModel model: [[String: AnyObject]]) -> [AnyObject] {
        var temp = [[String: AnyObject]]()
        for object in model {
            var temp2 = object
            if var nom = object["nom"] as? String {
                nom.capitalizeFirstLetter()
                nom = nom.html2String.html2String
                temp2["nom"] = nom as AnyObject?
            }
            if var lieu = object["lieu"] as? String {
                lieu.capitalizeFirstLetter()
                lieu = lieu.html2String.html2String
                temp2["lieu"] = lieu as AnyObject?
            }
            if let files = object["files"] as? [[String:String]] ?? object["media"] as? [[String:String]] {
                _ = "file"
                var surl: String = ""
                for file in files {
                    let url: String = file["file"] ?? file["path"]!
                    if (url.contains("quefaire/fiches"))  {
                        surl = url
                    }
                }
                let link = surl
                if let name = link.components(separatedBy: "/").last {
                    _ = "original__\(name)"
                    let optiUrl = "x\(Int(self.tableView.frame.size.width))_\(name)"
                    let urlWithoutName = link.replacingOccurrences(of: name, with: "")
                    _ = "http://filer.paris.fr/\(urlWithoutName)\(optiUrl)"
                }
                temp2["surl"] = surl as AnyObject?
            }

            temp.append(temp2)
        }
        return temp as [AnyObject]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let aVariable = appDelegate.deeplink
        if aVariable == true {
            self.performSegue(withIdentifier: "showDetail", sender: appDelegate)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]["idactivites"]
                let controller = (segue.destination as! UINavigationController).topViewController as! ActivityViewController
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
                let controller = (segue.destination as! UINavigationController).topViewController as! ActivityViewController
                controller.detailItem = object
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
            }
        } else if segue.identifier == "showMap" {
            let controller = (segue.destination as! UINavigationController).topViewController as! MapViewController
            controller.objects = self.objects
            controller.context = (self.univers, self.objects)
        } else if segue.identifier == "TimeChoice" {
            let controller = segue.destination
            controller.popoverPresentationController?.sourceRect = self.titleButton.frame
            controller.popoverPresentationController?.sourceView = self.titleButton
            controller.popoverPresentationController?.permittedArrowDirections = .up
            controller.popoverPresentationController?.delegate = self
        }
    }
    
    func prepareActivitySegue() {
        
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[indexPath.row]
        var nom = object["nom"] as! String
        nom.capitalizeFirstLetter()
        let lieu = object["lieu"] as! String
        let nomLabel = (cell.contentView.viewWithTag(102) as! MDHTMLLabel)
        nomLabel.htmlText = nom//.html2String.html2String
        
        let hasFee = object["hasFee"] as? String
        (cell.contentView.viewWithTag(103) as! MDHTMLLabel).textInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        if hasFee == "0" {
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Gratuit"
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).backgroundColor = UIColorFromRGB(0xbdf5c8)
        } else {
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).htmlText = "Payant"
            (cell.contentView.viewWithTag(103) as! MDHTMLLabel).backgroundColor = UIColor.white
        }
        
        (cell.contentView.viewWithTag(104) as! MDHTMLLabel).htmlText = lieu//.html2String.html2String
        
        if let surl = object["surl"] as? String {
            let placeholderImage = UIImage(named: "placeholder")!
            (cell.contentView.viewWithTag(101) as! UIImageView).af_setImage(withURL: Foundation.URL(string: "http://filer.paris.fr/\(surl)")!, placeholderImage: placeholderImage)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !loadingData && indexPath.row == refreshPage - 1 {
            loadingData = true
            refreshResults2()
        }
    }
    
    @IBAction func timeChoice(_ sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: "Quelle période ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cette semaine", style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Ajourd'hui", style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Ce week-end", style: .default, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "Annuler", style: .destructive, handler: { (action) in
            
        }))

        self.present(alert, animated: true, completion: nil)
        
    }
    
    func refreshResults2() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            // this runs on the background queue
            // here the query starts to add new 40 rows of data to arrays
            
            DispatchQueue.main.async {
                // this runs on the main queue
                self.fetchData()
            }
        }
    }
    
    @IBAction func cancelToMaster(_ segue:UIStoryboardSegue) {
    }
    
    @IBAction func filterMaster(_ segue:UIStoryboardSegue) {
        if let universViewController = segue.source as? UniversViewController {
            guard universViewController.univers != nil else { return }
            self.univers = universViewController.univers!
            self.title = "\(self.univers.1)"
            self.refreshPage = 0
            self.objects.removeAll()
            self.tableView.reloadData()
            self.fetchData()
        }
        guard let container = self.parent as? ContainerViewController else { return }
        container.buildTitleView()
    }
    
    func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func refreshTime(_ time: Double) {
        self.daysToAdd = time
        self.refreshPage = 0
        self.objects.removeAll()
        self.tableView.reloadData()
        timeRefreshing = true
        self.fetchData()
    }
    @IBAction func timeSelected(_ sender: AnyObject) {
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
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}


extension String {
    var html2AttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

