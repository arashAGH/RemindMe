import SwiftUI
import Contacts
import ContactsUI
import UserNotifications

// مدل ایونت با تقویم
struct Event: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let calendarIdentifier: Calendar.Identifier
    let contacts: [String]
}

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

// نمایی برای افزودن مخاطب
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

// نمایش تاریخ با توجه به تقویم
func formattedDate(for date: Date, calendarIdentifier: Calendar.Identifier) -> String {
    let calendar = Calendar(identifier: calendarIdentifier)
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

// نمای اصلی
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
                    Text("Islamic").tag(Calendar(identifier: .islamicUmmAlQura))
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                DatePicker("Select Date", selection: $eventDate, displayedComponents: .date)
                    .environment(\.calendar, selectedCalendar)
                    .padding()

                Picker("Select Event", selection: $eventTitle) {
                    Text("Select Event").tag(String?.none)
                    ForEach(defaultEvents, id: \.self) { event in
                        Text(event).tag(String?(event))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: eventTitle) { oldValue, newValue in
                    if newValue == nil {
                        showError = false
                    } else if newValue == "Add Custom Event" {
                        isShowingCustomEventView = true
                        eventTitle = nil
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
                        let eventDateComponents = selectedCalendar.dateComponents([.year, .month, .day], from: eventDate)
                        let eventDateFromComponents = selectedCalendar.date(from: eventDateComponents) ?? Date()

                        let newEvent = Event(id: UUID(), title: eventTitle, date: eventDateFromComponents, calendarIdentifier: selectedCalendar.identifier, contacts: selectedContacts)
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
                        .foregroundColor(.red)  // رنگ متن دکمه
                      }
                      .padding()
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Error"),
                        message: Text("Please select a valid event title."),
                        dismissButton: .default(Text("OK"))
                    )
                }

                List {
                    ForEach(events) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                            Text(formattedDate(for: event.date, calendarIdentifier: event.calendarIdentifier))
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
                    TextField("Custom Event Title", text: $newCustomEventTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        if !newCustomEventTitle.isEmpty, !defaultEvents.contains(newCustomEventTitle) {
                            defaultEvents.append(newCustomEventTitle)
                            isShowingCustomEventView = false
                            newCustomEventTitle = ""
                        }
                    }) {
                        Text("Add Event")
                    }
                    .padding()
                    
                    Button(action: {
                        isShowingCustomEventView = false
                    }) {
                        Text("Cancel")
                    }
                    .padding()
                }
                .padding()
            }
        }
    }

    func saveEvent(_ event: Event) {
        // ذخیره‌سازی ایونت
    }

    func loadEvents() {
        // بارگذاری ایونت‌ها
    }

    func deleteEvent(at offsets: IndexSet) {
        // حذف ایونت‌ها
    }

    func scheduleNotification(for event: Event) {
        // برنامه‌ریزی اعلان
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
