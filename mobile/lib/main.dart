import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/app/app.dart';
import 'package:ufuq_imperium/app/app_providers.dart';
import 'package:ufuq_imperium/core/firebase/firebase_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await FirebaseSetup.init();

  runApp(const AppProviders(child: UfuqApp()));
}
