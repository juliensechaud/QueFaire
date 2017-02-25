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
    
    var url: URL? {
        didSet {
            // Fetch data
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.loadRequest(URLRequest(url: url!))
        
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIView.animate(withDuration: 0.6 ,
                                   animations: {
                                    self.closeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            },
                                   completion: { finish in
                                    UIView.animate(withDuration: 0.6, animations: {
                                        self.closeButton.transform = CGAffineTransform.identity
                                    })
        })
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
