//
//  AutomaticViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 20/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class AutomaticViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    public var image:UIImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let screenshot = image else { return }
        imageView.image = screenshot
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
