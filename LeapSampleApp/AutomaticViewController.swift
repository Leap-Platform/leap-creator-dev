//
//  AutomaticViewController.swift
//  LeapSampleApp
//
//  Created by Aravind GS on 20/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class AutomaticViewController: UIViewController {
    
    @IBOutlet weak var priceValue: UILabel!
    
    @IBOutlet weak var priceSlider: UISlider!
    
    let value = 5000
    
    var image:UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        priceValue.text = "\(value)"
        priceSlider.setValue(Float(value), animated: true)
    }

    @IBAction func priceChanged(_ sender: UISlider) {
        priceValue.text = "\(sender.value)"
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
