//
//  JinyPageManager.swift
//  JinySDK
//
//  Created by Aravind GS on 27/01/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

protocol JinyPageManagerDelegate:NSObjectProtocol {
    
}

class JinyPageManager {
 
    private weak var delegate:JinyPageManagerDelegate?
    private var currentPage:JinyPage?
    
    init(_ pageDelegate:JinyPageManagerDelegate) {
        delegate = pageDelegate
    }
    
    func setCurrentPage(_ page:JinyPage?) {
        guard let identifiedPage = page else {
            currentPage = nil
            return
        }
        currentPage = identifiedPage.copy()
    }
    
    func getCurrentPage() -> JinyPage? {
        return currentPage
    }
    
}
