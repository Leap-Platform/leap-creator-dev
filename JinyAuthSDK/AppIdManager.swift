//
//  AppIdManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class AppIdManager{
    
    var appStoreId: String?
    var appIdFetchListener: AppIdListener
    
    init(appIdListener: AppIdListener){
        self.appIdFetchListener = appIdListener
    }
    
    @objc func findAppStoreId()->Void{


    }
}

protocol AppIdListener{
    func onIdFound()->String 
}
