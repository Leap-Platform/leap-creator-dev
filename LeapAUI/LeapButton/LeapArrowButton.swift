//
//  LeapArrowButton.swift
//  LeapAUISDK
//
//  Created by Aravind GS on 04/03/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import UIKit
import WebKit

enum LeapViewPortVisibility {
    case inViewPort
    case aboveViewPort
    case belowViewPort
}

protocol LeapArrowButtonDelegate:NSObjectProtocol {
    func arrowShown()
    func arrowHidden()
}

class LeapArrowButton: UIButton {
    
    weak var toView: UIView?
    var keyboardHeight:CGFloat = 0
    var rect: CGRect?
    weak var delegate:LeapArrowButtonDelegate?
    
    weak var inWebView: WKWebView?
    lazy var bottomConstraint: NSLayoutConstraint? = {
        let bottomConstant:CGFloat = keyboardHeight + 24
        guard let superView = self.superview else { return nil }
        return NSLayoutConstraint(item: superView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: bottomConstant)
    }()
    
    init(arrowDelegate:LeapArrowButtonDelegate) {
        delegate = arrowDelegate
        super.init(frame: .zero)
        layer.cornerRadius = 20
        layer.masksToBounds = true
        backgroundColor = .clear
        setupButton()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        
    }
    
    private override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func keyboardDidShow(_ notification:NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
        }
        updateArrowPosition()
    }
    
    @objc func keyboardDidHide(_ notification:NSNotification) {
        keyboardHeight = 0
        updateArrowPosition()
    }
    
    private func setupButton() {
        let kw = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let keywindow = kw else { return }
        keywindow.addSubview(self)
        self.setImage(UIImage.getImageFromBundle("scroll_arrow.png"), for: .normal)
        self.isHidden = true
        self.translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 40).isActive = true
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        leadingAnchor.constraint(equalTo: keywindow.leadingAnchor, constant: 24).isActive = true
        guard bottomConstraint != nil else { return }
        NSLayoutConstraint.activate([bottomConstraint!])
        addTarget(self, action: #selector(clicked), for: .touchUpInside)
    }
    
    private func updateArrowPosition() {
        UIView.animate(withDuration: 0.1) {
            self.bottomConstraint?.constant = self.keyboardHeight + 24
            self.layoutIfNeeded()
        }
    }
    
    func setView(view: UIView) {
        toView = view
        rect = nil
        inWebView = nil
        clicked()
    }
    
    func checkForView() {
        
        let visibilty = getViewVisibility()
        switch visibilty {
        case .inViewPort:
            hideArrow()
        default:
            showArrow(visibilty)
        }
    }
    
    func setRect(_ newRect: CGRect, in webView:WKWebView) {
        toView = nil
        rect = newRect
        inWebView = webView
        clicked()
    }
    
    func updateRect(newRect: CGRect) {
        if rect?.origin == newRect.origin { return }
        rect = newRect
        let visibility = getRectVisibility()
        switch visibility {
        case .inViewPort:
            hideArrow()
        default:
            showArrow(visibility)
        }
    }
    
    func noAssist() {
        self.isHidden = true
        toView = nil
        rect = nil
        inWebView = nil
    }
    
    private func showArrow(_ visibility: LeapViewPortVisibility) {
        if visibility == .aboveViewPort {
            
            self.setImage(UIImage.getImageFromBundle("scroll_arrow.png"), for: .normal)
            
        } else if visibility == .belowViewPort {
            
            self.setImage(UIImage.getImageFromBundle("scroll_arrow.png")?.getInvertedImage(), for: .normal)
        }
        guard isHidden else { return }
        self.isHidden = false
        delegate?.arrowShown()
    }
    
    private func hideArrow() {
        guard !isHidden else { return }
        self.isHidden = true
        delegate?.arrowHidden()
    }
    
    private func getRectVisibility() -> LeapViewPortVisibility {
        if isRectAboveVisibility(){ return .aboveViewPort }
        else if isRectBelowVisibility() { return .belowViewPort }
        return .inViewPort
    }
    
    private func isRectAboveVisibility() -> Bool {
        guard let tempRect = rect, let _ = inWebView else { return false }
        let majorityVisibilityPoint = tempRect.minY + (0.6 * tempRect.height)
        return majorityVisibilityPoint < 0
    }
    
    private func isRectBelowVisibility() -> Bool {
        guard let tempRect = rect, let webview = inWebView else { return false }
        let majorityVisibilityPoint = tempRect.minY + (0.4 * tempRect.height)
        if majorityVisibilityPoint > webview.frame.height { return true }
        guard keyboardHeight > 0 else { return false }
        return majorityVisibilityPoint > webview.frame.height - keyboardHeight
    }
    
    private func getViewVisibility() -> LeapViewPortVisibility {
        if isViewAboveViewPort() { return .aboveViewPort }
        else if isViewBelowViewPort() { return .belowViewPort }
        return .inViewPort
    }
    
    private func isViewAboveViewPort() -> Bool {
        let keywindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let view = toView, let kw = keywindow, let superview = view.superview else { return false }
        let viewFrameForWindow = superview.convert(view.frame, to: kw)
        let majorityPointInKeyWindowFrame = viewFrameForWindow.minY + (0.6 * viewFrameForWindow.height)
        if majorityPointInKeyWindowFrame < 0 { return true }
        let scrolls = getScrollViews()
        guard scrolls.count > 1 else { return false }
        for i in 1..<scrolls.count {
            let scroller = scrolls[i]
            let viewFrameForScroll = superview.convert(view.frame, to: scroller)
            let majorityViewPointForScroll = viewFrameForScroll.minY + (0.6 * viewFrameForScroll.height)
            if majorityViewPointForScroll < 0 { return true }
        }
        return false
    }
    
    private func isViewBelowViewPort() -> Bool {
        let keywindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let view = toView, let kw = keywindow, let superview = view.superview else { return false }
        let viewFrameForWindow = superview.convert(view.frame, to: kw)
        let majorityPointInKeyWindowFrame = viewFrameForWindow.minY + (0.4 * viewFrameForWindow.height)
        if majorityPointInKeyWindowFrame > kw.frame.height - keyboardHeight { return true }
        let scrolls = getScrollViews()
        guard scrolls.count > 1 else { return false }
        for i in 1..<scrolls.count {
            let scroll = scrolls[i]
            let viewFrameForScroll = superview.convert(view.frame, to: scroll)
            guard let scroller = scroll as? UIScrollView else { return false }
            let majorityViewPointForScroll = viewFrameForScroll.minY + (0.4 * viewFrameForScroll.height)
            if majorityViewPointForScroll > scroller.contentOffset.y + scroll.frame.height { return false }
        }
        return false
    }
    
    
    private func getScrollViews() -> Array<UIView> {
        guard var view = toView else { return [] }
        var scrollViews:Array<UIView> = [view]
        while !view.isKind(of: UIWindow.self) {
            if let scroll = view as? UIScrollView { scrollViews.append(scroll) }
            guard let superview = view.superview else { return scrollViews }
            view = superview
        }
        return scrollViews
    }
    
    private func getScrollViewsFromWebView() -> Array<UIView> {
        guard let view = inWebView else { return [] }
        var scrollViews: Array<UIView> = []
        
        func getWebScrollViews(view: UIView) {
            guard view.isKind(of: UIView.self) else { return }
            if let scroll = view as? UIScrollView { scrollViews.append(scroll) }
            for subview in view.subviews {
                getWebScrollViews(view: subview)
            }
        }
        getWebScrollViews(view: view)
        return scrollViews
    }
    
    @objc private func clicked() {
        if let _ = toView {
            let nestedScrolls = getScrollViews()
            for i in 0..<nestedScrolls.count-1 {
                let parentView = nestedScrolls[nestedScrolls.count - 1 - i]
                let childView = nestedScrolls[nestedScrolls.count - 1 - i - 1]
                if let scroller = parentView as? UIScrollView {
                    guard let superView = childView.superview else { return }
                    let childViewRectWRTParent = superView.convert(childView.frame, to: scroller)
                    scroller.scrollRectToVisible(childViewRectWRTParent, animated: true)
                }
            }
        } else if let toRect = rect, let webview = inWebView {
            let visibility = getRectVisibility()
            if visibility == .inViewPort { return }
            else if visibility == .aboveViewPort {
                let yOffset = webview.scrollView.contentOffset.y - toRect.minY + (0.5 * toRect.height) + (0.3 * webview.frame.height)
                //webview.scrollView.contentOffset = CGPoint(x: 0, y: yOffset)
            } else if visibility == .belowViewPort {
                let yOffset = webview.scrollView.contentOffset.y + toRect.minY - (0.5 * toRect.height) - (0.3 * webview.frame.height)
                //webview.scrollView.contentOffset = CGPoint(x: 0, y: yOffset)
            }
            
            let nestedScrolls = getScrollViewsFromWebView()
            
            for scroller in nestedScrolls {
                
                if let scroller = scroller as? UIScrollView {
                    
                    // for both aboveViewPort and belowViewPort.
                    var yOffset = (scroller.contentOffset.y + toRect.origin.y) - scroller.bounds.height/2
                    
                    // if toRect/target is at the bottom half of the scrollView.
                    if (scroller.contentSize.height-toRect.minY) <= (scroller.bounds.height/2) {
                        yOffset = scroller.contentSize.height - (scroller.bounds.height + scroller.contentInset.bottom)
                    }
                    
                    print("YOffset - \(yOffset)")
                    print("scrollview content height - \(scroller.contentSize.height)")
                    print("scrollview height - \(scroller.bounds.height)")
                    print("Keywindow height - \(UIApplication.shared.keyWindow!.bounds.height)")
                    print("toRect y position - \(toRect.minY)")
                    
                    scroller.setContentOffset(CGPoint(x: scroller.contentOffset.x, y: yOffset), animated: true)
                }
            }
        }
        let currentVc = UIApplication.getCurrentVC()
        guard let currentVCView = currentVc?.view else { return }
        currentVCView.endEditing(true)
    }
}
