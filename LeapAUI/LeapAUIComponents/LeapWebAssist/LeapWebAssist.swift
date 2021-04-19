//
//  LeapWebAssist.swift
//  LeapAUI
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// A super class for the LeapWebAssist AUI Components.
class LeapWebAssist: UIView, LeapAssist {
    
    /// webView to load html content.
    var webView = WKWebView()
    
    var leapIconView = LeapIconView()
    
    /// preferences property for webview of type WKPreferences.
    let preferences = WKPreferences()
    
    /// configuration property for webview of type WKWebViewConfiguration.
    let configuration = WKWebViewConfiguration()
    
    /// property to load content from local storage.
    var appLocale = String()
    
    var iconInfo: LeapIconInfo?
    
    let baseUrl: String?
    
    /// javascript to adjust width according to native view.
    private let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
    
    init(frame: CGRect, baseUrl: String?) {
        self.baseUrl = baseUrl
        super.init(frame: frame)
        
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        if #available(iOS 11.0, *) {
            configuration.setURLSchemeHandler(self, forURLScheme: "leap-scheme")
        } else {
            // Fallback on earlier versions
        }
        
        let jsCallBack = "iosListener"
        configuration.userContentController.add(self, name: jsCallBack)
        configuration.allowsInlineMediaPlayback = true
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        configuration.dataDetectorTypes = [.all]

        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.scrollView.isScrollEnabled = false
        self.webView.navigationDelegate = self
        self.webView.backgroundColor = .clear
        self.webView.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: LeapAssistDelegate?
    
    var style: LeapStyle?
    
    var assistInfo: LeapAssistInfo?
    
    func applyStyle(style: LeapStyle) {
        
    }
    
    func setContent(htmlUrl: String, appLocale: String, contentFileUriMap: Dictionary<String, String>?) {
        
        // Loading the html source file from the main project bundle
        guard let _ = URL(string: htmlUrl) else {
            
            let bundle = Bundle(for: type(of: self))
            
            if let url = bundle.url(forResource: appLocale, withExtension: "html") {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
            
            return
        }
        
        // Loading the html from documents directory
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Leap").appendingPathComponent("aui_component")
        let fileName = htmlUrl.replacingOccurrences(of: "/", with: "$")
        let filePath = documentPath.appendingPathComponent(fileName)
        guard var string = try? String(contentsOf: filePath, encoding: .utf8), let baseUrl = self.baseUrl else {
            webView.loadHTML(withUrl: filePath)
            return
        }
        if #available(iOS 11.0, *) { string = string.replacingOccurrences(of: baseUrl, with: "leap-scheme://") }
        webView.loadHTMLString(string, baseURL: nil)
    }
    
    func updateLayout(alignment: String, anchorBounds: CGRect?) {
        
    }
    
    func show() {
        setContent(htmlUrl: self.assistInfo?.htmlUrl ?? "", appLocale: self.appLocale, contentFileUriMap: nil)
    }
    
    /// method to perform enter animation.
    /// - Parameters:
    ///   - animation: string to describe the type of animation.
    func performEnterAnimation(animation: String) {
       
        if !animation.isEmpty {
            
            switch animation {
                
            case LeapLayoutAnimationType.slideRight.rawValue:
                
                let xPosition = webView.frame.origin.x
                
                   webView.frame.origin.x = -(UIScreen.main.bounds.width)
                
                   self.leapIconView.alpha = 0
                
                   let alpha = self.alpha
                
                   self.alpha = 0
                
                   UIView.animate(withDuration: 0.18, animations: {
                    
                      self.alpha = alpha
                   
                      self.webView.frame.origin.x = xPosition
                    
                   }) { (_) in
                    
                      UIView.animate(withDuration: 0.04) {
                        
                         self.leapIconView.alpha = 1
                        
                         self.delegate?.didPresentAssist()
                      }
                   }
                
            case LeapLayoutAnimationType.slideLeft.rawValue:
                
                let xPosition = webView.frame.origin.x
                
                   webView.frame.origin.x = (UIScreen.main.bounds.width)
                
                   leapIconView.alpha = 0
                
                   let alpha = self.alpha
                
                   self.alpha = 0
                
                   UIView.animate(withDuration: 0.18, animations: {
                    
                      self.alpha = alpha
                   
                      self.webView.frame.origin.x = xPosition
                    
                   }) { (_) in
                    
                      UIView.animate(withDuration: 0.04) {
                        
                          self.leapIconView.alpha = 1
                        
                          self.delegate?.didPresentAssist()
                      }
                   }
                
            case LeapLayoutAnimationType.slideTop.rawValue:
                
                let yPosition = webView.frame.origin.y
                
                webView.frame.origin.y = (UIScreen.main.bounds.height) + (UIScreen.main.bounds.height/2)
                
                leapIconView.alpha = 0
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                   self.webView.frame.origin.y = yPosition
                                        
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.leapIconView.alpha = 1
                        
                        self.delegate?.didPresentAssist()
                    }
                }
                
            case LeapLayoutAnimationType.slideBottom.rawValue:
                
                let yPosition = webView.frame.origin.y
                
                webView.frame.origin.y = -(UIScreen.main.bounds.height)
                
                leapIconView.alpha = 0
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.webView.frame.origin.y = yPosition
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                       self.leapIconView.alpha = 1
                        
                       self.delegate?.didPresentAssist()
                    }
                }
                
