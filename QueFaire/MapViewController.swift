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
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setUpMap() {
        mapView.removeAnnotations(mapView.annotations)
        for (index, activity) in self.objects.enumerated() {
            let location = CLLocationCoordinate2DMake((activity["lat"] as? Double)!, (activity["lon"] as? Double)!)
            // Drop a pin
            let dropPin = CustomPointAnnotation()
            dropPin.coordinate = location
            dropPin.title = (activity["nom"] as? String)?.html2String.html2String
            dropPin.subtitle = (activity["lieu"] as? String)?.html2String.html2String
            dropPin.tag = index
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if self.originalDataLoaded {
            self.fetchData(mapView.region)
        }
    }
    
    func fetchData(_ region: MKCoordinateRegion) -> Void {
        let otherType = self.context?.univers.type == "cid" ? "tag" : "cid"
        let start = Date().timeIntervalSince1970
        let daysToAdd: Double = 7.0;
        let end = Date().addingTimeInterval(60*60*24*daysToAdd).timeIntervalSince1970
        let type = self.context?.univers.type ?? "tag"
        var id: Int
        if let universID = self.context?.univers.id {
            id = universID
        } else {
            id = 0
        }
        let stringRequest = "https://api.paris.fr/api/data/1.4/QueFaire/get_geo_activities/?token=46cad19b4c01a8034d410d22a75d7400221fb84f7dd37791e55699b422de8914&\(otherType)=&\(type)=\(id)&created=&start=\(start)&end=\(end)&offset=0&limit=50&lat=\(region.center.latitude)&lon=\(region.center.longitude)&radius=100000"
        print(stringRequest)
        Alamofire.request(stringRequest, headers: nil)
            .responseJSON { response in
                if let JSON = response.result.value as? [String: AnyObject] {
                    self.objects = JSON["data"] as! [AnyObject]
                    self.loadingData = false
                    self.setUpMap()
                }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKPinAnnotationView
        if !annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "loc")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.performSegue(withIdentifier: "showDetailFromMap", sender: view)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailFromMap" {
            guard let annotation = (sender as AnyObject).annotation as? CustomPointAnnotation else { return }
            let object = objects[annotation.tag]["idactivites"]
            let controller = (segue.destination as! UINavigationController).topViewController as! ActivityViewController
            controller.detailItem = object as? Int
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
                
            
        }
    }



}
