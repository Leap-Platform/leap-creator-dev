//
//  JinyJSMaker.swift
//  JinySDK
//
//  Created by Aravind GS on 01/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class JinyJSMaker {
    
    class func createJSScript(for identifier:JinyWebIdentifier) -> String {
        
        let baseJs = getElementScript(identifier)
        var finalCheck = "(" + baseJs + " != null" + ")"
        
        if let innerHTML = identifier.innerHtml {
            if let localeInnerHTML = innerHTML[constant_ang] {
                let innerHTMLCheck = "(" + baseJs + ".innerHTML === " + "\"\(localeInnerHTML)\"" + ")"
                finalCheck += " && \(innerHTMLCheck)"
            }
        }
        
        if let innerText = identifier.innerText {
            if let localeInnerText = innerText[constant_ang] {
                let innerTextCheck = "(" + baseJs + ".innerText === " + "\"\(localeInnerText)\"" + ")"
                finalCheck += " && \(innerTextCheck)"
            }
        }
        
        if let value = identifier.value {
            if let localeValue = value[constant_ang] {
                let valueCheck = "(" + baseJs + ".value === " + "\"\(localeValue)\"" + ")"
                finalCheck += " && \(valueCheck)"
            }
        }
        
        
        return "("+finalCheck+").toString()"
    }
    
    class func createAttributeCheckScript(for identifier:JinyWebIdentifier) -> String? {
        
        var attributeScript = ""
        let querySelector = getElementScript(identifier)
        if let innerHTML = identifier.innerHtml {
            if let localeInnerHTML = innerHTML[constant_ang] {
                let innerHTMLCheck = "(" + querySelector + ".innerHTML === " + "\"\(localeInnerHTML)\"" + ") && "
                attributeScript += innerHTMLCheck
            }
        }
        
        if let innerText = identifier.innerText {
            if let localeInnerText = innerText[constant_ang] {
                let innerTextCheck = "(" + querySelector + ".innerText === " + "\"\(localeInnerText)\"" + ") && "
                attributeScript += innerTextCheck
            }
        }
        
        if let value = identifier.value {
            if let localeValue = value[constant_ang] {
                let valueCheck = "(" + querySelector + ".value === " + "\"\(localeValue)\"" + ") && "
                attributeScript += valueCheck
            }
        }
        attributeScript = String(attributeScript.dropLast(4))
        if attributeScript == "" { return nil }
        attributeScript = "(" + attributeScript + ")"
        return attributeScript
        
    }
    
    class func calculateBoundsScript(_ id:JinyWebIdentifier) -> String {
        let baseJs = getElementScript(id)
        let rect = baseJs + ".getBoundingClientRect()"
        let x = rect + ".x"
        let y = rect + ".y"
        let width = rect + ".width"
        let height = rect + ".height"
        let finalQuery = "([\(x),\(y),\(width),\(height)]).toString()"
        return finalQuery
    }
    
    class func getElementScript(_ id:JinyWebIdentifier) -> String {
        var baseJs = "document.querySelectorAll('"
        baseJs += id.tagName
        
        if let attributes = id.attributes, let localeAttrs = attributes[constant_ang] {
            localeAttrs.forEach { (attr, value) in
                baseJs += "[\(attr)=\"\(value)\"]"
            }
        }
        
        baseJs += "')[\(id.index)]"
        return baseJs
    }
    
}
