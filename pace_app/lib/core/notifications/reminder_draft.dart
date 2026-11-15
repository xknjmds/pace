/// A reminder that is about to be scheduled: when, and what it says.
/// Pure Dart so planners can build these without touching the database.
typedef ReminderDraft = ({DateTime fireAt, String title, String body});
