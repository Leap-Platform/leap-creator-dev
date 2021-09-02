//
//  HybridViewController.swift
//  LeapSampleApp
//
//  Created by Ajay S on 31/08/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import UIKit
import WebKit

class HybridViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var urlPickerView: UIPickerView!
        
    let urls = ["Myntra", "Amazon", "Flipkart", "RedBus", "Paytm", "Google", "Facebook", "BookMyShow"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlString = "https://www.myntra.com/"
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
        
        urlPickerView.delegate = self
        urlPickerView.dataSource = self
    }
}

extension HybridViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
       
        return urls.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return urls[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        var urlString = "https://www.myntra.com/"
        
        switch urls[row] {
        case "Myntra": urlString = "https://www.myntra.com/"
        case "Amazon": urlString = "https://www.amazon.com"
        case "Flipkart": urlString = "https://www.flipkart.com"
        case "RedBus": urlString = "https://www.redbus.com"
        case "Paytm": urlString = "https://www.paytm.com"
        case "Google": urlString = "https://www.google.com"
        case "Facebook": urlString = "https://www.facebook.com"
        case "BookMyShow": urlString = "https://www.bookmyshow.com"
        default: break
            
        }
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }
}
