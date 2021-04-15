//
//  LeapIdentifier.swift
//  LeapCore
//
//  Created by Aravind GS on 28/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit


class LeapWebIdentifier {
    
    let controller:String?
    let tagName:String
    let attributes:Dictionary<String,Dictionary<String,String>>?
    let innerHtml:Dictionary<String,String>?
    let innerText:Dictionary<String,String>?
    let value:Dictionary<String,String>?
    let url:String?
    let index:Int
    
    init(withDict webDict:Dictionary<String,Any>) {
        tagName = webDict[constant_tagName] as? String ?? ""
        attributes = webDict[constant_attributes] as? Dictionary<String,Dictionary<String,String>>
        innerHtml = webDict[constant_innerHtml] as? Dictionary<String,String>
        innerText = webDict[constant_innerText] as? Dictionary<String,String>
        value = webDict[constant_value] as? Dictionary<String,String>
        url = webDict[constant_url] as? String
        index = webDict[constant_index] as? Int ?? 0
        controller = webDict[constant_controller] as? String
    }
    
}

class LeapNativeParameters {
    
    var accId:String?
    var accLabel:String?
    var tag:String?
    var className:String?
    var text:Dictionary<String,String>?
    var placeholder:Dictionary<String,String>?
    var textRegex:String?
    
    init(withDict paramsDict:Dictionary<String,Any>) {
        accId = paramsDict[constant_ACC_ID] as? String
        accLabel = paramsDict[constant_ACC_LABEL] as? String
        tag = paramsDict[constant_TAG] as? String
        className = paramsDict[constant_class] as? String
        text = paramsDict[constant_text] as? Dictionary<String,String>
        placeholder = paramsDict[constant_placeholder] as? Dictionary<String,String>
        textRegex = paramsDict[constant_text_regex] as? String
    }
    
}

class LeapNativeViewProps {
    
    var isSelected:Bool?
    var isEnabled:Bool?
    var isFocused:Bool?
    var isChecked:Bool?
    var textRegex:String?
    var bgColor:UIColor?
    var className:String?
    var text:Dictionary<String,String>?
    
    init(withDict propsDict:Dictionary<String,Any>) {
        
        isSelected = propsDict[constant_isSelected] as? Bool
        isEnabled = propsDict[constant_isEnabled] as? Bool
        isFocused = propsDict[constant_isFocused] as? Bool
        isChecked = propsDict[constant_isChecked] as? Bool
        textRegex = propsDict[constant_text_regex] as? String
        className = propsDict[constant_className] as? String
        text = propsDict[constant_text] as? Dictionary<String,String>
        
    }
    
}

class LeapNativeElement {
    
    var idParameters:LeapNativeParameters?
    var viewProps:LeapNativeViewProps?

    init(withDict elementDict:Dictionary<String,Any>) {
        
        if let paramsDict = elementDict[constant_idParams] as? Dictionary<String,Any> {
            idParameters = LeapNativeParameters(withDict: paramsDict)
        }
        
        if let propsDict = elementDict[constant_viewProps] as? Dictionary<String,Any> {
            viewProps = LeapNativeViewProps(withDict: propsDict)
        }
    }
    
}

class LeapNativeIdentifier:LeapNativeElement {
    
    var controller:String?
    var nesting:String?
    var isAnchorSameAsTarget:Bool?
    var relationToTarget:Array<String>?
    var target:LeapNativeElement?
    
    override init(withDict nativeDict:Dictionary<String,Any>) {
        controller = nativeDict[constant_controller] as? String
        nesting = nativeDict[constant_nesting] as? String
        isAnchorSameAsTarget = nativeDict[constant_isAnchorSameAsTarget] as? Bool ?? true
        relationToTarget = nativeDict[constant_relationToTarget] as? Array<String>
        if let targetDict = nativeDict[constant_target] as? Dictionary<String,Any> {
            target = LeapNativeElement(withDict: targetDict)
        }
        super.init(withDict: nativeDict)
    }
    
}
