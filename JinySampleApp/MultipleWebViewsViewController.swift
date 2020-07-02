//
//  MultipleWebViewsViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 02/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit
import WebKit

class MultipleWebViewsViewController: UIViewController {
    
    @IBOutlet weak var webview1:WKWebView!
    @IBOutlet weak var webview2:WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let url1 = URL(string: "https://m.redbus.in")
        webview1.load(URLRequest(url: url1!))
        
        let url2 = URL(string: "https://www.amazon.in")
        webview2.load(URLRequest(url: url2!))
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
