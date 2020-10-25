//
//  AuthLifecycleDelegate.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 24/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class AuthLifecycleDelegate: NSObject, UIApplicationDelegate {
    var lifecycleListener: LifecycleStateListener
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("Termination ")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("Activi app")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("Resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Enter background ")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("Enter foreground")
    }
    
    init(lifecycleStateListener: LifecycleStateListener){
        self.lifecycleListener = lifecycleStateListener
    }
    
}

protocol LifecycleStateListener{
    func onAppInForeground()->Void
    func onAppInBackground()->Void
    func onAppInstanceActive()->Void
    func onAppInstanceTerminated()->Void
    
}
