import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'data/ml/spam_ml_scorer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop FFI support for Windows/Linux/macOS
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-load bundled GBDT ML model weights
  await SpamMLScorer.instance.loadBundledAsset();

  runApp(const CallShieldApp());
}
