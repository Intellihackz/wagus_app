import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wagus/app.dart';
import 'package:wagus/services/privy_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Load environment variables
  await dotenv.load(fileName: "lib/.env");

  await Firebase.initializeApp();

  // Initialize Privy service
  await PrivyService().initialize();

  runApp(const App());
}
