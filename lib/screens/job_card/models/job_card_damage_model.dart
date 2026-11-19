import 'package:flutter/material.dart';

class DamageHotspot {
  final String part;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const DamageHotspot(this.part, this.left, this.top, this.right, this.bottom);

  Rect get bounds => Rect.fromLTRB(left, top, right, bottom);
}

class JobCardDamageConfig {
  static const List<String> damageViews = [
    'Front',
    'Rear',
    'Left',
    'Right',
    'Top',
    'Bottom',
  ];

  static const List<String> interiorDamageViews = [
    'Interior - Front Seats',
    'Interior - Back Seat',
    'Interior - Roof',
    'Interior - Front Left Door',
    'Interior - Front Right Door',
    'Interior - Rear Left Door',
    'Interior - Rear Right Door',
    'Interior - Floor Mats',
    'Interior - Seat Cover',
    'Interior - Dashboard',
    'Interior - Controls',
  ];

  static const Map<String, String> damageViewAssets = {
    'Front': 'assets/inspection/front.png',
    'Rear': 'assets/inspection/rear.png',
    'Left': 'assets/inspection/left.png',
    'Right': 'assets/inspection/right.png',
    'Top': 'assets/inspection/top.png',
    'Bottom': 'assets/inspection/bottom.png',
    'Interior': 'assets/inspection/interior_dashboard.png',
    'Interior - Front Seats': 'assets/inspection/interior_front_seats.png',
    'Interior - Back Seat': 'assets/inspection/interior_rear_cabin.png',
    'Interior - Roof': 'assets/inspection/interior_roof.png',
    'Interior - Front Left Door':
        'assets/inspection/interior_front_left_door.png',
    'Interior - Front Right Door':
        'assets/inspection/interior_front_right_door.png',
    'Interior - Rear Left Door':
        'assets/inspection/interior_rear_left_door.png',
    'Interior - Rear Right Door':
        'assets/inspection/interior_rear_right_door.png',
    'Interior - Floor Mats': 'assets/inspection/interior_floor_mats.png',
    'Interior - Seat Cover': 'assets/inspection/interior_seat_cover.png',
    'Interior - Dashboard': 'assets/inspection/interior_dashboard.png',
    'Interior - Controls': 'assets/inspection/interior_controls.png',
    'Interior - Passenger Side': 'assets/inspection/interior_passenger.png',
    'Interior - Rear Cabin': 'assets/inspection/interior_rear_cabin.png',
    'Interior - Floor and Console':
        'assets/inspection/interior_floor_console.png',
  };

  static const Map<String, double> damageViewAspectRatios = {
    'Interior': 2.06,
    'Interior - Front Seats': 2.06,
    'Interior - Back Seat': 2.06,
    'Interior - Roof': 2.06,
    'Interior - Front Left Door': 2.06,
    'Interior - Front Right Door': 2.06,
    'Interior - Rear Left Door': 2.06,
    'Interior - Rear Right Door': 2.06,
    'Interior - Floor Mats': 2.06,
    'Interior - Seat Cover': 2.06,
    'Interior - Dashboard': 2.06,
    'Interior - Controls': 2.06,
    'Interior - Passenger Side': 2.06,
    'Interior - Rear Cabin': 2.06,
    'Interior - Floor and Console': 2.06,
  };

