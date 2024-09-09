import SwiftUI
import Contacts
import ContactsUI
import UserNotifications

// نمایی برای انتخاب مخاطب
struct ContactPickerView: UIViewControllerRepresentable {
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView
        
        init(parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let fullName = "\(contact.givenName) \(contact.familyName)"
            parent.selectedContact = fullName
            parent.didPickContact()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.didCancel()
        }
    }
    
    @Binding var selectedContact: String?
    var didPickContact: () -> Void
    var didCancel: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
}

struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedContacts: [String]
    @State private var newContactName: String = ""
    @State private var isContactPickerShown: Bool = false
    @State private var isEnteringManually: Bool = false
    @Binding var contactToAdd: String?

    var body: some View {
        VStack {
            if !isEnteringManually {
                Button(action: {
                    self.isContactPickerShown = true
                }) {
                    Text("Select Contact")
                }
                .padding()
                
                Button(action: {
                    self.isEnteringManually = true
                }) {
                    Text("Enter Manually")
                }
                .padding()
            } else {
                TextField("Enter Contact Name", text: $newContactName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if !newContactName.isEmpty, !selectedContacts.contains(newContactName) {
                        selectedContacts.append(newContactName)
                        newContactName = ""
                        isEnteringManually = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Add Contact")
                }
                .padding()

                Button(action: {
                    isEnteringManually = false
                }) {
                    Text("Cancel")
                }
                .padding()
            }
        }
        .sheet(isPresented: $isContactPickerShown) {
            ContactPickerView(selectedContact: $contactToAdd) {
                if let contactToAdd = contactToAdd {
                    if !selectedContacts.contains(contactToAdd) {
                        selectedContacts.append(contactToAdd)
                    }
                }
                self.isContactPickerShown = false
            } didCancel: {
                self.isContactPickerShown = false
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var eventTitle: String? = nil
    @State private var eventDate: Date = Date()
    @State private var selectedCalendar: Calendar = Calendar(identifier: .gregorian)
    @State private var selectedContacts: [String] = []
    @State private var events: [Event] = []
    @State private var isShowingAddContactsView: Bool = false
    @State private var contactToAdd: String? = nil
    @State private var newCustomEventTitle: String = ""
    @State private var isShowingCustomEventView: Bool = false

    @State private var defaultEvents = ["Birthday", "Anniversary", "Meeting", "Add Custom Event"]

    @State private var showError = false

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Calendar", selection: $selectedCalendar) {
                    Text("Gregorian").tag(Calendar(identifier: .gregorian))
                    Text("Persian").tag(Calendar(identifier: .persian))
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                DatePicker("Select Date", selection: $eventDate, displayedComponents: .date)
                    .environment(\.calendar, selectedCalendar)
                    .padding()

                Picker("Select Event", selection: $eventTitle) {
                    Text("Select Event").tag(String?.none) // Non-selectable title
                        .foregroundColor(.blue) // Set color to blue
                    ForEach(defaultEvents, id: \.self) { event in
                        Text(event).tag(String?(event))
                            .foregroundColor(.black) // Set color to black for other options
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: eventTitle) { newValue in
                    if newValue == nil {
                        showError = false // Reset error state
                    } else if newValue == "Add Custom Event" {
                        isShowingCustomEventView = true
                        eventTitle = nil // Reset the picker to avoid selecting custom event again
                    }
                }

                Button(action: {
                    if eventTitle == nil {
                        showError = true
                    } else {
                        self.isShowingAddContactsView = true
                    }
                }) {
                    Text("Add Contacts")
                }
                .padding()

                if !selectedContacts.isEmpty {
                    Text("Selected Contacts: \(selectedContacts.joined(separator: ", "))")
                }

                Button(action: {
                    if let eventTitle = eventTitle, !selectedContacts.isEmpty {
                        let newEvent = Event(title: eventTitle, date: eventDate, contacts: selectedContacts)
                        events.append(newEvent)
                        saveEvent(newEvent)
                        scheduleNotification(for: newEvent)
                        self.eventTitle = nil
                        selectedContacts = []
                    } else {
                        showError = true
                    }
                }) {
                    Text("Add Event")
                }
                .padding()
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Error"),
                        message: Text("Please select a valid event titles."),
                        dismissButton: .default(Text("OK"))
                    )
                }

                List {
                    ForEach(events, id: \.title) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                            Text(event.date, style: .date)
                            if !event.contacts.isEmpty {
                                Text("Contacts: \(event.contacts.joined(separator: ", "))")
                            }
                        }
                    }
                    .onDelete(perform: deleteEvent)
                }
                .listStyle(PlainListStyle())
                .navigationBarItems(trailing: EditButton())
            }
            .navigationTitle("RemindMe")
            .onAppear {
                loadEvents()
            }
            .sheet(isPresented: $isShowingAddContactsView) {
                AddContactView(selectedContacts: $selectedContacts, contactToAdd: $contactToAdd)
            }
            .sheet(isPresented: $isShowingCustomEventView) {
                VStack {
                    TextField("Enter custom event", text: $newCustomEventTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        if !newCustomEventTitle.isEmpty, !defaultEvents.contains(newCustomEventTitle) {
                            defaultEvents.append(newCustomEventTitle)
                            newCustomEventTitle = ""
                            isShowingCustomEventView = false
                        }
                    }) {
                        Text("Save Custom Event")
                    }
                    .padding()
                    
                    Button(action: {
                        isShowingCustomEventView = false
                    }) {
                        Text("Cancel")
                    }
                    .padding()
                }
            }
        }
    }

    func saveEvent(_ event: Event) {
        // Implement saving event to database or UserDefaults if needed
    }

    func scheduleNotification(for event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "\(event.title) is today!"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day], from: event.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    func loadEvents() {
        // Dummy data for testing
        events = [
            Event(title: "Alice's Birthday", date: Date(), contacts: ["Alice"])
        ]
    }

    func deleteEvent(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
    }
}

struct Event {
    let title: String
    let date: Date
    let contacts: [String]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
