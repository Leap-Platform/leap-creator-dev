//
//  LeapLanguageOptions.swift
//  LeapAUI
//
//  Created by Ajay S on 03/02/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

typealias languageSuccessCallback = (_ sucess: Bool, _ languageSelected: String?) -> Void

class LeapLanguageOptions: LeapBottomSheet {
    
    var discoveryLanguagesScript = ""
    
    private var completionHandler: ((Bool, String?) -> Void)?
        
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?) {
        super.init(withDict: assistDict, iconDict: iconDict, baseUrl: baseUrl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(withDict assisDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, withLanguages languages: [Dictionary<String, String>], withHtmlUrl htmlUrl: String?, baseUrl: String?, handler: (languageSuccessCallback)? = nil) {
        self.init(withDict: assisDict, iconDict: iconDict, baseUrl:baseUrl)
        
        self.completionHandler = handler
                
        if let htmlUrl = htmlUrl {
            
            assistInfo?.htmlUrl = htmlUrl
        }
        
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(languages) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                discoveryLanguagesScript = jsonString
            }
        }        
    }
    
    /// This is a custom configuration of constraints for the LanguageOptions component.
    override func configureWebViewForBottomSheet() {
      
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        
        let maxHeight = 0.8 * (self.superview?.frame.height ?? 0.0)
        
        heightConstraint = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: maxHeight)
        
        NSLayoutConstraint.activate([heightConstraint!])
    }
    
    private func getLanguages() {
        webView.evaluateJavaScript("initIOSHtml('\(discoveryLanguagesScript)', '\(self.iconInfo?.backgroundColor ?? "#00000000")')", completionHandler: nil)
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        super.didFinish(webView, didFinish: navigation)
        
        getLanguages()
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        super.didReceive(userContentController, didReceive: message)
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        
        if let type = dict[constant_type] as? String, type == constant_action_taken {
            
            if let dictBody = dict[constant_body] as? [String : Any], let selected = dictBody[constant_type] as? String, selected == constant_onLanguageSelected, let localeCode = dictBody[constant_localeCode] as? String {
                
                self.completionHandler?(true, localeCode)
            
            } else {
                
                self.completionHandler?(false, nil)
            }
        }
    }
}
