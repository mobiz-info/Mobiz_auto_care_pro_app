class JobCardConstants {
  static const List<String> defaultSections = [
    'General Inspection',
    'Washing & Cleaning',
    'Detailing & Polishing',
    'Mechanical & Service',
    'Electrical & AC',
    'Bodyshop & Denting',
    'Painting',
    'Quality Inspection',
    'Ready for Delivery',
  ];

  static double numberOrZero(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    return double.tryParse(value.toString().trim()) ?? fallback;
  }

  static String lookupName(List<dynamic> values, String id) {
    if (id.isEmpty) return '';
    for (final item in values) {
      if (item is Map && item['id']?.toString() == id) {
        return (item['name'] ?? '').toString();
      }
    }
    return '';
  }
}

double numberOrZero(dynamic value, {double fallback = 0}) =>
    JobCardConstants.numberOrZero(value, fallback: fallback);

String lookupName(List<dynamic> values, String id) =>
    JobCardConstants.lookupName(values, id);
