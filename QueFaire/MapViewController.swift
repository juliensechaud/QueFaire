//
//  MapViewController.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 26/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit
import MapKit
import Alamofire

class MapViewController: UIViewController, MKMapViewDelegate {
    var objects = [AnyObject]()
    var context: (univers: (id: Int, name: String, type: String), [AnyObject])?
    var loadingData = false
    var originalDataLoaded = false

    @IBOutlet weak var mapView: MKMapView!
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.setUpMap()
    }
    
    func setUpMap() {
        mapView.removeAnnotations(mapView.annotations)
        for (index, activity) in self.objects.enumerate() {
            let location = CLLocationCoordinate2DMake((activity["lat"] as? Double)!, (activity["lon"] as? Double)!)
            // Drop a pin
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = location
            dropPin.title = activity["lieu"] as? String
            dropPin.subtitle = String(index)
            mapView.addAnnotation(dropPin)
//            mapView.centerCoordinate = location
        }
        
        if self.originalDataLoaded == false {
            let location = CLLocationCoordinate2DMake(48.8534100, 2.3488000)
            let viewRegion: MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(location, 3000, 3000);
            let adjustedRegion: MKCoordinateRegion = mapView.regionThatFits(viewRegion)
            mapView.setRegion(adjustedRegion, animated: true)
            self.originalDataLoaded = true
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if self.originalDataLoaded {
            self.fetchData(mapView.region)
        }
    }
    
    func fetchData(region: MKCoordinateRegion) -> Void {
        let otherType = self.context?.univers.type == "cid" ? "tag" : "cid"
        let start = NSDate().timeIntervalSince1970
        let daysToAdd: Double = 7.0;
        let end = NSDate().dateByAddingTimeInterval(60*60*24*daysToAdd).timeIntervalSince1970
        let type = self.context?.univers.type
        let id = self.context?.univers.id
        //        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&cid=0&tag=1&created=0&start=1463402576&end=1463402576&offset=0&limit=10&created=1468091400"
        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_geo_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&\(otherType)=&\(type!)=\(id!)&created=&start=\(start)&end=\(end)&offset=0&limit=10&lat=\(region.center.latitude)&lon=\(region.center.longitude)&radius=3000"
        //        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&cid=0&tag=1&created=0&start=1483228800&end=1483228800&offset=0&limit=10"
        print(stringRequest)
        Alamofire.request(.GET, stringRequest, parameters: nil)
            .responseJSON { response in
                if let JSON = response.result.value {
                    self.objects = JSON.objectForKey("data") as! [AnyObject]
//                    self.refreshPage += 10
                    self.loadingData = false
                    self.setUpMap()
//                    self.refreshControl?.endRefreshing()
                }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKPinAnnotationView
        if !annotation.isKindOfClass(MKUserLocation) {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "loc")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            return annotationView
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        ((self.presentingViewController as? UISplitViewController)?.viewControllers[0] as? UINavigationController)?.topViewController!.performSegueWithIdentifier("showDetail", sender: view)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetailFromMap" {
            if let indexPath = Int((sender?.annotation!?.subtitle)!) {
                let object = objects[indexPath]["idactivites"]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ActivityViewController
                controller.detailItem = object as? Int
                let backItem = UIBarButtonItem()
                backItem.title = ""
                navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
                
            }
        }
    }



}
