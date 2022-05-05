//
//  LeapContextsValidator.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

/// LeapContextsValidator assists in getting valid LeapContexts for the provided hierarchy
class LeapContextsValidator {
    
    /// Valid contexts for hierachy provided
    /// - Parameters:
    ///   - hierarchy: Hierachy to check against
    ///   - contexts: All relevant contexts to check for
    ///   - nativeIdentifierFor: Callback to get native identifer for the corresponding id from the config
    ///   - webIdentifierFor: Callback to get web identifer for the corresponding id from the config
    ///   - completion: Completion callback providing all the valid contexts; in case no valid contexts, returns empty array
    public func findValidContextsIn(_ hierarchy:[String:LeapViewProperties],
                                    contexts:[LeapContext],
                                    nativeIdentifierFor:(_ nativeIdentifierId:String) -> LeapNativeIdentifier?,
                                    webIdentifierFor:(_ webIdentifierId:String) -> LeapWebIdentifier?,
                                    completion:@escaping(_ validContexts:[LeapContext]) -> Void) {
        
        let nativeIdentifierIds = nativeIdentifierIdList(from :contexts)
        let webIdentifierIds = webIdentifierIdList(from :contexts)
        
        var passingNativeIdentifierIds:[String] = []
        let nativeViewFinder = LeapNativeViewFinder(with: hierarchy)
        for nativeIdentifierId in nativeIdentifierIds {
            if let nativeIdentifier = nativeIdentifierFor(nativeIdentifierId),
               nativeViewFinder.isIdentifierValid(nativeIdentifier) {
                passingNativeIdentifierIds.append(nativeIdentifierId)
            }
        }
        
        let webViewFinder = LeapWebViewFinder(with: hierarchy)
        var webIdentifierTuples:[(String,LeapWebIdentifier)] = []
        for webIdentifierId in webIdentifierIds {
            if let webIdentifier = webIdentifierFor(webIdentifierId) {
                webIdentifierTuples.append((webIdentifierId, webIdentifier))
            }
        }
        webViewFinder.getValidIdentifiers(from: webIdentifierTuples) {[weak self] passedWebIds in
            let passingContexts = self?.validContextsFrom(contexts, forPassing: passingNativeIdentifierIds, and: passedWebIds) ?? []
            completion(passingContexts)
        }
    }
    
    /// Get lists of all native identifier ids to check for from the contexts
    /// - Parameter contexts: Contexts to retrive the ids from
    /// - Returns: Native identifiers list from all relevant contexts after removing duplicates
    private func nativeIdentifierIdList(from contexts:[LeapContext]) -> [String] {
        return contexts.reduce([]) { currentList, currentContext in
            return Array(Set(currentList + currentContext.nativeIdentifiers))
        }
    }
    
    /// Get lists of all web identifier ids to check for from the contexts
    /// - Parameter contexts: Contexts to retrive the ids from
    /// - Returns: Web identifiers list from all relevant contexts after removing duplicates
    private func webIdentifierIdList(from contexts:[LeapContext]) -> [String] {
        return contexts.reduce([]) { currentList, currentContext in
            return Array(Set(currentList + currentContext.webIdentifiers))
        }
    }
    
    /// Returns passing contexts based on the passing native ids and passing web ids
    /// - Parameters:
    ///   - contexts: All contexts passed for checking
    ///   - nativeIds: Passing native ids list
    ///   - webIds: Passing web ids list
    /// - Returns: Passing contexts
    private func validContextsFrom(_ contexts:[LeapContext], forPassing nativeIds:[String], and webIds:[String]) -> [LeapContext] {
        return contexts.filter { context in
            if context.webIdentifiers.count > 0 {
                guard Set(context.webIdentifiers).isSubset(of: Set(webIds)) else { return false }
            }
            if context.nativeIdentifiers.count > 0 {
                guard Set(context.nativeIdentifiers).isSubset(of: Set(nativeIds)) else { return false }
            }
            return true
        }
    }
    
}
