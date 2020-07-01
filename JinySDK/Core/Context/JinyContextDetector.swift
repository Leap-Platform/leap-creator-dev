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

/// JinyContextDetectorDelegate is a protocol that is to be implemented by the class that needs to communicate with the JinyContextDetector class. This protocol provides callbacks regarding which native/web page is identifed, native/web stage is identified. It also asks the delegate to provide the relevant flow to check from.
protocol JinyContextDetectorDelegate {
    
    func getWebIdentifier(identifierId:String) -> JinyWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> JinyNativeIdentifier?
    
    func getDiscoveriesToCheck()->Array<JinyDiscovery>
    func discoveryIdentified(discovery:JinyDiscovery)
    func noDiscoveryIdentified()
    
    func getTriggersToCheck() -> Array<JinyTrigger>
    func triggerIdentified(_ trigger:JinyTrigger)
    func noTriggerIdentified()
    
    func findCurrentFlow() -> JinyFlow?
    func checkForParentFlow()->JinyFlow?
    
    func nativePageFound(_ nativePage:JinyNativePage)
    func webPageFound(_ webPage:JinyWebPage)
    func pageNotFound()
    
    func getRelevantStages() -> Array<JinyStage>
    func nativeStageFound(_ nativeStage:JinyNativeStage,pointerView view:UIView?)
    func webStageFound(_ webStage:JinyWebStage, pointerRect rect:CGRect?)
    func stageNotFound()
}

enum JinyContextDetectionState {
    case Discovery
    case Stage
}

/// JinyContextDetector class fetches the trigger or flow to be detected  using its delegate and identifies the trigger or stege every 1 second. It informs it delegate which trigger/ stage has been identified
class JinyContextDetector {
    
    private let delegate:JinyContextDetectorDelegate
    private var contextTimer:Timer?
    private var state:JinyContextDetectionState = .Discovery
    
    init(withDelegate contextDetectorDelegate:JinyContextDetectorDelegate) {
        delegate = contextDetectorDelegate        
    }
    
