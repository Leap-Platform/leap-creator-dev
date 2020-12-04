//
//  JinyWebAssist.swift
//  JinyDemo
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// A super class for the JinyWebAssist AUI Components.
public class JinyWebAssist: UIView, JinyAssist {
    
    /// webView to load html content.
    var webView = WKWebView()
    
    var jinyIconView = JinyIconView()
    
    /// preferences property for webview of type WKPreferences.
    let preferences = WKPreferences()
    
    /// configuration property for webview of type WKWebViewConfiguration.
    let configuration = WKWebViewConfiguration()
    
    /// property to load content from local storage.
    public var appLocale = String()
    
    public var iconInfo: IconInfo?
    
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
    
    public weak var delegate: JinyAssistDelegate?
    
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
            
            return
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Jiny").appendingPathComponent("aui_component")
        let fileName = htmlUrl.replacingOccurrences(of: "/", with: "$")
        let filePath = documentPath.appendingPathComponent(fileName)
        let req = URLRequest(url: filePath)
        webView.load(req)        
    }
    
    public func updateLayout(alignment: String, anchorBounds: CGRect?) {
        
    }
    
    public func show() {
            
        setContent(htmlUrl: self.assistInfo?.htmlUrl ?? "", appLocale: self.appLocale, contentFileUriMap: nil)
        
        delegate?.willPresentAssist()
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
                
                   self.jinyIconView.alpha = 0
                
                   let alpha = self.alpha
                
                   self.alpha = 0
                
                   UIView.animate(withDuration: 0.18, animations: {
                    
                      self.alpha = alpha
                   
                      self.webView.frame.origin.x = xPosition
                    
                   }) { (_) in
                    
                      UIView.animate(withDuration: 0.04) {
                        
                         self.jinyIconView.alpha = 1
                        
                         self.delegate?.didPresentAssist()
                      }
                   }
                
            case JinyLayoutAnimationType.slideLeft.rawValue:
                
                let xPosition = webView.frame.origin.x
                
                   webView.frame.origin.x = (UIScreen.main.bounds.width)
                
                   jinyIconView.alpha = 0
                
                   let alpha = self.alpha
                
                   self.alpha = 0
                
                   UIView.animate(withDuration: 0.18, animations: {
                    
                      self.alpha = alpha
                   
                      self.webView.frame.origin.x = xPosition
                    
                   }) { (_) in
                    
                      UIView.animate(withDuration: 0.04) {
                        
                          self.jinyIconView.alpha = 1
                        
                          self.delegate?.didPresentAssist()
                      }
                   }
                
            case JinyLayoutAnimationType.slideTop.rawValue:
                
                let yPosition = webView.frame.origin.y
                
                webView.frame.origin.y = (UIScreen.main.bounds.height) + (UIScreen.main.bounds.height/2)
                
                jinyIconView.alpha = 0
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                   self.webView.frame.origin.y = yPosition
                                        
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.jinyIconView.alpha = 1
                        
                        self.delegate?.didPresentAssist()
                    }
                }
                
            case JinyLayoutAnimationType.slideBottom.rawValue:
                
                let yPosition = webView.frame.origin.y
                
                webView.frame.origin.y = -(UIScreen.main.bounds.height)
                
                jinyIconView.alpha = 0
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.webView.frame.origin.y = yPosition
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                       self.jinyIconView.alpha = 1
                        
                       self.delegate?.didPresentAssist()
                    }
                }
                
            case JinyLayoutAnimationType.zoomIn.rawValue:
                
                let alpha = self.alpha
                
                self.alpha = 0
                
                jinyIconView.alpha = 0
                
                self.webView.alpha = 0
                
                self.webView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                
                UIView.animate(withDuration: 0.08, animations: {
                    
                    self.alpha = alpha
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.webView.alpha = 1
                        
                        self.webView.transform = CGAffineTransform.identity
                        
                        self.jinyIconView.alpha = 1
                        
                        self.delegate?.didPresentAssist()
                    }
                }
                
            default: self.delegate?.didPresentAssist()
                
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
                
            case JinyLayoutAnimationType.slideLeft.rawValue:
                
                UIView.animate(withDuration: 0.18, animations: {
                    
                    self.jinyIconView.alpha = 0
                                        
                    self.webView.frame.origin.x = -(UIScreen.main.bounds.width)
                    
                    self.delegate?.didExitAnimation()
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.alpha = 0
                        
                        self.remove()
                        
                        self.jinyIconView.removeFromSuperview()
                    }
                }
                
            case JinyLayoutAnimationType.slideRight.rawValue:
                
                UIView.animate(withDuration: 0.18, animations: {
                    
                    self.jinyIconView.alpha = 0
                                        
                    self.webView.frame.origin.x = (UIScreen.main.bounds.width)
                    
                    self.delegate?.didExitAnimation()
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.alpha = 0
                        
                        self.remove()
                        
                        self.jinyIconView.removeFromSuperview()
                    }
                }
                
            case JinyLayoutAnimationType.slideBottom.rawValue:
                
                UIView.animate(withDuration: 0.18, animations: {
                    
                    self.jinyIconView.alpha = 0
                    
                    self.webView.frame.origin.y = (UIScreen.main.bounds.height)
                    
                    self.delegate?.didExitAnimation()
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.08) {
                        
                        self.alpha = 0
                        
                        self.remove()
                        
                        self.jinyIconView.removeFromSuperview()
                    }
                }
                
            case JinyLayoutAnimationType.fadeOut.rawValue:
                                
                UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseOut, animations: {
                    
                    self.jinyIconView.alpha = 0
                    
                    self.webView.alpha = 0
                    
                    self.alpha = 0
                    
                    self.delegate?.didExitAnimation()
                    
                }) { (success) in
                    
                    if success {
                        
                        self.remove()
                        
                        self.jinyIconView.removeFromSuperview()
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
    
    @objc func jinyIconButtonTapped(button: UIButton) {
        
        self.delegate?.didTapAssociatedJinyIcon()
    }
    
    /// method to configure JinyIconView constraints.
    /// - Parameters:
    ///   - superView: view to which JinyIconView is added.
    ///   - toItemView: JinyIconView constraints set w.r.t this view.
    ///   - alignmentType: whether it is top or bottom.
    func configureJinyIconView(superView: UIView, toItemView: UIView, alignmentType: JinyAlignmentType) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(jinyIconView)
        
        jinyIconView.iconButton.addTarget(self, action: #selector(jinyIconButtonTapped(button:)), for: .touchUpInside)
        
        jinyIconView.iconBackgroundColor = UIColor.colorFromString(string: iconInfo?.backgroundColor ?? UIColor.stringFromUIColor(color: .blue))
                
        self.jinyIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        var attributeType2: NSLayoutConstraint.Attribute = .top
        
        var attributeType3: NSLayoutConstraint.Attribute = .bottom
        
        var distance: CGFloat = self.jinyIconView.iconGap
        
        if !(iconInfo?.isLeftAligned ?? false) {

            attributeType1 = .trailing
        }
        
        if alignmentType == .top {
            
            attributeType2 = .bottom
            
            attributeType3 = .top
            
            distance = -self.jinyIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: 0))
        
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType3, multiplier: 1, constant: distance))
    }
    
    /// call the method when you want the webView content to be in the desired user's language.
    /// - Parameters:
    ///   - locale: User's desired language selected in the Jiny panel.
    func changeLanguage(locale: String) {
        webView.evaluateJavaScript("changeLocale('\(locale)')", completionHandler: nil)
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
        
        changeLanguage(locale: UserDefaults.standard.object(forKey: "audio_language_code") as! String)
                
        didFinish(webView, didFinish: navigation)
                
        performEnterAnimation(animation: assistInfo?.layoutInfo?.enterAnimation ?? "zoom_in")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        delegate?.failedToPresentAssist()
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
        delegate?.didSendAction(dict: dict)
        
        if let urlString = dictBody["external_url"] as? String, let url = URL(string: urlString) {

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                // Fallback on earlier versions
            }
                
           return
        }
        
        if close {
            
           self.performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out")
        }
    }
}
