import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RemindMeModel") // نام مدل Core Data شما
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // Save Event
    func saveEvent(event: AppEvent) {
        let context = persistentContainer.viewContext
        let newEvent = Event(context: context)
        
        newEvent.id = event.id
        newEvent.title = event.title
        newEvent.date = event.date
        newEvent.calendarIdentifier = Int16(event.calendarIdentifier) // تبدیل String به Int16
        newEvent.contact = event.contacts.joined(separator: ",")
        
        do {
            try context.save()
        } catch {
            print("Failed to save event: \(error)")
        }
    }
    
    // Load Events
    func loadEvents() -> [AppEvent] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        
        do {
            let eventEntities = try context.fetch(fetchRequest)
            return eventEntities.map { entity in
                AppEvent(
                    id: entity.id ?? UUID(), // فرض بر این است که UUID پیش‌فرض درست است
                    title: entity.title ?? "",
                    date: entity.date ?? Date(),
                    calendarIdentifier: Int16(entity.calendarIdentifier), // تبدیل Int16 به String
                    contacts: entity.contact?.components(separatedBy: ",") ?? []
                )
            }
        } catch {
            print("Failed to load events: \(error)")
            return []
        }
    }
    
    // Delete Event
    func deleteEvent(event: AppEvent) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", event.id.uuidString)
        
        do {
            let eventEntities = try context.fetch(fetchRequest)
            if let eventEntity = eventEntities.first {
                context.delete(eventEntity)
                try context.save()
            }
        } catch {
            print("Failed to delete event: \(error)")
        }
    }
}
