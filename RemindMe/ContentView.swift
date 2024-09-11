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
            return Calendar(identifier: Calendar.Identifier.gregorian)
        case .persian:
            return Calendar(identifier: Calendar.Identifier.persian)
        case .islamic:
            return Calendar(identifier: Calendar.Identifier.islamicUmmAlQura)
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
                // باکس ایونت‌های امروز
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today's Events:")
                        .font(.custom("AppleSymbols", size: 17))
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    ZStack {
                        // باکس اصلی
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5) // More pronounced shadow
                        
                        VStack {
                              let todaysEvents = eventsForToday(events: events, selectedCalendar: selectedCalendar)
                              if todaysEvents.isEmpty {
                                  Text("You have no events for today")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(todaysEvents) { event in
                                                                VStack(alignment: .leading, spacing: 9) {
                                                                    Text("\(event.contacts.joined(separator: ", ")) \(event.title) is today!")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .bold()
                                        
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(15)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                }
                            }
                        }
                        
                    }
                    
                }
                .padding()
                
                
                
                
                Picker("Select Calendar", selection: $selectedCalendar) {
                    Text("Gregorian").tag(CalendarType.gregorian)
                    Text("Persian").tag(CalendarType.persian)
                    Text("Islamic").tag(CalendarType.islamic)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // قرار دادن DatePicker و دکمه Today در کنار هم
                HStack {
                    DatePicker("Select Date:", selection: $eventDate, displayedComponents: .date)
                        .environment(\.calendar, selectedCalendar.toCalendar())
                        .padding()
                    
                    Spacer()
                    
                    // دکمه امروز
                    Button(action: {
                        eventDate = Date()  // تنظیم تاریخ به امروز
                    }) {
                        Text("Today")
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 20) // تنظیم فاصله‌ی دکمه از لبه‌ی راست
                }
                .padding(.horizontal)
                
                Picker("Select Event", selection: $eventTitle) {
                    Text("Select Event").tag(String?.none)
                    ForEach(defaultEvents, id: \.self) { event in
                        Text(event).tag(String?(event))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(0.1)
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
                        .foregroundColor(.red)
                    
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
            .navigationBarItems(
                leading: Text("RemindMe")
                    .font(.custom("Futura-Bold", size: 19)) // استفاده از فونت سفارشی
                    .fontWeight(.bold)
                    .padding(.horizontal)
            )
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
    func isHijriAnniversary(for eventDate: Date) -> Bool {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let todayComponents = hijriCalendar.dateComponents([.month, .day], from: Date())
        let eventComponents = hijriCalendar.dateComponents([.month, .day], from: eventDate)
        return todayComponents.month == eventComponents.month && todayComponents.day == eventComponents.day
    }
    
    func eventsForToday(events: [AppEvent], selectedCalendar: CalendarType) -> [AppEvent] {
        return events.filter { event in
            let eventCalendarType = CalendarType(rawValue: Int(event.calendarIdentifier)) ?? .gregorian
            
            if eventCalendarType == .islamic {
                // بررسی سالگردهای هجری قمری
                return isHijriAnniversary(for: event.date)
            } else {
                // بررسی سالگردهای میلادی یا شمسی
                let calendar = eventCalendarType.toCalendar()
                let todayComponents = calendar.dateComponents([.month, .day], from: Date())
                let eventComponents = calendar.dateComponents([.month, .day], from: event.date)
                return todayComponents.month == eventComponents.month && todayComponents.day == eventComponents.day
            }
        }
    }
    func scheduleNotificationAtTime(for event: AppEvent, hour: Int, minute: Int, content: UNNotificationContent) {
        let calendarType = CalendarType(rawValue: Int(event.calendarIdentifier)) ?? .gregorian
        let calendar = calendarType.toCalendar()

        var eventDateComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
        eventDateComponents.hour = hour
        eventDateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: eventDateComponents, repeats: true)
        let identifier = "\(event.id)-\(hour)-\(minute)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    func scheduleNotification(for event: AppEvent) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Reminder"
        notificationContent.body = "\(event.contacts.joined(separator: ", ")) has an event: \(event.title) today!"
        notificationContent.sound = UNNotificationSound.default
        
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let eventDateComponents = calendar.dateComponents([.month, .day], from: event.date)
        
        // تنظیم ساعت 00:00 برای نوتیفیکیشن
        scheduleNotificationAtTime(for: event, hour: 0, minute: 0, content: notificationContent)
        
        // تنظیم ساعت 12:00 برای نوتیفیکیشن
        scheduleNotificationAtTime(for: event, hour: 12, minute: 0, content: notificationContent)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

