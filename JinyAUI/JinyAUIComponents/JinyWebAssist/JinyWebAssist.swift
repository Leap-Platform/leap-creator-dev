//
//  JinyWebAssist.swift
//  AUIComponents
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public class JinyWebAssist: UIView, JinyAssist {
    
    /// webView to load html content.
    var webView = WKWebView()
    
    /// preferences property for webview of type WKPreferences.
    let preferences = WKPreferences()
    
    /// configuration property for webview of type WKWebViewConfiguration.
    let configuration = WKWebViewConfiguration()
    
    /// property to load content from local storage.
    public var appLocale = String()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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
        
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.scrollView.isScrollEnabled = true
        self.webView.navigationDelegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        fatalError("init(coder:) has not been implemented")
    }
    
    public var style: Style?
    
    public var assistInfo: AssistInfo?
    
    public func applyStyle(style: Style) {
        
    }
    
    public func setContent(htmlUrl: String, appLocale: String, contentFileUriMap: Dictionary<String, String>?) {
        
        // Loading the html source file from the project bundle
        
        guard let _ = URL(string: htmlUrl) else {
            
            if let url = Bundle.main.url(forResource: appLocale, withExtension: "html") {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
            
            performEnterAnimation(animation: assistInfo?.layoutInfo?.enterAnimation ?? "")
            
            return
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Jiny").appendingPathComponent("aui_component")
        let fileName = htmlUrl.replacingOccurrences(of: "/", with: "$")
        let filePath = documentPath.appendingPathComponent(fileName)
        let req = URLRequest(url: filePath)
        webView.load(req)
        
        performEnterAnimation(animation: assistInfo?.layoutInfo?.enterAnimation ?? "")
    }
    
    public func updateLayout(alignment: String, anchorBounds: CGRect?) {
        
    }
    
    public func show() {
            
        setContent(htmlUrl: self.assistInfo?.htmlUrl ?? "", appLocale: self.appLocale, contentFileUriMap: nil)
    }
    
    /// method to perform enter animation.
    /// - Parameters:
    ///   - animation: string to describe the type of animation.
    public func performEnterAnimation(animation: String) {
       
        if !animation.isEmpty {
            
            switch animation {
                
            case JinyLayoutAnimationType.slideRight.rawValue:
                
                let xPosition = webView.frame.origin.x
                
                webView.frame.origin.x = -(UIScreen.main.bounds.width)
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.x = xPosition
                }
                
            case JinyLayoutAnimationType.slideLeft.rawValue:
                
                let xPosition = webView.frame.origin.x
                
                webView.frame.origin.x = (UIScreen.main.bounds.width)
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.x = xPosition
                }
                
            case JinyLayoutAnimationType.slideTop.rawValue:
                
                let yPosition = webView.frame.origin.y
                
                webView.frame.origin.y = (UIScreen.main.bounds.height)
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.y = yPosition
                }
                
            case JinyLayoutAnimationType.slideBottom.rawValue:
                
                let yPosition = webView.frame.origin.y
                
                webView.frame.origin.y = -(UIScreen.main.bounds.height)
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.y = yPosition
                }
                
            case JinyLayoutAnimationType.zoomIn.rawValue:
                
                self.webView.transform = CGAffineTransform(scaleX: 0, y: 0)
                
                UIView.animate(withDuration: 1.0) {
                  
                   self.webView.transform = CGAffineTransform.identity
                }
                
            default: self.remove()
                
            }
        }
    }
    
    public func hide(withAnim: Bool) {
        
    }
    
    /// method to perform exit animation.
    /// - Parameters:
    ///   - animation: string to describe the type of animation.
    public func performExitAnimation(animation: String) {
        
        if !animation.isEmpty {
            
            switch animation {
                
            case JinyLayoutAnimationType.slideRight.rawValue:
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.x = (UIScreen.main.bounds.width)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    
                    self.remove()
                }
                
            case JinyLayoutAnimationType.slideLeft.rawValue:
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.x = -(UIScreen.main.bounds.width)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    
                    self.remove()
                }
                
            case JinyLayoutAnimationType.slideTop.rawValue:
                
                UIView.animate(withDuration: 1.5) {
                    
                    self.webView.frame.origin.y = -(UIScreen.main.bounds.height)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    
                    self.remove()
                }
                
            case JinyLayoutAnimationType.slideBottom.rawValue:
            
                UIView.animate(withDuration: 1.5) {
                
                    self.webView.frame.origin.y = (UIScreen.main.bounds.height)
                }
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                
                    self.remove()
                }
                
            case JinyLayoutAnimationType.fadeOut.rawValue:
                
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                    
                    self.webView.alpha = 0
                    
                    self.alpha = 0
                    
                }) { (success) in
                    
                    if success {
                        
                        self.remove()
                    }
                }
                
            default: self.remove()
                
            }
        
        } else {
            
            remove()
        }
    }
    
    public func remove() {
        
        self.removeFromSuperview()
        
    }

    /// call the method internally when webView didFinish navigation called
    /// - Parameters:
    ///   - webView: WebView object on which the method is called.
    ///   - navigation: to uniquely identify a webpage load from start to finish.
    func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    /// call the method internally when webView didReceive WKScriptMessage called
    /// - Parameters:
    ///   - userContentController: WKUserContentController object on which the method is called.
    ///   - message: Message of the webView callback.
    func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}

extension JinyWebAssist: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        self.isHidden = false
                
        didFinish(webView, didFinish: navigation)
    }
}

extension JinyWebAssist: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        didReceive(userContentController, didReceive: message)
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, Any> else {return}
        guard let dictBody = dict["body"] as? Dictionary<String, Any> else {return}
        guard let close = dictBody["close"] as? Bool else {return}
        
        print(dict)
        
        if let urlString = dictBody["external_url"] as? String, let url = URL(string: urlString) {

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                // Fallback on earlier versions
            }
                
           return
        }
        
        if close {
            
           self.performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "")
        }
    }
}

extension WKWebView {
    
    /// call the method internally to load content from web.
    /// - Parameters:
    ///   - urlString: A url to load content from.
    func load(url urlString: String) {
        
        if let url = URL(string: urlString) {
            
            let request = URLRequest(url: url)
            load(request)
        }
    }
}
