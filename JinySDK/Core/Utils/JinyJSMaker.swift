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
        var baseJs = "document.querySelectorAll('"
        baseJs += identifier.tagName
        identifier.attributes?.forEach({ (attr, value) in
            baseJs += "[\(attr)=\"\(value)\"]"
        })
        baseJs += "')[\(identifier.index)]"
        
        print (baseJs)
        
        var finalCheck = "(" + baseJs + " != null" + ")"
        
        if let innerHTML = identifier.innerHtml {
            if let localeInnerHTML = innerHTML["ang"] {
                let innerHTMLCheck = "(" + baseJs + ".innerHTML === " + "\"\(localeInnerHTML)\"" + ")"
                finalCheck += " && \(innerHTMLCheck)"
            }
        }
        
        if let innerText = identifier.innerText {
            if let localeInnerText = innerText["ang"] {
                let innerTextCheck = "(" + baseJs + ".innerText === " + "\"\(localeInnerText)\"" + ")"
                finalCheck += " && \(innerTextCheck)"
            }
        }
        
        if let value = identifier.value {
            if let localeValue = value["ang"] {
                let valueCheck = "(" + baseJs + ".value === " + "\"\(localeValue)\"" + ")"
                finalCheck += " && \(valueCheck)"
            }
        }
        
        
        return "("+finalCheck+").toString()"
    }
    
}
