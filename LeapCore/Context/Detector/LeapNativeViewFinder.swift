//
//  LeapNativeViewFinder.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapNativeViewFinder {
    
    
    public func isViewFor(_ identifer:LeapNativeIdentifier, presentIn hierarchy:[String:LeapViewProperties]) -> Bool {
        guard let _ = viewIdFor(identifer, in: hierarchy) else { return false }
        return true
    }
    
    public func viewIdFor(_ nativeIdentifier:LeapNativeIdentifier, in hierarchy:[String:LeapViewProperties]) -> String? {
        var viewId:String? = nil
        hierarchy.forEach { tempViewId, viewProps in
            if viewId == nil {
                if isNativeIdentifier(nativeIdentifier, matching: viewProps) { viewId = tempViewId }
            }
        }
        return viewId
    }
    
    private func isNativeIdentifier(_ nativeIdentifier:LeapNativeIdentifier, matching viewProps:LeapViewProperties) -> Bool {
        if let currentVC = UIApplication.getCurrentVC() {
            let currentVCString = String(describing: type(of: currentVC.self))
            let identifierController = nativeIdentifier.controller
            if currentVCString != identifierController { return false }
        } else if let _ = nativeIdentifier.controller { return false }
        guard let idParams = nativeIdentifier.idParameters else { return true }
        
        return true
    }
    
    private func isIdParams(_ idParams:LeapNativeParameters, matchingProps props:LeapViewProperties) -> Bool {
        
        return false
    }
    
}