  static const Map<String, List<String>> partsByView = {
    'Front': [
      'Bonnet',
      'Front bumper',
      'Front grille',
      'Left headlight',
      'Right headlight',
      'Front left tyre',
      'Front right tyre',
      'Windshield',
      'Other',
    ],
    'Rear': [
      'Boot',
      'Rear bumper',
      'Left tail light',
      'Right tail light',
      'Rear left tyre',
      'Rear right tyre',
      'Rear glass',
      'Other',
    ],
    'Left': [
      'Front left tyre',
      'Rear left tyre',
      'Left front door',
      'Left rear door',
      'Left front fender',
      'Left rear quarter panel',
      'Left mirror',
      'Left rocker panel',
      'Other',
    ],
    'Right': [
      'Front right tyre',
      'Rear right tyre',
      'Right front door',
      'Right rear door',
      'Right front fender',
      'Right rear quarter panel',
      'Right mirror',
      'Right rocker panel',
      'Other',
    ],
    'Top': [
      'Roof',
      'Bonnet',
      'Boot',
      'Windshield',
      'Rear glass',
      'Front left tyre',
      'Front right tyre',
      'Rear left tyre',
      'Rear right tyre',
      'Other',
    ],
    'Bottom': [
      'Undercarriage',
      'Exhaust',
      'Front suspension',
      'Rear suspension',
      'Fuel tank',
      'Other',
    ],
    'Interior': [
      'Dashboard',
      'Steering wheel',
      'Front seat',
      'Rear seat',
      'Door trim',
      'Carpet',
      'Ceiling liner',
      'Infotainment',
      'Other interior part',
    ],
    'Interior - Dashboard': [
      'Dashboard',
      'Windshield',
      'Dashboard vents',
      'Glove box',
      'Infotainment screen',
      'Other interior part',
    ],
    'Interior - Controls': [
      'Steering wheel',
      'Instrument cluster',
      'Steering controls',
      'Center controls',
      'Gear selector',
      'Other interior part',
    ],
    'Interior - Front Seats': [
      'Driver seat',
      'Front passenger seat',
      'Seat belt',
      'Headrest',
      'Door trim',
      'Seat cover',
      'Other interior part',
    ],
    'Interior - Back Seat': [
      'Rear seat',
      'Seat cover',
      'Rear seat belt',
      'Rear door trim',
      'Rear parcel shelf',
      'Headrest',
      'Other interior part',
    ],
    'Interior - Roof': [
      'Headliner',
      'Sunroof glass',
      'Overhead console',
      'Dome light',
      'Left sun visor',
      'Right sun visor',
      'Rearview mirror',
      'Other interior part',
    ],
    'Interior - Front Left Door': [
      'Door handle',
      'Window switch',
      'Armrest',
      'Door trim',
      'Speaker grille',
      'Door pocket',
      'Mirror control',
      'Other interior part',
    ],
    'Interior - Front Right Door': [
      'Door handle',
      'Window switch',
      'Armrest',
      'Door trim',
      'Speaker grille',
      'Door pocket',
      'Mirror control',
      'Other interior part',
    ],
    'Interior - Rear Left Door': [
      'Door handle',
      'Window switch',
      'Armrest',
      'Door trim',
      'Speaker grille',
      'Door pocket',
      'Other interior part',
    ],
    'Interior - Rear Right Door': [
      'Door handle',
      'Window switch',
      'Armrest',
      'Door trim',
      'Speaker grille',
      'Door pocket',
      'Other interior part',
    ],
    'Interior - Floor Mats': [
      'Floor mat',
      'Accelerator pedal',
      'Brake pedal',
      'Footrest',
      'Door sill plate',
      'Carpet',
      'Other interior part',
    ],
    'Interior - Seat Cover': [
      'Seat cover',
      'Headrest',
      'Backrest cushion',
      'Side bolster',
      'Seat bottom cushion',
      'Seat adjustment switch',
      'Seat belt buckle',
      'Other interior part',
    ],
    'Interior - Passenger Side': [
      'Front passenger seat',
      'Passenger door trim',
      'Glove box',
      'Seat belt',
      'Other interior part',
    ],
    'Interior - Rear Cabin': [
      'Rear seat',
      'Rear seat belt',
      'Rear door trim',
      'Rear parcel shelf',
      'Other interior part',
    ],
    'Interior - Floor and Console': [
      'Front carpet',
      'Rear carpet',
      'Center console',
      'Gear selector',
      'Cup holder',
      'Other interior part',
    ],
  };

