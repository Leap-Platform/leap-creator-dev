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
protocol JinyContextDetectorDelegate {
    
    func getWebIdentifier(identifierId:String) -> JinyWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> JinyNativeIdentifier?
    
    func getDiscoveriesToCheck()->Array<JinyDiscovery>
    func discoveryIdentified(discovery:JinyDiscovery)
    func noDiscoveryIdentified()
    
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

/// JinyContextDetector class fetches the discovery or flow to be detected  using its delegate and identifies the dsicovery or stage every 1 second. It informs it delegate which discovery, page, stage has been identified
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
            let discoveriesToCheck = delegate.getDiscoveriesToCheck()
            guard discoveriesToCheck.count > 0 else {
                delegate.noDiscoveryIdentified()
                return
            }
            identifyDiscoveryToLaunch(discoveries: discoveriesToCheck, hierarchy: allViews) { (discovery) in
                if discovery != nil { self.delegate.discoveryIdentified(discovery: discovery!)}
                else { self.delegate.noDiscoveryIdentified() }
            }
            
        case .Stage:
            guard let flow = delegate.getCurrentFlow() else {
                delegate.pageNotIdentified()
                return
            }
            var pageCheckComplete:((_ : JinyPage?) -> Void)?
            pageCheckComplete = { page in
                if page != nil {
                    self.delegate.pageIdentified(page!)
                    self.findStageFromStages(self.delegate.getStagesToCheck(), hierarchy: allViews) { (stage) in
                        if stage != nil { self.getViewOrRectForPointer(stage!, allViews) }
                        else { self.delegate.stageNotIdentified() }
                    }
                }
                else {
                    guard let parentFlow = self.delegate.getParentFlow() else {
                        self.delegate.pageNotIdentified()
                        return
                    }
                    self.findPageFromPages(parentFlow.pages, hierarchy: allViews, pageCheckComplete: pageCheckComplete!)
                }
            }
            findPageFromPages(flow.pages, hierarchy: allViews, pageCheckComplete: pageCheckComplete!)
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
        var childrenToCheck = (currentView.window == UIApplication.shared.keyWindow) ? getVisibleChildren(currentView.subviews) : currentView.subviews
        childrenToCheck = childrenToCheck.filter{ !$0.isHidden && ($0.alpha > 0)  && !String(describing: type(of: $0)).contains("Jiny") }
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
    
     func identifyDiscoveryToLaunch(discoveries:Array<JinyDiscovery>, hierarchy:[UIView], discoveryIdentified:@escaping(_ discoveryIdentified:JinyDiscovery?)->Void) {
        
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
                let discoveriesWithOnlyNativeIds = discoveries.filter{ $0.webIdentifiers.count == 0 && $0.nativeIdentifiers.count > 0 }
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
    
    func findPageFromPages(_ pages:Array<JinyPage>, hierarchy:Array<UIView>, pageCheckComplete:@escaping(_ : JinyPage?)->Void) {
        let webviews = hierarchy.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
        let pagesWithWebIds = pages.filter{ $0.webIdentifiers.count > 0 }
        
        if webviews.count == 0 || pagesWithWebIds.count == 0 {
            //Do native check only
            var passingPages:Array<JinyPage> = []
            let pagesWithNativeIdsOnly = pages.filter{ $0.webIdentifiers.count == 0 && $0.nativeIdentifiers.count > 0 }
            for page in pagesWithNativeIdsOnly {
                if isNativeIds(page.nativeIdentifiers, identifiableIn: hierarchy) { passingPages.append(page) }
            }
            var pageIdentified:JinyPage?
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
                    if self.isNativeIds(page.nativeIdentifiers, identifiableIn: hierarchy) { pagesPassed.append(page) }
                }
                var identifiedPage:JinyPage?
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
}


// MARK: - STAGE DETECTION
extension JinyContextDetector {
    
    private func findStageFromStages(_ stages:Array<JinyStage>, hierarchy:Array<UIView>, completedStageCheck:@escaping(_ : JinyStage?)->Void) {
        let webviews = hierarchy.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
        let stagesWithWebIds = stages.filter{ $0.webIdentifiers.count > 0 }
        
        if webviews.count == 0 || stagesWithWebIds.count == 0 {
            //Do native check only
            var passingStages:Array<JinyStage> = []
            let stagesWithNativeIdsOnly = stages.filter{ $0.webIdentifiers.count == 0 && $0.nativeIdentifiers.count > 0 }
            for stage in stagesWithNativeIdsOnly {
                if isNativeIds(stage.nativeIdentifiers, identifiableIn: hierarchy) { passingStages.append(stage) }
            }
            var stageIdentified:JinyStage?
            var maxWeight = 0
            for passingStage in passingStages {
                if stageIdentified == nil || passingStage.weight > maxWeight {
                    stageIdentified = passingStage
                    maxWeight = passingStage.weight
                }
            }
            completedStageCheck(stageIdentified)
        } else {
            // Do native & webcheck
            var dict: Dictionary<Int,Array<String>> = [:]
            for stage in stagesWithWebIds {
                dict[stage.id!] = stage.webIdentifiers
            }
            getElementsPassingWebIdCheck(input: dict, webviews: webviews) { (passingIdsDict) in
                let passingIds = passingIdsDict["ids"] ?? []
                var stagesPassed = stages.filter{ passingIds.contains($0.id!) && $0.nativeIdentifiers.count == 0 }
                let stagesToBeChecked = stages.filter{ (!stagesPassed.contains($0)) && ($0.nativeIdentifiers.count > 0) }
                for stage in stagesToBeChecked {
                    if self.isNativeIds(stage.nativeIdentifiers, identifiableIn: hierarchy) { stagesPassed.append(stage) }
                }
                var identifiedStage:JinyStage?
                var maxWeight = 0
                for stage in stagesPassed {
                    if (identifiedStage == nil) || (stage.weight > maxWeight) {
                        identifiedStage = stage
                        maxWeight = stage.weight
                    }
                }
                completedStageCheck(identifiedStage)
            }
            
        }
    }
    
    private func getViewOrRectForPointer(_ stage:JinyStage, _ hierarchy:Array<UIView>) {
        guard let pointerInfo = stage.instruction?.pointer, let identifier = pointerInfo.identifier else {
            delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
            return
        }
        var pointer:Any? = nil
        if pointerInfo.isWeb {
            pointer = delegate.getWebIdentifier(identifierId: identifier)
        } else {
            pointer = delegate.getNativeIdentifier(identifierId: identifier)
        }
        guard pointer != nil else {
            delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
            return
        }
        if let _ = pointer as? JinyNativeIdentifier {
            let views = getViewsForIdentifer(identifierId: identifier, hierarchy: hierarchy) ?? []
            delegate.stageIdentified(stage, pointerView: views.first, pointerRect: nil, webviewForRect: nil)
        } else if let webId = pointer as? JinyWebIdentifier {
            let webviews = hierarchy.filter{ $0.isKind(of: WKWebView.self) || $0.isKind(of: UIWebView.self) }
            if webviews.count > 0 {
                getRectForIdentifier(id: webId, webviews: webviews) { (rectCalculated, forWebView) in
                    if rectCalculated != nil { (self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: rectCalculated, webviewForRect: forWebView)) }
                    else { self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil) }
                }
            } else { delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil) }
            
        } else {
            self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
        }
    }
}


