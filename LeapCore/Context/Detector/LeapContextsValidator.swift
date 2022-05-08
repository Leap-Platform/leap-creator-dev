//
//  LeapContextsValidator.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapContextsValidator helps in getting valid LeapContexts for the provided hierarchy
class LeapContextsValidator<T:LeapContext> {
    
    /// The dictionary containing info of native identifiers
    let nativeIdentifierDict:[String:LeapNativeIdentifier]
    
    /// The dictionary containing info of web identifiers
    let webIdentifierDict:[String:LeapWebIdentifier]
    
    /// initialisation method
    /// - Parameters:
    ///   - withNativeDict: The dictionary containing info of native identifiers
    ///   - webDict: The dictionary containing info of web identifiers
    init(withNativeDict:[String:LeapNativeIdentifier], webDict:[String:LeapWebIdentifier]) {
        nativeIdentifierDict = withNativeDict
        webIdentifierDict = webDict
    }
    
    /// Valid contexts for hierachy provided
    /// - Parameters:
    ///   - hierarchy: Hierachy to check against
    ///   - contexts: All relevant contexts to check for
    ///   - completion: Completion callback providing all the valid contexts; in case no valid contexts, returns empty array
    public func findValidContextsIn(_ hierarchy:[String:LeapViewProperties], contexts:[T],
                                    completion:@escaping(_ validContexts:[T]) -> Void) {
        
        let nativeIdentifierIds = nativeIdentifierIdList(from :contexts)
        let webIdentifierIds = webIdentifierIdList(from :contexts)
        
        var passingNativeIdentifierIds:[String] = []
        let nativeViewFinder = LeapNativeViewFinder(with: hierarchy)
        for nativeIdentifierId in nativeIdentifierIds {
            if let nativeIdentifier = nativeIdentifierDict[nativeIdentifierId],
               nativeViewFinder.isIdentifierValid(nativeIdentifier) {
                passingNativeIdentifierIds.append(nativeIdentifierId)
            }
        }
        
        let webViewFinder = LeapWebViewFinder(with: hierarchy)
        var webIdentifierTuples:[(String,LeapWebIdentifier)] = []
        for webIdentifierId in webIdentifierIds {
            if let webIdentifier = webIdentifierDict[webIdentifierId] {
                webIdentifierTuples.append((webIdentifierId, webIdentifier))
            }
        }
        webViewFinder.getValidIdentifiers(from: webIdentifierTuples) {[weak self] passedWebIds in
            let passingContexts = self?.validContextsFrom(contexts, forPassing: passingNativeIdentifierIds, and: passedWebIds) ?? []
            completion(passingContexts)
        }
    }
    
    /// Get context to trigger along with necessary anchor view
    /// - Parameters:
    ///   - liveContext: The current running context if any
    ///   - validContexts: The list of valid contexts
    ///   - hierarchy: The hierarchy to check in
    ///   - completion: Completion callback providing the context, view, rect, webview according to which is relevant. Irrelevant ones would be nil. If not context if triggerable, context value will also be nil
    public func getTriggerableContext(_ liveContext:T?, validContexts:[T], hierarchy:[String:LeapViewProperties],
                                      _ completion:@escaping(_ contextToTrigger:T?,
                                                             _ anchorViewId:String?,
                                                             _ anchorRect:CGRect?,
                                                             _ anchorWebview:WKWebView?)->Void) {
        var contextToCheck:T? = liveContext ?? highestPreferredContext(validContexts)
        var isTriggerableCompletion:((_:Bool, _:String?, _:CGRect?, _:WKWebView?)->Void)? = nil
        isTriggerableCompletion = {[weak self] triggerable, anchorViewId, anchorRect, anchorWebview in
            if triggerable { completion(contextToCheck, anchorViewId, anchorRect, anchorWebview) }
            else {
                if contextToCheck != liveContext { completion(nil,anchorViewId,anchorRect,anchorWebview) }
                else {
                    contextToCheck = self?.highestPreferredContext(validContexts)
                    guard contextToCheck != liveContext else {
                        completion(nil,anchorViewId,anchorRect,anchorWebview)
                        return
                    }
                    self?.isContextTriggerable(contextToCheck, hierarchy: hierarchy, completion: isTriggerableCompletion!)
                }
            }
        }
        isContextTriggerable(contextToCheck, hierarchy: hierarchy, completion: isTriggerableCompletion!)
    }
    
