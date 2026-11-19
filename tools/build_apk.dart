#!/usr/bin/env dart
// tools/build_apk.dart
//
// Run this script from the Flutter project root:
//   dart tools/build_apk.dart
//
// It will:
//   1. Run "flutter build apk --release"
//   2. Read the app version from pubspec.yaml
//   3. Ensure the output APK is named "Mobiz auto care pro v [Version].apk" in build/app/outputs/flutter-apk/

import 'dart:io';

void main() async {
  print('🚀 Starting Flutter Release APK Build...');
  print('');

  // 1. Run flutter build apk --release
  final process = await Process.start(
    'flutter',
    ['build', 'apk', '--release'],
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('');
    print('❌ Flutter build failed with exit code $exitCode');
    exit(exitCode);
  }

  // 2. Read version from pubspec.yaml
  var version = '1.6.8';
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final lines = pubspecFile.readAsLinesSync();
    for (final line in lines) {
      if (line.trim().startsWith('version:')) {
        version = line.split(':')[1].trim().split('+')[0];
        break;
      }
    }
  }

  final finalName = 'Mobiz auto care pro v $version.apk';
  final dir = Directory('build/app/outputs/flutter-apk');
  final destFile = File('${dir.path}/$finalName');

  // Handle various potential output names from gradle
  if (!destFile.existsSync() && dir.existsSync()) {
    final appRelease = File('${dir.path}/app-release.apk');
    if (appRelease.existsSync()) {
      appRelease.copySync(destFile.path);
    } else {
      final apks = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.apk')).toList();
      apks.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (apks.isNotEmpty) {
        apks.first.copySync(destFile.path);
      }
    }
  }

  if (destFile.existsSync()) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🎉 APK Built & Ready!');
    print('═══════════════════════════════════════════════════════');
    print('📂 Filename: $finalName');
    print('📂 Location: ${destFile.path}');
    print('═══════════════════════════════════════════════════════');
    print('');
  } else {
    print('❌ Error: Could not locate built APK in ${dir.path}');
  }
}