// MARK: - NATIVE IDENTIFIER CHECK
extension JinyContextDetector {
    
    private func isNativeIds(_ identifierIds:Array<String>, identifiableIn hierarchy:Array<UIView>) -> Bool {
        var isPassing:Bool = true
        for id in identifierIds {
            let viewsForIdentifier = getViewsForIdentifer(identifierId: id, hierarchy: hierarchy)
            isPassing = isPassing && (viewsForIdentifier?.count ?? 0 > 0)
        }
        return isPassing
    }
    
    func getViewsForIdentifer(identifierId:String, hierarchy:Array<UIView>) -> Array<UIView>? {
        guard let identifier = delegate.getNativeIdentifier(identifierId: identifierId) else { return nil }
        guard let params = identifier.idParameters else { return nil }
        var anchorViews = hierarchy
        if params.accId != nil { anchorViews = anchorViews.filter{ $0.accessibilityIdentifier == params.accId } }
        if params.accLabel != nil { anchorViews = anchorViews.filter{ $0.accessibilityLabel == params.accLabel } }
        if params.tag != nil { anchorViews = anchorViews.filter{ $0.tag == params.tag } }
        if params.text != nil {
            if let localeText = params.text!["ang"] {
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
            if let localeText = params.placeholder!["ang"] {
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
    
    func getRectForIdentifier(id:JinyWebIdentifier, webviews:Array<UIView>, rectCalculated:@escaping(_ :CGRect?, _ :UIView?)->Void) {
        let boundsScript = JinyJSMaker.calculateBoundsScript(id)
        var counter = 0
        
        var resultCompletion:((_ :CGRect?)->Void)?
        resultCompletion = { rect in
            if rect != nil { rectCalculated(rect, webviews[counter]) }
            else {
                counter += 1
                if counter < webviews.count { self.runJs(script: boundsScript, in: webviews[counter], result: resultCompletion!) }
                else { rectCalculated(nil, nil) }
            }
        }
        runJs(script: boundsScript, in: webviews[counter], result: resultCompletion!)
    }
    
    func runJs(script:String, in webview:UIView, result:@escaping(_ :CGRect?)->Void) {
        
        if let wk = webview as? WKWebView {
            
            wk.evaluateJavaScript(script) { (output, error) in
                if let resultString = output as? String {
                    let rectStringsArray = (resultString.split(separator: ","))
                    let rectInfoArray = rectStringsArray.map { (string) -> CGFloat? in
                        CGFloat((string as NSString).floatValue)
                    }.filter { $0 != nil } as! Array<CGFloat>
                    if rectInfoArray.count != 4 { result(nil) }
                    else {
                        let resultRect = CGRect(x: rectInfoArray[0], y: rectInfoArray[1], width: rectInfoArray[2], height: rectInfoArray[3])
                        result(resultRect)
                    }
                } else {
                    result(nil)
                }
            }
            
        } else if let uiweb = webview as? UIWebView {
            
            if let resultString = uiweb.stringByEvaluatingJavaScript(from: script) {
                let rectStringsArray = (resultString.split(separator: ","))
                let rectInfoArray = rectStringsArray.map { (string) -> CGFloat? in
                    CGFloat((string as NSString).floatValue)
                }.filter { $0 != nil } as! Array<CGFloat>
                if rectInfoArray.count != 4 { result(nil) }
                else {
                    let resultRect = CGRect(x: rectInfoArray[0], y: rectInfoArray[1], width: rectInfoArray[2], height: rectInfoArray[3])
                    result(resultRect)
                }
            } else {
                result(nil)
            }
            
        } else {
            result(nil)
        }
        
    }
    
    
}
