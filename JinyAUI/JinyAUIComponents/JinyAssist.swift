//
//  JinyAssist.swift
//  JinyDemo
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

// The type that has methods which is used by the developer when certain action gets called.
public protocol JinyAssistDelegate: class {
    
    /// going to present the AUIComponent.
    func willPresentAssist()
    
    /// AUIComponent is successfully presented.
    func didPresentAssist()
    
    /// failed to present AUIComponent
    func failedToPresentAssist()
    
    /// AUIComponent is successfully dismissed.
    func didDismissAssist()
    
    /// A webview action when user interacts and the callback dictionary is passed as a param.
    func didSendAction(dict: Dictionary<String, Any>)
    
    /// This method is called when the first set of animation exits, usually after 180ms.
    func didExitAnimation()
    
    /// This method is called when the jinyIcon is tapped.
    func didTapAssociatedJinyIcon()
}

// The type that has properties and methods which is used by each AUIComponent when necessary
public protocol JinyAssist {
    
    var delegate: JinyAssistDelegate? { get set }
    
    /// style for the AUIComponent
    var style: Style? { get set }
    
    /// required AssistInfo depending on the AUIComponent
    var assistInfo: AssistInfo? { get set }
    
    /// call the method internally to apply style to the AUIComponent
    /// - Parameters:
    ///   - style: A property of the type Style.
    func applyStyle(style: Style)
    
    /// - Parameters:
    ///   - htmlUrl: A url string to load html content.
    ///   - appLocale: Another value.
    ///   - contentFileUriMap: Another value.
    func setContent(htmlUrl: String, appLocale: String, contentFileUriMap: Dictionary<String, String>?)
    
    /// updates layout of the AUIComponent
    /// - Parameters:
    ///   - alignment: Alignment of the layout.
    ///   - anchorBounds: Another value.
    func updateLayout(alignment: String, anchorBounds: CGRect?)
    
    /// call when there is a callback from webview
    func show()
    
    /// performs animation to the AUIComponent
    /// - Parameters:
    ///   - animation: Enter Animation Type.
    func performEnterAnimation(animation: String)
    
    /// hides the AUIComponent
    /// - Parameters:
    ///   - withAnim: value to check whether to have animation or without animation
    func hide(withAnim: Bool)
    
    /// performs exit animation after the enter animation
    /// - Parameters:
    ///   - animation: Exit Animation Type.
    func performExitAnimation(animation: String)
    
    /// removes the AUIComponent
    func remove()
}
