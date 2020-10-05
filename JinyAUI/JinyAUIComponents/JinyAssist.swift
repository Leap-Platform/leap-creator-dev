//
//  JinyAssist.swift
//  AUIComponents
//
//  Created by mac on 01/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

// The type that has properties and methods which is used by each AUIComponent when necessary
public protocol JinyAssist {
    
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
