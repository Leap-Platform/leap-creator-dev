//
//  LeapContextDetector.swift
//  LeapCore
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapContextDetectorDelegate is a protocol that is to be implemented by the class that needs to communicate with the LeapContextDetector class. This protocol provides callbacks regarding which discovery, page and stage is identifed. It also asks the delegate to provide the relevant flow/discoveries to check from.
protocol LeapContextDetectorDelegate:NSObjectProtocol {
    
    func getWebIdentifier(identifierId:String) -> LeapWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> LeapNativeIdentifier?
    
    func getContextsToCheck() -> Array<LeapContext>
    func getLiveContext() -> LeapContext?
    func contextDetected(context:LeapContext, view:UIView?, rect: CGRect?, webview:UIView?)
    func noContextDetected()
    
    func getCurrentFlow() -> LeapFlow?
    func getParentFlow() -> LeapFlow?
    
    func pageIdentified(_ page:LeapPage)
    func pageNotIdentified()
    
    func getStagesToCheck() -> Array<LeapStage>
    func getCurrentStage() -> LeapStage?
    func stageIdentified(_ stage:LeapStage, pointerView:UIView?, pointerRect:CGRect?, webviewForRect:UIView?)
    func stageNotIdentified()
}

enum LeapContextDetectionState {
    case Discovery
    case Stage
}

/// LeapContextDetector class fetches the assist,discovery or flow to be detected  using its delegate and identifies the dsicovery or stage every 1 second. It informs it delegate which assist, discovery, page, stage has been identified
class LeapContextDetector:NSObject {
    
    private weak var delegate:LeapContextDetectorDelegate?
    private var contextTimer:Timer?
    private var state:LeapContextDetectionState = .Discovery
    private lazy var clickHandler:LeapClickHandler = {
        let clickHandler = LeapClickHandler.shared
        clickHandler.delegate = self
        return clickHandler
    }()
    
    init(withDelegate contextDetectorDelegate:LeapContextDetectorDelegate) {
        delegate = contextDetectorDelegate
        super.init()
    }
    
    func getState() ->LeapContextDetectionState { return state }
    
    func switchState() {
        switch state {
        case .Discovery:
            state = .Stage
        case .Stage:
            state = .Discovery
        }
    }
}

// MARK: - TIMER HANDLER
extension LeapContextDetector {
    
    /// Start context detection by starting one second timer
    func start() {
        contextTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(detectContext), userInfo: nil, repeats: true)
    }
    
    /// Stop context detection by invalidating and removing timer
    func stop() {
        contextTimer?.invalidate()
        contextTimer = nil
    }
}


// MARK: - HIERARCHY FETCHER
extension LeapContextDetector {
    
    /// Get all views and  pass it to find currrent context
    @objc private func detectContext() {
        let allViews = fetchViewHierarchy()
        identifyContext(inHierarchy: allViews)
    }
    
    /// Get all views in the current hierarchy
    /// - Returns: an array of all visible and relevant `UIViews`
    func fetchViewHierarchy() -> [UIView] {
        var views:[UIView] = []
        var allWindows:Array<UIWindow> = []
        allWindows = UIApplication.shared.windows
        let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        if keyWindow != nil {
            if !allWindows.contains(keyWindow!) { allWindows.append(keyWindow!)}
        }
        for window in allWindows { views.append(contentsOf: getChildren(window))}
        return views
    }
    
    /// Fetching all child views and child views of child views recursively
    /// - Parameter currentView: view to find children and subchildren for
    /// - Returns: an array of all views under `currentView`
    private func getChildren(_ currentView:UIView) -> [UIView] {
        var subviewArray:[UIView] = []
        subviewArray.append(currentView)
        let validChildren = currentView.subviews.filter{ !$0.isHidden && ($0.alpha > 0)  && !String(describing: type(of: $0)).contains(constant_leap) }
        var childrenToCheck = getVisibleChildren(validChildren)
        childrenToCheck = childrenToCheck.filter{
            guard let superview = $0.superview else { return true }
            let frameToWindow = superview.convert($0.frame, to: UIApplication.shared.windows.first { $0.isKeyWindow })
            guard let keyWindow = UIApplication.shared.keyWindow else { return true }
            if frameToWindow.minX > keyWindow.frame.maxX || frameToWindow.maxX < 0 { return false }
            return true
        }
        for subview in childrenToCheck {
            subviewArray.append(contentsOf: getChildren(subview))
        }
        return subviewArray
    }
    
