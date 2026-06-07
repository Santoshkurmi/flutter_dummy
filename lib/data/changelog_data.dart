class ChangelogVersion {
  final String version;
  final String date;
  final List<String> logs;

  const ChangelogVersion({
    required this.version,
    required this.date,
    required this.logs,
  });
}
//add Latest one at top not bottom
class ChangelogData {
  static const List<ChangelogVersion> versions = [
     ChangelogVersion(
      version: '1.0.1',
      date: '2082-02-26',
      logs: [
        'Some minor bugs fixes',
      ],
    ),
    ChangelogVersion(
      version: '1.0.0',
      date: '2082-02-22',
      logs: [
        'Initial release of Bright Sahakari Mobile Banking application.',
        'Supports savings accounts overview, statements, and rate logs.',
        'Integrated scanner feature for secure QR payments.',
        'Enabled biometric fingerprint/Face ID authorization setup.',
        'Added biometric credential database change key invalidation and reset flow on iOS and Android.',
        'Added dynamic Face ID detection and icon changes for Apple devices.',
      ],
    ),
  ];
}
