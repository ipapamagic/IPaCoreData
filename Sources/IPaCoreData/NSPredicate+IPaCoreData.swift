//
//  NSPredicate+IPaCoreData.swift
//  IPaCoreData
//
//  Created by IPa Chen on 2022/10/3.
//

import UIKit

extension NSPredicate:IPaPredicateProvider {
    public convenience init(_ properties:[String:Any]) {
        var format = [String]()
        var arguments = [Any]()
        for key in properties.keys {
            format.append(key + " = %@ ")
            arguments.append(properties[key]!)
        }
        self.init(format: format.joined(separator: "and "), argumentArray: arguments)
    }
    public var predicate: NSPredicate? {
        return self
    }
}


