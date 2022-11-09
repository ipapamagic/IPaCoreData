//
//  IPaSortDescriptorsProvider.swift
//  IPaCoreData
//
//  Created by IPa Chen on 2022/10/3.
//

import UIKit

public protocol IPaSortDescriptorsProvider {
    var sortDescriptor:NSSortDescriptor {get}
}

extension NSSortDescriptor:IPaSortDescriptorsProvider {
    public var sortDescriptor: NSSortDescriptor {
        return self
    }
}

extension String:IPaSortDescriptorsProvider {
    public var sortDescriptor:NSSortDescriptor {
        var desc = self.hasSuffix("-")
        var key = self.trimmingCharacters(in: CharacterSet(arrayLiteral: "+","-"))
        return NSSortDescriptor(key: key, ascending: !desc)
    }
}