    /// Removing overlapped children
    /// - Parameter views: Array of views to be filtered for only visible siblings
    /// - Returns: array of views not completely overlapped by younger siblings
    private func getVisibleChildren(_ views: Array<UIView>) -> Array<UIView> {
        var visibleViews:Array<UIView> = views
        for coveringView in views.reversed() {
            if !visibleViews.contains(coveringView) { continue }
            let index = views.firstIndex(of: coveringView)
            if index == nil || index == 0 { continue }
            let elderSiblings = views[0..<index!]
            let elderSiblingsHiddenByCoveringView = elderSiblings.filter { !visibleViews.contains($0) || coveringView.frame.contains($0.frame) }
            visibleViews = visibleViews.filter { !elderSiblingsHiddenByCoveringView.contains($0) }
        }
        return visibleViews
    }
}

// MARK: - ASSIST/DISCOVERY/PAGE/STAGE IDENTIFICATION
extension LeapContextDetector {
    
    /// Starts to find the relevant context
    /// - Parameter hierarchy: current view hierarchy as an array
    private func identifyContext(inHierarchy hierarchy:Array<UIView>){
        switch state {
        case .Discovery:
            findIdentifiableAssistsAndDiscoveries(in: hierarchy)
        case .Stage:
            findIdentifiablePage(in: hierarchy, forFlow: delegate?.getCurrentFlow())
        }
    }
    
    /// Finds the eligible assists and discoveries when state = .Discovery
    /// - Parameter hierarchy: views to check for eligibility
    private func findIdentifiableAssistsAndDiscoveries(in hierarchy:Array<UIView>) {
        let contextsToCheck:Array<LeapContext> =  delegate?.getContextsToCheck() ?? []
        getPassingIdentifiers(for: contextsToCheck, in: hierarchy) { (passedNativeIds, passedWebIds) in
            let contextsIdentified = self.getPassingContexts(contextsToCheck, passedNativeIds, passedWebIds)
            guard contextsIdentified.count > 0 else {
                self.delegate?.noContextDetected()
                return
            }
            if let liveContext = self.delegate?.getLiveContext() {
                if contextsIdentified.contains(where: { (tempContext) -> Bool in
                    return tempContext.id == liveContext.id
                }) {
                    let assistInfo = liveContext.instruction?.assistInfo
                    self.getViewOrRect(allView: hierarchy, id: assistInfo?.identifier, isWeb: (assistInfo?.isWeb ?? false)) { (anchorView, anchorRect, anchorWebview) in
                        self.delegate?.contextDetected(context: liveContext, view: anchorView, rect: anchorRect, webview: anchorWebview)
                    }
                } else { self.findContextToTrigger(contextsIdentified, allViews: hierarchy) }
            } else { self.findContextToTrigger(contextsIdentified, allViews: hierarchy)}
        }
    }
    
    /// Finds the eligible page for flow when state = .Stage
    /// - Parameters:
    ///   - hierarchy: views to check for eligibilty
    ///   - flowToCheck: the flow containing the pages to check
    private func findIdentifiablePage(in hierarchy:Array<UIView>, forFlow flowToCheck:LeapFlow?) {
        guard let flow = flowToCheck else {
            // No flow. Hence no stage can be identified
            delegate?.pageNotIdentified()
            return
        }
        getPassingIdentifiers(for: flow.pages, in: hierarchy) { (passingNativeIds, passingWebIds) in
            guard let passingPages = self.getPassingContexts(flow.pages, passingNativeIds, passingWebIds) as? Array<LeapPage> else {
                self.findIdentifiablePage(in: hierarchy, forFlow: self.delegate?.getParentFlow())
                return
            }
            guard passingPages.count > 0 else {
                // No passing pages in current flow, hence checking in parent flow
                self.findIdentifiablePage(in: hierarchy, forFlow: self.delegate?.getParentFlow())
                return
            }
            let identifiedPage = passingPages.reduce(passingPages[0]) { (currentPage, pageToCheck) -> LeapPage in
                return currentPage.weight < pageToCheck.weight ? pageToCheck : currentPage
            }
            self.delegate?.pageIdentified(identifiedPage)
            self.findIdentifiableStage(in: hierarchy)
        }
        
    }
    
    /// Finds eligible stage when page is identified
    /// - Parameter hierarchy: views to check for eligibilty
    private func findIdentifiableStage(in hierarchy:Array<UIView>) {
        guard let stages = delegate?.getStagesToCheck(), stages.count > 0 else {
            delegate?.stageNotIdentified()
            return
        }
        getPassingIdentifiers(for: stages, in: hierarchy) { (passedNativeIds, passedWebIds) in
            guard let passingStages = self.getPassingContexts(stages, passedNativeIds, passedWebIds) as? Array<LeapStage> else {
                self.delegate?.stageNotIdentified()
                return
            }
            guard passingStages.count > 0 else {
                self.delegate?.stageNotIdentified()
                return
            }
            if let liveStage = self.delegate?.getCurrentStage(), passingStages.contains(liveStage) {
                let assistInfo = liveStage.instruction?.assistInfo
                self.getViewOrRect(allView: hierarchy, id: assistInfo?.identifier, isWeb: assistInfo?.isWeb ?? false) { (anchorView, anchorRect, webview) in
                    self.delegate?.stageIdentified(liveStage, pointerView: anchorView, pointerRect: anchorRect, webviewForRect: webview)
                }
            } else { self.findContextToTrigger(passingStages, allViews: hierarchy) }
        }
    }
    
