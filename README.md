# RemindME
#### Video Demo:  <https://youtu.be/OWJ99AL5WvQ>
#### Description:
RemindMe is an event management and reminder app built with Swift and SwiftUI. It allows users to create, organize, and schedule events while supporting multiple calendar types, including Gregorian, Persian, and Islamic. The app lets users add contacts to events and sends timely notifications to ensure they never miss important dates.

Features

	•	Multiple Calendar Support: Users can switch between Gregorian, Persian, and Islamic (Umm al-Qura) calendars. This feature ensures that events are scheduled and displayed according to the user’s cultural or regional preferences.
	•	Event Creation: Users can create events with pre-defined types (e.g., birthdays, anniversaries) or add custom events. Events can be scheduled for any selected date using the calendar picker.
	•	Contact Management: Users can associate contacts with each event, either by selecting from their phone’s contact list or manually entering names. This feature allows for flexibility in managing event participants.
	•	Notifications: RemindMe sends two daily notifications for each event: one at midnight and another at noon on the event date. This ensures that users are reminded throughout the day, helping them stay on top of their events.
	•	Data Persistence: Events are stored locally using CoreData, ensuring that all data is retained even if the app is closed. Users can also delete events from the event list.

How It Works

	1.	Select Calendar: The user can select their preferred calendar (Gregorian, Persian, or Islamic) from a segmented picker. The selected calendar will be applied to all events and the date picker.
	2.	Create an Event:
	•	Select a date from the date picker.
	•	Choose an event from pre-defined options or create a custom event.
	•	Add contacts by selecting them from the contact picker or entering their names manually.
	3.	Schedule Notifications: The app will schedule two notifications for each event, ensuring the user is reminded on the day of the event at both midnight and noon.
	4.	View and Manage Events: The main screen displays today’s events based on the selected calendar. Users can delete events or add new ones easily.

Technical Details

	•	Languages & Frameworks:
	•	Swift, SwiftUI
	•	CoreData for persistent storage
	•	Contacts and ContactsUI for contact selection and management
	•	UserNotifications for scheduling notifications
	•	Custom Calendar Support: The app dynamically switches between different calendar systems, adjusting dates and events accordingly. Special handling is provided for Islamic dates.
	•	CoreData Integration: All events are saved using CoreData, providing persistent storage across app sessions. The app loads events at startup and allows users to delete events if needed.

Future Improvements

	•	Add time-specific notifications for events (e.g., allow users to specify the exact time for the reminder).
	•	Integrate cloud sync for cross-device event management.
	•	Expand support for additional calendar systems.

Installation

	1.	Clone the repository:

git clone [repo-url]


	2.	Open the project in Xcode.
	3.	Build and run on a simulator or device running iOS 14.0 or later.
