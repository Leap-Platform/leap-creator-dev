//
//  LeapCreator.swift
//  LeapCreator
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

internal let LEAP_SDK_VERSION:String = "1.4.2"

@objc public class LeapCreator: NSObject {
    @objc public static let shared = LeapCreator()
    private var creatorInternal:LeapCreatorInternal?
    private var token:String?
  
   @objc public func start(_ apiKey:String) -> Void {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard floatVersion >= 11 else { return }
        LeapReachabilityManager.shared.initialize()
        token = apiKey
        creatorInternal = LeapCreatorInternal(apiKey: apiKey)
        creatorInternal?.apiKey = token
        LeapCreatorShared.shared.apiKey = token
        creatorInternal?.start()
    }
    
    public func openSampleApp(delegate: SampleAppDelegate) -> UIViewController? {
        let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
        guard floatVersion >= 11 else { return nil}
        let name = Bundle.main.bundleIdentifier
        if name != constant_LeapPreview_BundleId  { return nil }
        let leapCameraViewController = LeapCameraViewController()
        leapCameraViewController.sampleAppDelegate = delegate
        leapCameraViewController.configureSampleApp()
        return leapCameraViewController
    }
}
