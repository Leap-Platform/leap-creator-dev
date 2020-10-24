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
    
    func getAllNativeIds() -> Array<String>
    func getAllWebIds() -> Array<String>
    
    func getWebIdentifier(identifierId:String) -> JinyWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> JinyNativeIdentifier?
    
    func getAllAssistsToCheck() -> Array<JinyAssist>
    func assistFound(assist:JinyAssist, view:UIView?, rect:CGRect?, webview:UIView?)
    func assistNotFound()
    
    func getDiscoveriesToCheck()->Array<JinyDiscovery>
    func discoveriesIdentified(discoveries:Array<(JinyDiscovery, UIView?, CGRect?, UIView?)>)
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

enum JinyContexttDetectionSubstate {
    case Assist
    case Discovery
}

/// JinyContextDetector class fetches the discovery or flow to be detected  using its delegate and identifies the dsicovery or stage every 1 second. It informs it delegate which discovery, page, stage has been identified
class JinyContextDetector {
    
    private let delegate:JinyContextDetectorDelegate
    private var contextTimer:Timer?
    private var state:JinyContextDetectionState = .Discovery
    var substate:JinyContexttDetectionSubstate = .Assist
    
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
        findIdentifiersPassing(inHierarchy: allViews) { (passingNativeIds, passingWebIds) in
            switch self.state {
            case .Discovery:
                let assistFound = self.detectAssist(passingNativeIds: passingNativeIds, passingWebIds: passingWebIds)
                
                if assistFound != nil {
                    guard let identifier = assistFound!.instruction?.assistInfo?.identifier else {
                        self.delegate.assistFound(assist: assistFound!, view: nil, rect: nil, webview: nil)
                        return
                    }
                    if assistFound!.isWeb {
                        guard let webId = self.delegate.getWebIdentifier(identifierId:identifier) else {
                            self.delegate.assistFound(assist: assistFound!, view: nil, rect: nil, webview: nil)
                            return
                        }
                        self.getRectForIdentifier(id: webId, webviews:allViews.filter{$0.isKind(of: WKWebView.self) || $0.isKind(of: UIWebView.self) }) { (rect, webview) in
                            self.delegate.assistFound(assist: assistFound!, view: nil, rect: rect, webview: webview)
                        }
                    } else {
                        guard let views = self.getViewsForIdentifer(identifierId: identifier, hierarchy: allViews) else {
                            self.delegate.assistFound(assist: assistFound!, view: nil, rect: nil, webview: nil)
                            return
                        }
                        if views.count > 0 { self.delegate.assistFound(assist: assistFound!, view: views.first, rect: nil, webview: nil)}
                        else { self.delegate.assistFound(assist: assistFound!, view: nil, rect: nil, webview: nil) }
                    }
                }
                else {
                    self.delegate.assistNotFound()
                    let discoveriesIdentified = self.findDiscoveries(passingNativeIds: passingNativeIds, passingWebIds: passingWebIds)
                    if discoveriesIdentified.count == 0{ self.delegate.noDiscoveryIdentified() }
                    else {
                        var discoveryObjectArray:Array<(JinyDiscovery, UIView?, CGRect?, UIView?)> = []
                        let discoveriesWithNativeAnchor = discoveriesIdentified.filter{ $0.isWeb == false }
                        let discoveriesWithWebAnchor = discoveriesIdentified.filter{ $0.isWeb == true }
                        for discovery in discoveriesWithNativeAnchor {
                            let identifier = discovery.discoveryInfo?.identifier
                            let anchorViews = self.getViewsForIdentifer(identifierId: identifier ?? "empty", hierarchy: allViews)
                            discoveryObjectArray.append((discovery, anchorViews?.first, nil, nil))
                            
                        }
                        let webViews = allViews.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
                        if webViews.count > 0 && discoveriesWithWebAnchor.count > 0 {
                            var counter = 0
                            var resultCompletion:((_ :CGRect?, _ :UIView?)->Void)?
                            resultCompletion = { rect, webview in
                                discoveryObjectArray.append( (discoveriesWithWebAnchor[counter], nil, rect, webview) )
                                counter += 1
                                
                                if counter < discoveriesWithWebAnchor.count {
                                    let webIdentifier = self.delegate.getWebIdentifier(identifierId: discoveriesWithWebAnchor[counter].discoveryInfo?.identifier ?? "")
                                    self.getRectForIdentifier(id: webIdentifier!, webviews: webViews, rectCalculated: resultCompletion!)
                                } else {
                                    self.delegate.discoveriesIdentified(discoveries: discoveryObjectArray)
                                }
                            }
                            let webIdentifier = self.delegate.getWebIdentifier(identifierId: discoveriesWithWebAnchor[counter].discoveryInfo?.identifier ?? "")
                            self.getRectForIdentifier(id: webIdentifier!, webviews: webViews, rectCalculated: resultCompletion!)
                            
                        } else {
                            self.delegate.discoveriesIdentified(discoveries: discoveryObjectArray)
                        }
                        
                    }
                }
                
            case .Stage:
                
                guard let flow = self.delegate.getCurrentFlow() else {
                    self.delegate.pageNotIdentified()
                    return
                }
                if let page = self.findPage(pages: flow.pages, webIds: passingWebIds, nativeIds: passingNativeIds) {
                    self.delegate.pageIdentified(page)
                    if let stage = self.findStage(stages: page.stages, webIds: passingWebIds, nativeIds: passingNativeIds) {
                        if let identifier = stage.instruction?.assistInfo?.identifier {
                            if stage.isWeb {
                                if let webId = self.delegate.getWebIdentifier(identifierId: identifier) {
                                    self.getRectForIdentifier(id: webId, webviews:allViews.filter{$0.isKind(of: WKWebView.self) || $0.isKind(of: UIWebView.self) }) { (rect, webview) in
                                        self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: rect, webviewForRect: webview)
                                    }
                                } else {
                                    self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
                                }
                            } else {
                                if let _ = self.delegate.getNativeIdentifier(identifierId: identifier) {
                                    guard let views = self.getViewsForIdentifer(identifierId: identifier, hierarchy: allViews) else {
                                        self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
                                        return
                                    }
                                    if views.count > 0 { self.delegate.stageIdentified(stage, pointerView: views.first, pointerRect: nil, webviewForRect: nil)}
                                    else { self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil) }
                                } else {
                                    self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
                                }
                            }
                        } else {
                            self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
                        }
                        
                    } else { self.delegate.stageNotIdentified() }
                } else { self.delegate.pageNotIdentified() }
            }
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
        childrenToCheck = childrenToCheck.filter{
            guard let superview = $0.superview else { return true }
            let frameToWindow = superview.convert($0.frame, to: UIApplication.shared.keyWindow)
            guard let keyWindow = UIApplication.shared.keyWindow else { return true }
            if frameToWindow.minX > keyWindow.frame.maxX || frameToWindow.maxX < 0 { return false }
            return true
        }
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


