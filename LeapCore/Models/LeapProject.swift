//
//  LeapProject.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 12/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

class LeapProject: LeapContext {
   
    let projectParams: LeapProjectParameters
    
    init(with dict: Dictionary<String, Any>, projectParams: LeapProjectParameters) {
        self.projectParams = projectParams
        super.init(with: dict)
    }
}
