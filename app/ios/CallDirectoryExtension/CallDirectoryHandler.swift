import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // 1. Add Call Blocking entries (must be strictly sequential ascending int64)
        addAllBlockingPhoneNumbers(to: context)

        // 2. Add Caller Identification entries (sequential ascending int64 with labels)
        addAllIdentificationPhoneNumbers(to: context)

        context.completeRequest()
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // High risk spam numbers in ascending int64 order (E.164 without '+')
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [
            12023527734,
            18005551234,
            18091234567,
            18761234567,
            18885551234
        ]

        for phoneNumber in phoneNumbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let labels: [(CXCallDirectoryPhoneNumber, String)] = [
            (12127365000, "Legitimate Business"),
            (18002752273, "Apple Support")
        ]

        for (phoneNumber, label) in labels {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // Log or handle error if needed
    }
}