extension JinyContextDetector {
    
    func findIdentifiersPassing(inHierarchy hierarchy:Array<UIView>, passingIds:@escaping (_ passingNativeIds:Array<String>, _ passingWebIds:Array<String>)->Void) {
        let allNativeIds = delegate.getAllNativeIds()
        let allWebIds = delegate.getAllWebIds()
        
        let passingNativeIds = getNativeIdentifiersPassing(allNativeIds, inHierarchy: hierarchy)
        
        let currentWebViews = hierarchy.filter { $0.isKind(of: WKWebView.self) || $0.isKind(of: UIWebView.self) }
        if currentWebViews.count == 0 || allWebIds.count == 0 { passingIds(passingNativeIds,[]) }
        else {
            getPassingWebIds(allWebIds, inAllWebviews: currentWebViews) { (passedWebIds) in
                passingIds(passingNativeIds, passedWebIds)
            }
        }
        
        
    }
    
}


// MARK: - ASSIST DETECTION
extension JinyContextDetector {
    
    func detectAssist(passingNativeIds:Array<String>, passingWebIds:Array<String>) -> JinyAssist? {
        var assistFound:JinyAssist?
        var maxWeight:Int = 0
        
        let assists = delegate.getAllAssistsToCheck()
        for assist in assists {
            var isIdentified = true
            for webId in assist.webIdentifiers {
                if !passingWebIds.contains(webId) {
                    isIdentified = false
                    break
                }
            }
            if !isIdentified { continue }
            for nativeId in assist.nativeIdentifiers {
                if !passingNativeIds.contains(nativeId) {
                    isIdentified = false
                    break
                }
            }
            if isIdentified && assist.weight > maxWeight {
                assistFound = assist
                maxWeight = assist.weight
            }
        }
        return assistFound
    }
    
}

