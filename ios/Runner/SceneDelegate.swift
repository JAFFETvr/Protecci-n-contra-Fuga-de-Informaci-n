import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        guard let windowScene = scene as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        // Aplicar protección anti-captura después de que el layout esté listo
        DispatchQueue.main.async {
            self.applyScreenshotProtection(to: window)
        }
    }

    // Técnica UITextField isSecureTextEntry: iOS excluye los layers de un campo
    // seguro de capturas y grabaciones de pantalla (igual que WhatsApp).
    // El window.layer se re-parentea dentro del secureLayer con frames explícitos
    // para que no cambie su posición visible en pantalla.
    private func applyScreenshotProtection(to window: UIWindow) {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        window.addSubview(field)

        // Subir el layer del field al nivel de la pantalla (sibling del window.layer)
        window.layer.superlayer?.addSublayer(field.layer)

        // El último sublayer de un UITextField secure ES el layer protegido por iOS
        guard let secureLayer = field.layer.sublayers?.last else { return }

        // Darle el frame completo de la pantalla para que window.layer quede en (0,0)
        let screenBounds = UIScreen.main.bounds
        field.layer.frame = screenBounds
        secureLayer.frame = CGRect(origin: .zero, size: screenBounds.size)

        // Mover window.layer dentro del secureLayer y fijar su frame
        secureLayer.addSublayer(window.layer)
        window.layer.frame = CGRect(origin: .zero, size: screenBounds.size)
    }
}
