//
//  LoginViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 23/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? AutomaticViewController {
            dest.image = image
        }
    }
}
