//
//  LeapViewFinder.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapViewFinder {
    
    public func findValidContextsIn(_ hierarchy:[String:LeapViewProperties],
                             contexts:[LeapContext],
                             nativeIdentifierFor:(_ nativeIdentifierId:String) -> LeapNativeIdentifier?,
                             webIdentifierFor:(_ webIdentifierId:String) -> LeapWebIdentifier?,
                             completion:(_ validContexts:[LeapContext]) -> Void) {
        
        let nativeIdentifierIds = nativeIdentifierIdList(from :contexts)
        let webIdentifierIds = webIdentifierIdList(from :contexts)
        var passingNativeIdentifierIds:[String] = []
        for nativeIdentifierId in nativeIdentifierIds {
            if let nativeIdentifier = nativeIdentifierFor(nativeIdentifierId),
                LeapNativeViewFinder().isViewFor(nativeIdentifier, presentIn: hierarchy) {
                passingNativeIdentifierIds.append(nativeIdentifierId)
            }
        }
    }
    
    private func nativeIdentifierIdList(from contexts:[LeapContext]) -> [String] {
        return contexts.reduce([]) { currentList, currentContext in
            return Array(Set(currentList + currentContext.nativeIdentifiers))
        }
    }
    
    private func webIdentifierIdList(from contexts:[LeapContext]) -> [String] {
        return contexts.reduce([]) { currentList, currentContext in
            return Array(Set(currentList + currentContext.webIdentifiers))
        }
    }
    
}
