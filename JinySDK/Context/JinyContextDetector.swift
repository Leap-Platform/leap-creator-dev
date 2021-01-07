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
    
    func getAllNativeIds() -> Array<String>
    func getAllWebIds() -> Array<String>
    
    func getWebIdentifier(identifierId:String) -> JinyWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> JinyNativeIdentifier?
    
    func getAllAssistsToCheck() -> Array<JinyAssist>
    func assistFound(assist:JinyAssist, view:UIView?, rect:CGRect?, webview:UIView?)
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

/// JinyContextDetector class fetches the discovery or flow to be detected  using its delegate and identifies the dsicovery or stage every 1 second. It informs it delegate which discovery, page, stage has been identified
class JinyContextDetector {
    
    private weak var delegate:JinyContextDetectorDelegate?
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
        findIdentifiersPassing(inHierarchy: allViews) { (passingNativeIds, passingWebIds) in
            self.findAUIElement(in: allViews, withPassing: passingWebIds, passingNativeIds)
        }
    }
    
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
    
    private func findIdentifiersPassing(inHierarchy hierarchy:Array<UIView>, passingIds:@escaping (_ passingNativeIds:Array<String>, _ passingWebIds:Array<String>)->Void) {
        let allNativeIds = delegate!.getAllNativeIds()
        let allWebIds = delegate!.getAllWebIds()
        
        let passingNativeIds = getNativeIdentifiersPassing(allNativeIds, inHierarchy: hierarchy)
        
        let currentWebViews = hierarchy.filter { $0.isKind(of: WKWebView.self) || $0.isKind(of: UIWebView.self) }
        if currentWebViews.count == 0 || allWebIds.count == 0 { passingIds(passingNativeIds,[]) }
        else {
            let currentControllerString = String(describing: type(of: UIApplication.getCurrentVC().self))
            let controllerCheckedWebIds = allWebIds.filter { (webId) -> Bool in
                guard let webIdentifier = delegate!.getWebIdentifier(identifierId: webId) else { return false }
                guard let controllerCheckString = webIdentifier.controller else { return true }
                return controllerCheckString == currentControllerString
            }
            getPassingWebIds(controllerCheckedWebIds, inAllWebviews: currentWebViews) { (passedWebIds) in
                passingIds(passingNativeIds, passedWebIds)
            }
        }
    }
}

// MARK: - ASSIST/DISCOVERY/STAGE CHECKING
extension JinyContextDetector {
    
    private func findAUIElement(in allViews:Array<UIView>, withPassing webIds:Array<String>,_ nativeIds:Array<String>) {
        switch state {
        case .Discovery:
            checkForAssistOrDiscovery(in: allViews, withPassing: webIds, nativeIds)
        case .Stage:
            checkForStage(in: allViews, withPassing: webIds, nativeIds, forFlow: delegate!.getCurrentFlow())
        }
    }
    
    private func isAUIElementPassing(_ passedWebIds:Array<String>,_ passedNativedIds:Array<String>,_ toCheckWebIds:Array<String>,_ toCheckNativeIds:Array<String>) -> Bool {
        
        if toCheckNativeIds.count > 0 { if !(Set(toCheckNativeIds).isSubset(of: Set(passedNativedIds)))  { return false} }
        if toCheckWebIds.count > 0 { if !(Set(toCheckWebIds).isSubset(of: Set(passedWebIds)))  { return false} }
        
        return true
    }
    
    private func checkForAssistOrDiscovery(in allViews:Array<UIView>, withPassing webIds:Array<String>,_ nativeIds:Array<String>) {
        if let assistDetected = detectAssist(passingNativeIds: nativeIds, passingWebIds: webIds) {
            getViewOrRect(allView: allViews, id: assistDetected.instruction?.assistInfo?.identifier, isWeb: assistDetected.isWeb) { (view, rect, webview) in
                self.delegate!.assistFound(assist: assistDetected, view: view, rect: rect, webview: webview)
            }
        }
        else {
            self.delegate!.assistNotFound()
            let discoveriesIdentified = findDiscoveries(passingNativeIds: nativeIds, passingWebIds: webIds)
            guard discoveriesIdentified.count > 0 else {
                self.delegate!.noDiscoveryFound()
                return
            }
            var discoveryObj:Array<(JinyDiscovery, UIView?, CGRect?, UIView?)> = []
            var counter = 0
            var rectCalculateCompletion:((UIView?,CGRect?,UIView?)-> Void)?
            rectCalculateCompletion = { view, rect, webview in
                discoveryObj.append((discoveriesIdentified[counter],view,rect,webview))
                counter += 1
                if discoveriesIdentified.count == counter {
                    self.delegate!.discoveriesFound(discoveries: discoveryObj)
                } else {
                    self.getViewOrRect(allView: allViews, id: discoveriesIdentified[counter].instruction?.assistInfo?.identifier, isWeb: discoveriesIdentified[counter].isWeb, targetCheckCompleted: rectCalculateCompletion!)
                }
            }
            
            getViewOrRect(allView: allViews, id: discoveriesIdentified[counter].instruction?.assistInfo?.identifier, isWeb: discoveriesIdentified[counter].isWeb, targetCheckCompleted: rectCalculateCompletion!)
        }
    }
    