    /// Finds if a identified context is to be triggered or has to wait to receive a click
    /// - Parameters:
    ///   - contexts: contexts that was identified by context detection
    ///   - allViews: current hierarchy
    private func findContextToTrigger(_ contexts:Array<LeapContext>, allViews:Array<UIView>) {
        
        // Check for assist/discoveries with instant or delay trigger.
        let instantOrDelayedContexts = contexts.filter { (contextToCheck) -> Bool in
            guard let trigger = contextToCheck.trigger else { return true }
            return trigger.type == .instant || trigger.type == .delay
        }
        
        // Check for assists first. Independent assists have higher preference
        let instantOrDelayedAssists: Array<LeapAssist> = instantOrDelayedContexts.compactMap { return $0 as? LeapAssist }
        let instantOrDelayedContextsToCheckForWeight: Array<LeapContext> = instantOrDelayedAssists.count > 0 ? instantOrDelayedAssists : instantOrDelayedContexts
        
        // Get most weighted assist/discovery
        let instantContextToTrigger = instantOrDelayedContextsToCheckForWeight.reduce(nil) { (res, newContextToCheck) -> LeapContext? in
            if res == nil || res?.weight ?? 0 < newContextToCheck.weight { return newContextToCheck }
            return res
        }
        if let toTriggerContext = instantContextToTrigger {
            // Context to trigger found
            clickHandler.removeAllClickListeners()
            let assistInfo =  toTriggerContext.instruction?.assistInfo
            getViewOrRect(allView: allViews, id: assistInfo?.identifier, isWeb: assistInfo?.isWeb ?? false) { (anchorview, anchorRect, anchorWebview) in
                if self.state == .Discovery {
                    self.delegate?.contextDetected(context: toTriggerContext, view: anchorview, rect: anchorRect, webview: anchorWebview)
                } else {
                    guard let stage = toTriggerContext as? LeapStage else { return }
                    self.delegate?.stageIdentified(stage, pointerView: anchorview, pointerRect: anchorRect, webviewForRect: anchorWebview)
                }
            }
        } else {
            // No instant or delay trigger found. Add click listeners.
            addListeners(allViews: allViews, contexts: contexts)
        }
    }
    
    private func addListeners(allViews:Array<UIView>, contexts:Array<LeapContext>) {
        
        // Filter contexts with identifer
        let contextsWithIdentifiers = contexts.filter{ $0.instruction?.assistInfo?.identifier != nil}
        
        // Split contexts into web context and native context
        let (webContexts, nativeContexts) = contextsWithIdentifiers.reduce(([], [])) { (result, context) -> ([LeapContext], [LeapContext]) in
            var result = result
            if context.instruction?.assistInfo?.isWeb ?? false { result.0.append(context) }
            else { result.1.append(context) }
            return result
        }
        
        // Get views for corresponding native contexts and assign listener
        addNativeListeners(nativeContexts: nativeContexts, in: allViews)
        
        
        // Add listeners for web elements
        guard let wkwebviews = allViews.filter({ $0.isKind(of: WKWebView.self) }) as? Array<WKWebView>, wkwebviews.count > 0, webContexts.count > 0 else { return }
        addWebListeners(webContexts: webContexts, in: wkwebviews)
    }
    
    private func addNativeListeners(nativeContexts:Array<LeapContext>, in hierarchy:Array<UIView>) {
        let nativeContextAndViewArray:Array<(Int,UIView)> = nativeContexts.map { (context) -> (Int, UIView)? in
            guard let instruction = context.instruction, let assistInfo = instruction.assistInfo, let identifier = assistInfo.identifier else { return nil }
            guard let view = getViewsForIdentifer(identifierId: identifier, hierarchy: hierarchy)?.first else { return nil }
            return (context.id,view)
        }.compactMap{ return $0 }
        clickHandler.addClickListeners(nativeContextAndViewArray)
    }
    
