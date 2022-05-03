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
        for (index, window) in allWindows.enumerated() {
            let windowProps = generateLeapViewProperties(window, nil, index)
            let windowHierachy = getChildrenHierachy(windowProps)
            hierarchy.merge(windowHierachy) { originalProps, _ in
                return originalProps
            }
        }
        return hierarchy
    }
    
    private func getChildrenHierachy(_ viewProperties:LeapViewProperties) -> [String:LeapViewProperties] {
        let viewId = viewProperties.viewId
        var hierarchy:[String : LeapViewProperties] = [viewId : viewProperties]
        guard let view = viewProperties.weakView else { return [:] }
        for subview in validSubviewsFor(view) {
            let viewIndex = view.subviews.firstIndex(of: subview)!
            let subviewProps = generateLeapViewProperties(subview, viewId, viewIndex)
            hierarchy[viewId]?.children.append(subviewProps.viewId)
            let subviewHierarchy = getChildrenHierachy(subviewProps)
            hierarchy.merge(subviewHierarchy) { originalProps, _ in
                return originalProps
            }
        }
        return hierarchy
    }
    
    private func validSubviewsFor(_ view:UIView) -> [UIView] {
        let filteredSubviews = view.subviews.filter{ !$0.isHidden && ($0.alpha > 0)  && !String(describing: type(of: $0)).contains("Leap") }
        let filteredVisibleSubviews = visibleChildrenFor(filteredSubviews)
        return filteredVisibleSubviews
    }
    
    private func visibleChildrenFor(_ views: Array<UIView>) -> Array<UIView> {
        var visibleViews:Array<UIView> = views
        for coveringView in views.reversed() {
            if !visibleViews.contains(coveringView) { continue }
            let index = views.firstIndex(of: coveringView)
            if index == nil || index == 0 { continue }
            let elderSiblings = views[0..<index!]
            let elderSiblingsHiddenByCoveringView = elderSiblings.filter { !visibleViews.contains($0) || coveringView.frame.contains($0.frame) }
            visibleViews = visibleViews.filter { !elderSiblingsHiddenByCoveringView.contains($0) }
        }
        return visibleViews
    }
    
    private func generateLeapViewProperties(_ view: UIView, _ parentUUID:String?, _ index:Int) -> LeapViewProperties {
        return LeapViewProperties(with: view, uuid: UUID().uuidString, parentUUID: parentUUID, index: index)
    }
    
}