    private func checkForStage(in allViews:Array<UIView>, withPassing webIds:Array<String>,_ nativeIds:Array<String>, forFlow:JinyFlow?) {
        guard let flow = forFlow, let page = findPage(pages: flow.pages, webIds: webIds, nativeIds: nativeIds) else {
            delegate!.pageNotIdentified()
            return
        }
        delegate!.pageIdentified(page)
        if let stage = findStage(stages: page.stages, webIds: webIds, nativeIds: nativeIds) {
            getViewOrRect(allView: allViews, id: stage.instruction?.assistInfo?.identifier, isWeb: stage.isWeb) { (view, rect, webview) in
                self.delegate!.stageIdentified(stage, pointerView: view, pointerRect: rect, webviewForRect: webview)
            }
        } else { checkForStage(in: allViews, withPassing: webIds, nativeIds, forFlow: delegate!.getParentFlow()) }
    }
    
    private func getViewOrRect(allView:Array<UIView>,id:String?, isWeb:Bool, targetCheckCompleted:@escaping(_:UIView?,_:CGRect?, UIView?)->Void) {
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


// MARK: - ASSIST DETECTION
extension JinyContextDetector {
    
    private func detectAssist(passingNativeIds:Array<String>, passingWebIds:Array<String>) -> JinyAssist? {
        var assistFound:JinyAssist?
        var maxWeight:Int = 0
        let assists = delegate!.getAllAssistsToCheck()
        for assist in assists {
            if isAUIElementPassing(passingWebIds, passingNativeIds, assist.webIdentifiers, assist.nativeIdentifiers) && assist.weight > maxWeight {
                assistFound = assist
                maxWeight = assist.weight
            }
        }
        return assistFound
    }
    
}

// MARK: - DISCOVERY DETECTION
extension JinyContextDetector {
    
    private func findDiscoveries(passingNativeIds:Array<String>, passingWebIds:Array<String>) -> Array<JinyDiscovery> {
        let discoveries = delegate!.getDiscoveriesToCheck()
        let passingDiscoveries = discoveries.filter({ (checkDiscovery) -> Bool in
            return isAUIElementPassing(passingWebIds, passingNativeIds, checkDiscovery.webIdentifiers, checkDiscovery.nativeIdentifiers)
        })
        return passingDiscoveries
    }
    
}


// MARK: - NATIVE IDENTIFIER CHECK
extension JinyContextDetector {
    
    private func getNativeIdentifiersPassing(_ identifiers:Array<String>, inHierarchy allView:Array<UIView>) -> Array<String> {
        let controllerString = String(describing: type(of: UIApplication.getCurrentVC().self))
        let controllerFilteredIdentifiers = identifiers.filter { (identifier) -> Bool in
            guard let nativeIdentifier = delegate!.getNativeIdentifier(identifierId: identifier) else { return false }
            guard let controllerCheckString = nativeIdentifier.controller else { return true }
            return controllerString == controllerCheckString
        }
        
        let passingIds = controllerFilteredIdentifiers.filter { (checkIdentifier) -> Bool in
            let views = getViewsForIdentifer(identifierId: checkIdentifier, hierarchy: allView)
            return views?.count ?? 0 > 0
        }
        return passingIds
    }
    
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


// MARK: - PAGE CHECK
extension JinyContextDetector {
    
    private func findPage(pages:Array<JinyPage>, webIds:Array<String>, nativeIds:Array<String>) -> JinyPage? {
        var pageIdentified:JinyPage?
        var maxWeight = 0
        for page in pages {
            if isAUIElementPassing(webIds, nativeIds, page.webIdentifiers, page.nativeIdentifiers) && page.weight > maxWeight {
                pageIdentified = page
                maxWeight = page.weight
            }
        }
        return pageIdentified
    }
    
}

// MARK: - STAGE CHECK
extension JinyContextDetector {
    
    private func findStage(stages:Array<JinyStage>, webIds:Array<String>, nativeIds:Array<String>) -> JinyStage? {
        var stageIdentified:JinyStage?
        var maxWeight = 0
        for stage in stages {
            if isAUIElementPassing(webIds, nativeIds, stage.webIdentifiers, stage.nativeIdentifiers) && stage.weight > maxWeight{
                stageIdentified = stage
                maxWeight = stage.weight
            }
        }
        return stageIdentified
    }
}

// MARK: - WEB IDENTFIER CHECK
extension JinyContextDetector {
    
    private func getRectForIdentifier(id:JinyWebIdentifier, webviews:Array<UIView>, rectCalculated:@escaping(_ :CGRect?, _ :UIView?)->Void) {
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
    
    private func getPassingWebIds(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ passingIds:Array<String>)->Void) {
        getElementsPresent(webIds, inSingleWebview: inSingleWebview) { (presentWebIds) in
            if presentWebIds.count > 0 {
                self.getElementsPassingAttributes(presentWebIds, inSingleWebview: inSingleWebview) { (passingWebIds) in
                    completion(passingWebIds)
                }
            } else { completion([]) }
        }
        
    }
    
    private func getElementsPresent(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ presentElements:Array<String>) -> Void ) {
        
        //Create query to check if element is present
        var jsString = "["
        for (index,webId) in webIds.enumerated() {
            if index != 0 { jsString += "," }
            if let webIdentifier = delegate!.getWebIdentifier(identifierId: webId) {
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
    
    private func getElementsPassingAttributes(_ webIds:Array<String>, inSingleWebview:UIView, completion:@escaping(_ passingElements:Array<String>) -> Void ) {
        var jsString = "["
        for (index,webId) in webIds.enumerated() {
            if index != 0 { jsString += "," }
            var checkScript = ""
            if let webIdentifier = delegate!.getWebIdentifier(identifierId: webId) {
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
