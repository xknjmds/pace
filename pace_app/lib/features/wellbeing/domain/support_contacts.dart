/// One place to reach a person. Bundled with the app, so it works offline.
class SupportContact {
  const SupportContact({required this.name, required this.numbers, this.note});

  final String name;
  final List<String> numbers;
  final String? note;
}

/// Philippine crisis lines. The owner must check every number before each
/// release (NOTES.md, Phase D): numbers change, and a wrong one here does
/// real harm.
const supportContacts = [
  SupportContact(
    name: 'Emergency',
    numbers: ['911'],
    note: 'If you or someone else is in danger right now.',
  ),
  SupportContact(
    name: 'NCMH Crisis Hotline',
    numbers: ['1553', '0917 899 8727', '0966 351 4518', '0908 639 2672'],
    note: 'National Center for Mental Health. Free, 24 hours.',
  ),
  SupportContact(
    name: 'Hopeline PH',
    numbers: ['(02) 8804 4673', '0917 558 4673', '2919 (Globe and TM)'],
    note: '24 hours.',
  ),
];