// MARK: - DISCOVERY DETECTION
extension JinyContextDetector {
    
    func findDiscoveries(passingNativeIds:Array<String>, passingWebIds:Array<String>) -> Array<JinyDiscovery> {
        var passingDiscoveries:Array<JinyDiscovery> = []
        let discoveries = delegate.getDiscoveriesToCheck()
        for discovery in discoveries {
            var isPassing = true
            for nativeId in discovery.nativeIdentifiers {
                if !passingNativeIds.contains(nativeId) {
                    isPassing = false
                    break
                }
            }
            if !isPassing { continue }
            for webId in discovery.webIdentifiers {
                if !passingWebIds.contains(webId) {
                    isPassing = false
                    break
                }
            }
            if isPassing { passingDiscoveries.append(discovery) }
        }
        
        return passingDiscoveries
    }
    
    func identifyDiscoveryToLaunch(discoveries:Array<JinyDiscovery>, hierarchy:[UIView], discoveriesIdentified:@escaping(_ discoveryIdentified:Array<JinyDiscovery>)->Void) {
        
        // Get all webviews in hierarchy
        let webviews = hierarchy.filter{ $0.isKind(of: UIWebView.self) || $0.isKind(of: WKWebView.self) }
        
        // Get all discoveries with webidentifiers
        let discoveriesWithWebIdentifiers = discoveries.filter{ $0.webIdentifiers.count != 0 }
        if discoveriesWithWebIdentifiers.count == 0 {
            // If no discovery has web identifiers, check for native identifiers only
            let identifiedDisccovery = identifyNativeDiscovery(discoveries: discoveries, hierarchy: hierarchy)
            discoveriesIdentified(identifiedDisccovery)
        } else {
            // Check if webview is present in current hierarchy, if not skip to native check only
            if webviews.count == 0 {
                // No webviews in current hierarchy, check for native
                let discoveriesWithOnlyNativeIds = discoveries.filter{ $0.webIdentifiers.count == 0 && $0.nativeIdentifiers.count > 0 }
                guard discoveriesWithOnlyNativeIds.count > 0 else {
                    discoveriesIdentified([])
                    return
                }
                let identifiedDiscovery = identifyNativeDiscovery(discoveries: discoveriesWithOnlyNativeIds, hierarchy: hierarchy)
                discoveriesIdentified(identifiedDiscovery)
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
                    discoveriesIdentified(discoveriesPassed)
                }
                
            }
        }
    }
    
    private func identifyNativeDiscovery(discoveries:Array<JinyDiscovery>, hierarchy:Array<UIView>) -> Array<JinyDiscovery> {
        var discoveriesIdentified:Array<JinyDiscovery> = []
        for discovery in discoveries {
            let isIdentfiable = isDiscoveryFoundInNativeHierarchy(discovery: discovery, hierarcy: hierarchy)
            if isIdentfiable { discoveriesIdentified.append(discovery) }
        }
        return discoveriesIdentified
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
        //        guard let pointerInfo = stage.instruction?.ass, let identifier = pointerInfo.identifier else {
        //            delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
        //            return
        //        }
        //        var pointer:Any? = nil
        //        if pointerInfo.isWeb {
        //            pointer = delegate.getWebIdentifier(identifierId: identifier)
        //        } else {
        //            pointer = delegate.getNativeIdentifier(identifierId: identifier)
        //        }
        //        guard pointer != nil else {
        //            delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
        //            return
        //        }
        //        if let _ = pointer as? JinyNativeIdentifier {
        //            let views = getViewsForIdentifer(identifierId: identifier, hierarchy: hierarchy) ?? []
        //            delegate.stageIdentified(stage, pointerView: views.first, pointerRect: nil, webviewForRect: nil)
        //        } else if let webId = pointer as? JinyWebIdentifier {
        //            let webviews = hierarchy.filter{ $0.isKind(of: WKWebView.self) || $0.isKind(of: UIWebView.self) }
        //            if webviews.count > 0 {
        //                getRectForIdentifier(id: webId, webviews: webviews) { (rectCalculated, forWebView) in
        //                    if rectCalculated != nil { (self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: rectCalculated, webviewForRect: forWebView)) }
        //                    else { self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil) }
        //                }
        //            } else { delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil) }
        //
        //        } else {
        //            self.delegate.stageIdentified(stage, pointerView: nil, pointerRect: nil, webviewForRect: nil)
        //        }
    }
}


