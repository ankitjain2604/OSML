

import Foundation
import CoreData

class ResourceMO: NSManagedObject {
    
    @NSManaged var userId: String?
    @NSManaged var recordId: NSNumber?
    @NSManaged var claimId: NSNumber?
    @NSManaged var resourceId: NSNumber?
    @NSManaged var path: String?
    @NSManaged var type: String?
    @NSManaged var uploadStatus: String?
    @NSManaged var url: String?
}

class ChunkMO: NSManagedObject {
    
    @NSManaged var chunkId: NSNumber?
    @NSManaged var resourceId: NSNumber?
    @NSManaged var uploadStatus: String?
    
}
