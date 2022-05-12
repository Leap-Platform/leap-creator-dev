//
//  LeapTestHierarchyGenerator.swift
//  LeapCoreSDKTests
//
//  Created by Aravind GS on 08/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
@testable import LeapCoreSDK
import UIKit

class LeapTestHierarchyGenerator {
    
    let controllerName = "HomeViewController"
    let parentUUID = "8C3C0DA1-D7E7-41F5-AE9B-7FE0A4DB1F5B"
    
    func getModelHierarchy() -> [String:LeapViewProperties] {
        var hierarchy:[String:LeapViewProperties] = [:]
        let parentViewProps = getParentView()
        hierarchy[parentUUID] = parentViewProps
        hierarchy[parentViewProps.children[0]] = getSourceButton(parentViewProps.children[0], 0)
        hierarchy[parentViewProps.children[1]] = getDestinationButton(parentViewProps.children[1], 1)
        hierarchy[parentViewProps.children[2]] = getDateTextField(parentViewProps.children[2], 2)
        hierarchy[parentViewProps.children[3]] = getSearchButton(parentViewProps.children[3], 3)
        hierarchy[parentViewProps.children[4]] = getFromLabel(parentViewProps.children[4], 4)
        hierarchy[parentViewProps.children[5]] = getToLabel(parentViewProps.children[5], 5)
        hierarchy[parentViewProps.children[6]] = getBookHoteLabel(parentViewProps.children[6], 6)
        hierarchy[parentViewProps.children[7]] = getClickHereButton(parentViewProps.children[7], 7)
        hierarchy[parentViewProps.children[8]] = getPassengerNameLabel(parentViewProps.children[8], 8)
        hierarchy[parentViewProps.children[9]] = getPassengerNameTextField(parentViewProps.children[9], 9)
        hierarchy[parentViewProps.children[10]] = getPassengetAgeLabel(parentViewProps.children[10], 10)
        hierarchy[parentViewProps.children[11]] = getPassengerAgeTextField(parentViewProps.children[11], 11)
        return hierarchy
    }
    
    func getParentView() -> LeapViewProperties {
        let parentProps = LeapViewProperties(with: UIView(), uuid: parentUUID, parentUUID: nil, index: 0, controllerName: controllerName)
        parentProps.children = [
            "28E7FED4-C7B6-40FB-9CA1-9F763D936D3C",
            "2E04004D-9BBA-4FD4-BC7B-E617E21B62F1",
            "E353EDB2-016F-4F72-8293-4D06A4F8A836",
            "D098ECD3-785B-49D6-80DE-4095C4AD89D3",
            "9C130CF0-D25C-49F9-90B3-CB96A37C9928",
            "82D0ECA4-927D-4618-9316-0BD43A149E80",
            "54A75DA7-0A07-401B-9AC6-F4656DFB2F6E",
            "22987152-BDF1-4621-9C46-899BB79476B6",
            "B134A88E-FF3B-4B16-8765-2BC63AD3FD35",
            "19C1A0AA-D779-4B65-8FDE-44E36D8D7685",
            "A93D320E-08A5-4B4C-9CB4-10ADCB61DDF0",
            "218FEF67-F96C-4B75-8362-EB68A3FB914D",
        ]
        return parentProps
    }
    
    func getSourceButton(_ id:String,_ index:Int) -> LeapViewProperties {
        let source = LeapViewProperties(with: UIButton(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        source.accId = "source"
        source.text = "Enter Source"
        return source
    }
    
    func getDestinationButton(_ id:String,_ index:Int) -> LeapViewProperties {
        let destination = LeapViewProperties(with: UIButton(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        destination.accId = "destination"
        destination.text = "Enter Destination"
        return destination
    }
    
    func getDateTextField(_ id:String,_ index:Int) -> LeapViewProperties {
        let tfProps = LeapViewProperties(with: UITextField(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        tfProps.accId = "date"
        return tfProps
    }
    
    func getSearchButton(_ id:String,_ index:Int) -> LeapViewProperties {
        let buttonProps = LeapViewProperties(with: UIButton(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        buttonProps.accLabel = "search"
        buttonProps.text = "Search"
        return buttonProps
    }
    
    func getFromLabel(_ id:String,_ index:Int) -> LeapViewProperties {
        let labelProps = LeapViewProperties(with: UILabel(), uuid: id, parentUUID: parentUUID, index: index, controllerName: "HomeViewController")
        labelProps.text = "From:"
        labelProps.accId = "from"
        return labelProps
    }
    
    func getToLabel(_ id:String,_ index:Int) -> LeapViewProperties {
        let labelProps = LeapViewProperties(with: UILabel(), uuid: id, parentUUID: parentUUID, index: index, controllerName: "HomeViewController")
        labelProps.text = "To:"
        labelProps.accId = "to"
        return labelProps
    }
    
    func getBookHoteLabel(_ id:String,_ index:Int) -> LeapViewProperties {
        let labelProps = LeapViewProperties(with: UILabel(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        labelProps.text = "To Book Hotel "
        return labelProps
    }
    
    func getClickHereButton(_ id:String,_ index:Int) -> LeapViewProperties {
        let buttonProps = LeapViewProperties(with: UIButton(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        buttonProps.text = "Click Here"
        return buttonProps
    }
    
    func getPassengerNameLabel(_ id:String,_ index:Int) -> LeapViewProperties {
        let labelProps = LeapViewProperties(with: UILabel(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        labelProps.text = "Passenger Name:"
        return labelProps
    }
    
    func getPassengerNameTextField(_ id:String,_ index:Int) -> LeapViewProperties {
        let tfProps = LeapViewProperties(with: UITextField(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        return tfProps
    }
    
    func getPassengetAgeLabel(_ id:String,_ index:Int) -> LeapViewProperties {
        let labelProps = LeapViewProperties(with: UILabel(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        labelProps.text = "Age :"
        return labelProps
    }
    
    func getPassengerAgeTextField(_ id:String,_ index:Int) -> LeapViewProperties {
        let tfProps = LeapViewProperties(with: UITextField(), uuid: id, parentUUID: parentUUID, index: index, controllerName: controllerName)
        return tfProps
    }
    
    
}
