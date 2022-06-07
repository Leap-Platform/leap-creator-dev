//
//  AppDelegate.swift
//  LeapSampleApp
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit
import LeapCreatorSDK
import LeapSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var mainController: MainViewController?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if #available(iOS 13.0, *) {
            // In iOS 13 setup is done in SceneDelegate
        } else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            
            let mainstoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let navigationController = mainstoryboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
            
            mainController = navigationController.viewControllers.first as? MainViewController
        }
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let arguments = ProcessInfo.processInfo.arguments
        let apiKey:String = {
            guard let tokenKeyIndex = arguments.firstIndex(of: "apiKey"),
                  arguments.count > tokenKeyIndex+1 else { return Bundle.main.infoDictionary?["APP_API_KEY"] as! String }
            return arguments[tokenKeyIndex+1]
        }()
        
        let projectId:String? = {
            guard let projectIdKeyIndex = arguments.firstIndex(of: "projectId"),
                  arguments.count > projectIdKeyIndex+1 else { return nil }
            return arguments[projectIdKeyIndex+1]
        }()
        
        let resetProject:Bool = {
            guard let projectIdKeyIndex = arguments.firstIndex(of: "resetProject"),
                  arguments.count > projectIdKeyIndex+1 else { return true }
            return arguments[projectIdKeyIndex+1] != "false"
        }()
        
        Leap.shared.start(apiKey)
        Leap.shared.callback = self
        LeapCreator.shared.start(apiKey)
        if let projectId = projectId { Leap.shared.startProject(projectId, resetProject: resetProject) }
        return true
    }
     
    // MARK: UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host else {
            return false
        }
        
        guard let deeplink = DeepLink(rawValue: host) else {
            return false
        }
        
        mainController?.handleDeeplink(deeplink)
        
        return true
    }
}

extension AppDelegate: LeapCallback {
    
    func eventNotification(eventInfo: Dictionary<String, Any>) {
        print("DemoApp - \(eventInfo)")
    }
}
