//
//  JinyIconView.swift
//  JinyDemo
//
//  Created by mac on 13/10/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import UIKit
import WebKit

/// JinyIconView which holds a button with Jiny Icon image.
class JinyIconView: UIView {

    /// iconButton of type UIbutton.
    var iconWebView = WKWebView()
    
    /// icon's background color.
    var iconBackgroundColor: UIColor = .blue {
        
        didSet {
            
            self.iconWebView.backgroundColor = iconBackgroundColor
        }
    }
    
    /// the height and width of the icon.
    var iconSize: CGFloat = 36
    
    /// the gap between icon and it's toView.
    let iconGap: CGFloat = 12
    
    var htmlUrl: String = ""
    
    /// preferences property for webview of type WKPreferences.
    let preferences = WKPreferences()
    
    /// configuration property for webview of type WKWebViewConfiguration.
    let configuration = WKWebViewConfiguration()
    
    let tapGestureRecognizer = UITapGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
        
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        configuration.userContentController.addUserScript(userScript)
            
        preferences.javaScriptEnabled = true
        
        let jsCallBack = "iosListener"
        configuration.userContentController.add(self, name: jsCallBack)
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences.javaScriptEnabled = true
        if #available(iOS 10.0, *) {
            configuration.dataDetectorTypes = [.all]
        } else {
            // Fallback on earlier versions
        }
        
        self.iconWebView = WKWebView(frame: .zero, configuration: configuration)
        self.iconWebView.scrollView.isScrollEnabled = false
        self.iconWebView.navigationDelegate = self
        
        self.iconWebView.addGestureRecognizer(tapGestureRecognizer)
        
        self.iconWebView.isUserInteractionEnabled = true
                
        self.iconWebView.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// sets iconButton's constraints w.r.t self.
    func configureIconButon() {
        
        self.addSubview(iconWebView)
        
       // Setting Constraints to iconButton
                
        iconWebView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: iconWebView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: iconWebView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: iconWebView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: iconWebView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
        
        // set width and height constraints to JinyIconView
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.iconWebView.clipsToBounds = true
        self.iconWebView.layer.cornerRadius = iconSize/2
                
        self.iconWebView.contentMode = .scaleAspectFit
        
        self.iconWebView.backgroundColor = iconBackgroundColor
        
        loadJinyIcon()
    }
    
    func loadJinyIcon() {
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Jiny").appendingPathComponent("aui_component")
        let fileName = htmlUrl.replacingOccurrences(of: "/", with: "$")
        let filePath = documentPath.appendingPathComponent(fileName)
        let req = URLRequest(url: filePath)
        self.iconWebView.load(req)
    }
}

extension JinyIconView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}

extension JinyIconView: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}
