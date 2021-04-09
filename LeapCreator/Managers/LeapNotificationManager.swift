//
//  LeapNotificationManager.swift
//  LeapCreatorSDK
//
//  Created by Aravind GS on 30/03/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

enum NotificationType: String {
    case preview
    case sampleApp
}

class LeapNotificationManager:NSObject {
    
    static let shared = LeapNotificationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    
    func checkForAuthorisation(type: NotificationType = .preview, infoDict: Dictionary<String, Any>? = nil) {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        
        notificationCenter.delegate = self
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.askAuthorisation(type: type, infoDict: infoDict)
            case .authorized:
                if type == .preview {
                   self.triggerNotification()
                } else if type == .sampleApp {
                   self.triggerSampleAppNotification(infoDict: infoDict!)
                }
            case .denied:
                break
            default:
                break
            }
        }
    }

    @objc func appWillTerminate(notification:NSNotification) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["LeapScanNotification", "LeapEndPreviewNotification"])
    }
    
    func askAuthorisation(type: NotificationType, infoDict: Dictionary<String, Any>?) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (result, err) in
            if let error = err { print(error.localizedDescription) }
            if result {
                if type == .preview {
                   self.triggerNotification()
                } else if type == .sampleApp {
                   self.triggerSampleAppNotification(infoDict: infoDict!)
                }
            }
        }
    }
    
    func triggerNotification() {
        
        let rescanAction = UNNotificationAction(identifier: "PreviewScan", title: "Scan", options: UNNotificationActionOptions(rawValue: 0))
        
        let scanSuccessCategory = UNNotificationCategory(identifier: "scanSuccess", actions: [rescanAction], intentIdentifiers: [], options: [])
        
        self.notificationCenter.setNotificationCategories([scanSuccessCategory])

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "scanSuccess"
        content.title = Bundle.main.infoDictionary!["CFBundleName"] as! String
        content.body = "App Version: \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)"
        let request = UNNotificationRequest(identifier: "LeapScanNotification", content: content, trigger: nil)
        
        self.notificationCenter.add(request, withCompletionHandler: nil)
    }
    
    func triggerSampleAppNotification(infoDict: Dictionary<String, Any>) {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
         
        guard settings.authorizationStatus == .authorized else { return }
            
        let rescanAction = UNNotificationAction(identifier: "Rescan",
                      title: "Rescan",
                      options: UNNotificationActionOptions(rawValue: 0))
                
        let scanSuccessCategory = UNNotificationCategory(identifier: "scanSuccess", actions: [rescanAction], intentIdentifiers: [], options: [])
                
        UNUserNotificationCenter.current().setNotificationCategories([scanSuccessCategory])
                    
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "scanSuccess"
        if let appName = infoDict["appName"] as? String {
           content.title = appName
           content.subtitle = "connected"
        }
        let request = UNNotificationRequest(identifier: "LeapScanNotification", content: content, trigger: nil)
            
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}


extension LeapNotificationManager: UNUserNotificationCenterDelegate {
    
    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.alert, .badge, .sound])
    }
    
    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        switch response.actionIdentifier {
        case "PreviewScan":
            let vc = UIApplication.getCurrentVC()
            guard let viewc = vc else { return }
            let camVC = LeapCameraViewController()
            camVC.delegate = self
            camVC.modalPresentationStyle = .fullScreen
            if #available(iOS 13.0, *) { camVC.isModalInPresentation = false }
            viewc.present(camVC, animated: true)
        case "EndPreview":
            NotificationCenter.default.post(name: NSNotification.Name("leap_end_preview"), object:  nil)
        case "Rescan":
            NotificationCenter.default.post(name: NSNotification.Name("rescan"), object: nil)
        default:
            break
        }
        completionHandler()
    }
    
    func triggerEndPreviewNotification(projName:String) {
        let endPreview = UNNotificationAction(identifier: "EndPreview", title: "End Preview", options: UNNotificationActionOptions(rawValue: 0))
        
        let endPreviewCategory = UNNotificationCategory(identifier: "endPreview", actions: [endPreview], intentIdentifiers: [], options: [])
        
        self.notificationCenter.setNotificationCategories([endPreviewCategory])

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "endPreview"
        content.title = "✅ Previewing..."
        content.body = projName
        let request = UNNotificationRequest(identifier: "LeapEndPreviewNotification", content: content, trigger: nil)
        
        self.notificationCenter.add(request, withCompletionHandler: nil)
    }
}

extension LeapNotificationManager: LeapCameraViewControllerDelegate {
    
    func configFetched(type: NotificationType, config: Dictionary<String, Any>, projectName:String) {
        NotificationCenter.default.post(name: NSNotification.Name("leap_preview_config"), object: config)
        if type == .preview {
           triggerEndPreviewNotification(projName: projectName)
        } else if type == .sampleApp {
           triggerSampleAppNotification(infoDict: config)
        }
    }
    
    func closed(type: NotificationType) {
        if type == .preview {
           triggerNotification()
        }
    }
    
}
