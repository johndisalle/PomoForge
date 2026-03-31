// Persistence.swift
// Core Data stack with CloudKit optional sync

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "PomoForge")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure CloudKit sync — disabled by default, toggled in Settings
        if let description = container.persistentStoreDescriptions.first {
            let cloudKitEnabled = UserDefaults.standard.bool(forKey: "cloudKitSyncEnabled")
            if cloudKitEnabled {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.pomoforge.app"
                )
            } else {
                description.cloudKitContainerOptions = nil
            }
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle this gracefully
                fatalError("Core Data load error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Seed default workflow if none exist
    func seedDefaultWorkflowIfNeeded() {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDWorkflow")
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            if count == 0 {
                let workflow = NSEntityDescription.insertNewObject(forEntityName: "CDWorkflow", into: context)
                workflow.setValue(UUID(), forKey: "id")
                workflow.setValue("Classic Pomodoro", forKey: "name")
                workflow.setValue(true, forKey: "isDefault")
                workflow.setValue(Date(), forKey: "createdAt")

                // Intervals stored as JSON: [{work: 1500, break: 300}] x4 + long break
                let intervals: [[String: Any]] = [
                    ["type": "work", "duration": 1500],
                    ["type": "break", "duration": 300],
                    ["type": "work", "duration": 1500],
                    ["type": "break", "duration": 300],
                    ["type": "work", "duration": 1500],
                    ["type": "break", "duration": 300],
                    ["type": "work", "duration": 1500],
                    ["type": "longBreak", "duration": 900]
                ]
                let data = try JSONSerialization.data(withJSONObject: intervals)
                workflow.setValue(data, forKey: "intervalsData")

                try context.save()
            }
        } catch {
            print("Seed error: \(error)")
        }
    }
}
