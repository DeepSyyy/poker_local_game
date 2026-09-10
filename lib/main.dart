import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:belajar_flutter/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sembunyikan status bar & navigasi (Fullscreen Immersive Mode)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Kunci orientasi layar ke Landscape untuk simulator meja poker
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}
