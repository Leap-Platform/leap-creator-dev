//
//  JinyIconView.swift
//  JinyDemo
//
//  Created by mac on 13/10/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import UIKit
import WebKit

/// Type to track the state.
enum JinyIconState: String {
    case rest
    case loading
    case audioPlay
}

/// Type to notify icon state change
protocol JinyIconStateDelegate: class {
    func iconDidChange(state: JinyIconState)
}

/// JinyIconView which holds a webview with Jiny Icon image.
public class JinyIconView: UIView {
    
    /// Delegation when there is a change in icon state.
    weak var stateDelegate: JinyIconStateDelegate?
    
    /// enum property to track the state.
    var iconState: JinyIconState = .rest {
        
        didSet {
            
            stateDelegate?.iconDidChange(state: iconState)
        }
    }
    
    /// iconWebView of type WKWebView.
    var iconWebView: WKWebView?
    
    /// audioWebView of type WKWebView.
    var audioWebView: WKWebView?
    
    /// icon's background color.
    var iconBackgroundColor: UIColor = .black
    
    /// the height and width of the icon.
    var iconSize: CGFloat = 36
    
    /// the gap between icon and it's toView.
    let iconGap: CGFloat = 12
    
    /// tap gesture for iconWebView.
    let tapGestureRecognizer = UITapGestureRecognizer()
    
    /// if customised is true then this url is non-nil.
    var htmlUrl: String?
    
    /// default audio anim in the SDK bundle.
    private var audioUrl: String = "jiny_audio_anim"
    
    /// default icon in the SDK bundle.
    private var defaultIconUrl: String = "jiny_default_icon"
    
    /// javascript to adjust width according to native view.
    private let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
    
    /// loading view for download progress.
    var loadingView: UIView?
    
    /// loading layer for download progress.
    var loadingLayer: CAShapeLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupIconView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupIconView() {
        
        let preferences = WKPreferences()
        
        let configuration = WKWebViewConfiguration()
        
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
        self.iconWebView?.scrollView.isScrollEnabled = false
        self.iconWebView?.isOpaque = false
        self.iconWebView?.navigationDelegate = self
        
        self.iconWebView?.addGestureRecognizer(tapGestureRecognizer)
        self.iconWebView?.isUserInteractionEnabled = true
    }
    
    func setupAudioAnimView() {
        
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(userScript)
        
        let preferences = WKPreferences()
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
        
        self.audioWebView = WKWebView(frame: .zero, configuration: configuration)
        self.audioWebView?.navigationDelegate = self
        self.audioWebView?.scrollView.isScrollEnabled = false
        self.audioWebView?.isOpaque = false
    }
    
    /// sets iconButton's constraints w.r.t self.
    func configureIconButon() {
        
        self.addSubview(iconWebView!)
        
        // Setting Constraints to iconButton
        
        iconWebView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: iconWebView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: iconWebView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: iconWebView!, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: iconWebView!, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
        
        // set width and height constraints to JinyIconView
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.iconWebView?.clipsToBounds = true
        self.iconWebView?.layer.cornerRadius = iconSize/2
        
        self.iconWebView?.contentMode = .scaleAspectFit
                
        loadJinyIcon()
    }
    
