//
//  MainViewController.swift
//  LeapSampleApp
//
//  Created by Ajay S on 27/07/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import UIKit
import Foundation

enum DeepLink: String {
    case booking
    case flipkart
}

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func hybridViewsButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "demoApp://flipkart")!)
    }
}

extension MainViewController {
    func handleDeeplink(_ deeplink: DeepLink) {
        switch deeplink {
        case .booking:
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController
            self.navigationController?.pushViewController(vc!, animated: true)
        case .flipkart:
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "SingleWebviewViewController") as? SingleWebviewViewController
            self.navigationController?.pushViewController(vc!, animated: true)
        }
    }
}