    func start() {
        contextTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fetchViews), userInfo: nil, repeats: true)
    }
    
    func stop() {
        contextTimer?.invalidate()
        contextTimer = nil
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


// MARK: - HIERARCHY FETCHER
extension JinyContextDetector {
    
    @objc private func fetchViews() {
        let allViews = fetchViewHierarchy()
        switch state {
        case .Discovery:
            let triggersToCheck = delegate.getTriggersToCheck()
            guard triggersToCheck.count > 0 else {
                delegate.noTriggerIdentified()
                return
            }
            identifyDiscoveryToLaunch(discoveries: [], hierarchy: allViews) { (discovery) in
                if discovery != nil { self.delegate.discoveryIdentified(discovery: discovery!)}
                else { self.delegate.noDiscoveryIdentified() }
            }
            
        case .Stage:
            guard let currentFlow = delegate.findCurrentFlow() else {
                delegate.pageNotFound()
                return
            }
//            findPageForFlow(currentFlow, inHierarchy: allViews)
        }
        
    }
    
    func fetchViewHierarchy() -> [UIView] {
        var views:[UIView] = []
        var allWindows:Array<UIWindow> = []
        allWindows = UIApplication.shared.windows
        let keyWindow = UIApplication.shared.keyWindow
        if keyWindow != nil {
            if !allWindows.contains(keyWindow!) { allWindows.append(keyWindow!)}
        }
        for window in allWindows { views.append(contentsOf: getChildren(window))}
        return views
    }
    
    private func getChildren(_ currentView:UIView) -> [UIView] {
        var subviewArray:[UIView] = []
        subviewArray.append(currentView)
        let childrenToCheck = (currentView.window == UIApplication.shared.keyWindow) ? getVisibleChildren(currentView.subviews) : currentView.subviews
        
        for subview in childrenToCheck {
            subviewArray.append(contentsOf: getChildren(subview))
        }
        return subviewArray
    }
    
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

// MARK: - DISCOVERY DETECTION
extension JinyContextDetector {
    
    private func identifyDiscoveryToLaunch(discoveries:Array<JinyDiscovery>, hierarchy:[UIView], discoveryIdentified:@escaping(_ discoveryIdentified:JinyDiscovery?)->Void) {
        
        // Get all webviews in hierarchy
        let webviews = hierarchy.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
        
        // Get all discoveries with webidentifiers
        let discoveriesWithWebIdentifiers = discoveries.filter{ $0.webIdentifiers.count != 0 }
        if discoveriesWithWebIdentifiers.count == 0 {
            // If no discovery has web identifiers, check for native identifiers only
            let identifiedDisccovery = identifyNativeDiscovery(discoveries: discoveries, hierarchy: hierarchy)
            discoveryIdentified(identifiedDisccovery)
        } else {
            // Check if webview is present in current hierarchy, if not skip to native check only
            if webviews.count == 0 {
                // No webviews in current hierarchy, check for native
                let discoveriesWithOnlyNativeIds = discoveriesWithWebIdentifiers.filter{ $0.webIdentifiers.count == 0 && $0.nativeIdentifiers.count > 0 }
                guard discoveriesWithOnlyNativeIds.count > 0 else {
                    discoveryIdentified(nil)
                    return
                }
                let identifiedDiscovery = identifyNativeDiscovery(discoveries: discoveriesWithOnlyNativeIds, hierarchy: hierarchy)
                discoveryIdentified(identifiedDiscovery)
            } else {
                // Webviews and webidentifiers present
                // Get discoveryids whose webidentifiers can be found
                var dict: Dictionary<Int,Array<String>> = [:]
                for discovery in discoveriesWithWebIdentifiers {
                    dict[discovery.id!] = discovery.webIdentifiers
                }
                getElementsPassingWebIdCheck(input: dict, webviews: webviews) { (idsPassingDict) in
                    let idsPassing = idsPassingDict["ids"] ?? []
                    // Check discoveries whose webidentifiers passed and which has no webidentifiers
                    var discoveriesPassed = discoveries.filter{ $0.nativeIdentifiers.count == 0 && idsPassing.contains($0.id!)}
                    
                    // Get list of discoveries which did passed web identifiers check and has native identifiers. Also get discoveries with native identifiers only
                    let discoveriesToCheck = discoveries.filter{ (!discoveriesPassed.contains($0)) && ($0.nativeIdentifiers.count > 0) }
                    
                    for discovery in discoveriesToCheck {
                        if self.isDiscoveryFoundInNativeHierarchy(discovery: discovery, hierarcy: hierarchy) {
                            //Add to discoveriesPassed list if all discovery was identified
                            discoveriesPassed.append(discovery)
                        }
                    }
                    var identifiedDiscovery:JinyDiscovery?
                    var maxWeight = 0
                    for discovery in discoveriesPassed {
                        if (identifiedDiscovery == nil) || (discovery.weight > maxWeight) {
                            identifiedDiscovery = discovery
                            maxWeight = discovery.weight
                        }
                    }
                    discoveryIdentified(identifiedDiscovery)
                }
                
            }
        }
    }
    
    private func identifyNativeDiscovery(discoveries:Array<JinyDiscovery>, hierarchy:Array<UIView>) -> JinyDiscovery? {
        var identifiedDiscovery:JinyDiscovery?
        var maxWeight:Int = 0
        for discovery in discoveries {
            let isIdentfiable = isDiscoveryFoundInNativeHierarchy(discovery: discovery, hierarcy: hierarchy)
            if (isIdentfiable && identifiedDiscovery == nil) || (isIdentfiable && discovery.weight > maxWeight) {
                identifiedDiscovery = discovery
                maxWeight = discovery.weight
            }
        }
        return identifiedDiscovery
    }
    
    private func isDiscoveryFoundInNativeHierarchy(discovery:JinyDiscovery, hierarcy:Array<UIView>) -> Bool {
        for nativeIdentifier in discovery.nativeIdentifiers {
            let matchingViews = getViewsForIdentifer(identifierId: nativeIdentifier, hierarchy: hierarcy)
            if matchingViews?.count == 0 || matchingViews == nil { return false }
        }
        return true
    }
    
}

// MARK: - PAGE DETECTION
extension JinyContextDetector {
    
    func findPageFromPages(_ pages:Array<JinyPageObject>, hierarchy:Array<UIView>, pageCheckComplete:@escaping(_ : JinyPageObject?)->Void) {
        let webviews = hierarchy.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
        let pagesWithWebIds = pages.filter{ $0.webIdentifiers.count > 0 }
        
        if webviews.count == 0 || pagesWithWebIds.count == 0 {
            //Do native check only
            var passingPages:Array<JinyPageObject> = []
            let pagesWithNativeIdsOnly = pages.filter{ $0.webIdentifiers.count == 0 && $0.nativeIdentifiers.count > 0 }
            for page in pagesWithNativeIdsOnly {
                if isPagesNativeIds(page.nativeIdentifiers, identifiableIn: hierarchy) { passingPages.append(page) }
            }
            var pageIdentified:JinyPageObject?
            var maxWeight = 0
            for passingPage in passingPages {
                if pageIdentified == nil || passingPage.weight > maxWeight {
                    pageIdentified = passingPage
                    maxWeight = passingPage.weight
                }
            }
            pageCheckComplete(pageIdentified)
        } else {
            // Do native & webcheck
            var dict: Dictionary<Int,Array<String>> = [:]
            for page in pagesWithWebIds {
                dict[page.id!] = page.webIdentifiers
            }
            getElementsPassingWebIdCheck(input: dict, webviews: webviews) { (passingIdsDict) in
                let passingIds = passingIdsDict["ids"] ?? []
                var pagesPassed = pages.filter{ passingIds.contains($0.id!) && $0.nativeIdentifiers.count == 0 }
                let pagesToBeChecked = pages.filter{ (!pagesPassed.contains($0)) && ($0.nativeIdentifiers.count > 0) }
                for page in pagesToBeChecked {
                    if self.isPagesNativeIds(page.nativeIdentifiers, identifiableIn: hierarchy) { pagesPassed.append(page) }
                }
                var identifiedPage:JinyPageObject?
                var maxWeight = 0
                for page in pagesPassed {
                    if (identifiedPage == nil) || (page.weight > maxWeight) {
                        identifiedPage = page
                        maxWeight = page.weight
                    }
                }
                pageCheckComplete(identifiedPage)
            }
            
        }
    }
    
    private func isPagesNativeIds(_ identifierIds:Array<String>, identifiableIn hierarchy:Array<UIView>) -> Bool {
        var isPassing:Bool = true
        for id in identifierIds {
            let viewsForIdentifier = getViewsForIdentifer(identifierId: id, hierarchy: hierarchy)
            isPassing = isPassing && (viewsForIdentifier?.count ?? 0 > 0)
        }
        return isPassing
    }
    
}

// MARK: - PAGE IDENTIFICATION
extension JinyContextDetector {
    
    private func findPageForFlow(_ flow:JinyFlow?, inHierarchy hierarchy:Array<UIView> ) {
        guard let currentFlow = flow else {
            delegate.pageNotFound()
            return
        }
        if let currentNativePage = findCurrentNativePage(currentFlow.nativePages, hierarchy) {
            delegate.nativePageFound(currentNativePage)
            findNativeStage(inHierarchy: hierarchy)
            
        } else if let currentWebPage = findCurrentWebPage(currentFlow.webPages, hierarchy) {
            delegate.webPageFound(currentWebPage)
        } else {
            findPageForFlow(delegate.checkForParentFlow(), inHierarchy: hierarchy)
        }
    }
    
    func findCurrentNativePage(_ nativePages:Array<JinyNativePage>?, _ inHierarchy:Array<UIView>) -> JinyNativePage? {
        guard let nativeArray = nativePages else { return nil }
        var maxWeight = 0
        var tempIdentifiedPage:JinyNativePage?
        for nativePage in nativeArray {
            nativePageIdentifiable(nativePage, inHierarchy) { (isPage, currentWeight) in
                if isPage && currentWeight > maxWeight {
                    tempIdentifiedPage = nativePage
                    maxWeight = currentWeight
                }
            }
        }
        return tempIdentifiedPage
    }
    
    private func nativePageIdentifiable(_ page:JinyNativePage, _ allViews:Array<UIView>, checkCompleted:(_ isPage:Bool, _ weight:Int)->Void) {
        var pageWeight = 0
        for stage in page.pageIdentifers {
            if !(isNativeStage(stage, presentIn: allViews))  {
                checkCompleted(false,0)
                return
            }
            pageWeight += stage.matches["weight"] as? Int ?? 1
        }
        checkCompleted(true,pageWeight)
    }
    
    func findCurrentWebPage(_ webPages:Array<JinyWebPage>, _ inHierarchy:Array<UIView>) -> JinyWebPage? {
        return nil
    }
    
}


// MARK: - NATIVE STAGE IDENTIFICATION
extension JinyContextDetector {
    private func isNativeStage(_ stage:JinyNativeIdentifer, presentIn views:Array<UIView>) -> Bool {
        let matchingViews = getViews(forIdentifier: stage, inHierarchy: views)
        return matchingViews.count > 0
    }
    
    private func getViews(forIdentifier identifier: JinyNativeIdentifer, inHierarchy hierarchy:Array<UIView>) -> Array<UIView>{
        let views = hierarchy.filter { (view) -> Bool in
            switch identifier.searchType {
            case .AccID:
                return view.accessibilityIdentifier == identifier.searchString
            case .AccLabel:
                return view.accessibilityLabel == identifier.searchString
            case .Tag:
                return view.tag == Int(identifier.searchString)
            default:
                return false
            }
        }
        guard views.count > 0 else { return views }
        if identifier.childInfo.count > 0 {
            var finalViews:Array<UIView> = []
            for view in views {
                let childView = findChildForView(view, withChildInfo: identifier.childInfo)
                if childView != nil { finalViews.append(childView!) }
            }
            return finalViews
        }
        else if let siblingInfo = identifier.siblingInfo {
            var finalViews:Array<UIView> = []
            for view in views {
                let siblingView = findSiblingForView(view, withSiblingInfo: siblingInfo)
                if siblingView != nil { finalViews.append(siblingView!) }
            }
            return finalViews
        }
        return views
    }
    
    private func findChildForView(_ view:UIView, withChildInfo:Array<String>) -> UIView? {
        var tempView = view
        for stringIndex in withChildInfo {
            guard let index = Int(stringIndex), tempView.subviews.count > index else { return nil }
            tempView = tempView.subviews[index]
        }
        return tempView
    }
    
    private func findSiblingForView(_ view:UIView, withSiblingInfo:String) -> UIView? {
        guard let parentView = view.superview, let index = Int(withSiblingInfo), parentView.subviews.count > index  else { return nil }
        return parentView.subviews[index]
    }
    
    private func findNativeStage (inHierarchy views:Array<UIView>) {
        guard let stages = delegate.getRelevantStages() as? Array<JinyNativeStage> else {
            delegate.stageNotFound()
            return
        }
        if stages.count == 0 { delegate.stageNotFound() }
        guard let stageIdentified = findCurrentNativeStage(stages, views) else {
            delegate.stageNotFound()
            return
        }
        guard let pointerIdentifer = stageIdentified.pointerIdentfier else {
            delegate.nativeStageFound(stageIdentified, pointerView: nil)
            return
        }
        let pointerViews = getViews(forIdentifier: pointerIdentifer, inHierarchy: views)
        delegate.nativeStageFound(stageIdentified, pointerView: pointerViews.first)
    }
    
    private func findCurrentNativeStage(_ stages:Array<JinyNativeStage>, _ inViews:Array<UIView>) -> JinyNativeStage? {
        var maxWeight = 0
        var stageIdentified:JinyNativeStage?
        for stage in stages {
            var currentWeight = 0
            var isStagePresent = true
            for stageIdentifier in stage.stageIdentifiers {
                if isNativeStage(stageIdentifier, presentIn: inViews){
                    currentWeight += stageIdentifier.matches["weight"] as? Int ?? 1
                } else {
                    isStagePresent = false
                    break
                }
            }
            if isStagePresent && currentWeight > maxWeight {
                stageIdentified = stage
                maxWeight = currentWeight
            }
        }
        return stageIdentified
    }
}


// MARK: - WEB STAGE IDENTIFICATION
extension JinyContextDetector {
    
    private func findWebStage () {
        let stages = delegate.getRelevantStages()
        if stages.count == 0 { delegate.stageNotFound() }
    }
    
}


// MARK: - NATIVE IDENTIFIER CHECK
extension JinyContextDetector {
    
    func getViewsForIdentifer(identifierId:String, hierarchy:Array<UIView>) -> Array<UIView>? {
        guard let identifier = delegate.getNativeIdentifier(identifierId: identifierId) else { return nil }
        guard let params = identifier.idParameters else { return nil }
        var filteredViews = hierarchy
        if params.accId != nil { filteredViews = filteredViews.filter{ $0.accessibilityIdentifier == params.accId } }
        if params.accLabel != nil { filteredViews = filteredViews.filter{ $0.accessibilityLabel == params.accLabel } }
        if params.tag != nil { filteredViews = filteredViews.filter{ $0.tag == params.tag } }
        if params.text != nil {
            if let localeText = params.text!["ang"] {
                filteredViews =  filteredViews.filter { (view) -> Bool in
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
            if let localeText = params.placeholder!["ang"] {
                filteredViews =  filteredViews.filter { (view) -> Bool in
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
        return nil
    }
    
}


// MARK: WEB IDENTFIER CHECK
extension JinyContextDetector {
    
    func getElementsPassingWebIdCheck(input:Dictionary<Int, Array<String>>, webviews:Array<UIView>, idsPassing:@escaping(_ :Dictionary<String,Array<Int>>) -> Void) {
        var allIdentifierIdsToCheck:Array<String> = []
        input.forEach { (jinyFeatureId, webIds) in
            for webId in webIds {
                if !allIdentifierIdsToCheck.contains(webId) { allIdentifierIdsToCheck.append(webId) }
            }
        }
        var passingIds:Array<Int> = []
        checkListOfIdentifiers(allIdentifierIdsToCheck, in: webviews) { (identifierStatuses) in
            input.forEach { (jinyElementId, identifierIdsArray) in
                var isIdPassing = true
                for identifierId in identifierIdsArray {
                    isIdPassing = isIdPassing && (identifierStatuses[identifierId] ?? false)
                }
                if isIdPassing { passingIds.append(jinyElementId) }
            }
            idsPassing(["ids":passingIds])
        }
    }
    
    func checkListOfIdentifiers(_ identifierIds:Array<String>, in webviews:Array<UIView>, completedCheck:@escaping(_ : Dictionary<String,Bool>)->Void) {

        var identifierStatus:Dictionary<String,Bool> = [:]
        var counter = 0
        
        //Recursive closure to make async js execution sync by processing one identifier at a time
        var identifierCheck:((_: Bool)->Void)?
        identifierCheck = { isPresent in
            identifierStatus[identifierIds[counter]] = isPresent
            counter += 1
            if counter < identifierIds.count { self.isWebIdentifier(identifierIds[counter], presentIn: webviews, identifierChecked: identifierCheck!) }
            else { completedCheck(identifierStatus) }
        }
        
        isWebIdentifier(identifierIds[counter], presentIn: webviews, identifierChecked: identifierCheck!)
    }
    
    func isWebIdentifier(_ identifier:String, presentIn webviews:Array<UIView>, identifierChecked:@escaping(_ : Bool)->Void) {
        
        var counter = 0
        var checkCompletion:((_ : Bool) -> Void)?
        // Recursive closure for each webview to handle asynchronous js execution synchronusly
        checkCompletion = { isPresent in
            if isPresent { identifierChecked(true) }
            else {
                counter += 1
                if counter < webviews.count { self.isWebIdentifier(identifier, inCurrentWebview: webviews[counter], individualWebviewCheckComplete: checkCompletion!)}
                else { identifierChecked(false) }
            }
        }
        
        isWebIdentifier(identifier, inCurrentWebview: webviews[0], individualWebviewCheckComplete: checkCompletion!)
        
    }
    
    func isWebIdentifier(_ identfier:String, inCurrentWebview:UIView, individualWebviewCheckComplete:@escaping(_ : Bool)->Void) {
        if let webIdObj = delegate.getWebIdentifier(identifierId: identfier) {
            let query = JinyJSMaker.createJSScript(for: webIdObj)
            if let wk = inCurrentWebview as? WKWebView {
                wk.evaluateJavaScript(query) { (res, err) in
                    if let resString = res as? String {
                        individualWebviewCheckComplete((resString as NSString).boolValue)
                    }
                }
            } else if let uiweb = inCurrentWebview as? UIWebView {
                if let resString = uiweb.stringByEvaluatingJavaScript(from: query) {
                    individualWebviewCheckComplete((resString as NSString).boolValue)
                } else { individualWebviewCheckComplete(false) }
                
            }
        } else { individualWebviewCheckComplete(false) }
    }
    
    
}
