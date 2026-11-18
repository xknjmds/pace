import 'package:flutter/material.dart';

/// After a removal: says what went and offers Undo.
///
/// Deletes in PACE are soft, so undo is cheap and nothing needs an
/// "Are you sure?" first. The snack stays until it is used or closed (no
/// timer to race), and a new one replaces it, so deletes never queue up.
void showUndo(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        showCloseIcon: true,
        action: SnackBarAction(label: 'Undo', onPressed: onUndo),
      ),
    );
}

/// "‘Lab report’", trimmed so a long title still fits a snack line.
String quoted(String text, {int max = 40}) {
  final t = text.trim();
  final short = t.length > max ? '${t.substring(0, max - 1)}…' : t;
  return '‘$short’';
}
