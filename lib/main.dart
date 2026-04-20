import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 未キャッチの例外をすべてログに出力
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
    return false;
  };

  // ネイティブ起動画面が表示されている間にルート判定
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool('onboarding_completed') ?? false;
  final initialRoute = completed ? '/home' : '/onboarding';

  runApp(App(initialRoute: initialRoute));
}
