/// Extra steps some Android brands need before reminders arrive reliably.
/// Many phones popular in the Philippines stop background apps on their own,
/// beyond Android's battery optimisation.
class PhoneMakerGuide {
  const PhoneMakerGuide({
    required this.brand,
    required this.steps,
    this.hasAutoStartPage = false,
  });

  /// As people know it ("Xiaomi, Redmi or POCO").
  final String brand;

  /// Short, plain steps, in order.
  final List<String> steps;

  /// The brand has an auto-start list the app can try to open directly.
  final bool hasAutoStartPage;
}

const _lockRecents =
    'In the recent apps view, press and hold PACE and lock it, so '
    'clearing recents never closes it.';

/// Pure: the guide for a phone maker (Android's `Build.MANUFACTURER`), or
/// null when the brand needs nothing beyond the standard steps.
PhoneMakerGuide? guideFor(String manufacturer) {
  final m = manufacturer.trim().toLowerCase();
  if (m.isEmpty) return null;
  if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
    return const PhoneMakerGuide(
      brand: 'Xiaomi, Redmi or POCO',
      hasAutoStartPage: true,
      steps: [
        'Turn on Autostart for PACE.',
        'In App info, Battery saver: choose No restrictions.',
        _lockRecents,
      ],
    );
  }
  if (m.contains('oppo') || m.contains('realme') || m.contains('oneplus')) {
    return const PhoneMakerGuide(
      brand: 'OPPO, realme or OnePlus',
      hasAutoStartPage: true,
      steps: [
        'Allow PACE to auto-launch (or start in the background).',
        'In App info, Battery: allow background activity.',
        _lockRecents,
      ],
    );
  }
  if (m.contains('vivo') || m.contains('iqoo')) {
    return const PhoneMakerGuide(
      brand: 'vivo',
      hasAutoStartPage: true,
      steps: [
        'Allow PACE to auto-start.',
        'In Battery, allow high background power use for PACE.',
        _lockRecents,
      ],
    );
  }
  if (m.contains('infinix') || m.contains('tecno') || m.contains('itel')) {
    return const PhoneMakerGuide(
      brand: 'Infinix, TECNO or itel',
      hasAutoStartPage: true,
      steps: [
        'In Phone Master, allow PACE to auto-start.',
        'Turn off power saving for PACE.',
        _lockRecents,
      ],
    );
  }
  if (m.contains('huawei') || m.contains('honor')) {
    return const PhoneMakerGuide(
      brand: 'Huawei or Honor',
      hasAutoStartPage: true,
      steps: [
        'In App launch, set PACE to Manage manually and turn on all three '
            'switches.',
        _lockRecents,
      ],
    );
  }
  if (m.contains('samsung')) {
    return const PhoneMakerGuide(
      brand: 'Samsung',
      steps: [
        'In App info, Battery: choose Unrestricted.',
        'In Device care, Battery, Background usage limits: add PACE to '
            'Never sleeping apps.',
      ],
    );
  }
  return null;
}
