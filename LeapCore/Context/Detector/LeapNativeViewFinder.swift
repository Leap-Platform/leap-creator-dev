//
//  LeapNativeViewFinder.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

/// LeapNativeViewFinder helps to see if a native identifier is present in provided hierarchy
class LeapNativeViewFinder {
    
    /// Hierarchy to check against as flat map
    let hierarchy:[String:LeapViewProperties]
    
    /// Intialization method
    /// - Parameter currentHierarchy: Hierarchy to check against
    init(with currentHierarchy:[String:LeapViewProperties]) {
        hierarchy = currentHierarchy
    }
    
    /// Returns if the identifier is valid in the hierarchy
    /// - Parameter identifier: Identifier to check
    /// - Returns: True if identifier is valid; else false
    public func isIdentifierValid(_ identifier:LeapNativeIdentifier) -> Bool {
        guard let _ = viewIdFor(identifier) else { return false }
        return true
    }
    
    /// Returns viewId of the native identifier is present
    /// - Parameter nativeIdentifier: Identifier to check for
    /// - Returns: ViewId of the native identifier if present; else nil
    public func viewIdFor(_ nativeIdentifier:LeapNativeIdentifier) -> String? {
        var viewId:String? = nil
        hierarchy.forEach { tempViewId, viewProps in
            if viewId == nil {
                if isNativeIdentifier(nativeIdentifier, anchorFor: viewProps) {
                    if nativeIdentifier.isAnchorSameAsTarget ?? true { viewId = tempViewId }
                    else if let targetViewId = self.targetViewId(for: nativeIdentifier, from: tempViewId) {
                        viewId = targetViewId
                    }
                }
            }
        }
        return viewId
    }
    
    /// Checks if the native identifier properties are matching against a particular view in the hierarchy
    /// - Parameters:
    ///   - nativeIdentifier: Identifier to check for
    ///   - viewProps: View properties of the view to check against
    /// - Returns: True if the view matches the identifier; else false
    private func isNativeIdentifier(_ nativeIdentifier:LeapNativeIdentifier, anchorFor viewProps:LeapViewProperties) -> Bool {
        if let currentVC = viewProps.controller {
            let identifierController = nativeIdentifier.controller
            if currentVC != identifierController { return false }
        } else if let _ = nativeIdentifier.controller { return false }
        guard let idParams = nativeIdentifier.idParameters else { return true }
        guard isIdParams(idParams, matchingProps: viewProps) else { return false }
        if let identifierViewProps = nativeIdentifier.viewProps {
            guard isIdentifierViewProps(identifierViewProps, matching: viewProps) else { return false }
        }
        return true
    }
    
    /// Get target views id from anchor view using relation
    /// - Parameters:
    ///   - nativeIdentifier: The native identifier containing information about the relation
    ///   - anchorViewId: The anchor view id from the hierarchy to start search for target view
    /// - Returns: The target view id if found; else nil
    private func targetViewId(for nativeIdentifier:LeapNativeIdentifier, from anchorViewId:String) -> String? {
        guard let relation = nativeIdentifier.relationToTarget,
              let anchorViewProps = hierarchy[anchorViewId] else { return nil }
        guard let targetViewPropsId = getViewIdFromRelation(relation, forViewProps: anchorViewProps),
              let targetViewProps = hierarchy[targetViewPropsId] else { return nil }
        guard let targetIdParam = nativeIdentifier.target?.idParameters else { return targetViewPropsId }
        guard isIdParams(targetIdParam, matchingProps: targetViewProps) else { return nil }
        guard let targetMatchingProps = nativeIdentifier.target?.viewProps else { return targetViewPropsId }
        guard isIdentifierViewProps(targetMatchingProps, matching: targetViewProps) else { return nil }
        return targetViewPropsId
    }
    