    private func addWebListeners(webContexts:Array<LeapContext>, in webviews:Array<WKWebView>) {
        
        var webIdsToCheck = webContexts.map { (context) -> String? in
            return context.instruction?.assistInfo?.identifier
        }.compactMap{ return $0 }
        var passingIdsAndWebView:Dictionary<WKWebView,Array<Dictionary<String,Any>>> = [:]
        webIdsToCheck = Array(Set(webIdsToCheck))
        var counter = 0
        var checkCompletion:((_:Array<String>)->Void)?
        checkCompletion = { passedIds in
            if passedIds.count > 0 {
                webIdsToCheck = webIdsToCheck.filter { !passedIds.contains($0) }
                var contextInfoArray:Array<Dictionary<String,Any>> = []
                for passedId in passedIds {
                    let contextsForPassedId = webContexts.filter{ $0.instruction?.assistInfo?.identifier ?? "" == passedId }
                    let contextInfo = contextsForPassedId.map { (context) -> Dictionary<String,Any>? in
                        guard let webId = self.delegate?.getWebIdentifier(identifierId: passedId) else { return nil }
                        return ["id":context.id, "identifier":webId]
                    }.compactMap { return $0 }
                    contextInfoArray.append(contentsOf: contextInfo)
                }
                passingIdsAndWebView[webviews[counter]] = contextInfoArray
            }
            counter += 1
            if webIdsToCheck.count > 0, counter < webviews.count {
                guard let checkCompletion = checkCompletion else { return }
                self.getPassingWebIds(webIdsToCheck, inSingleWebview: webviews[counter], completion: checkCompletion)
            } else {
                self.clickHandler.addClickListener(to: passingIdsAndWebView)
            }
        }
        guard let completion = checkCompletion else { return }
        getPassingWebIds(webIdsToCheck, inSingleWebview: webviews[counter], completion: completion)
    }
    
    /// Get list of passing native identifiers and webidentifires
    /// - Parameters:
    ///   - contexts: the contexts that need to checked for
    ///   - hierarchy: current view hierarchy
    ///   - checkCompletion: completion block returning the passing native ids and web ids
    ///   - passingNativeIds: Array of native identifier ids which are valid
    ///   - passingWebIds: array of web identifier ids which are valid
    private func getPassingIdentifiers(for contexts:Array<LeapContext>, in hierarchy:Array<UIView>, checkCompletion:@escaping(_ passingNativeIds:Array<String>,_ passingWebIds:Array<String>)->Void) {
        let toCheckNativeIds:Array<String> = contexts.reduce([]) { (nativeIdsArray, context) -> Array<String> in
            if let instructionIdentifier =  context.instruction?.assistInfo?.identifier,
               let isWeb =  context.instruction?.assistInfo?.isWeb, !isWeb {
                return Array(Set(nativeIdsArray+context.nativeIdentifiers+[instructionIdentifier]))
            }
            return Array(Set(nativeIdsArray+context.nativeIdentifiers))
        }
        let toCheckWebIds:Array<String> = contexts.reduce([]) { (webIdsArray, context) -> Array<String> in
            if let instructionIdentifier =  context.instruction?.assistInfo?.identifier,
               let isWeb =  context.instruction?.assistInfo?.isWeb, isWeb {
                return Array(Set(webIdsArray+context.webIdentifiers+[instructionIdentifier]))
            }
            return Array(Set(webIdsArray+context.webIdentifiers))
        }
        let passingNativeIds = getNativeIdentifiersPassing(toCheckNativeIds, inHierarchy: hierarchy)
        let webviews = hierarchy.filter{ $0.isKind(of: WKWebView.self) }
        guard webviews.count > 0, toCheckWebIds.count > 0 else {
            checkCompletion(passingNativeIds,[])
            return
        }
        let currentController = String(describing: type(of: UIApplication.getCurrentVC().self))
        let webIdsPassingControllerCheck = toCheckWebIds.filter { (webIdentifierId) -> Bool in
            guard let webIdentifier = delegate?.getWebIdentifier(identifierId: webIdentifierId) else { return false }
            guard let identifierController = webIdentifier.controller else { return true }
            return identifierController == currentController
        }
        getPassingWebIds(webIdsPassingControllerCheck, inAllWebviews: webviews) { (passedWebIds) in
            checkCompletion(passingNativeIds,passedWebIds)
        }
    }
    
    /// Checks if a contexts native identifers and web identifiers are present in the passing list
    /// - Parameters:
    ///   - passedWebIds: web identifiers that are passing in the current hierarchy
    ///   - passedNativedIds: native identifiers that are passing in the current hierarchy
    ///   - toCheckWebIds: web identifiers of the context that has to be checked
    ///   - toCheckNativeIds: native identifiers of the context that has to be checked
    /// - Returns: true if the context is passing; else false
    private func isContextPassing(_ passedWebIds:Array<String>,_ passedNativedIds:Array<String>,_ toCheckWebIds:Array<String>,_ toCheckNativeIds:Array<String>) -> Bool {
        if toCheckNativeIds.count > 0 { if !(Set(toCheckNativeIds).isSubset(of: Set(passedNativedIds)))  { return false} }
        if toCheckWebIds.count > 0 { if !(Set(toCheckWebIds).isSubset(of: Set(passedWebIds)))  { return false} }
        return true
    }
    
