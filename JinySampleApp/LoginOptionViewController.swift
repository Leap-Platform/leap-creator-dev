//
//  LoginOptionViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 18/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class LoginOptionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginWithEmail() {
        performSegue(withIdentifier: "login", sender: nil)
    }
    
    @IBAction func continueWithoutEmail() {
        performSegue(withIdentifier: "no_login", sender: nil)
    }

}
