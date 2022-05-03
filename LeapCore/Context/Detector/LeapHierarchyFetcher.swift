//
//  LeapHierarchyFetcher.swift
//  LeapCoreSDK
//
//  Created by Aravind GS on 29/04/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

/// LeapHierarchyFetcher class' sole objective is to generate the hierarchy of the app as a dictionary. The dictionary wil be as [viewId : LeapViewProperties]
class LeapHierarchyFetcher {
    
    /// Fetches current hierarchy of the app as a flat map
    /// - Returns: current hierarchy
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
    
    /// Gets view properties hierarchy for a specific view. Recursive method doing depth-first-search to get all properties of a single view
    /// - Parameter viewProperties: view properties of the view for which the hieratchy is to be generated
    /// - Returns: hierarchy for specific view as a flat dictionary
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
    
    /// Gets valid subviews for a view by eliminating hidden, invisible, covered views. Also eliminates views created by Leap
    /// - Parameter view: view to get valid subviews
    /// - Returns: visible and valid subviews
    private func validSubviewsFor(_ view:UIView) -> [UIView] {
        let filteredSubviews = view.subviews.filter{ !$0.isHidden && ($0.alpha > 0)  && !String(describing: type(of: $0)).contains("Leap") }
        let filteredVisibleSubviews = visibleChildrenFor(filteredSubviews)
        return filteredVisibleSubviews
    }
    
    /// Eliminates views covered by younger sibling views
    /// - Parameter views: list of subviews
    /// - Returns: list of subviews which are visible and are not completely covered by younger siblings
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
    
    /// Generates LeapViewProperties object for a view
    /// - Parameters:
    ///   - view: view for which the LeapViewProperties object is to be generated
    ///   - parentUUID: the viewId of the parent view
    ///   - index: index of view in list of subviews of the parent
    /// - Returns: LeapViewProperties object for the view
    private func generateLeapViewProperties(_ view: UIView, _ parentUUID:String?, _ index:Int) -> LeapViewProperties {
        return LeapViewProperties(with: view, uuid: UUID().uuidString, parentUUID: parentUUID, index: index)
    }
    
}
