//
//  ManualScrollViewController.swift
//  LeapSampleApp
//
//  Created by Ajay S on 09/02/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import UIKit
import LeapSDK

class ManualScrollViewController: UIViewController {

    @IBOutlet weak var manualScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            
            self.manualScrollView.scrollRectToVisible(CGRect(x: 0, y: 800, width: self.view.frame.width, height: self.view.frame.height), animated: true)
        }
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