// MARK: - NATIVE IDENTIFIER CHECK
extension JinyContextDetector {
    
    private func getNativeIdentifiersPassing(_ identifiers:Array<String>, inHierarchy allView:Array<UIView>) -> Array<String> {
        var idsPassing:Array<String> = []
        for id in identifiers {
            if let views = getViewsForIdentifer(identifierId: id, hierarchy: allView) {
                if views.count > 0 {
                    idsPassing.append(id)
                }
            }
        }
        return idsPassing
    }
    
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


// MARK: - PAGE CHECK
extension JinyContextDetector {
    
    func findPage(pages:Array<JinyPage>, webIds:Array<String>, nativeIds:Array<String>) -> JinyPage? {
        var pageIdentified:JinyPage?
        var maxWeight = 0
        for page in pages {
            var isPassing:Bool = true
            if page.nativeIdentifiers.count > 0 { isPassing = isPassing && Set(page.nativeIdentifiers).isSubset(of: Set(nativeIds)) }
            if page.webIdentifiers.count > 0 { isPassing = isPassing && Set(page.webIdentifiers).isSubset(of: Set(webIds)) }
            if isPassing && page.weight > maxWeight {
                pageIdentified = page
                maxWeight = page.weight
            }
        }
        return pageIdentified
    }
    
}

// MARK: - STAGE CHECK
extension JinyContextDetector {
    
