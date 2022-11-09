//
//  NSFetchRequestResult+IPaCoreData.swift
//  IPaCoreData
//
//  Created by IPa Chen on 2021/12/28.
//

import CoreData
import IPaLog

extension NSFetchRequestResult where Self: NSManagedObject {
    
    public static var count:Int {
        get {
            return self.count()
        }
    }
    @inlinable public func clone(from managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> Self? {
        if self.managedObjectContext == managedObjectContext {
            return self
        }
        return managedObjectContext.object(with: self.objectID) as? Self
    }
    @inlinable public static func managedObject(for objectId:NSManagedObjectID,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> Self? {
        return managedObjectContext.object(with: objectId) as? Self
        
    }
    @inlinable public static func create(_ properties:[String:Any]? = nil,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> Self {
        let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: Self.self), in: managedObjectContext)!
        let entity = NSManagedObject(entity: entityDescription, insertInto: managedObjectContext) as! Self
        if let properties = properties {
            for key in properties.keys {
                entity.setValue(properties[key], forKey: key)
            }
        }
        return entity
    }
    @inlinable public static func create(with uri:URL,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> Self? {
        guard let objectID = managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
            return nil
        }
        return self.managedObject(for: objectID,managedObjectContext: managedObjectContext)
    }
    @inlinable public static func fetchRequest(with predicate:IPaPredicateProvider? = nil,sortProviders:[IPaSortDescriptorsProvider]? = nil,limit:Int = 0) -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: String(describing:self))
        request.fetchLimit = limit
        request.predicate = predicate?.predicate
        request.sortDescriptors = sortProviders?.map{ $0.sortDescriptor}
        return request
    }
    @inlinable public static func firstOrCreate(with properties:[String:Any] = [:]) throws -> Self {
        return try self.fetchFirst(properties) ?? self.create(properties)
    }
    
    @inlinable public static func fetchFirst(_ predicate:IPaPredicateProvider? = nil,sortProviders:[IPaSortDescriptorsProvider]? = nil,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) throws ->  Self? {
        return try self.fetch(with: {
            request in
            request.fetchLimit = 1
            request.predicate = predicate?.predicate
            request.sortDescriptors = sortProviders?.map{ $0.sortDescriptor}
        },managedObjectContext: managedObjectContext).first
    }
    
    @inlinable public static func fetchFirst(with requestHandler:(NSFetchRequest<Self>)->(),managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) throws ->  Self? {
        return try self.fetch(with: {
            request in
            request.fetchLimit = 1
            requestHandler(request)
        },managedObjectContext: managedObjectContext).first
        
        
    }
    @inlinable public static func fetch(with requestHandler:(NSFetchRequest<Self>) -> (),managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) throws -> [Self] {
        let request = self.fetchRequest()
        requestHandler(request)
        return try managedObjectContext.fetch(request)
        
    }
    @inlinable public static func fetch(_ predicate:IPaPredicateProvider? = nil,sortProviders:[IPaSortDescriptorsProvider]? = nil,limit:Int = 0,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) throws -> [Self] {
        return try self.fetch(with: { request in
            request.predicate = predicate?.predicate
            request.sortDescriptors = sortProviders?.map{ $0.sortDescriptor}
            request.fetchLimit = limit
        },managedObjectContext: managedObjectContext)
        
    }
    
    @inlinable public static func fetchedResultsController(with requestHandler:((NSFetchRequest<Self>)->())? = nil ,sectionNameKeyPath:String? = nil,cacheName:String? = nil,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> NSFetchedResultsController<Self> {
        let request = Self.fetchRequest()
        requestHandler?(request)
        return NSFetchedResultsController<Self>(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    @inlinable public static func fetchedResultsController(_ predicate:IPaPredicateProvider? = nil,sortProviders:[IPaSortDescriptorsProvider]? = nil,fetchBatchSize:Int = 0,sectionNameKeyPath:String? = nil,cacheName:String? = nil,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> NSFetchedResultsController<Self> {
        return self.fetchedResultsController(with:{
            request in
            request.predicate = predicate?.predicate
            request.sortDescriptors = sortProviders?.map{ $0.sortDescriptor}
            request.fetchBatchSize = fetchBatchSize
        },sectionNameKeyPath:sectionNameKeyPath,cacheName: cacheName, managedObjectContext: managedObjectContext)
    }
    
    @inlinable public static func count(_ predicate:IPaPredicateProvider? = nil,limit:Int = 0, manager:IPaCoreDataManager = IPaCoreDataManager.shared) -> Int {
        do {
            let request = self.fetchRequest(with: predicate, limit: limit)
            return try manager.managedObjectContext.count(for: request)
        }
        catch let error as NSError {
            IPaLog(error.localizedDescription)
        }
        return 0
    }
    
    @inlinable public static func deleteAll(_ manager:IPaCoreDataManager = IPaCoreDataManager.shared) throws {
        let entities = try self.fetch(with: {
            request in
            request.includesPropertyValues = false
        },managedObjectContext: manager.managedObjectContext)
        for entity in entities {
            entity.delete()
        }
    }
    
    @inlinable public func delete() {
        self.managedObjectContext?.delete(self)
    }
    @inlinable public func save() {
        try? self.managedObjectContext?.save()
    }
    @inlinable public func trySave() throws {
        try self.managedObjectContext?.save()
    }
}

