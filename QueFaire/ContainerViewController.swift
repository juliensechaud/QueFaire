//
//  ContainerViewController.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 13/08/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {
    var masterVc: MasterViewController?
    var mapVc: MapViewController?
    var rightBarButton: UIBarButtonItem? = nil
    
    @IBOutlet weak var masterContainer: UIView!
    @IBOutlet weak var mapContainer: UIView!
    
    override func viewDidLoad() {
        rightBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(ContainerViewController.filterMaster))
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.leftBarButtonItem?.action = #selector(ContainerViewController.switchContainer)
        self.navigationItem.leftBarButtonItem?.target = self
        self.buildTitleView()
    }
        
    func buildTitleView() {
        guard let m = masterVc else { return }
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        let attributedTitle = NSMutableAttributedString(string: Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String,
                                                        attributes: [NSFontAttributeName : UIFont(name: "Avenir-Heavy", size: 15)!, NSForegroundColorAttributeName: UIColor.white])
        
        if m.univers.name != "Master" {
            attributedTitle.append(NSAttributedString(string: "\n" + m.univers.name,
                attributes: [NSForegroundColorAttributeName: UIColor.white,
                    NSFontAttributeName : UIFont(name: "Avenir-Roman", size: 11)!]))
        }
        
        titleLabel.attributedText = attributedTitle
        self.navigationItem.titleView = titleLabel

    }
    
    func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed

        if segue.identifier == "MasterContainer" {
            masterVc = segue.destination as? MasterViewController
        } else if segue.identifier == "MapContainer" {
            mapVc = segue.destination as? MapViewController
        } else if segue.identifier == "FilterMaster" {
            let universVc = (segue.destination as? UINavigationController)?.viewControllers[0] as? UniversViewController
            universVc?.univers = masterVc?.univers
        }
    }
    
    func switchContainer() {
        // Go to map
        if self.masterContainer.alpha == 1 {
            mapVc!.objects = masterVc!.objects
            mapVc!.context = (masterVc!.univers, masterVc!.objects)
            mapVc?.setUpMap()
            self.masterContainer.alpha = 0
            self.navigationItem.leftBarButtonItem?.image = UIImage(named: "list")
            self.navigationItem.rightBarButtonItem? = UIBarButtonItem()
            
        // Go to list
        } else {
            self.masterContainer.alpha = 1
            self.navigationItem.leftBarButtonItem?.image = UIImage(named: "map")
            self.navigationItem.rightBarButtonItem?.accessibilityElementsHidden = false
            self.navigationItem.rightBarButtonItem? = rightBarButton!;
        }
    }
    
    func filterMaster() {
        self.performSegue(withIdentifier: "FilterMaster", sender: self)
    }

}
