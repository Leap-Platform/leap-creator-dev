//
//  LeapAppIdManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapAppIdManager{
    
    var appStoreId: String?
    var appIdFetchListener: LeapAppIdListener
    
    init(appIdListener: LeapAppIdListener){
        self.appIdFetchListener = appIdListener
    }
    
    @objc func findAppStoreId()->Void{


    }
}

protocol LeapAppIdListener{
    func onIdFound()->String 
}
