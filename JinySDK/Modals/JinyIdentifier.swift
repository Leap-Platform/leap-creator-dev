//
//  JinyIdentifier.swift
//  JinySDK
//
//  Created by Aravind GS on 28/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit


class JinyWebIdentifier {
    
    let tagName:String
    let attributes:Dictionary<String,Dictionary<String,String>>?
    let innerHtml:Dictionary<String,String>?
    let innerText:Dictionary<String,String>?
    let value:Dictionary<String,String>?
    let url:String?
    let index:Int
    
    init(withDict webDict:Dictionary<String,Any>) {
        tagName = webDict["tag_name"] as? String ?? ""
        attributes = webDict["attributes"] as? Dictionary<String,Dictionary<String,String>>
        innerHtml = webDict["inner_html"] as? Dictionary<String,String>
        innerText = webDict["inner_text"] as? Dictionary<String,String>
        value = webDict["value"] as? Dictionary<String,String>
        url = webDict["url"] as? String
        index = webDict["index"] as? Int ?? 0
    }
    
}

class JinyNativeParameters {
    
    var accId:String?
    var accLabel:String?
    var tag:Int?
    var className:String?
    var text:Dictionary<String,String>?
    var placeholder:Dictionary<String,String>?
    var textRegex:String?
    
    init(withDict paramsDict:Dictionary<String,Any>) {
        accId = paramsDict["ACC_ID"] as? String
        accLabel = paramsDict["ACC_LABEL"] as? String
        tag = paramsDict["TAG"] as? Int
        className = paramsDict["class_name"] as? String
        text = paramsDict["text"] as? Dictionary<String,String>
        placeholder = paramsDict["placeholder"] as? Dictionary<String,String>
        textRegex = paramsDict["text_regex"] as? String
    }
    
}

class JinyNativeViewProps {
    
    var isSelected:Bool?
    var isEnabled:Bool?
    var isFocused:Bool?
    var isChecked:Bool?
    var textRegex:String?
    var bgColor:UIColor?
    var className:String?
    var text:Dictionary<String,String>?
    
    init(withDict propsDict:Dictionary<String,Any>) {
        
        isSelected = propsDict["is_selected"] as? Bool
        isEnabled = propsDict["is_enabled"] as? Bool
        isFocused = propsDict["is_focused"] as? Bool
        isChecked = propsDict["is_checked"] as? Bool
        textRegex = propsDict["text_regex"] as? String
        
        className = propsDict["class_name"] as? String
        text = propsDict["text"] as? Dictionary<String,String>
        
    }
    
}

class JinyNativeElement {
    
    var idParameters:JinyNativeParameters?
    var viewProps:JinyNativeViewProps?

    init(withDict elementDict:Dictionary<String,Any>) {
        
        if let paramsDict = elementDict["id_params"] as? Dictionary<String,Any> {
            idParameters = JinyNativeParameters(withDict: paramsDict)
        }
        
        if let propsDict = elementDict["view_props"] as? Dictionary<String,Any> {
            viewProps = JinyNativeViewProps(withDict: propsDict)
        }
    }
    
}

class JinyNativeIdentifier:JinyNativeElement {
    
    var controller:String?
    var nesting:String?
    var isAnchorSameAsTarget:Bool?
    var relationToTarget:Array<String>?
    var target:JinyNativeElement?
    
    override init(withDict nativeDict:Dictionary<String,Any>) {
        controller = nativeDict["controller"] as? String
        nesting = nativeDict["nesting"] as? String
        isAnchorSameAsTarget = nativeDict["is_anchor_same_as_target"] as? Bool ?? false
        relationToTarget = nativeDict["relation_to_target"] as? Array<String>
        if let targetDict = nativeDict["target"] as? Dictionary<String,Any> {
            target = JinyNativeElement(withDict: targetDict)
        }
        super.init(withDict: nativeDict)
    }
    
}
