//
//  IPaCoreDataManager.swift
//  IPaCoreDataManager
//
//  Created by IPa Chen on 2015/8/16.
//  Copyright (c) 2021年 A Magic Studio. All rights reserved.
//

import Foundation
import CoreData
import IPaLog
open class IPaCoreDataManager :NSObject{
    public static let shared = IPaCoreDataManager()
    public static let errorNotificationName = Notification.Name("IPaCoreData.errorNotificationName")
    public lazy var managedObjectModel:NSManagedObjectModel = NSManagedObjectModel() {
        didSet {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.dbStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true,NSInferMappingModelAutomaticallyOption: true])
                /*
                 Replace this implementation with code to handle the error appropriately.
                 
                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                 
                 Typical reasons for an error here include:
                 * The persistent store is not accessible
                 * The schema for the persistent store is incompatible with current managed object model
                 Check the error message to determine what the actual problem was.
                 */
                
                
                
            }
            catch let error as NSError {
                //persitentStore fail
                NotificationCenter.default.post(name: IPaCoreDataManager.errorNotificationName, object: self, userInfo: ["Error":error])
            }
            
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
            managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            self.managedObjectContext = managedObjectContext
        }
    }
    open lazy var managedObjectContext:NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    open var dbStoreURL:URL?
    override init() {
        super.init()
    }
    public init(_ dbName:String,dbPath:String? = nil,modelName:String? = nil) {
        super.init()
        self.load(dbName, dbPath: dbPath, modelName: modelName)
    }
    public func load(_ dbName:String,dbPath:String? = nil,modelName:String? = nil) {
        
        let modelName = modelName ?? dbName
        
        let dbFileName = (dbName as NSString).appendingPathExtension("sqlite")!
        var momdUrl:URL?
        var storePath = dbPath ?? (NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true).first)!
        storePath = (storePath as NSString).appendingPathComponent(dbFileName)
        var modelPath:String? = nil
        modelPath = Bundle.main.path(forResource: modelName, ofType: "momd")
        if modelPath == nil {
            modelPath = Bundle.main.path(forResource: modelName, ofType: "mom")
        }
        momdUrl = URL(fileURLWithPath: modelPath!)
        dbStoreURL = URL(fileURLWithPath:storePath)
        managedObjectModel = NSManagedObjectModel(contentsOf: momdUrl!)!
            
        
        
         
        if self.checkMigration() {
            _ = self.makeMigration()
        }
    }
    //MARK: Migration
    func findTargetModel(from array:[String],bundle:Bundle,sourceModel:NSManagedObjectModel) -> (String,NSManagedObjectModel,NSMappingModel)? {
        for momPath in array {
            
            if let model =  NSManagedObjectModel(contentsOf: URL(fileURLWithPath: momPath)) {
                
                if let mappingModel = NSMappingModel(from:[bundle], forSourceModel: sourceModel, destinationModel: model) {
                    let targetModelName = ((momPath as NSString).lastPathComponent as NSString).deletingPathExtension
                    
                   
                    // Set policy here (I have one policy per migration, so this works)
                    mappingModel.entityMappings.forEach {
                            if let entityMigrationPolicyClassName = $0.entityMigrationPolicyClassName,
                                var namespace = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String {
                                namespace = namespace.replacingOccurrences(of: " ", with: "_")
                                $0.entityMigrationPolicyClassName = entityMigrationPolicyClassName.replacingOccurrences(of: "${ModuleName}", with: namespace)
                            }
                        }
                    
                    
                    
                    return (targetModelName,model,mappingModel)
                }

            }
        }
        return nil
        
        
    }
    func makeMigration() -> Bool {
        guard let sourceURL = dbStoreURL else {
            return false
        }
        let bundle = Bundle.main
        var sourceModel:NSManagedObjectModel
        do {
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceURL, options: nil)
            if managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) {
                return true
            }
            if let model = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: sourceMetadata) {
                sourceModel = model
            }
            else {
                return false
            }
        }
        catch let error as NSError {
            //migration fail
            NotificationCenter.default.post(name: IPaCoreDataManager.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
            return false
        }
        //search model paths in bundle
        var targetModel:NSManagedObjectModel?
        var targetMappingModel:NSMappingModel?
        var targetModelName:String?
        let momdArray = bundle.paths(forResourcesOfType: "momd", inDirectory: nil)
        
        for momdPath in momdArray {
            
            let resourceSubpath = (momdPath as NSString).lastPathComponent
            let array = bundle.paths(forResourcesOfType: "mom", inDirectory: resourceSubpath)
            if let (modelName,model,mappingModel) = self.findTargetModel(from: array, bundle: bundle, sourceModel: sourceModel)
            {
                targetModelName = modelName
                targetModel = model
                targetMappingModel = mappingModel
                break
            }
            
        }
        if targetModel == nil {
            let otherModels = bundle.paths(forResourcesOfType: "mom", inDirectory: nil)
            
            if let (modelName,model,mappingModel) = self.findTargetModel(from: otherModels, bundle: bundle, sourceModel: sourceModel)
            {
                targetModelName = modelName
                targetModel = model
                targetMappingModel = mappingModel
            }
            
        }
        guard let destinationModel = targetModel,let destinationMappingModel = targetMappingModel else {
            print("destination model not found!!")
            return false
        }
        // Build a path to write the new store
        let storePath:NSString = sourceURL.path as NSString
        let destinationURL = URL(fileURLWithPath:"\(storePath.deletingPathExtension).\(targetModelName!).\(storePath.pathExtension)")
        //start migration
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        do {
            try manager.migrateStore(from: sourceURL, sourceType: NSSQLiteStoreType, options: nil, with: destinationMappingModel, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
        }
        catch let error as NSError {
            //migration fail
            NotificationCenter.default.post(name: IPaCoreDataManager.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
            
            return false
        }
        
        // Migration was successful, move the files around to preserve the source in case things go bad
        let guid = ProcessInfo.processInfo.globallyUniqueString
        let backupPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(guid)
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(atPath: sourceURL.path, toPath: backupPath)
            try fileManager.moveItem(atPath: destinationURL.path, toPath: sourceURL.path)
            
        }
        catch let error as NSError {
            
            //file backup fail
            NotificationCenter.default.post(name: IPaCoreDataManager.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
            return false
        }
        return makeMigration()
    }
    func checkMigration() -> Bool {
        guard let dbStoreURL = dbStoreURL, FileManager.default.fileExists(atPath: dbStoreURL.path) else {
            return false
        }
        //check migration
        do {
            let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: dbStoreURL, options: nil)
            // Migration is needed if destinationModel is NOT compatible
            if !managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetadata) {
                //migration needed
            }
        }
        catch let error as NSError {
            //metadataForPersistentStore fail
            NotificationCenter.default.post(name: IPaCoreDataManager.errorNotificationName, object: self, userInfo: ["Error":error])
            return false
        }
        catch {
        }
        return true
    }
    open func save() {
        do {
            if managedObjectContext.hasChanges {
                try managedObjectContext.save()
            }
        } catch let error as NSError {
            //save fail
            IPaLog(error.localizedDescription)
            if let current = OperationQueue.current?.underlyingQueue {
                current.asyncAfter(deadline: .now()+1) {
                    self.save()
                }
            }
        }
    }
    
    @inlinable public func createSubManagedContext(_ concurencyType:NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let workerMOC = NSManagedObjectContext(concurrencyType: concurencyType)
        workerMOC.parent = managedObjectContext
        return workerMOC
    }
    @inlinable public func managedObjectID(forURIRepresentation url:URL,managedObjectContext:NSManagedObjectContext = IPaCoreDataManager.shared.managedObjectContext) -> NSManagedObjectID? {
        return managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
    }
    
     
}