    /// Gets the anchor element(UIVIew for native element; CGRect and corresponding webview for web element)
    /// - Parameters:
    ///   - allView: hierarchy to check against
    ///   - id: the identifier to check for
    ///   - isWeb: whether the identifier is a web or not
    ///   - targetCheckCompleted: completion after finding anchor element
    ///   - view: the corresponding native view if the identifier is native identifier
    ///   - rect: the corresponding CGRect value  if the identifier is web identifier
    ///   - webview: the corresponding webview for the rect if the identifier is web identifier
    func getViewOrRect(allView:Array<UIView>,id:String?, isWeb:Bool, targetCheckCompleted:@escaping(_ view:UIView?,_ rect:CGRect?, _ webview:UIView?)->Void) {
        guard let identifier = id else {
            targetCheckCompleted (nil, nil, nil)
            return
        }
        if isWeb {
            guard let delegate = self.delegate, let webId = delegate.getWebIdentifier(identifierId: identifier) else {
                targetCheckCompleted(nil, nil, nil)
                return
            }
            getRectForIdentifier(id: webId, webviews: allView.filter{ $0.isKind(of: WKWebView.self) }) { (rect, webview) in
                targetCheckCompleted(nil, rect, webview)
            }
        } else {
            guard let delegate = self.delegate, let _ = delegate.getNativeIdentifier(identifierId: identifier) else {
                targetCheckCompleted(nil, nil, nil)
                return
            }
            let views = getViewsForIdentifer(identifierId: identifier, hierarchy: allView)
            targetCheckCompleted(views?.first, nil, nil)
        }
    }
    
    
    private func getPassingContexts(_ contexts: Array<LeapContext>,_ passedNativeIds: Array<String>,_ passedWebIds:Array<String>) -> Array<LeapContext> {
        return contexts.filter { (context) -> Bool in
            guard let instructionIdentifier = context.instruction?.assistInfo?.identifier,
                  let isWeb = context.instruction?.assistInfo?.isWeb else {
                return isContextPassing(passedWebIds, passedNativeIds, context.webIdentifiers, context.nativeIdentifiers)
            }
            if isWeb {
                return isContextPassing(passedWebIds, passedNativeIds, context.webIdentifiers + [instructionIdentifier], context.nativeIdentifiers)
            } else {
                return isContextPassing(passedWebIds, passedNativeIds, context.webIdentifiers, context.nativeIdentifiers + [instructionIdentifier])
            }
        }
    }
    
}

// MARK: - NATIVE IDENTIFIER CHECK
extension LeapContextDetector {
    
    /// Get the passing native identifers
    /// - Parameters:
    ///   - identifiers: array of native identifier ids to check
    ///   - allView: hierarchy to check against
    /// - Returns: an array of passing native identifier ids
    private func getNativeIdentifiersPassing(_ identifiers:Array<String>, inHierarchy allView:Array<UIView>) -> Array<String> {
        guard identifiers.count > 0  else { return [] }
        var controllerFilteredIdentifiers = identifiers
        
        if let currentController = UIApplication.getCurrentVC() {
            let controllerString = String(describing: type(of: currentController.self))
            controllerFilteredIdentifiers = controllerFilteredIdentifiers.filter { (identifier) -> Bool in
                guard let delegate = self.delegate, let nativeIdentifier = delegate.getNativeIdentifier(identifierId: identifier) else { return false }
                guard let controllerCheckString = nativeIdentifier.controller, !controllerCheckString.isEmpty else { return true }
                return controllerString == controllerCheckString
            }
        }
        let alreadyPassedIdentifiers = controllerFilteredIdentifiers.filter { (identifier) -> Bool in
            guard let nativeIdentifier = delegate?.getNativeIdentifier(identifierId: identifier) else { return false }
            guard let _ = nativeIdentifier.idParameters else { return true }
            return false
        }
        let toCheckIdentifiers = controllerFilteredIdentifiers.filter{ !alreadyPassedIdentifiers.contains($0) }
        let passingIds = toCheckIdentifiers.filter { (checkIdentifier) -> Bool in
            let views = getViewsForIdentifer(identifierId: checkIdentifier, hierarchy: allView)
            return views?.count ?? 0 > 0
        }
        
        return (passingIds + alreadyPassedIdentifiers)
    }
    
