//
//  AppDelegate.swift
//  JinySampleApp
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit
//import JinySDK
import JinyAuthSDK
//import JinyAUI

@available(iOS 13.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        JinyAUI.shared.initialize(withToken: "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36")
//        let _ = Jiny.shared.initialize(withToken: "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36", isTesting: false, uiManager: nil)
        
        JinyAuth.instance.initialize(withToken: "5b4208c2-5f48-4fd2-8f0f-33362ca2d0ed")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
