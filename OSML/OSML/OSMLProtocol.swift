

import Foundation

protocol OSMLDelegate: class {
    func uploadCompletedForRecord(claimId: NSNumber, recordId: NSNumber)
    func uploadCompletedForResource(claimId: NSNumber, recordId: NSNumber, resourceUrl: String)
    func assessmentCompletedForRecord(claimId: NSNumber, recordId: NSNumber)
}

protocol OSMLNetworkDelegate: class {
    func uploadCompletedForRecord(claimId: NSNumber, recordId: NSNumber)
    func uploadCompletedForResource(claimId: NSNumber, recordId: NSNumber, resourceId: NSNumber)
    func assessmentCompletedForRecord(claimId: NSNumber, recordId: NSNumber)
}

