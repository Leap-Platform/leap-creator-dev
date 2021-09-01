//
//  LoginViewController.swift
//  LeapSampleApp
//
//  Created by Aravind GS on 23/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    private var image:UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func captureScreen(_ sender: Any) {
        
    }
    
    @IBAction func goToNext(_ sender: Any) {
        performSegue(withIdentifier: "login_completed", sender: nil)
    }
}
