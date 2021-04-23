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

class LeapNotificationManager: NSObject {
    
    static let shared = LeapNotificationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        self.notificationCenter.removeAllDeliveredNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        notificationCenter.delegate = self
    }
    
    func checkForAuthorisation(type: NotificationType = .preview) {
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.askAuthorisation(type: type)
            case .authorized:
                if type == .preview {
                    self.triggerNotification()
                } else if type == .sampleApp {
                    self.triggerNotification(notificationType: type)
                }
            case .denied:
                break
            default:
                break
            }
        }
    }
    
    @objc func appWillTerminate(notification: NSNotification) {
        DispatchQueue.main.async {
            self.notificationCenter.removeAllDeliveredNotifications()
        }
    }
    
    func askAuthorisation(type: NotificationType) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (result, err) in
            if let error = err { print(error.localizedDescription) }
            if result {
                if type == .preview {
                    self.triggerNotification()
                } else if type == .sampleApp {
                    self.triggerNotification(notificationType: type)
                }
            }
        }
    }
    
    func triggerNotification(notificationType: NotificationType = .preview) {
        
        var scanAction = UNNotificationAction(identifier: constant_PreviewScan, title: constant_Scan, options: UNNotificationActionOptions(rawValue: 0))
        
        let content = UNMutableNotificationContent()
        
        var category = UNNotificationCategory(identifier: NotificationType.preview.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
        
        if notificationType == .preview {
            scanAction = UNNotificationAction(identifier: constant_PreviewScan, title: constant_Scan, options: UNNotificationActionOptions(rawValue: 0))
            category = UNNotificationCategory(identifier: NotificationType.preview.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
            content.categoryIdentifier = NotificationType.preview.rawValue
        } else if notificationType == .sampleApp {
            scanAction = UNNotificationAction(identifier: constant_SampleAppScan, title: constant_Scan, options: UNNotificationActionOptions(rawValue: 0))
            category = UNNotificationCategory(identifier: NotificationType.sampleApp.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
            content.categoryIdentifier = NotificationType.sampleApp.rawValue
        }
        
        self.notificationCenter.setNotificationCategories([category])
        
        content.title = "Leap creator mode: ON"
        let bundleShortVersionString = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Empty"
        content.body = "App Version: \(bundleShortVersionString)"
        let request = UNNotificationRequest(identifier: "LeapScanNotification", content: content, trigger: nil)
        self.notificationCenter.removeAllDeliveredNotifications()
        self.notificationCenter.add(request, withCompletionHandler: nil)
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
        case constant_PreviewScan:
            let vc = UIApplication.getCurrentVC()
            guard let viewc = vc else { return }
            let camVC = LeapCameraViewController()
            camVC.delegate = self
            camVC.modalPresentationStyle = .fullScreen
            if #available(iOS 13.0, *) { camVC.isModalInPresentation = false }
            viewc.present(camVC, animated: true)
        case constant_EndPreview:
            NotificationCenter.default.post(name: NSNotification.Name("leap_end_preview"), object:  nil)
            triggerNotification(notificationType: .preview)
        case constant_SampleAppScan:
            NotificationCenter.default.post(name: NSNotification.Name("rescan"), object: nil)
        default:
            checkForAuthorisation(type: NotificationType(rawValue: response.notification.request.content.categoryIdentifier) ?? .preview)
            
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
        
        if type == .preview {
            NotificationCenter.default.post(name: NSNotification.Name("leap_preview_config"), object: config)
            triggerEndPreviewNotification(projName: projectName)
        } else if type == .sampleApp {
            checkForAuthorisation(type: .sampleApp)
        }
    }
    
    func closed(type: NotificationType) {
        checkForAuthorisation(type: type)
    }
    
}
