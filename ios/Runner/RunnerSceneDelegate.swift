import FirebaseAuth
import Flutter
import UIKit

@available(iOS 13.0, *)
@objc(RunnerSceneDelegate)
class RunnerSceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for urlContext in URLContexts {
      if Auth.auth().canHandle(urlContext.url) {
        NSLog("FirebaseAuth handled scene auth callback URL: \(urlContext.url.absoluteString)")
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
