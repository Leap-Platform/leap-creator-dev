//
//  Encoder.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 10/08/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}
