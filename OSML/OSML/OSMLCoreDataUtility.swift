

import Foundation
import CoreData
import UIKit

class CoreDataController: NSObject {
    static let shared:CoreDataController = CoreDataController()
    
    var managedObjectContext: NSManagedObjectContext
    var persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    private override init() {
        guard let modelURL = Bundle.main.url(forResource: "OSML", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("Unable to resolve document directory")
        }
        let storeURL = docURL.appendingPathComponent("OSML.sqlite")
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        
    }
    
    func saveContext(context:NSManagedObjectContext) {
        let curManagedObjectContext:NSManagedObjectContext? = context;
        curManagedObjectContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if (curManagedObjectContext != nil) {
            curManagedObjectContext?.perform({
                if (curManagedObjectContext?.hasChanges)! {
                    do {
                        try curManagedObjectContext?.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            })
        }
    }

    func saveResource(path: String, status: String, claimId: NSNumber, recordId: NSNumber, type: String, userId: String, url:String) {
        let currentMOC = self.getCurrentContext()
        let entity = NSEntityDescription.entity(forEntityName: "Resource", in: currentMOC)
        let newResource = NSManagedObject(entity: entity!, insertInto: currentMOC)
        newResource.setValue(path, forKey: "path")
        newResource.setValue(status, forKey: "uploadStatus")
        newResource.setValue(claimId, forKey: "claimId")
        newResource.setValue(self.getMaxID(), forKey: "resourceId")
        newResource.setValue(recordId, forKey: "recordId")
        newResource.setValue(type, forKey: "type")
        newResource.setValue(userId, forKey: "userId")
        newResource.setValue(url, forKey: "url")
        self.saveContext(context: currentMOC)
    }
    
    func getMaxID() -> NSNumber {
        let currentMOC = self.getCurrentContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        let sortDescriptor = NSSortDescriptor(key: "resourceId", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        var newID = NSNumber(value: 0)
        do {
            let result = try currentMOC.fetch(fetchRequest) as! [ResourceMO]
            if result.count > 0 {
                newID = NSNumber(value: (result.last?.resourceId?.intValue)! + 1)
            }
        } catch let error as NSError {
            NSLog("Unresolved error \(error)")
        }
        return newID
    }

    func saveChunk(resourceId:NSNumber, status: String, chunkId: NSNumber) {
        let currentMOC = self.getCurrentContext()
        let entity = NSEntityDescription.entity(forEntityName: "Chunk", in: currentMOC)
        let newChunk = NSManagedObject(entity: entity!, insertInto: currentMOC)
        newChunk.setValue(resourceId, forKey: "resourceId")
        newChunk.setValue(status, forKey: "uploadStatus")
        newChunk.setValue(chunkId, forKey: "chunkId")
        self.saveContext(context: currentMOC)
    }
    
    func updateResourceUploadStatus(resourceId: NSNumber, status: String) {
        let currentMOC = self.getCurrentContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "resourceId = %@", resourceId)
        request.returnsObjectsAsFaults = false
        do {
            let result = try currentMOC.fetch(request) as! [ResourceMO]
            for data in result {
                data.setValue(status, forKey: "uploadStatus")
                self.saveContext(context: currentMOC)
            }
            
        } catch {
            
            print("Failed")
        }
    }
    
    func updateResourceURL(resourceId: NSNumber, url: String) {
        let currentMOC = self.getCurrentContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "resourceId = %@", resourceId)
        request.returnsObjectsAsFaults = false
        do {
            let result = try currentMOC.fetch(request) as! [ResourceMO]
            for data in result {
                data.setValue(url, forKey: "url")
                self.saveContext(context: currentMOC)
            }
            
        } catch {
            
            print("Failed")
        }
    }
    
    func updateChunkUploadStatus(chunkId: NSNumber, resourceId: NSNumber, status: String) {
        let currentMOC = self.getCurrentContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Chunk")
        request.predicate = NSPredicate(format: "chunkId = %@ && resourceId = %@", chunkId,resourceId)
        request.returnsObjectsAsFaults = false
        do {
            let result = try currentMOC.fetch(request) as! [ChunkMO]
            for data in result {
                data.setValue(status, forKey: "uploadStatus")
                self.saveContext(context: currentMOC)
            }
            
        } catch {
            
            print("Failed")
        }
    }
    
    func fetchResourceDetail(resourceId: NSNumber) -> ResourceMO {
        let currentMOC = self.getCurrentContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "resourceId = %@", resourceId)
        request.returnsObjectsAsFaults = false
        var resourceObj:ResourceMO = ResourceMO()
        do {
            let result = try currentMOC.fetch(request) as! [ResourceMO]
            resourceObj = result.last!
        } catch {
            
            print("Failed")
        }
        return resourceObj;
    }