  static const Map<String, List<DamageHotspot>> damageHotspots = {
    'Front': [
      DamageHotspot('Bonnet', .25, .40, .75, .62),
      DamageHotspot('Front bumper', .24, .62, .76, .82),
      DamageHotspot('Front grille', .35, .54, .65, .68),
      DamageHotspot('Left headlight', .15, .45, .36, .59),
      DamageHotspot('Right headlight', .64, .45, .85, .59),
      DamageHotspot('Front left tyre', .12, .72, .33, .91),
      DamageHotspot('Front right tyre', .67, .72, .88, .91),
      DamageHotspot('Windshield', .25, .20, .75, .43),
    ],
    'Rear': [
      DamageHotspot('Rear glass', .28, .18, .72, .42),
      DamageHotspot('Boot', .27, .40, .73, .62),
      DamageHotspot('Rear bumper', .24, .62, .76, .82),
      DamageHotspot('Left tail light', .14, .40, .36, .56),
      DamageHotspot('Right tail light', .64, .40, .86, .56),
      DamageHotspot('Rear left tyre', .12, .72, .33, .91),
      DamageHotspot('Rear right tyre', .67, .72, .88, .91),
    ],
    'Left': [
      DamageHotspot('Rear left tyre', .13, .48, .39, .72),
      DamageHotspot('Front left tyre', .62, .48, .90, .72),
      DamageHotspot('Left rear door', .39, .42, .58, .61),
      DamageHotspot('Left front door', .57, .42, .76, .61),
      DamageHotspot('Left rear quarter panel', .10, .39, .31, .60),
      DamageHotspot('Left front fender', .76, .39, .94, .60),
      DamageHotspot('Left mirror', .72, .31, .84, .48),
      DamageHotspot('Left rocker panel', .32, .59, .72, .68),
    ],
    'Right': [
      DamageHotspot('Front right tyre', .10, .48, .38, .72),
      DamageHotspot('Rear right tyre', .62, .48, .90, .72),
      DamageHotspot('Right front door', .25, .42, .45, .61),
      DamageHotspot('Right rear door', .44, .42, .63, .61),
      DamageHotspot('Right front fender', .07, .39, .27, .60),
      DamageHotspot('Right rear quarter panel', .69, .39, .94, .60),
      DamageHotspot('Right mirror', .16, .31, .28, .48),
      DamageHotspot('Right rocker panel', .30, .59, .70, .68),
    ],
    'Top': [
      DamageHotspot('Bonnet', .34, .20, .66, .40),
      DamageHotspot('Windshield', .32, .38, .68, .48),
      DamageHotspot('Roof', .33, .48, .67, .70),
      DamageHotspot('Rear glass', .32, .68, .68, .78),
      DamageHotspot('Boot', .34, .76, .66, .88),
      DamageHotspot('Front left tyre', .18, .25, .34, .39),
      DamageHotspot('Front right tyre', .66, .25, .82, .39),
      DamageHotspot('Rear left tyre', .18, .64, .34, .78),
      DamageHotspot('Rear right tyre', .66, .64, .82, .78),
    ],
    'Bottom': [
      DamageHotspot('Undercarriage', .20, .25, .80, .75),
      DamageHotspot('Exhaust', .30, .42, .72, .58),
      DamageHotspot('Front suspension', .15, .16, .85, .32),
      DamageHotspot('Rear suspension', .15, .68, .85, .84),
      DamageHotspot('Fuel tank', .35, .35, .65, .52),
    ],
    'Interior - Dashboard': [
      DamageHotspot('Dashboard', .08, .35, .92, .74),
      DamageHotspot('Windshield', .05, .03, .95, .32),
      DamageHotspot('Dashboard vents', .32, .42, .70, .56),
      DamageHotspot('Glove box', .63, .56, .91, .75),
      DamageHotspot('Infotainment screen', .42, .37, .60, .55),
    ],
    'Interior - Controls': [
      DamageHotspot('Steering wheel', .12, .08, .48, .92),
      DamageHotspot('Instrument cluster', .32, .12, .68, .44),
      DamageHotspot('Steering controls', .18, .43, .45, .66),
      DamageHotspot('Center controls', .58, .20, .96, .66),
      DamageHotspot('Gear selector', .57, .66, .78, .96),
    ],
    'Interior - Front Seats': [
      DamageHotspot('Driver seat', .08, .08, .49, .93),
      DamageHotspot('Front passenger seat', .50, .08, .91, .93),
      DamageHotspot('Seat belt', .38, .12, .68, .79),
      DamageHotspot('Headrest', .13, .08, .83, .35),
      DamageHotspot('Door trim', .02, .18, .16, .78),
      DamageHotspot('Seat cover', .10, .25, .85, .90),
    ],
    'Interior - Back Seat': [
      DamageHotspot('Rear seat', .14, .25, .86, .92),
      DamageHotspot('Seat cover', .15, .30, .85, .88),
      DamageHotspot('Rear seat belt', .20, .08, .81, .74),
      DamageHotspot('Headrest', .25, .08, .75, .25),
      DamageHotspot('Rear door trim', .02, .10, .22, .73),
      DamageHotspot('Rear parcel shelf', .23, .05, .78, .27),
    ],
    'Interior - Roof': [
      DamageHotspot('Sunroof glass', .15, .00, .85, .26),
      DamageHotspot('Headliner', .05, .24, .95, .65),
      DamageHotspot('Overhead console', .40, .35, .60, .62),
      DamageHotspot('Dome light', .42, .52, .58, .62),
      DamageHotspot('Left sun visor', .05, .42, .38, .60),
      DamageHotspot('Right sun visor', .62, .42, .95, .60),
      DamageHotspot('Rearview mirror', .42, .66, .58, .78),
    ],
    'Interior - Front Left Door': [
      DamageHotspot('Door handle', .50, .14, .70, .26),
      DamageHotspot('Door trim', .18, .28, .80, .52),
      DamageHotspot('Armrest', .22, .48, .68, .62),
      DamageHotspot('Window switch', .44, .49, .56, .55),
      DamageHotspot('Door pocket', .22, .62, .66, .78),
      DamageHotspot('Speaker grille', .60, .60, .80, .79),
    ],
    'Interior - Front Right Door': [
      DamageHotspot('Door handle', .30, .14, .50, .26),
      DamageHotspot('Door trim', .20, .28, .82, .52),
      DamageHotspot('Armrest', .32, .48, .78, .62),
      DamageHotspot('Window switch', .44, .49, .56, .55),
      DamageHotspot('Door pocket', .34, .62, .78, .78),
      DamageHotspot('Speaker grille', .20, .60, .40, .79),
    ],
    'Interior - Rear Left Door': [
      DamageHotspot('Door handle', .52, .16, .70, .28),
      DamageHotspot('Door trim', .28, .30, .78, .52),
      DamageHotspot('Armrest', .32, .48, .70, .62),
      DamageHotspot('Window switch', .52, .49, .60, .54),
      DamageHotspot('Door pocket', .34, .62, .68, .78),
      DamageHotspot('Speaker grille', .60, .60, .78, .79),
    ],
    'Interior - Rear Right Door': [
      DamageHotspot('Door handle', .30, .16, .48, .28),
      DamageHotspot('Door trim', .22, .30, .72, .52),
      DamageHotspot('Armrest', .30, .48, .68, .62),
      DamageHotspot('Window switch', .40, .49, .48, .54),
      DamageHotspot('Door pocket', .32, .62, .66, .78),
      DamageHotspot('Speaker grille', .22, .60, .40, .79),
    ],
    'Interior - Floor Mats': [
      DamageHotspot('Floor mat', .24, .24, .80, .96),
      DamageHotspot('Brake pedal', .34, .12, .44, .28),
      DamageHotspot('Accelerator pedal', .43, .08, .49, .22),
      DamageHotspot('Footrest', .18, .18, .32, .52),
      DamageHotspot('Door sill plate', .15, .74, .34, .99),
      DamageHotspot('Carpet', .52, .32, .88, .88),
    ],
    'Interior - Seat Cover': [
      DamageHotspot('Headrest', .62, .02, .75, .25),
      DamageHotspot('Backrest cushion', .52, .32, .72, .72),
      DamageHotspot('Side bolster', .49, .36, .60, .68),
      DamageHotspot('Seat bottom cushion', .32, .62, .64, .86),
      DamageHotspot('Seat adjustment switch', .50, .76, .61, .88),
      DamageHotspot('Seat belt buckle', .46, .61, .51, .69),
      DamageHotspot('Seat cover', .32, .10, .76, .88),
    ],
    'Interior - Passenger Side': [
      DamageHotspot('Front passenger seat', .32, .14, .88, .91),
      DamageHotspot('Passenger door trim', .02, .09, .37, .54),
      DamageHotspot('Glove box', .42, .37, .78, .62),
      DamageHotspot('Seat belt', .24, .08, .68, .80),
    ],
    'Interior - Rear Cabin': [
      DamageHotspot('Rear seat', .14, .25, .86, .92),
      DamageHotspot('Rear seat belt', .20, .08, .81, .74),
      DamageHotspot('Rear door trim', .02, .10, .22, .73),
      DamageHotspot('Rear parcel shelf', .23, .05, .78, .27),
    ],
    'Interior - Floor and Console': [
      DamageHotspot('Front carpet', .02, .56, .42, .98),
      DamageHotspot('Rear carpet', .60, .56, .98, .98),
      DamageHotspot('Center console', .35, .02, .66, .69),
      DamageHotspot('Gear selector', .42, .22, .58, .56),
      DamageHotspot('Cup holder', .61, .25, .79, .57),
    ],
  };

