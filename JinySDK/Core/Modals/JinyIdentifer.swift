//
//  JinyIdentifier.swift
//  JinySDK
//
//  Created by Aravind GS on 15/04/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyIdentifier {
    let searchString:String
    let pointerType:JinyPointerType
    let highlightClickable:Bool
    
    init(withDict dict:Dictionary<String,Any>) {
        searchString = dict["search_string"] as? String ?? ""
        highlightClickable = dict["highlight_clickable"] as? Bool ?? false
        switch dict["pointer_type"] as? String {
        case "NORMAL":
            pointerType = . Normal
        case "NEGATIVE_UI":
            pointerType = .NegativeUI
        default:
            pointerType = .None
        }
    }
}

class JinyNativeIdentifer: JinyIdentifier {
    
    let searchType:JinySearchType
    var siblingInfo:String?
    var childInfo:Array<String>
    var nesting:String?
    var recyclerInfo:String?
    var pageId:Int?
    var matches:Dictionary<String,Any> = [:]
    var scrollIdenfier:String?
    var autoScroll:Bool
    
    override init(withDict dict: Dictionary<String, Any>) {
        
        switch dict["search_type"] as? String{
        case "ACCESSIBILITY_IDENTIFIER":
            searchType = .AccID
        case "ACCESSIBILITY_LABEL":
            searchType = .AccLabel
        case "TAG":
            searchType = .Tag 
        default:
            searchType = .None
        }
        siblingInfo = dict["sibling_info"] as? String
        childInfo = dict["child_info"] as? Array<String> ?? []
        nesting = dict["nesting"] as? String
        recyclerInfo = dict["recycler_info"] as? String
        pageId = dict["page_id"] as? Int ?? -1
        matches = dict["matches"] as? Dictionary<String,Any> ?? [:]
        scrollIdenfier = dict["scroll_identifier"] as? String
        autoScroll = dict["auto_scroll"] as? Bool ?? false
        super.init(withDict: dict)
        
    }
}

class JinyBranchInfo {
    let branchTitle:Dictionary<String,Any>
    var branchFlows:Array<JinyFlow> = []
    
    init(withBranchInfo dict:Dictionary<String,Any>) {
        branchTitle = dict["branch_title"] as? Dictionary<String,Any> ?? [:]
        if let branchFlowDictsArray = dict["branch_flows"] as? Array<Dictionary<String,Any>> {
            for branchFlowDict in branchFlowDictsArray {
                branchFlows.append(JinyFlow(withFlowDict: branchFlowDict))
            }
        }
    }
}
