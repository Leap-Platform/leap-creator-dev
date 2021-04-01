//
//  LeapPreviewManager.swift
//  LeapCreatorSDK
//
//  Created by Aravind GS on 30/03/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications


class LeapPreviewManager:NSObject {
    
    static let shared = LeapPreviewManager()
    let notificationCenter = UNUserNotificationCenter.current()
    
    func checkForAuthorisation() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        
        notificationCenter.delegate = self
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.askAuthorisation()
            case .authorized:
                self.triggerNotification()
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
    
    func askAuthorisation() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (result, err) in
            if let error = err { print(error.localizedDescription) }
            if result { self.triggerNotification() }
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
    
}


extension LeapPreviewManager: UNUserNotificationCenterDelegate {
    
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

extension LeapPreviewManager: LeapCameraViewControllerDelegate {
    
    func configFetched(config: Dictionary<String, Any>, projectName:String) {
        NotificationCenter.default.post(name: NSNotification.Name("leap_preview_config"), object: config)
        triggerEndPreviewNotification(projName: projectName)
    }
    
    func closed() {
        triggerNotification()
    }
    
}
