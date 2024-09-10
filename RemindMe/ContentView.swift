import SwiftUI
import Contacts
import ContactsUI
import UserNotifications

// مدل ایونت با تقویم
struct AppEvent: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let calendarIdentifier: Int16
    let contacts: [String]
}

// CalendarType برای مدیریت تقویم‌ها
enum CalendarType: Int {
    case gregorian = 0
    case persian = 1
    case islamic = 2

    func toCalendar() -> Calendar {
        switch self {
        case .gregorian:
            return Calendar(identifier: .gregorian)
        case .persian:
            return Calendar(identifier: .persian)
        case .islamic:
            return Calendar(identifier: .islamicUmmAlQura)
        }
    }

    static func fromCalendar(_ calendar: Calendar) -> CalendarType {
        switch calendar.identifier {
        case .gregorian:
            return .gregorian
        case .persian:
            return .persian
        case .islamicUmmAlQura:
            return .islamic
        default:
            return .gregorian // مقدار پیش‌فرض
        }
    }
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
func formattedDate(for date: Date, calendarIdentifier: Int) -> String {
    let calendarType = CalendarType(rawValue: calendarIdentifier) ?? .gregorian
    let calendar = calendarType.toCalendar()
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
    @State private var selectedCalendar: CalendarType = .gregorian
    @State private var selectedContacts: [String] = []
    @State private var events: [AppEvent] = []
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
                    Text("Gregorian").tag(CalendarType.gregorian)
                    Text("Persian").tag(CalendarType.persian)
                    Text("Islamic").tag(CalendarType.islamic)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                DatePicker("Select Date", selection: $eventDate, displayedComponents: .date)
                    .environment(\.calendar, selectedCalendar.toCalendar())
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
                        let eventDateComponents = selectedCalendar.toCalendar().dateComponents([.year, .month, .day], from: eventDate)
                        let eventDateFromComponents = selectedCalendar.toCalendar().date(from: eventDateComponents) ?? Date()

                        let newEvent = AppEvent(
                            id: UUID(),
                            title: eventTitle, // استفاده از eventTitle به صورت غیر اختیاری
                            date: eventDateFromComponents,
                            calendarIdentifier: Int16(selectedCalendar.rawValue),
                            contacts: selectedContacts
                        )
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
                        message: Text("Please select a valid event title."),
                        dismissButton: .default(Text("OK"))
                    )
                }

                List {
                    ForEach(events) { event in
                        VStack(alignment: .leading) {
                            Text(event.title)
                            Text(formattedDate(for: event.date, calendarIdentifier: Int(event.calendarIdentifier)))
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


    func saveEvent(_ event: AppEvent) {
        CoreDataManager.shared.saveEvent(event: event)
        loadEvents()  // بارگذاری مجدد رویدادها بعد از ذخیره
    }

    func loadEvents() {
        events = CoreDataManager.shared.loadEvents()
    }

    func deleteEvent(at offsets: IndexSet) {
        offsets.forEach { index in
            let eventToDelete = events[index]
            CoreDataManager.shared.deleteEvent(event: eventToDelete)
            events.remove(atOffsets: offsets)
        }
    }

    func scheduleNotification(for event: AppEvent) {
        // برنامه‌ریزی اعلان
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