    func findStage(stages:Array<JinyStage>, webIds:Array<String>, nativeIds:Array<String>) -> JinyStage? {
        var stageIdentified:JinyStage?
        var maxWeight = 0
        for stage in stages {
            var isPassing:Bool = true
            if stage.nativeIdentifiers.count > 0 { isPassing = isPassing && Set(stage.nativeIdentifiers).isSubset(of: Set(nativeIds)) }
            if stage.webIdentifiers.count > 0 { isPassing = isPassing && Set(stage.webIdentifiers).isSubset(of: Set(webIds)) }
            if isPassing && stage.weight > maxWeight {
                stageIdentified = stage
                maxWeight = stage.weight
            }
        }
        return stageIdentified
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
            else {
                completedCheck(identifierStatus)
                
            }
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
                    
                    if identfier == "goib_source" {
                        
                    }
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
    
    func getPassingWebIds(_ webIds:Array<String>, inAllWebviews:Array<UIView>, completion: @escaping(_ passingIds:Array<String>)->Void) {
        
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
    
    func getPassingWebIds(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ passingIds:Array<String>)->Void) {
        getElementsPresent(webIds, inSingleWebview: inSingleWebview) { (presentWebIds) in
            if presentWebIds.count > 0 {
                self.getElementsPassingAttributes(presentWebIds, inSingleWebview: inSingleWebview) { (passingWebIds) in
                    completion(passingWebIds)
                }
            } else { completion([]) }
        }
        
    }
    
    func getElementsPresent(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ presentElements:Array<String>) -> Void ) {
        
        //Create query to check if element is present
        var jsString = "["
        for (index,webId) in webIds.enumerated() {
            if index != 0 { jsString += "," }
            if let webIdentifier = delegate.getWebIdentifier(identifierId: webId) {
                let querySelectorCheck = "(" + JinyJSMaker.getElementScript(webIdentifier) + " != null" + ").toString()"
                jsString += querySelectorCheck
            } else {
                let falseReturn = "(document.querySelectorAll('div[class=\"return_false\"')[0] != null).toString()"
                jsString += falseReturn
            }
        }
        jsString += "]"
        
        
        if let uiweb = inSingleWebview as? UIWebView {
            //Inject query into UIWebview
            jsString = "(" + jsString + ").toString()"
            if let result = uiweb.stringByEvaluatingJavaScript(from: jsString){
                let resultArray = result.components(separatedBy: ",")
                let presentWebIds = webIds.filter { (webId) -> Bool in
                    let webIdIndex = webIds.firstIndex(of: webId)!
                    return NSString(string: resultArray[webIdIndex]).boolValue
                }
                completion(presentWebIds)
            } else { completion([]) }
        } else if let wkweb = inSingleWebview as? WKWebView {
            //Inject query into WKWebview
            wkweb.evaluateJavaScript(jsString) { (result, error) in
                if let boolStrings = result as? Array<String> {
                    let presentWebIds = webIds.filter { (webId) -> Bool in
                        let webIdIndex = webIds.firstIndex(of: webId)!
                        return NSString(string: boolStrings[webIdIndex]).boolValue
                    }
                    completion(presentWebIds)
                } else { completion([]) }
            }
        }
    }
    
    func getElementsPassingAttributes(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ passingElements:Array<String>) -> Void ) {
        var jsString = "["
        for (index,webId) in webIds.enumerated() {
            if index != 0 { jsString += "," }
            var checkScript = ""
            if let webIdentifier = delegate.getWebIdentifier(identifierId: webId) {
                if let attributeCheck = JinyJSMaker.createAttributeCheckScript(for: webIdentifier) {
                    checkScript += "(" + attributeCheck + ").toString()"
                } else {
                    checkScript += "(" + JinyJSMaker.getElementScript(webIdentifier) + " != null" + ").toString()"
                }
                jsString += checkScript
            }
        }
        jsString += "]"
        if let uiweb = inSingleWebview as? UIWebView {
            //Inject query into UIWebview
            jsString = "(" + jsString + ").toString()"
            if let result = uiweb.stringByEvaluatingJavaScript(from: jsString){
                let resultArray = result.components(separatedBy: ",")
                let presentWebIds = webIds.filter { (webId) -> Bool in
                    let webIdIndex = webIds.firstIndex(of: webId)!
                    return NSString(string: resultArray[webIdIndex]).boolValue
                }
                completion(presentWebIds)
            } else { completion([]) }
        } else if let wkweb = inSingleWebview as? WKWebView {
            //Inject query into WKWebview
            wkweb.evaluateJavaScript(jsString) { (result, error) in
                if let boolStrings = result as? Array<String> {
                    let presentWebIds = webIds.filter { (webId) -> Bool in
                        let webIdIndex = webIds.firstIndex(of: webId)!
                        return NSString(string: boolStrings[webIdIndex]).boolValue
                    }
                    completion(presentWebIds)
                } else { completion([]) }
            }
        }
    }
    
    
}
