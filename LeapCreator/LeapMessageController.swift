//
//  LeapMessageController.swift
//  LeapCreatorSDK
//
//  Created by Ajay S on 14/05/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showToast(message: String, font: UIFont = UIFont.boldSystemFont(ofSize: 17), color: UIColor) {
        
        let width = (self.view.frame.width * 80) / 100
        let height = 35

        let toastLabel = UILabel(frame: CGRect(x: Int(self.view.center.x) - Int(width)/2, y: Int(self.view.frame.size.height)-100, width: Int(width), height: height))
        toastLabel.backgroundColor = color
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        toastLabel.adjustsFontSizeToFitWidth = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 1.0, delay: 2, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func showAlertForSettingsPage(with message: String) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        let goButton = "Go"
        var goAction = UIAlertAction(title: goButton, style: .default, handler: nil)
        let cancelButton = "Cancel"
        let cancelAction = UIAlertAction(title: cancelButton, style: .cancel, handler: nil)
        if UIApplication.shared.canOpenURL(settingsUrl) {

            goAction = UIAlertAction(title: goButton, style: .default, handler: {(alert: UIAlertAction!) -> Void in
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            })
        }

        let alert = UIAlertController(title: "Permission Required", message: message, preferredStyle: .alert)
        alert.addAction(goAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}
