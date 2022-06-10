//
//  LeapWebViewFinder.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import WebKit

/// LeapWebViewFinder helps to see if a web identifier is present in provided hierarchy
class LeapWebViewFinder {
    
    /// Array of viewprops of views which are WKWebviews
    let webviewProps:[LeapViewProperties]
    let webInjectionDispatchGroup = DispatchGroup()
    
    /// Intialization method
    /// - Parameter hierarchy: hierachy to filter out webviews from
    init(with hierarchy:[String:LeapViewProperties]) {
        var tempArray:[LeapViewProperties] = []
        hierarchy.forEach { viewId, props in
            if props.isWKWebview { tempArray.append(props) }
        }
        webviewProps = tempArray
    }
    
    /// Get valid web identifiers
    /// - Parameters:
    ///   - webIdentifierTuples: List of all (webIdentifierId, webIdentifier) as array of tuples
    ///   - completion: Competion callback with passing webIds
    public func getValidIdentifiers(from webIdentifierTuples:[(String,LeapWebIdentifier)],
                                    _ completion:@escaping(_ passingIds:[String])->Void) {
        guard webIdentifierTuples.count > 0 else {
            completion([])
            return
        }
        var passedIds:[String] = []
        
        for webviewProp in webviewProps {
            if let wkWebView = webviewProp.weakView as? WKWebView {
                webInjectionDispatchGroup.enter()
                webIdsPassingIn(webIdentifierTuples, passingIn: wkWebView) {[weak self] newPassedIds in
                    passedIds = Array(Set(passedIds+newPassedIds))
                    self?.webInjectionDispatchGroup.leave()
                }
            }
        }
        webInjectionDispatchGroup.notify(queue: .main) {
            completion(passedIds)
        }
    }
    
    /// Get bounds of web element if present
    /// - Parameters:
    ///   - webIdentifier: The identifier of the web element to get the bounds for
    ///   - completion: Completion callback providing bounds and the webview in which the bounds is present; If not present both are nil
    ///   - rect: The bounds as CGrect of element; If not found returns nil
    ///   - webview: The webview in which the web element was identified
    public func getRectFor(_ webIdentifier:LeapWebIdentifier, completion:@escaping(_ rect:CGRect?, _ webview:WKWebView?)->Void) {
        let webViewList = webviewProps.compactMap { return $0.weakView as? WKWebView }
        guard webViewList.count > 0 else {
            completion(nil,nil)
            return
        }
        var counter = 0
        var boundsCompletion:((_ rect:CGRect?) -> Void)? = nil
        boundsCompletion = { rect in
            if rect != nil {
                completion(rect, webViewList[counter])
                return
            }
            counter += 1
            guard counter < webViewList.count else {
                completion(nil,nil)
                return
            }
            self.getRect(for: webIdentifier, inWebView: webViewList[counter], completion: boundsCompletion!)
        }
        self.getRect(for: webIdentifier, inWebView: webViewList[counter], completion: boundsCompletion!)
    }
    
    ///  Checks if webId is passing in webview
    /// - Parameters:
    ///   - idTuples: List of all (webIdentifierId, webIdentifier) as array of tuples
    ///   - webview: Webview to check in
    ///   - completion: Completion callback returning ids of passing web identifiers
    public func webIdsPassingIn(_ idTuples:[(String,LeapWebIdentifier)],
                                 passingIn webview:WKWebView,
                                 completion:@escaping(_ newPassedIds:[String])->Void) {
        webIdsPresentCheck(idTuples, presentIn: webview) {[weak self] presentIdTuples in
            self?.webIdsAttributeCheck(presentIdTuples, in: webview, attributeCheckCompletion: { passedIdTuples in
                let passedIds:[String] = passedIdTuples.map { return $0.0 }
                completion(passedIds)
            })
        }
    }
    
    /// Checks if webIds is present in webview
    /// - Parameters:
    ///   - idTuples: List of all (webIdentifierId, webIdentifier) as array of tuples
    ///   - webview: Webview to check in
    ///   - presentCheckCompletion: Completion callback returning list of (id,identifier) tuples for present web identifiers
    private func webIdsPresentCheck(_ idTuples:[(String,LeapWebIdentifier)],
                                    presentIn webview:WKWebView,
                                    presentCheckCompletion:@escaping(_ presentIdTuples:[(String,LeapWebIdentifier)])->Void) {
        var overAllCheckElementScript = "["
        for (index,(_, identifier)) in idTuples.enumerated() {
            if index != 0 { overAllCheckElementScript += "," }
            let checkElementScript  = LeapJSMaker.generateNullCheckScript(identifier: identifier)
            overAllCheckElementScript += checkElementScript
        }
        overAllCheckElementScript += "].toString()"
        
        runJavascript(overAllCheckElementScript, wkweb: webview) { resultString in
            if let result = resultString {
                let allIds:[String] = idTuples.map { return $0.0 }
                let presentIds = self.getPassingIdsFromJSResult(jsResult: result, toCheckIds: allIds)
                let presentTuples = idTuples.filter { return presentIds.contains($0.0) }
                presentCheckCompletion(presentTuples)
            } else { presentCheckCompletion([]) }
        }
    }
    
