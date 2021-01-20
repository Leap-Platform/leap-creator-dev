//
//  JinyContextDetector.swift
//  JinySDK
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyContextDetectorDelegate is a protocol that is to be implemented by the class that needs to communicate with the JinyContextDetector class. This protocol provides callbacks regarding which discovery, page and stage is identifed. It also asks the delegate to provide the relevant flow/discoveries to check from.
protocol JinyContextDetectorDelegate:NSObjectProtocol {
    
    func getWebIdentifier(identifierId:String) -> JinyWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> JinyNativeIdentifier?
    
    func contextDetected(context:JinyContext, view:UIView?, rect: CGRect?, webview:UIView?)
    func contextsDetected(contextObjs:Array<(JinyContext,UIView?,CGRect?, UIView?)>)
    func noContextDetected()
    
    func getAssistsToCheck() -> Array<JinyAssist>
    func assistsFound(assists:Array<(JinyAssist, UIView?, CGRect?, UIView?)>)
    func assistNotFound()
    
    func getDiscoveriesToCheck()->Array<JinyDiscovery>
    func discoveriesFound(discoveries:Array<(JinyDiscovery, UIView?, CGRect?, UIView?)>)
    func noDiscoveryFound()
    
    func getCurrentFlow() -> JinyFlow?
    func getParentFlow() -> JinyFlow?
    func pageIdentified(_ page:JinyPage)
    func pageNotIdentified()
    
    func getStagesToCheck() -> Array<JinyStage>
    func stageIdentified(_ stage:JinyStage, pointerView:UIView?, pointerRect:CGRect?, webviewForRect:UIView?)
    func stageNotIdentified()
}

enum JinyContextDetectionState {
    case Discovery
    case Stage
}

/// JinyContextDetector class fetches the assist,discovery or flow to be detected  using its delegate and identifies the dsicovery or stage every 1 second. It informs it delegate which assist, discovery, page, stage has been identified
class JinyContextDetector:NSObject {
    
    private weak var delegate:JinyContextDetectorDelegate?
    private var contextTimer:Timer?
    private var state:JinyContextDetectionState = .Discovery
    private lazy var clickHandler:JinyClickHandler = {
        let clickHandler = JinyClickHandler.shared
        clickHandler.delegate = self
        return clickHandler
    }()
    
    init(withDelegate contextDetectorDelegate:JinyContextDetectorDelegate) {
        delegate = contextDetectorDelegate
        super.init()
    }
    
    func getState() ->JinyContextDetectionState { return state }
    
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

extension JinyContextDetector {
    
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
extension JinyContextDetector {
    
    /// Get all views and  pass it to find currrent context
    @objc private func detectContext() {
        let allViews = fetchViewHierarchy()
        identifyContext(inHierarchy: allViews)
    }
    
    /// Get all views in the current hierarchy
    /// - Returns: an array of all visible and relevant `UIViews`
    private func fetchViewHierarchy() -> [UIView] {
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
        var childrenToCheck = (currentView.window == UIApplication.shared.windows.first { $0.isKeyWindow }) ? getVisibleChildren(currentView.subviews) : currentView.subviews
        childrenToCheck = childrenToCheck.filter{ !$0.isHidden && ($0.alpha > 0)  && !String(describing: type(of: $0)).contains("Jiny") }
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
        var visibleViews = views
        for view in views.reversed() {
            if !visibleViews.contains(view) { continue }
            let indexOfView =  views.firstIndex(of: view)
            if indexOfView == nil  { break }
            if indexOfView == 0 { break }
            let viewsToCheck = visibleViews[0..<indexOfView!]
            let hiddenViews = viewsToCheck.filter { view.frame.contains($0.frame) }
            visibleViews = visibleViews.filter { !hiddenViews.contains($0) }
        }
        return visibleViews
    }
}

// MARK: - ASSIST/DISCOVERY/PAGE/STAGE IDENTIFICATION
extension JinyContextDetector {
    
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
        let contextsToCheck:Array<JinyContext> = (delegate?.getAssistsToCheck() ?? []) + (delegate?.getDiscoveriesToCheck() ?? [])
        getPassingIdentifiers(for: contextsToCheck, in: hierarchy) { (passedNativeIds, passedWebIds) in
            let contextsIdentified = contextsToCheck.filter { self.isContextPassing(passedWebIds, passedNativeIds, $0.webIdentifiers, $0.nativeIdentifiers) }
            guard contextsIdentified.count > 0 else {
                self.delegate?.noContextDetected()
                return
            }
            self.findContextToTrigger(contextsIdentified, allViews: hierarchy)
        }
    }
    