    /// sets iconButton's constraints w.r.t self.
    func configureAudioIconButon() {
        
        self.addSubview(audioWebView!)
        
        // Setting Constraints to iconButton
        
        audioWebView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: audioWebView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: audioWebView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: audioWebView!, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: audioWebView!, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
        
        // set width and height constraints to JinyIconView
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: iconSize))
        
        self.audioWebView?.clipsToBounds = true
        self.audioWebView?.layer.cornerRadius = iconSize/2
        
        self.audioWebView?.contentMode = .scaleAspectFit
                
        loadAudioAnim()
    }
    
    func loadJinyIcon() {
        
        guard let htmlUrl = self.htmlUrl else {
            
            let bundle = Bundle(for: type(of: self))
            
            if let url = bundle.url(forResource: defaultIconUrl, withExtension: "html") {
                self.iconWebView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
            return
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Jiny").appendingPathComponent("aui_component")
        let fileName = htmlUrl.replacingOccurrences(of: "/", with: "$")
        let filePath = documentPath.appendingPathComponent(fileName)
        let req = URLRequest(url: filePath)
        self.iconWebView?.load(req)
    }
    
    func loadAudioAnim() {
        
        let bundle = Bundle(for: type(of: self))
        
        if let url = bundle.url(forResource: audioUrl, withExtension: "html") {
            self.audioWebView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
    func changeToRest() {
        self.loadingLayer?.removeFromSuperlayer()
        self.loadingView?.removeFromSuperview()
        
        self.audioWebView?.isHidden = true
    }
    
    func changeToAudioPlay() {
        self.loadingLayer?.removeFromSuperlayer()
        self.loadingView?.removeFromSuperview()
        if audioWebView == nil {
            setupAudioAnimView()
            configureAudioIconButon()
        }
        self.audioWebView?.isHidden = false
    }
    
    func changeToLoading() {
        self.loadingLayer?.removeFromSuperlayer()
        self.loadingView?.removeFromSuperview()
        
        loadingView = UIView(frame: self.iconWebView!.frame)
        loadingView?.backgroundColor = .clear
        self.iconWebView?.addSubview(loadingView!)
        
        self.loadingView?.clipsToBounds = true
        self.loadingView?.layer.cornerRadius = iconSize/2
        
        loadingLayer = CAShapeLayer()
        loadingLayer?.strokeColor = UIColor(red: 244/255, green: 243/255, blue: 238/255, alpha: 1.0).cgColor
        loadingLayer?.lineWidth = iconSize * 0.15
        loadingLayer?.fillColor = UIColor.clear.cgColor
        loadingLayer?.lineCap = .round
        
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: (self.loadingView?.bounds.width)!, height: (self.loadingView?.bounds.height)!))
        loadingLayer?.path = path.cgPath
        
        self.loadingView?.layer.addSublayer(loadingLayer!)
        
        animateStroke()
        animateRotation()
    }
    
    // MARK: - Animations
    private func animateStroke() {
        
        let startAnimation = StrokeAnimation(
            type: .start,
            beginTime: 0.0,
            fromValue: 0.75,
            toValue: 1.0,
            duration: .greatestFiniteMagnitude
        )
        
        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = .greatestFiniteMagnitude
        strokeAnimationGroup.repeatDuration = .infinity
        strokeAnimationGroup.animations = [startAnimation]
        
        loadingLayer?.add(strokeAnimationGroup, forKey: nil)
    }
    
    private func animateRotation() {
        let rotationAnimation = RotationAnimation(
            direction: .z,
            fromValue: 0,
            toValue: .greatestFiniteMagnitude,
            duration: .greatestFiniteMagnitude,
            repeatCount: .infinity
        )
        
        self.loadingView?.layer.add(rotationAnimation, forKey: nil)
    }
}

extension JinyIconView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        self.iconWebView?.backgroundColor = iconBackgroundColor
        self.audioWebView?.backgroundColor = iconBackgroundColor
    }
}

extension JinyIconView: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}

private class StrokeAnimation: CABasicAnimation {
    
    override init() {
        super.init()
    }
    
    init(type: StrokeType,
         beginTime: Double = 0.0,
         fromValue: CGFloat,
         toValue: CGFloat,
         duration: Double) {
        
        super.init()
        
        self.keyPath = type == .start ? "strokeStart" : "strokeEnd"
        
        self.beginTime = beginTime
        self.fromValue = fromValue
        self.toValue = toValue
        self.duration = duration
        self.timingFunction = .init(name: .linear)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    enum StrokeType {
        case start
        case end
    }
}

private class RotationAnimation: CABasicAnimation {
    
    enum Direction: String {
        case x, y, z
    }
    
    override init() {
        super.init()
    }
    
    public init(
        direction: Direction,
        fromValue: CGFloat,
        toValue: CGFloat,
        duration: Double,
        repeatCount: Float
    ) {
        
        super.init()
        
        self.keyPath = "transform.rotation.\(direction.rawValue)"
        
        self.fromValue = fromValue
        self.toValue = toValue
        
        self.duration = duration
        
        self.repeatCount = repeatCount
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
