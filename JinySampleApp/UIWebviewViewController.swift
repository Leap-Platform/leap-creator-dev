//
//  UIWebviewViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 21/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class UIWebviewViewController: UIViewController {

    @IBOutlet weak var webview: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let urlString = "https://www.goibibo.com/flights"
        guard let url = URL(string: urlString) else { return }
        webview.loadRequest(URLRequest(url: url))
        
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
