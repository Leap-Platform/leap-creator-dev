//
//  SingleWebviewViewController.swift
//  LeapSampleApp
//
//  Created by Aravind GS on 02/07/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit
import WebKit

class SingleWebviewViewController: UIViewController {
    
    @IBOutlet weak var webview:WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let urlString = "https://www.goibibo.com/flights"
        guard let url = URL(string: urlString) else { return }
        webview.load(URLRequest(url: url))
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