    /// Get views corresponding to a native identifier
    /// - Parameters:
    ///   - identifierId: the id of the native identifer to find views for
    ///   - hierarchy: the hierarchy of views to check against
    /// - Returns: an array of UIViews passing for the native identifier
    private func getViewsForIdentifer(identifierId:String, hierarchy:Array<UIView>) -> Array<UIView>? {
        guard let delegate = self.delegate, let identifier = delegate.getNativeIdentifier(identifierId: identifierId) else { return nil }
        guard let params = identifier.idParameters else { return nil }
        var anchorViews = getViewsMatchingIdParams(hierarchy, params)
        if let matchingProps = identifier.viewProps {
            anchorViews = getViewsHavingMatchingProps(views: anchorViews, viewProps: matchingProps)
        }
        guard let isAnchorSameAsTarget = identifier.isAnchorSameAsTarget else { return nil }
        if isAnchorSameAsTarget || anchorViews.count == 0 { return anchorViews }
        guard let relations = identifier.relationToTarget else { return anchorViews }
        let targetViews = getViewsFromRelation(anchorViews, relations)
        guard let targetIdParams = identifier.target?.idParameters, targetViews.count > 0 else { return targetViews }
        var targetViewsMatchingIdParams = getViewsMatchingIdParams(targetViews, targetIdParams)
        if let targetMatchingProps = identifier.target?.viewProps {
            targetViewsMatchingIdParams = getViewsHavingMatchingProps(views: targetViewsMatchingIdParams, viewProps: targetMatchingProps)
        }
        return targetViewsMatchingIdParams
    }
    
    
    
    private func getViewsMatchingIdParams(_ views: Array<UIView>,_ params: LeapNativeParameters) -> Array<UIView> {
        var resultViews = views
        if params.accId != nil { resultViews = resultViews.filter{ $0.accessibilityIdentifier == params.accId } }
        if params.accLabel != nil { resultViews = resultViews.filter{ $0.accessibilityLabel == params.accLabel } }
        if params.tag != nil { resultViews = resultViews.filter{ "\($0.tag)" == params.tag } }
        if params.className != nil { resultViews = resultViews.filter{ String(describing: type(of: $0)) == params.className! }}
        if let text = params.text, let localeText = text[constant_ang] {
            resultViews =  resultViews.filter { (view) -> Bool in
                if let label = view as? UILabel { return label.text == localeText }
                else if let button = view as? UIButton { return (button.title(for: .normal) == localeText) }
                else if let textField = view as? UITextField { return textField.text == localeText }
                else if let textView = view as? UITextView { return textView.text == localeText }
                return false
            }
        }
        return resultViews
    }
    
    private func getViewsFromRelation(_ anchorViews: Array<UIView>, _ relations :Array<String>) -> Array<UIView> {
        let targetViews = anchorViews.compactMap { (tempView) -> UIView? in
            var currentview = tempView
            for relation in relations {
                if relation == "P" {
                    guard let superView = currentview.superview else { return nil }
                    currentview = superView
                }
                else if relation.hasPrefix("C") {
                    guard let index = Int(relation.split(separator: "C")[0]), currentview.subviews.count > index else { return nil }
                    currentview = currentview.subviews[index]
                } else if relation.hasPrefix("S") {
                    guard let index = Int(relation.split(separator: "S")[0]),
                          let superView = currentview.superview, superView.subviews.count > index else {return nil }
                    currentview = superView.subviews[index]
                }
            }
            return currentview
        }
        return targetViews
    }
    
    private func getViewsHavingMatchingProps(views: Array<UIView>, viewProps: LeapNativeViewProps) -> Array<UIView> {
        let matchingViews = views.filter { (tempView) -> Bool in
            if let isEnabled = viewProps.isEnabled { return (tempView as? UIControl)?.isEnabled ?? false == isEnabled }
            if let isSelected = viewProps.isSelected { return (tempView as? UIControl)?.isSelected ?? false == isSelected }
            if let isFocused = viewProps.isFocused { return tempView.isFocused == isFocused }
            if let className = viewProps.className { return String(describing: type(of: tempView)) == className }
            if let textDictionary = viewProps.text,  let localeText = textDictionary[constant_ang] {
                if let label = tempView as? UILabel { return label.text == localeText }
                else if let button = tempView as? UIButton { return (button.title(for: .normal) == localeText) }
                else if let textField = tempView as? UITextField { return textField.text == localeText }
                else if let textView = tempView as? UITextView { return textView.text == localeText }
                return false
            }
            return true
        }
        return matchingViews
    }
    
}

// MARK: - WEB IDENTFIER CHECK
extension LeapContextDetector {
    