    /// Finds the eligible page for flow when state = .Stage
    /// - Parameters:
    ///   - hierarchy: views to check for eligibilty
    ///   - flowToCheck: the flow containing the pages to check
    private func findIdentifiablePage(in hierarchy:Array<UIView>, forFlow flowToCheck:JinyFlow?) {
        guard let flow = flowToCheck else {
            // No flow. Hence no stage can be identified
            delegate?.stageNotIdentified()
            return
        }
        getPassingIdentifiers(for: flow.pages, in: hierarchy) { (passingNativeIds, passingWebIds) in
            let passingPages = flow.pages.filter { self.isContextPassing(passingWebIds, passingNativeIds, $0.webIdentifiers, $0.nativeIdentifiers) }
            guard passingPages.count > 0 else {
                // No passing pages in current flow, hence checking in parent flow
                self.findIdentifiablePage(in: hierarchy, forFlow: self.delegate?.getParentFlow())
                return
            }
            let identifiedPage = passingPages.reduce(passingPages[0]) { (currentPage, pageToCheck) -> JinyPage in
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
            self.findIdentifiablePage(in: hierarchy, forFlow: delegate?.getParentFlow())
            return
        }
        getPassingIdentifiers(for: stages, in: hierarchy) { (passedNativeIds, passedWebIds) in
            let passingStages = stages.filter{ self.isContextPassing(passedWebIds, passedNativeIds, $0.webIdentifiers, $0.nativeIdentifiers) }
            guard passingStages.count > 0 else {
                self.findIdentifiablePage(in: hierarchy, forFlow: self.delegate?.getParentFlow())
                return
            }
            let identifiedStage = passingStages.reduce(passingStages[0]) { (currentStage, stageToCheck) -> JinyStage in
                return currentStage.weight < stageToCheck.weight ? stageToCheck : currentStage
            }
            self.getViewOrRect(allView: hierarchy, id: identifiedStage.instruction?.assistInfo?.identifier, isWeb: identifiedStage.instruction?.assistInfo?.isWeb ?? false) { (anchorView, anchorRect, anchorWebview) in
                self.delegate?.stageIdentified(identifiedStage, pointerView: anchorView, pointerRect: anchorRect, webviewForRect: anchorWebview)
            }
        }
    }
    
    /// Finds if a identified context is to be triggered or has to wait to receive a click
    /// - Parameters:
    ///   - contexts: contexts that was identified by context detection
    ///   - allViews: current hierarchy
    private func findContextToTrigger(_ contexts:Array<JinyContext>, allViews:Array<UIView>) {
        
        // Check for assist/discoveries with instant or delay trigger.
        let instantOrDelayedContexts = contexts.filter { (contextToCheck) -> Bool in
            guard let trigger = contextToCheck.trigger else { return true }
            return trigger.type == "instant" || trigger.type == "delay"
        }
        
        // Get most weighted assist/discovery
        let instantContextToTrigger = instantOrDelayedContexts.reduce(nil) { (res, newContextToCheck) -> JinyContext? in
            if res == nil || res?.weight ?? 0 < newContextToCheck.weight { return newContextToCheck }
            return res
        }
        if let toTriggerContext = instantContextToTrigger {
            // Context to trigger found
            clickHandler.removeAllClickListeners()
            let assistInfo =  toTriggerContext.instruction?.assistInfo
            getViewOrRect(allView: allViews, id: assistInfo?.identifier, isWeb: assistInfo?.isWeb ?? false) { (anchorview, anchorRect, anchorWebview) in
                self.delegate?.contextDetected(context: toTriggerContext, view: anchorview, rect: anchorRect, webview: anchorWebview)
            }
        } else {
            // No instant or delay trigger found. Add click listeners.
            addListeners(allViews: allViews, contexts: contexts)
        }
    }
    
    private func addListeners(allViews:Array<UIView>, contexts:Array<JinyContext>) {
        
        // Filter contexts with identifer
        let contextsWithIdentifiers = contexts.filter{ $0.instruction?.assistInfo?.identifier != nil}
        
        // Split contexts into web context and native context
        let (webContexts, nativeContexts) = contextsWithIdentifiers.reduce(([], [])) { (result, context) -> ([JinyContext], [JinyContext]) in
            var result = result
            if context.instruction?.assistInfo?.isWeb ?? false { result.0.append(context) }
            else { result.1.append(context) }
            return result
        }
        
        // Get views for corresponding native contexts and assign listener
        let nativeContextAndViewArray:Array<(Int,UIView)> = nativeContexts.map { (context) -> (Int, UIView)? in
            let identifier = context.instruction!.assistInfo!.identifier!
            guard let view = getViewsForIdentifer(identifierId: identifier, hierarchy: allViews)?.first else { return nil }
            return (context.id,view)
        }.compactMap{ return $0 }
        clickHandler.addClickListeners(nativeContextAndViewArray)
        
    }
    
    /// Get list of passing native identifiers and webidentifires
    /// - Parameters:
    ///   - contexts: the contexts that need to checked for
    ///   - hierarchy: current view hierarchy
    ///   - checkCompletion: completion block returning the passing native ids and web ids
    ///   - passingNativeIds: Array of native identifier ids which are valid
    ///   - passingWebIds: array of web identifier ids which are valid
    private func getPassingIdentifiers(for contexts:Array<JinyContext>, in hierarchy:Array<UIView>, checkCompletion:@escaping(_ passingNativeIds:Array<String>,_ passingWebIds:Array<String>)->Void) {
        let toCheckNativeIds:Array<String> = contexts.reduce([]) { (nativeIdsArray, context) -> Array<String> in
            return Array(Set(nativeIdsArray+context.nativeIdentifiers))
        }
        let toCheckWebIds:Array<String> = contexts.reduce([]) { (webIdsArray, context) -> Array<String> in
            return Array(Set(webIdsArray+context.webIdentifiers))
        }
        let passingNativeIds = getNativeIdentifiersPassing(toCheckNativeIds, inHierarchy: hierarchy)
        let webviews = hierarchy.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
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
    private func getViewOrRect(allView:Array<UIView>,id:String?, isWeb:Bool, targetCheckCompleted:@escaping(_ view:UIView?,_ rect:CGRect?, _ webview:UIView?)->Void) {
        guard let identifier = id else {
            targetCheckCompleted (nil, nil, nil)
            return
        }
        if isWeb {
            guard let webId = delegate!.getWebIdentifier(identifierId: identifier) else {
                targetCheckCompleted(nil, nil, nil)
                return
            }
            getRectForIdentifier(id: webId, webviews: allView.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }) { (rect, webview) in
                targetCheckCompleted(nil, rect, webview)
            }
        } else {
            guard let _ = delegate!.getNativeIdentifier(identifierId: identifier) else {
                targetCheckCompleted(nil, nil, nil)
                return
            }
            let views = getViewsForIdentifer(identifierId: identifier, hierarchy: allView)
            targetCheckCompleted(views?.first, nil, nil)
        }
    }
    
}

// MARK: - NATIVE IDENTIFIER CHECK
extension JinyContextDetector {
    
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
                guard let nativeIdentifier = delegate!.getNativeIdentifier(identifierId: identifier) else { return false }
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
        guard let identifier = delegate!.getNativeIdentifier(identifierId: identifierId) else { return nil }
        guard let params = identifier.idParameters else { return nil }
        var anchorViews = hierarchy
        if params.accId != nil { anchorViews = anchorViews.filter{ $0.accessibilityIdentifier == params.accId } }
        if params.accLabel != nil { anchorViews = anchorViews.filter{ $0.accessibilityLabel == params.accLabel } }
        if params.tag != nil { anchorViews = anchorViews.filter{ $0.tag == params.tag } }
        if params.text != nil {
            if let localeText = params.text![constant_ang] {
                anchorViews =  anchorViews.filter { (view) -> Bool in
                    if let label = view as? UILabel {
                        return label.text == localeText
                    } else if let button = view as? UIButton {
                        return (button.title(for: .normal) == localeText)
                    } else if let textField = view as? UITextField {
                        return textField.text == localeText
                    } else if let textView = view as? UITextView {
                        return textView.text == localeText
                    }
                    return false
                }
            }
        }
        if params.placeholder != nil {
            if let localeText = params.placeholder![constant_ang] {
                anchorViews =  anchorViews.filter { (view) -> Bool in
                    if let label = view as? UILabel {
                        return label.text == localeText
                    } else if let button = view as? UIButton {
                        return (button.title(for: .normal) == localeText)
                    } else if let textField = view as? UITextField {
                        return textField.text == localeText
                    } else if let textView = view as? UITextView {
                        return textView.text == localeText
                    }
                    return false
                }
            }
        }
        if let nesting = identifier.nesting {
            let nestArray = nesting.split(separator: "-")
            let nestedViews = anchorViews.map({ (tempView) -> UIView? in
                var nestedView = tempView
                for pos in nestArray {
                    if let intPos = Int(pos) {
                        if tempView.subviews.count > intPos {
                            nestedView = nestedView.subviews[intPos]
                        } else { return nil }
                    } else { return nil }
                }
                return nestedView
            }).filter { $0 != nil } as! Array<UIView>
            anchorViews = nestedViews
        }
        if identifier.isAnchorSameAsTarget! { return anchorViews }
        
