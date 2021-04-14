//
//  LeapCreator.swift
//  LeapCreator
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public class LeapCreator: NSObject {
    @objc public static let shared = LeapCreator()
    private var creatorInternal:LeapCreatorInternal?
    private var token:String?
  
   @objc public func start(_ apiKey:String) -> Void {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        LeapReachabilityManager.shared.initialize()
        token = apiKey
        creatorInternal = LeapCreatorInternal(apiKey: apiKey)
        creatorInternal?.apiKey = token
        LeapCreatorShared.shared.apiKey = token
        creatorInternal?.start()
    }
    
    public func openSampleApp(delegate: SampleAppDelegate) -> UIViewController? {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return nil } 
        let name = Bundle.main.bundleIdentifier
        if name != "com.leap.LeapSampleApp"  { return nil }
        let leapCameraViewController = LeapCameraViewController()
        leapCameraViewController.sampleAppDelegate = delegate
        leapCameraViewController.delegate = LeapNotificationManager.shared
        return leapCameraViewController
    }
}
