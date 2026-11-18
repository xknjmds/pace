import 'package:flutter/material.dart';

import '../time/local_time.dart';

/// A time of day (minutes since midnight) shown as a button that opens the
/// system time picker. Null shows [placeholder].
class TimeButton extends StatelessWidget {
  const TimeButton({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.placeholder = 'Set time',
  });

  final int? minutes;
  final ValueChanged<int> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () async {
      final m = minutes ?? 8 * 60;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      );
      if (picked != null) onChanged(picked.hour * 60 + picked.minute);
    },
    child: Text(minutes == null ? placeholder : LocalTime(minutes!).format24()),
  );
}

/// "08:00–09:30".
String formatSpan(int start, int end) =>
    '${LocalTime(start % LocalTime.minutesPerDay).format24()}–'
    '${LocalTime(end % LocalTime.minutesPerDay).format24()}';
