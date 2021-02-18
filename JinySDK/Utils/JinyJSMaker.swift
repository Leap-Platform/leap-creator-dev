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
   
    class func calculateBoundsScript(_ id:JinyWebIdentifier) -> String {
        let baseJs = generateBasicElementScript(id:id)
        let rect = baseJs + ".getBoundingClientRect()"
        let x = rect + ".x"
        let y = rect + ".y"
        let width = rect + ".width"
        let height = rect + ".height"
        let finalQuery = "([\(x),\(y),\(width),\(height)]).toString()"
        return finalQuery
    }
    
    class func generateNullCheckScript(identifier:JinyWebIdentifier) -> String {
        let elementScript = generateBasicElementScript(id: identifier)
        return "(" + elementScript + " != null).toString()"
    }

    class func generateAttributeCheckScript(webIdentifier:JinyWebIdentifier) -> String? {
        let elementScript = generateBasicElementScript(id: webIdentifier)
        var overallScript = "("
        if let innerTextValue = webIdentifier.innerText?["ang"] {
            overallScript += elementScript + ".innerText === \"\(innerTextValue)\" && "
        }
        if let innerHTMLValue = webIdentifier.innerHtml?["ang"] {
            overallScript += elementScript + ".innerHTML === \"\(innerHTMLValue)\" && "
        }
        if let valueValue = webIdentifier.value?["ang"] {
            overallScript += elementScript + ".value === \"\(valueValue)\" && "
        }
        if overallScript.suffix(4) == " && " { overallScript.removeLast(4) }
        else { return nil }
        
        overallScript += ").toString()"
        return overallScript
    }

    class func generateBasicElementScript(id:JinyWebIdentifier) -> String {
        var baseJs = "document.querySelectorAll('"
        baseJs += id.tagName
        
        if let attributes = id.attributes, let localeAttrs = attributes["ang"] {
            localeAttrs.forEach { (attr, value) in
                baseJs += "[\(attr)=\"\(value)\"]"
            }
        }
        baseJs += "')[\(id.index)]"
        return baseJs
    }
    
}