            case LeapLayoutAnimationType.zoomIn.rawValue:
                
                let alpha = self.alpha
                
                self.alpha = 0
                
                leapIconView.alpha = 0
                
                self.webView.alpha = 0
                
                self.webView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                
                UIView.animate(withDuration: 0.08, animations: {
                    
                    self.alpha = alpha
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.webView.alpha = 1
                        
                        self.webView.transform = CGAffineTransform.identity
                        
                        self.leapIconView.alpha = 1
                        
                        self.delegate?.didPresentAssist()
                    }
                }
                
            default: self.delegate?.didPresentAssist()
                
            }
        }
    }
    
    /// method to perform exit animation.
    /// - Parameters:
    ///   - animation: string to describe the type of animation.
    func performExitAnimation(animation: String, byUser:Bool, autoDismissed:Bool, byContext:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        
        if !animation.isEmpty {
            
            switch animation {
                
            case LeapLayoutAnimationType.slideLeft.rawValue:
                
                UIView.animate(withDuration: 0.18, animations: {
                    
                    self.leapIconView.alpha = 0
                                        
                    self.webView.frame.origin.x = -(UIScreen.main.bounds.width)
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.alpha = 0
                        
                        self.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
                        
                        self.leapIconView.removeFromSuperview()
                    }
                }
                
            case LeapLayoutAnimationType.slideRight.rawValue:
                
                UIView.animate(withDuration: 0.18, animations: {
                    
                    self.leapIconView.alpha = 0
                                        
                    self.webView.frame.origin.x = (UIScreen.main.bounds.width)
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.04) {
                        
                        self.alpha = 0
                        
                        self.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
                        
                        self.leapIconView.removeFromSuperview()
                    }
                }
                
            case LeapLayoutAnimationType.slideBottom.rawValue:
                
                UIView.animate(withDuration: 0.18, animations: {
                    
                    self.leapIconView.alpha = 0
                    
                    self.webView.frame.origin.y = (UIScreen.main.bounds.height)
                    
                }) { (_) in
                    
                    UIView.animate(withDuration: 0.08) {
                        
                        self.alpha = 0
                        
                        self.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
                        
                        self.leapIconView.removeFromSuperview()
                    }
                }
                
            case LeapLayoutAnimationType.fadeOut.rawValue:
                                
                UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseOut, animations: {
                    
                    self.leapIconView.alpha = 0
                    
                    self.webView.alpha = 0
                    
                    self.alpha = 0
                    
                }) { (_) in
                    
                    self.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
                    
                    self.leapIconView.removeFromSuperview()
                }
                
            default: self.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
                
            }
        
        } else {
            
            self.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
        }
    }
    
    func remove(byContext:Bool, byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        self.removeFromSuperview()
        self.delegate?.didDismissAssist(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    func hide() {
        self.isHidden = true
    }
    
    func unhide() {
        self.isHidden = false
    }
    
    /// method to configure LeapIconView constraints.
    /// - Parameters:
    ///   - superView: view to which LeapIconView is added.
    ///   - toItemView: LeapIconView constraints set w.r.t this view.
    ///   - alignmentType: whether it is top or bottom.
    func configureLeapIconView(superView: UIView, toItemView: UIView, alignmentType: LeapAlignmentType, cornerDistance: CGFloat = 0) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(leapIconView)
        
        leapIconView.htmlUrl = iconInfo?.htmlUrl
        
        leapIconView.tapGestureRecognizer.addTarget(self, action: #selector(leapIconButtonTapped))
        
        leapIconView.tapGestureRecognizer.delegate = self
        
        leapIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
        
        self.leapIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var cornerConstraint: NSLayoutConstraint.Attribute = .leading
        
        var attributeType2: NSLayoutConstraint.Attribute = .top
        
        var attributeType3: NSLayoutConstraint.Attribute = .bottom
        
        var distance: CGFloat = self.leapIconView.iconGap
        
        if !(iconInfo?.isLeftAligned ?? false) {

            cornerConstraint = .trailing
        }
        
        if alignmentType == .top {
            
            attributeType2 = .bottom
            
            attributeType3 = .top
            
            distance = -self.leapIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: cornerConstraint, relatedBy: .equal, toItem: toItemView, attribute: cornerConstraint, multiplier: 1, constant: cornerDistance))
        
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType3, multiplier: 1, constant: distance))
        
        leapIconView.configureIconButton()
    }
    
    /// call the method when you want the webView content to be in the desired user's language.
    /// - Parameters:
    ///   - locale: User's desired language selected in the Leap panel.
    func changeLanguage(locale: String) {
        webView.evaluateJavaScript("changeLocale('\(locale)')", completionHandler: nil)
    }

    /// call the method internally when webView didFinish navigation called
    /// - Parameters:
    ///   - webView: WebView object on which the method is called.
    ///   - navigation: to uniquely identify a webpage load from start to finish.
    func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
    }
    
    /// call the method internally when webView didReceive WKScriptMessage called
    /// - Parameters:
    ///   - userContentController: WKUserContentController object on which the method is called.
    ///   - message: Message of the webView callback.
    func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}

