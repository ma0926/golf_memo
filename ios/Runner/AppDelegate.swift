import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Flutterエンジン初期化中の白い画面を防ぐ（スプラッシュ背景色 #E6EAEE に合わせる）
    if let controller = window?.rootViewController as? FlutterViewController {
      controller.view.backgroundColor = UIColor(
        red: 230.0 / 255.0,
        green: 234.0 / 255.0,
        blue: 238.0 / 255.0,
        alpha: 1.0
      )
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
