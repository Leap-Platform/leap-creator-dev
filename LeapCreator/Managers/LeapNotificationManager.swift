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
    case genericApp
    case sampleApp
    case preview
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
    
    @objc func appWillTerminate(notification: NSNotification) {
        DispatchQueue.main.async {
            self.notificationCenter.removeAllDeliveredNotifications()
        }
    }
    
    func checkForAuthorisation(type: NotificationType = .genericApp) {
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.askAuthorisation(type: type)
            case .authorized:
                self.triggerNotification(notificationType: type)
            case .denied:
                break
            default:
                break
            }
        }
    }
    
    func askAuthorisation(type: NotificationType) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (result, err) in
            if let error = err { print(error.localizedDescription) }
            if result {
                self.triggerNotification(notificationType: type)
            }
        }
    }
    
    func triggerNotification(notificationType: NotificationType = .genericApp) {
        
        var scanAction = UNNotificationAction(identifier: constant_GenericAppScan, title: constant_Scan, options: UNNotificationActionOptions(rawValue: 0))
        
        let content = UNMutableNotificationContent()
        
        content.title = "Leap creator mode: ON"
        let bundleShortVersionString = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Empty"
        content.body = "App Version: \(bundleShortVersionString)"
        
        var request: UNNotificationRequest?
        
        var category = UNNotificationCategory(identifier: NotificationType.genericApp.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
        
        if notificationType == .genericApp {
            scanAction = UNNotificationAction(identifier: constant_GenericAppScan, title: constant_Scan, options: UNNotificationActionOptions(rawValue: 0))
            category = UNNotificationCategory(identifier: NotificationType.genericApp.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
            content.categoryIdentifier = NotificationType.genericApp.rawValue
        } else if notificationType == .sampleApp {
            scanAction = UNNotificationAction(identifier: constant_SampleAppScan, title: constant_Scan, options: UNNotificationActionOptions(rawValue: 0))
            category = UNNotificationCategory(identifier: NotificationType.sampleApp.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
            content.categoryIdentifier = NotificationType.sampleApp.rawValue
        } else if notificationType == .preview {
            scanAction = UNNotificationAction(identifier: constant_Preview, title: constant_EndPreview, options: UNNotificationActionOptions(rawValue: 0))
            category = UNNotificationCategory(identifier: NotificationType.preview.rawValue, actions: [scanAction], intentIdentifiers: [], options: [])
            content.categoryIdentifier = NotificationType.preview.rawValue
            content.title = "✅ Previewing..."
            content.body = UserDefaults.standard.object(forKey: constant_previewProjectName) as? String ?? ""
        }
        
        self.notificationCenter.setNotificationCategories([category])
        
        if notificationType == .preview {
            request = UNNotificationRequest(identifier: "LeapPreviewNotification", content: content, trigger: nil)
        } else {
            request = UNNotificationRequest(identifier: "LeapScanNotification", content: content, trigger: nil)
        }
        self.notificationCenter.removeAllDeliveredNotifications()
        guard let confirmedRequest = request else { return }
        self.notificationCenter.add(confirmedRequest, withCompletionHandler: nil)
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
        case constant_GenericAppScan:
            let vc = UIApplication.getCurrentVC()
            guard let viewc = vc else { return }
            let camVC = LeapCameraViewController()
            camVC.delegate = self
            camVC.modalPresentationStyle = .fullScreen
            if #available(iOS 13.0, *) { camVC.isModalInPresentation = false }
            viewc.present(camVC, animated: true)
        case constant_Preview:
            if Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
                self.checkForAuthorisation(type: .sampleApp)
            } else {
                self.checkForAuthorisation(type: .genericApp)
            }
            NotificationCenter.default.post(name: NSNotification.Name("leap_end_preview"), object:  nil)
        case constant_SampleAppScan:
            NotificationCenter.default.post(name: NSNotification.Name("rescan"), object: nil)
        default:
            checkForAuthorisation(type: NotificationType(rawValue: response.notification.request.content.categoryIdentifier) ?? .genericApp)
        }
        completionHandler()
    }
}

extension LeapNotificationManager: LeapCameraViewControllerDelegate {
    
    func configFetched(type: NotificationType, config: Dictionary<String, Any>) {
        
        checkForAuthorisation(type: type)
        
        if type == .preview {
            NotificationCenter.default.post(name: NSNotification.Name("leap_preview_config"), object: config)
        }
    }
    
    func closed(type: NotificationType) {
        checkForAuthorisation(type: type)
    }
}
