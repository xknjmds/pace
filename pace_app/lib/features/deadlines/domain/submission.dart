/// Pure: whether [submittedAt] came after [dueAt]. Derived, never stored,
/// and only ever shown as a neutral count.
bool isLateSubmission({
  required DateTime dueAt,
  required DateTime submittedAt,
}) => submittedAt.isAfter(dueAt);

/// Pure: how many of [tasks] were submitted after their due time. Entries
/// with no submission time are skipped.
int countLateSubmissions(
  Iterable<({DateTime dueAt, DateTime? submittedAt})> tasks,
) => tasks
    .where(
      (t) =>
          t.submittedAt != null &&
          isLateSubmission(dueAt: t.dueAt, submittedAt: t.submittedAt!),
    )
    .length;
