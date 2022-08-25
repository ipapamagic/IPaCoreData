//
//  NSManagedObject+IPaCoreData.swift
//  IPaCoreData
//
//  Created by IPa Chen on 2021/12/28.
//

import CoreData
import IPaLog

extension NSFetchRequestResult where Self: NSManagedObject {
    public static var count:Int {
        let request = self.fetchRequest()
        request.includesSubentities = false
        return self.count(with: request)
    }
    @inlinable public static func create(_ properties:[String:Any]? = nil, cdManager:IPaCoreDataManager = IPaCoreDataManager.shared) -> Self {
        return cdManager.create(properties)
    }
    @inlinable public static func create(with uri:URL, manager:IPaCoreDataManager = IPaCoreDataManager.shared) -> Self? {
        return manager.create(with: uri)
    }
    @inlinable public static func fetchRequest(with predicate:NSPredicate? = nil,sortDescriptors:[NSSortDescriptor]? = nil,limit:Int = 0) -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: String(describing:self))
        request.fetchLimit = limit
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
    @inlinable public static func firstOrCreate(with properties:[String:Any]) throws -> Self {
        var format = [String]()
        var arguments = [Any]()
        for key in properties.keys {
            format.append(key + " = %@ ")
            arguments.append(properties[key]!)
        }
        let predicate = NSPredicate(format: format.joined(separator: "and "), argumentArray: arguments)
        return try self.fetchFirst(with: predicate) ?? self.create(properties)
    }
    @inlinable public static func fetchFirst(with predicate:NSPredicate? = nil) throws ->  Self? {
        return try self.fetch(predicate, limit: 1).first
    }
    @inlinable public static func fetch(_ predicate:NSPredicate? = nil,limit:Int = 0,manager:IPaCoreDataManager = IPaCoreDataManager.shared) throws -> [Self] {
        return try manager.fetch(predicate, limit: limit)
    }
    @inlinable public static func fetchedResultsController(with request:NSFetchRequest<Self> ,sectionNameKeyPath:String? = nil,cacheName:String? = nil,manager:IPaCoreDataManager = IPaCoreDataManager.shared) -> NSFetchedResultsController<Self> {
        return manager.fetchedResultsController(with: request, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    @inlinable public static func fetchedResultsController(_ predicate:NSPredicate? = nil,sortDescriptors:[NSSortDescriptor], limit:Int = 0,sectionNameKeyPath:String? = nil,cacheName:String? = nil,manager:IPaCoreDataManager = IPaCoreDataManager.shared) -> NSFetchedResultsController<Self> {
        return manager.fetchedResultsController(predicate,sortDescriptors:sortDescriptors, limit: limit, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    @inlinable public static func count(with request:NSFetchRequest<Self>,manager:IPaCoreDataManager = IPaCoreDataManager.shared) -> Int {
        return manager.count(with: request)
    }
    
    @inlinable public static func deleteAll(_ manager:IPaCoreDataManager = IPaCoreDataManager.shared) throws {
        let request = Self.fetchRequest()
        request.includesPropertyValues = false  //only fetch the managedObjectID
        
        let entities = try manager.fetch(request)
        for entity in entities {
            entity.delete()
        }
    }
    
    @inlinable public func delete() {
        self.managedObjectContext?.delete(self)
    }
}