    /// Checks if the parameters provided for the native identifier is matching the properties of the view
    /// - Parameters:
    ///   - idParams: LeapNativeParameters of the native identifier to check for
    ///   - props: View props of the view to check to check against
    /// - Returns: True if is matching; else false
    private func isIdParams(_ idParams:LeapNativeParameters, matchingProps props:LeapViewProperties) -> Bool {
        if let accId = idParams.accId { if accId != props.accId { return false } }
        if let accLabel = idParams.accLabel { if accLabel != props.accLabel { return false } }
        if let tag = idParams.tag { if tag != props.tag { return false } }
        if let className = idParams.className { if className != props.className { return false } }
        if let text = idParams.text[constant_ang] as? String { if text != props.text { return false } }
        return true
    }
    
    /// Checks if the propeties provided for the native identifier is matching the properties of the view
    /// - Parameters:
    ///   - identifierProps: LeapNativeViewProps of the native identifier to check for
    ///   - viewProps: View properties of the view to check against
    /// - Returns: True if matching; else false
    private func isIdentifierViewProps(_ identifierProps:LeapNativeViewProps, matching viewProps:LeapViewProperties) -> Bool {
        if let isFocused = identifierProps.isChecked { if isFocused != viewProps.isFocused { return false} }
        if let isEnabled = identifierProps.isEnabled { if isEnabled != viewProps.isEnabled { return false} }
        if let isSelected = identifierProps.isSelected { if isSelected != viewProps.isSelected { return false} }
        if let className = identifierProps.className { if className != viewProps.className { return false} }
        if let text = identifierProps.text[constant_ang] as? String { if text != viewProps.text { return false} }
        return true
    }
    
    /// Get the view id of view if the target and anchor are not same, using relation
    /// - Parameters:
    ///   - relations: Array of string representing relation
    ///   - viewProps: View Properties of anchor view
    /// - Returns: View id of target element if found; else nil
    private func getViewIdFromRelation(_ relations:[String], forViewProps viewProps:LeapViewProperties) -> String? {
        var finalViewProps = viewProps
        for relation in relations {
            if relation == "P" {
                guard let tempProps = getParentProps(finalViewProps) else { return nil }
                finalViewProps = tempProps
            } else if relation.hasPrefix("C") {
                guard let index = Int(relation.split(separator: "C")[0]),
                      let tempProps = getChildProp(of: finalViewProps, at: index) else { return nil }
                finalViewProps = tempProps
            } else if relation.hasPrefix("S") {
                guard let index = Int(relation.split(separator: "S")[0]),
                      let tempProps = getSiblingProp(of: finalViewProps, at: index) else { return nil }
                finalViewProps = tempProps
            } else { return nil }
        }
        return finalViewProps.viewId
    }
    
    /// Gets the parent view id of current view
    /// - Parameter viewProps: View Properties of view to get parent of
    /// - Returns: ViewId if parent is found; else nil
    private func getParentProps(_ viewProps:LeapViewProperties) -> LeapViewProperties? {
        guard let parentId = viewProps.parent, let parentProps = hierarchy[parentId] else { return nil }
        return parentProps
    }
    
    /// Gets the child view id of current view based on index
    /// - Parameters:
    ///   - viewProps: View Properties of view to get child of
    ///   - index: Index of child
    /// - Returns: ViewId if child is found; else nil
    private func getChildProp(of viewProps:LeapViewProperties, at index:Int) -> LeapViewProperties? {
        for childId in viewProps.children {
            if let childProps = hierarchy[childId], childProps.nodeIndex == index { return childProps }
        }
        return nil
    }
    
    /// Gets the sibling view id of current view based on index
    /// - Parameters:
    ///   - viewProps: View Properties of view to get sibling of
    ///   - index: Index of sibling
    /// - Returns: ViewId if sibling is found; else nil
    private func getSiblingProp(of viewProps:LeapViewProperties, at index:Int) -> LeapViewProperties? {
        guard let parentProps = getParentProps(viewProps),
              let childProps = getChildProp(of: parentProps, at: index) else { return nil }
        return childProps
    }
    
    
}
