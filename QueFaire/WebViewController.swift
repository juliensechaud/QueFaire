//
//  WebViewController.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 09/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var closeButton: UIButton!
    
    var url: NSURL? {
        didSet {
            // Fetch data
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.loadRequest(NSURLRequest(URL: url!))
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIView.animateWithDuration(0.6 ,
                                   animations: {
                                    self.closeButton.transform = CGAffineTransformMakeScale(0.6, 0.6)
            },
                                   completion: { finish in
                                    UIView.animateWithDuration(0.6){
                                        self.closeButton.transform = CGAffineTransformIdentity
                                    }
        })
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
