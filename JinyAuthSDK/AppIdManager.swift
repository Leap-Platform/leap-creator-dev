//
//  AppIdManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class AppIdManager{
    
    init(appIdListener: AppIdListener, applicationcontext: UIApplication){
        
    }
}

protocol AppIdListener{
    func onIdFound()->String 
}
