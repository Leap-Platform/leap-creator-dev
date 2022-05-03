//
//  LeapNativeViewFinder.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 03/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapNativeViewFinder {
    
    let hierarchy:[String:LeapViewProperties]
    
    init(with currentHierarchy:[String:LeapViewProperties]) {
        hierarchy = currentHierarchy
    }
    
    public func isIdentifierValid(_ identifer:LeapNativeIdentifier) -> Bool {
        guard let _ = viewIdFor(identifer) else { return false }
        return true
    }
    
    public func viewIdFor(_ nativeIdentifier:LeapNativeIdentifier) -> String? {
        var viewId:String? = nil
        hierarchy.forEach { tempViewId, viewProps in
            if viewId == nil {
                if isNativeIdentifier(nativeIdentifier, matching: viewProps) { viewId = tempViewId }
            }
        }
        return viewId
    }
    
    private func isNativeIdentifier(_ nativeIdentifier:LeapNativeIdentifier, matching viewProps:LeapViewProperties) -> Bool {
        if let currentVC = UIApplication.getCurrentVC() {
            let currentVCString = String(describing: type(of: currentVC.self))
            let identifierController = nativeIdentifier.controller
            if currentVCString != identifierController { return false }
        } else if let _ = nativeIdentifier.controller { return false }
        guard let idParams = nativeIdentifier.idParameters else { return true }
        guard isIdParams(idParams, matchingProps: viewProps) else { return false }
        if let identifierViewProps = nativeIdentifier.viewProps {
            guard isIdentifierViewProps(identifierViewProps, matching: viewProps) else { return false }
        }
        if nativeIdentifier.isAnchorSameAsTarget ?? true { return true }
        guard let relation = nativeIdentifier.relationToTarget else { return true }
        guard let _ = getViewIdFromRelation(relation, forViewProps: viewProps) else { return false }
        return true
    }
    
    private func isIdParams(_ idParams:LeapNativeParameters, matchingProps props:LeapViewProperties) -> Bool {
        guard idParams.accId == props.accId,
              idParams.accLabel == props.accLabel,
              idParams.tag == props.tag,
              idParams.className == props.className,
              (idParams.text[constant_ang] as? String) == props.text else { return false }
        return true
    }
    
    private func isIdentifierViewProps(_ identifierProps:LeapNativeViewProps, matching viewProps:LeapViewProperties) -> Bool {
        guard identifierProps.isFocused == viewProps.isFocused,
              identifierProps.isEnabled == viewProps.isEnabled,
              identifierProps.isSelected == viewProps.isSelected,
              identifierProps.className == viewProps.className,
              identifierProps.text[constant_ang] as? String == viewProps.text else { return false }
        return true
    }
    
    private func getViewIdFromRelation(_ relations:[String], forViewProps viewProps:LeapViewProperties) -> String? {
        var finalViewProps = viewProps
        for relation in relations {
            if relation == "P" {
                guard let parentId = finalViewProps.parent, let newViewProps = hierarchy[parentId] else { return nil }
                finalViewProps = newViewProps
            } else if relation.hasPrefix("C") {
                guard let index = Int(relation.split(separator: "C")[0]) else { return nil }
                var tempProps:LeapViewProperties? = nil
                for childId in finalViewProps.children {
                    if let childViewProps = hierarchy[childId], childViewProps.nodeIndex == index {
                        tempProps = childViewProps
                        break
                    }
                }
                guard let finalTempProps = tempProps else { return nil }
                finalViewProps = finalTempProps
            } else if relation.hasPrefix("S") {
                guard let index = Int(relation.split(separator: "S")[0]) else { return nil }
                var tempProps:LeapViewProperties? = nil
                guard let parentId = finalViewProps.parent,
                      let parentProps = hierarchy[parentId] else { return nil }
                for childId in parentProps.children {
                    if let childViewProps = hierarchy[childId], childViewProps.nodeIndex == index {
                        tempProps = childViewProps
                        break
                    }
                }
                guard let finalTempProps = tempProps else { return nil }
                finalViewProps = finalTempProps
            } else { return nil }
        }
        return finalViewProps.viewId
    }
    
    
}