  static List<String> partsForView(String view) {
    return partsByView[view] ?? partsByView['Interior']!;
  }

  static List<Offset> parseDamagePoints(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (point) => Offset(
            (point['x'] as num?)?.toDouble() ?? 0,
            (point['y'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  static Offset calculateStrokeCenter(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    final sum = points.fold<Offset>(Offset.zero, (total, p) => total + p);
    return sum / points.length.toDouble();
  }

  static String? findPartAtHotspot(String view, Offset point) {
    for (final spot in damageHotspots[view] ?? const <DamageHotspot>[]) {
      if (spot.bounds.contains(point)) return spot.part;
    }
    return null;
  }

  static const List<String> damageTypes = [
    'Scratch',
    'Dent',
    'Crack',
    'Broken',
    'Repainted',
  ];

  static const List<String> damageSeverities = [
    'Minor',
    'Moderate',
    'Severe',
  ];

  static Color severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'severe':
        return const Color(0xFFDC2626); // Red
      case 'moderate':
        return const Color(0xFFD97706); // Amber / Deep Orange
      case 'minor':
      default:
        return const Color(0xFF059669); // Emerald Green
    }
  }

  static Color severityBgColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'severe':
        return const Color(0xFFFEE2E2);
      case 'moderate':
        return const Color(0xFFFEF3C7);
      case 'minor':
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  static Color damageTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'scratch':
        return const Color(0xFF2563EB); // Blue
      case 'dent':
        return const Color(0xFF7C3AED); // Purple
      case 'crack':
        return const Color(0xFFEA580C); // Orange-Red
      case 'broken':
        return const Color(0xFFDC2626); // Red
      case 'repainted':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFF475569); // Slate
    }
  }

  static Color damageTypeBgColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'scratch':
        return const Color(0xFFEFF6FF);
      case 'dent':
        return const Color(0xFFF5F3FF);
      case 'crack':
        return const Color(0xFFFFF7ED);
      case 'broken':
        return const Color(0xFFFEF2F2);
      case 'repainted':
        return const Color(0xFFF0FDFA);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}