    func fetchResourceUploadStatus(resourceId: NSNumber) -> String {
        let currentMOC = self.getCurrentContext()
        //upload status of a resource
        var uploadStatus = ""
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "resourceId = %@", resourceId)
//        request.returnsObjectsAsFaults = true
        do {
            let result = try currentMOC.fetch(request) as! [ResourceMO]
            for data in result {
                uploadStatus = data.value(forKey: "uploadStatus") as! String
                print(uploadStatus)
            }
            
        } catch {
            
            print("Failed")
        }
        return uploadStatus;
    }

    func fetchChunkUploadStatus(chunkId: NSNumber, resourceId: NSNumber) -> String {
        let currentMOC = self.getCurrentContext()
        //upload status of specific chunk of a resource
        var uploadStatus = ""
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Chunk")
        request.predicate = NSPredicate(format: "chunkId = %@ && resourceId = %@", chunkId,resourceId)
        request.returnsObjectsAsFaults = false
        do {
            let result = try currentMOC.fetch(request) as! [ChunkMO]
            for data in result {
                uploadStatus = data.value(forKey: "uploadStatus") as! String
                print(uploadStatus)
            }
            
        } catch {
            
            print("Failed")
        }
        return uploadStatus;
    }
    
    func fetchResourcesToBeUploaded() -> [ResourceMO] {
        let currentMOC = self.getCurrentContext()
        //upload status whether all chunks has been uploaded for a resource or not
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "(uploadStatus = %@ OR uploadStatus = %@)", UploadStatus.Started.rawValue, UploadStatus.InProgress.rawValue)
        request.returnsObjectsAsFaults = false
        var resources = [ResourceMO]()
        do {
            resources = try currentMOC.fetch(request) as! [ResourceMO]
        } catch {
            
            print("Failed")
        }
        return resources;
    }
    
    func fetchResourcesWithURLForARecord(claimId: NSNumber, recordId: NSNumber) -> [ResourceMO] {
        let currentMOC = self.getCurrentContext()
        //upload status whether all chunks has been uploaded for a resource or not
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "(claimId = %@ AND recordId = %@ AND url != \"\")", claimId, recordId)
        request.returnsObjectsAsFaults = false
        var resources = [ResourceMO]()
        do {
            resources = try currentMOC.fetch(request) as! [ResourceMO]
        } catch {
            
            print("Failed")
        }
        return resources;
    }

    func fetchChunksToBeUploaded(resourceId: NSNumber) -> [ChunkMO] {
        let currentMOC = self.getCurrentContext()
        //upload status whether all chunks has been uploaded for a resource or not
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Chunk")
        request.predicate = NSPredicate(format: "(resourceId = %@) AND (uploadStatus = %@ OR uploadStatus = %@)", resourceId, UploadStatus.Started.rawValue, UploadStatus.InProgress.rawValue)
        request.returnsObjectsAsFaults = false
        var chunks = [ChunkMO]()
        do {
            chunks = try currentMOC.fetch(request) as! [ChunkMO]
        } catch {
            
            print("Failed")
        }
        return chunks;
    }
    
    func fetchRemainingResourcesForARecord(claimId: NSNumber, recordId: NSNumber) -> [ResourceMO] {
        let currentMOC = self.getCurrentContext()
        //upload status whether all chunks has been uploaded for a resource or not
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "(claimId = %@ AND recordId = %@ AND (uploadStatus = %@ or uploadStatus = %@))", claimId, recordId, UploadStatus.Started.rawValue, UploadStatus.InProgress.rawValue)
        request.returnsObjectsAsFaults = false
        var resources = [ResourceMO]()
        do {
            resources = try currentMOC.fetch(request) as! [ResourceMO]
        } catch {
            
            print("Failed")
        }
        return resources;
    }
    
    func fetchResourcesForARecord(claimId: NSNumber, recordId: NSNumber) -> [ResourceMO] {
        let currentMOC = self.getCurrentContext()
        //upload status whether all chunks has been uploaded for a resource or not
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Resource")
        request.predicate = NSPredicate(format: "(claimId = %@ AND recordId = %@)", claimId, recordId)
        request.returnsObjectsAsFaults = false
        var resources = [ResourceMO]()
        do {
            resources = try currentMOC.fetch(request) as! [ResourceMO]
        } catch {
            
            print("Failed")
        }
        return resources;
    }
    
    func deleteChunks(resourceId: NSNumber) {
        let currentMOC = self.getCurrentContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Chunk")
        let result = try? currentMOC.fetch(request) as! [ChunkMO]
        for data in result! {
            currentMOC.delete(data)
        }
        self.saveContext(context: currentMOC)
    }
    
    // Get the new context if the DB context is on a different thread...
    func getCurrentContext() -> NSManagedObjectContext {
        var curMOC:NSManagedObjectContext? = self.managedObjectContext
        let thisThread:Thread = Thread.current
        if thisThread == Thread.main {
            if curMOC != nil {
                return curMOC!
            }
            let coordinator:NSPersistentStoreCoordinator? = self.persistentStoreCoordinator
            if coordinator != nil {
                curMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
                curMOC?.persistentStoreCoordinator = coordinator
            }
            return curMOC!
        }
        // if this is some other thread....
        // Get the current context from the same thread..
        var threadManagedObjectContext:NSManagedObjectContext? = thisThread.threadDictionary.object(forKey:"MOC_KEY") as? NSManagedObjectContext;
        // Return separate MOC for each new thread
        if threadManagedObjectContext != nil {
            return threadManagedObjectContext!;
        }
        
        let coordinator:NSPersistentStoreCoordinator? = self.persistentStoreCoordinator
        if coordinator != nil {
            threadManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            threadManagedObjectContext?.persistentStoreCoordinator = coordinator
            thisThread.threadDictionary.setObject(threadManagedObjectContext!, forKey: "MOC_KEY" as NSCopying)
        }
        return threadManagedObjectContext!;
    }
    
}