    /// Get highest preferred context based on weight
    /// - Parameter contexts: List of contexts to check in
    /// - Returns: Highest preferred context
    public func highestPreferredContext(_ contexts:[T]) -> T? {
        guard contexts.count > 0 else { return nil }
        let instantOrDelayedContexts = contexts.filter { (contextToCheck) -> Bool in
            guard let trigger = contextToCheck.trigger else { return true }
            return trigger.type == .instant || trigger.type == .delay
        }
        let instantOrDelayedAssists: [LeapAssist] = instantOrDelayedContexts.compactMap { return $0 as? LeapAssist }
        let instantOrDelayedContextsToCheckForWeight: [LeapContext] = instantOrDelayedAssists.count > 0 ? instantOrDelayedAssists : instantOrDelayedContexts
        
        let selectedContext = instantOrDelayedContextsToCheckForWeight.reduce(contexts[0]) { currrentContext, toCheckContext in
            return toCheckContext.weight > currrentContext.weight ? toCheckContext : currrentContext
        }
        return selectedContext as? T
    }
    
    /// Checks if a context is triggerable
    /// - Parameters:
    ///   - context: The context to check
    ///   - hierarchy: The hierarchy to check in
    ///   - completion: Completion callback letting if it is triggerable; If triggerable relevant info like anchor view, anchor rect, webview are also returned. Irrelevant ones will be nil
    private func isContextTriggerable(_ context:T?, hierarchy:[String:LeapViewProperties],
                                      completion:@escaping(_ isTriggerable:Bool,
                                                           _ anchorViewId:String?,
                                                           _ anchorRect:CGRect?,
                                                           _ webview:WKWebView?)->Void) {
        guard let context = context else {
            completion(false, nil, nil, nil)
            return
        }

        guard let assistInfo = context.instruction?.assistInfo,
              let identifier = assistInfo.identifier else {
            completion(true, nil, nil, nil)
            return
        }
        
        if assistInfo.isWeb{
            guard let webIdentifier = webIdentifierDict[identifier] else {
                completion(false, nil, nil, nil)
                return
            }
            getAnchorViewRect(for: webIdentifier, in: hierarchy) { rect, webview in
                completion(rect != nil, nil, rect, webview)
                return
            }
        } else {
            guard let nativeIdentifier = nativeIdentifierDict[identifier],
                  let anchorViewId = getNativeAnchorView(for: nativeIdentifier, in: hierarchy) else {
                completion(false, nil, nil, nil)
                return
            }
            completion(true, anchorViewId, nil, nil)
        }
    }
    
    /// Get the native view for identifier from hierarchy
    /// - Parameters:
    ///   - identifier: The identifier to get native view for
    ///   - hierarchy: The hierarchy to check in
    /// - Returns: Native view if found; else nil
    private func getNativeAnchorView(for identifier:LeapNativeIdentifier, in hierarchy:[String:LeapViewProperties]) -> String? {
        let nativeViewFinder = LeapNativeViewFinder(with: hierarchy)
        guard let viewId = nativeViewFinder.viewIdFor(identifier) else { return nil }
        return viewId
    }
    
    /// Get the rect and webview for web identifier from hierarchy
    /// - Parameters:
    ///   - identifier: The web identifier to get rect for
    ///   - hierarchy: The hierarchy to search in
    ///   - completion: Completion callback to get the rect and webview in which element is present; Both are nil if not found
    private func getAnchorViewRect(for identifier:LeapWebIdentifier, in hierarchy:[String:LeapViewProperties], completion:@escaping(_ rect:CGRect?, _ webview:WKWebView?)->Void) {
        let webViewFinder = LeapWebViewFinder(with: hierarchy)
        webViewFinder.getRectFor(identifier) { rect, webview in
            completion(rect, webview)
        }
    }
    
    /// Get lists of all native identifier ids to check for from the contexts
    /// - Parameter contexts: Contexts to retrive the ids from
    /// - Returns: Native identifiers list from all relevant contexts after removing duplicates
    private func nativeIdentifierIdList(from contexts:[T]) -> [String] {
        return contexts.reduce([]) { currentList, currentContext in
            return Array(Set(currentList + currentContext.nativeIdentifiers))
        }
    }
    
    /// Get lists of all web identifier ids to check for from the contexts
    /// - Parameter contexts: Contexts to retrive the ids from
    /// - Returns: Web identifiers list from all relevant contexts after removing duplicates
    private func webIdentifierIdList(from contexts:[T]) -> [String] {
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
    private func validContextsFrom(_ contexts:[T], forPassing nativeIds:[String], and webIds:[String]) -> [T] {
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