    /// Get passing web identifiers
    /// - Parameters:
    ///   - webIds: array of all web identifier ids to check
    ///   - inAllWebviews: list of all webviews to check in
    ///   - completion: completion block after calculating the passing the passing web identifiers
    ///   - passingIds: list of passing web identifier ids
    private func getPassingWebIds(_ webIds:Array<String>, inAllWebviews:Array<UIView>, completion: @escaping(_ passingIds:Array<String>)->Void) {
        
        var counter = 0
        var passingWebIds:Array<String> = []
        var passingWebIdsInSingleWebViewCompletion:((_ : Array<String>) -> Void)?
        passingWebIdsInSingleWebViewCompletion = { passingWebIdsInSingleWebView in
            counter += 1
            passingWebIds = Array(Set((passingWebIds + passingWebIdsInSingleWebView)))
            if counter == inAllWebviews.count { completion(passingWebIds) }
            else {
                guard let completion = passingWebIdsInSingleWebViewCompletion else { return }
                self.getPassingWebIds(webIds, inSingleWebview: inAllWebviews[counter], completion: completion)
            }
        }
        guard let completion = passingWebIdsInSingleWebViewCompletion else { return }
        getPassingWebIds(webIds, inSingleWebview: inAllWebviews[counter], completion: completion)
    }
    
    /// Get passing web ids in specific webviwe
    /// - Parameters:
    ///   - webIds: array of all web identifier ids to check
    ///   - inSingleWebview: webview to check in
    ///   - completion: completion block after calculating the passing the passing web identifiers
    ///   - passingIds: list of passing web identifier ids
    private func getPassingWebIds(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ passingIds:Array<String>)->Void) {
        webIdsPresentCheck(allIds: webIds, webview: inSingleWebview) { (presentIds) in
            if let idsPresentInWebview = presentIds {
                self.webIdsPassingCheck(presentIds: idsPresentInWebview, webview: inSingleWebview) { (passingIds) in
                    completion(passingIds ?? [])
                }
            } else { completion([]) }
        }
    }
    
    /// Gets list of web identifier ids which are present in the webview
    /// - Parameters:
    ///   - allIds: array of all web identifiers ids to check
    ///   - webview: the webview to check in
    ///   - completion: completion block after finding the present ids
    ///   - presentIds: the list of web identifier ids that are present in the webview
    private func webIdsPresentCheck(allIds:Array<String>, webview:UIView, completion:@escaping(_ presentIds:Array<String>?)->Void) {
        
        var overAllCheckElementScript = "["
        for (index,id) in allIds.enumerated() {
            if index != 0 { overAllCheckElementScript += "," }
            if let webId = delegate?.getWebIdentifier(identifierId: id) {
                let checkElementScript  = LeapJSMaker.generateNullCheckScript(identifier: webId)
                overAllCheckElementScript += checkElementScript
            } else {
                overAllCheckElementScript += "(document.querySelectorAll('div[class=\"return_false\"')[0] != null).toString()"
            }
        }
        overAllCheckElementScript += "].toString()"
        runJavascript(overAllCheckElementScript, inWebView: webview) { (res) in
            if let result = res {
                let presentIds = self.getPassingIdsFromJSResult(jsResult: result, toCheckIds: allIds)
                completion(presentIds)
            } else { completion([]) }
        }
    }
    
    /// Gets list of web identifier ids which are present and having matching parameters in the webview
    /// - Parameters:
    ///   - presentIds: array of  web identifer ids which are already present in the webview
    ///   - webview: webview to check in
    ///   - completion: completion block after find  passing web identifier ids
    ///   - passingIds: the list of web identifier ids that are passing on the webview
    private func webIdsPassingCheck(presentIds:Array<String>, webview:UIView, completion:@escaping(_ passingIds:Array<String>?)->Void) {
        
        var overallAttributeCheckScript = "["
        for (index, id) in presentIds.enumerated() {
            if let webId = delegate?.getWebIdentifier(identifierId: id) {
                if index != 0 { overallAttributeCheckScript += ","}
                if let attributeElementCheck = LeapJSMaker.generateAttributeCheckScript(webIdentifier: webId) {
                    overallAttributeCheckScript += attributeElementCheck
                } else {
                    let nullCheckScript  = LeapJSMaker.generateNullCheckScript(identifier: webId)
                    overallAttributeCheckScript += nullCheckScript
                }
            } else {
                overallAttributeCheckScript += "(document.querySelectorAll('div[class=\"return_false\"')[0] != null).toString()"
            }
        }
        overallAttributeCheckScript += "].toString()"
        runJavascript(overallAttributeCheckScript, inWebView: webview) { (res) in
            if let result = res {
                let passingIds = self.getPassingIdsFromJSResult(jsResult: result, toCheckIds: presentIds)
                completion(passingIds)
            } else { completion([]) }
        }
    }
    
    /// Gets the rect for a web identifier from a list of webviews
    /// - Parameters:
    ///   - id: the web identifier id to check for
    ///   - webviews: the list if webviews to check in
    ///   - rectCalculated: completion handler after rect is calculated
    ///   - rect: the calculated rect; can be nil
    ///   - webview: the webview in which the rect was found; can be nil
    private func getRectForIdentifier(id:LeapWebIdentifier, webviews:Array<UIView>, rectCalculated:@escaping(_ rect:CGRect?, _ webview:UIView?)->Void) {
        let boundsScript = LeapJSMaker.calculateBoundsScript(id)
        var counter = 0
        var resultCompletion:((_ :CGRect?)->Void)?
        resultCompletion = { rect in
            if rect != nil { rectCalculated(rect, webviews[counter]) }
            else {
                counter += 1
                guard let resultCompletion = resultCompletion else { return }
                if counter < webviews.count { self.calculateBoundsWithScript(_script: boundsScript, in: webviews[counter], rectCalculated: resultCompletion) }
                else { rectCalculated(nil, nil) }
            }
        }
        guard let completion = resultCompletion else { return }
        calculateBoundsWithScript(_script: boundsScript, in: webviews[counter], rectCalculated: completion)
    }
    
    /// Gets the rect for a web identifier from a specific webview
    /// - Parameters:
    ///   - _script: rect calculation script
    ///   - webview: the webview to check the rect for
    ///   - completed: completion handler after calculating rect
    ///   - rect: calculated rect value; can be nil
    private func calculateBoundsWithScript(_script:String, in webview:UIView, rectCalculated completed:@escaping(_ rect:CGRect?)->Void) {
        runJavascript(_script, inWebView: webview) { (res) in
            if let result = res {
                let resultArray = result.components(separatedBy: ",").compactMap({ CGFloat(($0 as NSString).doubleValue) })
                if resultArray.count != 4 { completed(nil) }
                else {
                    let rect = CGRect(x: resultArray[0], y: resultArray[1], width: resultArray[2], height: resultArray[3])
                    completed(rect)
                }
            } else { (completed(nil)) }
        }
    }
    
    /// Runs a  script on a webvview and calculates the result
    /// - Parameters:
    ///   - script: the script to run
    ///   - inWebView: the webview to run in
    ///   - completion: completion block after calculation
    ///   - resultString: the result after script is run; can be nil
    private func runJavascript(_ script:String, inWebView:UIView, completion:@escaping(_ resultString:String?)->Void) {
        if let wkweb = inWebView as? WKWebView {
            wkweb.evaluateJavaScript(script.replacingOccurrences(of: "\n", with: "\\n")) { (res, err) in
                if let result = res as? String { completion(result) }
                else { completion(nil) }
            }
        } else { completion(nil) }
    }
    
    /// Parse js result string to array of bool and get array of identifiers
    /// - Parameters:
    ///   - jsResult: result from javascript injection
    ///   - toCheckIds: the ids that are being checked
    /// - Returns: the ids that are passing
    private func getPassingIdsFromJSResult(jsResult:String, toCheckIds:Array<String>) -> Array<String> {
        let boolStrings = jsResult.components(separatedBy: ",")
        var presentIds:Array<String> = []
        for (index,id) in toCheckIds.enumerated() {
            if NSString(string: boolStrings[index]).boolValue { presentIds.append(id) }
        }
        return presentIds
    }
}


