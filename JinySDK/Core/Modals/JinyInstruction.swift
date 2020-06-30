//
//  JinyInstruction.swift
//  JinySDK
//
//  Created by Aravind GS on 29/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyInstruction {
    
    var soundName:String?
    var pointer:Dictionary<String,Any>?
    
    init(withDict instructionDict:Dictionary<String,Any>) {
        soundName = instructionDict["sound_name"] as? String
        pointer = instructionDict["pointer"] as? Dictionary<String,Any>
    }
    
}