        let targetViews = anchorViews.map { (tempView) -> UIView? in
            var currentview = tempView
            if let relations = identifier.relationToTarget {
                for relation in relations {
                    if relation == "P" {
                        guard let superView = currentview.superview else { return nil }
                        currentview = superView
                    }
                    else if relation.hasPrefix("C") {
                        guard let index = Int(relation.split(separator: "C")[0]), currentview.subviews.count > index else { return nil }
                        currentview = currentview.subviews[index]
                    } else if relation.hasPrefix("S") {
                        guard let index = Int(relation.split(separator: "S")[0]), let superView = currentview.superview, superView.subviews.count > index else {return nil }
                        currentview = superView.subviews[index]
                    }
                }
            }
            return currentview
        }.filter { $0 != nil } as! Array<UIView>
        
        return targetViews
    }
    
}

// MARK: - WEB IDENTFIER CHECK
extension JinyContextDetector {
    
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
                self.getPassingWebIds(webIds, inSingleWebview: inAllWebviews[counter], completion: passingWebIdsInSingleWebViewCompletion!)
            }
        }
        getPassingWebIds(webIds, inSingleWebview: inAllWebviews[counter], completion: passingWebIdsInSingleWebViewCompletion!)
        
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
                let checkElementScript  = JinyJSMaker.generateNullCheckScript(identifier: webId)
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
                if let attributeElementCheck = JinyJSMaker.generateAttributeCheckScript(webIdentifier: webId) {
                    overallAttributeCheckScript += attributeElementCheck
                } else {
                    let nullCheckScript  = JinyJSMaker.generateNullCheckScript(identifier: webId)
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
    private func getRectForIdentifier(id:JinyWebIdentifier, webviews:Array<UIView>, rectCalculated:@escaping(_ rect:CGRect?, _ webview:UIView?)->Void) {
        let boundsScript = JinyJSMaker.calculateBoundsScript(id)
        var counter = 0
        var resultCompletion:((_ :CGRect?)->Void)?
        resultCompletion = { rect in
            if rect != nil { rectCalculated(rect, webviews[counter]) }
            else {
                counter += 1
                if counter < webviews.count { self.calculateBoundsWithScript(_script: boundsScript, in: webviews[counter], rectCalculated: resultCompletion!) }
                else { rectCalculated(nil, nil) }
            }
        }
        calculateBoundsWithScript(_script: boundsScript, in: webviews[counter], rectCalculated: resultCompletion!)
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
        } else if let uiweb = inWebView as? UIWebView {
            let result = uiweb.stringByEvaluatingJavaScript(from: script.replacingOccurrences(of: "\n", with: "\\n"))
            completion(result)
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


extension JinyContextDetector:JinyClickHandlerDelegate {
    
    func nativeClickEventForContext(id: Int, onView: UIView) {
        let allContexts = (delegate?.getAssistsToCheck() ?? []) + (delegate?.getDiscoveriesToCheck() ?? [])
        let contextFound = allContexts.first { $0.id == id }
        guard let triggerContext = contextFound else { return }
        stop()
        delegate?.contextDetected(context: triggerContext, view: onView, rect: nil, webview: nil)
        start()
    }
    
}