    /// Checks if webIds attributes are correct is present in webview
    /// - Parameters:
    ///   - idTuples: List of all (webIdentifierId, webIdentifier) as array of tuples
    ///   - webview: Webview to check in
    ///   - attributeCheckCompletion: Completion callback returning list of (id,identifier) tuples for attribute matching web identifiers
    private func webIdsAttributeCheck(_ idTuples:[(String,LeapWebIdentifier)],
                                      in webview:WKWebView,
                                      attributeCheckCompletion:@escaping(_ passedIdTuples:[(String,LeapWebIdentifier)])->Void) {
        var overallAttributeCheckScript = "["
        for (index, (_, identifier)) in idTuples.enumerated() {
            if index != 0 { overallAttributeCheckScript += ","}
            if let attributeElementCheck = LeapJSMaker.generateAttributeCheckScript(webIdentifier: identifier) {
                overallAttributeCheckScript += attributeElementCheck
            } else {
                let nullCheckScript  = LeapJSMaker.generateNullCheckScript(identifier: identifier)
                overallAttributeCheckScript += nullCheckScript
            }
            
        }
        overallAttributeCheckScript += "].toString()"
        
        runJavascript(overallAttributeCheckScript, wkweb: webview) { (res) in
            if let result = res {
                let presentIds = idTuples.map{ return $0.0 }
                let passingIds = self.getPassingIdsFromJSResult(jsResult: result, toCheckIds: presentIds)
                let passingTuples = idTuples.filter{ return passingIds.contains($0.0) }
                attributeCheckCompletion(passingTuples)
            } else { attributeCheckCompletion([]) }
        }
    }
    
    /// Inject js into webview and retrieve results
    /// - Parameters:
    ///   - script: Script to inject
    ///   - wkweb: Webview to inject script in
    ///   - completion: Completion callback returning script result as string
    private func runJavascript(_ script:String, wkweb:WKWebView, completion:@escaping(_ resultString:String?)->Void) {
        wkweb.evaluateJavaScript(script.replacingOccurrences(of: "\n", with: "\\n")) { (res, err) in
            if let result = res as? String { completion(result) }
            else { completion(nil) }
        }
    }
    
    /// Extract passing ids based on js script result
    /// - Parameters:
    ///   - jsResult: Result from running the js script
    ///   - toCheckIds: The array of web identifier ids to check
    /// - Returns: Array of web identifier ids passing the test
    private func getPassingIdsFromJSResult(jsResult:String, toCheckIds:Array<String>) -> Array<String> {
        let boolStrings = jsResult.components(separatedBy: ",")
        var presentIds:Array<String> = []
        for (index,id) in toCheckIds.enumerated() {
            if NSString(string: boolStrings[index]).boolValue { presentIds.append(id) }
        }
        return presentIds
    }
    
    
    /// Method to calculate bounds of a web element in a single webview
    /// - Parameters:
    ///   - identifier: The identifier of the web element to which rect is to be found
    ///   - inWebView: The webview in which the element is to be checked for
    ///   - completion: Completion callback returning bounds if found; else nil
    private func getRect(for identifier:LeapWebIdentifier, inWebView:WKWebView, completion:@escaping(_ rect:CGRect?)->Void) {
        let boundsScript = LeapJSMaker.calculateBoundsScript(identifier)
        runJavascript(boundsScript, wkweb: inWebView) { resultString in
            if let result = resultString {
                let resultArray = result.components(separatedBy: ",").compactMap({ CGFloat(($0 as NSString).doubleValue) })
                if resultArray.count != 4 { completion(nil) }
                else {
                    var rect = CGRect(x: resultArray[0] * inWebView.scrollView.zoomScale, y: resultArray[1] * inWebView.scrollView.zoomScale, width: resultArray[2] * inWebView.scrollView.zoomScale, height: resultArray[3] * inWebView.scrollView.zoomScale)
                    
                    if #available(iOS 11.0, *) {
                        rect.origin.y += inWebView.scrollView.adjustedContentInset.top
                        rect.origin.x += UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0.0
                    }
                    
                    if rect.origin.y < 0 || rect.origin.x < 0 || rect.origin.x > inWebView.bounds.maxX {
                        completion(nil)
                    } else {
                        completion(rect)
                    }
                }
            } else { (completion(nil)) }
        }
    }
}
