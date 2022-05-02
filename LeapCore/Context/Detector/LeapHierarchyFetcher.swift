//
//  LeapHierarchyFetcher.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 29/04/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class LeapHierarchyFetcher {
    
    func fetchHierarchy() -> [String : LeapViewProperties] {
        var hierarchy:[String : LeapViewProperties] = [:]
        let allWindows = UIApplication.shared.windows
        for window in allWindows {
            var props = generateLeapViewProperties(window, nil, allWindows.firstIndex(of: window) ?? 0)
            hierarchy[props.viewId] = props
        }
        return hierarchy
    }
    
    func getChildrenLeapViewProperties(_ viewProperties:LeapViewProperties) -> [String:LeapViewProperties] {
        var props:[String : LeapViewProperties] = [:]
        guard let view = viewProperties.weakView else { return [:] }
        for subview in view.subviews {
            let subviewProps = generateLeapViewProperties(subview, viewProperties.viewId, view.subviews.firstIndex(of: subview)!)
            props[subviewProps.viewId] = subviewProps
            viewProperties.children.append(subviewProps.viewId)
            let childProps = getChildrenLeapViewProperties(subviewProps)
            props.merge(childProps) { originalDictProps, newDictProps in
                return originalDictProps
            }
        }
        return props
    }
    
    func generateLeapViewProperties(_ view: UIView, _ parentUUID:String?, _ index:Int = 0) -> LeapViewProperties {
        return LeapViewProperties(with: view, uuid: UUID().uuidString, parentUUID: parentUUID, index: index)
    }
    
}
