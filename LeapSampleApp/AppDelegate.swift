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
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if #available(iOS 13.0, *) {
            // In iOS 13 setup is done in SceneDelegate
        } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            self.window = window
            
            let mainstoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewcontroller: UINavigationController = mainstoryboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            window.rootViewController = newViewcontroller
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 13.0, *) {
            // In iOS 13 setup is done in SceneDelegate
        } else {
            self.window?.makeKeyAndVisible()
        }
        
        Leap.shared.withBuilder(Bundle.main.infoDictionary?["APP_API_KEY"] as! String)?
            .addProperty("username", stringValue: "Aravind")
            .addProperty("age", intValue: 30)
            .addProperty("ts", dateValue: Date()).start()
        LeapCreator.shared.start(Bundle.main.infoDictionary?["APP_API_KEY"] as! String)
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
}
