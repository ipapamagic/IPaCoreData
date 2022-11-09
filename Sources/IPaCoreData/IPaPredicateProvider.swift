//
//  NSPredicateProvider.swift
//  IPaCoreData
//
//  Created by IPa Chen on 2022/10/3.
//

import UIKit

public protocol IPaPredicateProvider {
    var predicate:NSPredicate? { get }
}
extension Dictionary:IPaPredicateProvider where Key == String ,Value == Any {
    public var predicate: NSPredicate? {
        if self.count == 0 {
            return nil
        }
        return NSPredicate(self)
    }
    
    
}
