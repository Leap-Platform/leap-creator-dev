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
  
   @objc public func initialize(withToken apiKey:String) -> Void {
        LeapReachabilityManager.shared.initialize()
        token = apiKey
        creatorInternal = LeapCreatorInternal(apiKey: apiKey)
        creatorInternal?.apiKey = token
        LeapCreatorShared.shared.apiKey = token
        creatorInternal?.start()
    }
    
    public func openSampleApp(delegate: SampleAppDelegate) -> UIViewController {
        let leapCameraViewController = LeapCameraViewController()
        leapCameraViewController.sampleAppDelegate = delegate
        return leapCameraViewController
    }
}
