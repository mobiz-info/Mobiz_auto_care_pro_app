import 'package:car_wash_mobile/screens/job_card/controllers/job_card_inspection_controller.dart';
import 'package:car_wash_mobile/screens/job_card/models/job_card_damage_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interior damage views have images, parts, and tappable hotspots', () {
    expect(JobCardDamageConfig.interiorDamageViews, hasLength(11));
    for (final view in JobCardDamageConfig.interiorDamageViews) {
      expect(JobCardDamageConfig.damageViewAssets[view], isNotNull);
      expect(JobCardDamageConfig.partsForView(view), isNotEmpty);
      expect(JobCardDamageConfig.damageHotspots[view], isNotEmpty);
      final hotspot = JobCardDamageConfig.damageHotspots[view]!.first;
      final center = Offset(
        (hotspot.left + hotspot.right) / 2,
        (hotspot.top + hotspot.bottom) / 2,
      );
      expect(JobCardDamageConfig.findPartAtHotspot(view, center), hotspot.part);
    }
  });

  test('damage inspection config has required damage types and severities', () {
    expect(
      JobCardDamageConfig.damageTypes,
      equals(['Scratch', 'Dent', 'Crack', 'Broken', 'Repainted']),
    );
    expect(
      JobCardDamageConfig.damageSeverities,
      equals(['Minor', 'Moderate', 'Severe']),
    );
    expect(JobCardDamageConfig.severityColor('Severe'), const Color(0xFFDC2626));
    expect(JobCardDamageConfig.severityColor('Moderate'), const Color(0xFFD97706));
    expect(JobCardDamageConfig.severityColor('Minor'), const Color(0xFF059669));
    expect(JobCardDamageConfig.damageTypeColor('Scratch'), const Color(0xFF2563EB));
  });

  test('interior damage marks persist through the existing inspection payload', () {
    final controller = JobCardInspectionController();
    controller.addDamageMark(
      view: 'Interior - Rear Cabin',
      part: 'Rear seat',
      remarks: 'Small tear on left side',
      points: const [Offset(.2, .4), Offset(.3, .5)],
    );

    final saved = controller.getInspectionPayload();
    final restored = JobCardInspectionController()
      ..loadExistingInspection(saved);

    expect(restored.damageMarks, hasLength(1));
    expect(restored.damageMarks.single['view'], 'Interior - Rear Cabin');
    expect(restored.damageMarks.single['part'], 'Rear seat');
    expect(restored.damageMarks.single['remarks'], 'Small tear on left side');
    expect(
      JobCardDamageConfig.parseDamagePoints(
        restored.damageMarks.single['points'],
      ),
      const [Offset(.2, .4), Offset(.3, .5)],
    );

    controller.dispose();
    restored.dispose();
  });

  test('enhanced damage marks support damage_type, severity, photo_url, and remarks', () {
    final controller = JobCardInspectionController();
    controller.addDamageMark(
      view: 'Front',
      part: 'Front bumper',
      damageType: 'Dent',
      severity: 'Severe',
      remarks: 'Deep dent on right side of bumper',
      photoUrl: 'data:image/jpeg;base64,samplephoto123',
      points: const [Offset(.3, .6)],
    );

    expect(controller.damageMarks, hasLength(1));
    final mark = controller.damageMarks.first;
    expect(mark['damage_type'], 'Dent');
    expect(mark['severity'], 'Severe');
    expect(mark['remarks'], 'Deep dent on right side of bumper');
    expect(mark['photo_url'], 'data:image/jpeg;base64,samplephoto123');

    // Test update
    controller.updateDamageMark(
      0,
      severity: 'Moderate',
      remarks: 'Moderate dent after closer review',
    );
    expect(controller.damageMarks.first['severity'], 'Moderate');
    expect(controller.damageMarks.first['remarks'], 'Moderate dent after closer review');

    // Test serialization & deserialization
    final payload = controller.getInspectionPayload();
    final restored = JobCardInspectionController()..loadExistingInspection(payload);

    expect(restored.damageMarks, hasLength(1));
    final restoredMark = restored.damageMarks.first;
    expect(restoredMark['view'], 'Front');
    expect(restoredMark['part'], 'Front bumper');
    expect(restoredMark['damage_type'], 'Dent');
    expect(restoredMark['severity'], 'Moderate');
    expect(restoredMark['remarks'], 'Moderate dent after closer review');
    expect(restoredMark['photo_url'], 'data:image/jpeg;base64,samplephoto123');

    controller.dispose();
    restored.dispose();
  });

  test('undo and clear operations work properly', () {
    final controller = JobCardInspectionController();

    controller.addDamageMark(
      view: 'Front',
      part: 'Bonnet',
      damageType: 'Scratch',
      severity: 'Minor',
      remarks: 'Light scratch',
      points: const [Offset(.4, .5)],
    );
    controller.addDamageMark(
      view: 'Rear',
      part: 'Boot',
      damageType: 'Dent',
      severity: 'Moderate',
      remarks: 'Small dent',
      points: const [Offset(.5, .5)],
    );
    controller.addDamageMark(
      view: 'Front',
      part: 'Front grille',
      damageType: 'Crack',
      severity: 'Severe',
      remarks: 'Cracked plastic',
      points: const [Offset(.45, .55)],
    );

    expect(controller.damageMarks, hasLength(3));

    // Undo for 'Front' view removes the last mark for 'Front' (grille)
    controller.undoDamageMark(view: 'Front');
    expect(controller.damageMarks, hasLength(2));
    expect(controller.damageMarks.any((m) => m['part'] == 'Front grille'), isFalse);

    // Clear marks for 'Rear' view removes the Rear mark
    controller.clearDamageMarksForView('Rear');
    expect(controller.damageMarks, hasLength(1));
    expect(controller.damageMarks.first['part'], 'Bonnet');

    // Clear all marks
    controller.clearAllDamageMarks();
    expect(controller.damageMarks, isEmpty);

    controller.dispose();
  });
}