extension LeapWebAssist: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        self.isHidden = false
        
        if let language = LeapPreferences.shared.getUserLanguage() {
            
           changeLanguage(locale: language)
        }
        
        didFinish(webView, didFinish: navigation)
                
        performEnterAnimation(animation: assistInfo?.layoutInfo?.enterAnimation ?? "zoom_in")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        
        delegate?.failedToPresentAssist()
    }
}

extension LeapWebAssist: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        didReceive(userContentController, didReceive: message)
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String, Any> else {return}
        guard let dictBody = dict[constant_body] as? Dictionary<String, Any> else {return}
        guard let close = dictBody[constant_close] as? Bool else {return}
        
        if let urlString = dictBody[constant_external_url] as? String, let url = URL(string: urlString) {

           UIApplication.shared.open(url)

           return
        }
        
        if close {
            
            self.performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: dict)
        }
    }
}

extension LeapWebAssist:WKURLSchemeHandler {
    
    @available(iOS 11.0, *)
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url?.relativeString else { return }
        let fileUrl = url.replacingOccurrences(of: "leap-scheme://", with: "")
        let fileName = fileUrl.replacingOccurrences(of: "/", with: "$")
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("Leap").appendingPathComponent("aui_component").appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: filePath.path), let fileData = try? Data(contentsOf: filePath) {
            urlSchemeTask.didReceive(URLResponse())
            urlSchemeTask.didReceive(fileData)
            urlSchemeTask.didFinish()
        } else {
            guard let baseUrl = baseUrl, let newUrl = URL(string: baseUrl+fileName) else { return }
            let dlTask = URLSession.shared.downloadTask(with: newUrl) { (loc, res, err) in
                guard let location = loc else { return }
                DispatchQueue.main.async {
                    guard let data = try? Data(contentsOf: location) else { return }
                    urlSchemeTask.didReceive(URLResponse())
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                }
            }
            dlTask.resume()
        }
    }
    
    @available(iOS 11.0, *)
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
    }
    
    
}

extension LeapWebAssist: UIGestureRecognizerDelegate {
    
    @objc func leapIconButtonTapped() {
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