extension LeapContextDetector:LeapClickHandlerDelegate {
    func nativeClickEventForContext(id: Int, onView: UIView) {
        guard let allContexts = state == .Discovery ? delegate?.getContextsToCheck() : delegate?.getStagesToCheck() else { return }
        let contextFound = allContexts.first { $0.id == id }
        guard let triggerContext = contextFound else { return }
        stop()
        switch self.state {
        case .Discovery:
            self.delegate?.contextDetected(context: triggerContext, view: onView, rect: nil, webview: nil)
        case .Stage:
            guard let stage = triggerContext as? LeapStage else { return }
            self.delegate?.stageIdentified(stage, pointerView: onView, pointerRect: nil, webviewForRect: nil)
        }
        start()
    }
    
    func webClickEventForContext(id:Int) {
        guard let allContexts = state == .Discovery ? delegate?.getContextsToCheck() : delegate?.getStagesToCheck() else { return }
        let contextFound = allContexts.first { $0.id == id }
        guard let triggerContext = contextFound,
              let identifierId = triggerContext.instruction?.assistInfo?.identifier,
              let webIdentifier = delegate?.getWebIdentifier(identifierId: identifierId),
              let webviews = fetchViewHierarchy().filter({ $0.isKind(of: WKWebView.self) }) as? Array<WKWebView>
        else { return }
        stop()
        getRectForIdentifier(id: webIdentifier, webviews: webviews) { (rect, webview) in
            switch self.state {
            case .Discovery:
                self.delegate?.contextDetected(context: triggerContext, view: nil, rect: rect, webview: webview)
            case .Stage:
                guard let stage = triggerContext as? LeapStage else { return }
                self.delegate?.stageIdentified(stage, pointerView: nil, pointerRect: rect, webviewForRect: webview)
            }
            self.start()
        }
    }
}
