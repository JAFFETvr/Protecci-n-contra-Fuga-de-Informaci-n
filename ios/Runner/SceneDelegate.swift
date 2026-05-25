import Flutter
import UIKit
import CoreLocation

class SceneDelegate: FlutterSceneDelegate, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private weak var mainWindow: UIWindow?
    private var fakeGpsOverlay: UIView?
    private var fakeGpsDetected = false

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        guard let windowScene = scene as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        mainWindow = window

        // Aplicar protección anti-captura después de que el layout esté listo
        DispatchQueue.main.async {
            self.applyScreenshotProtection(to: window)
            self.startFakeGpsMonitoring()
        }
    }

    private func startFakeGpsMonitoring() {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        locationManager = manager

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        handleLocationAuthorization(status)
    }

    private func handleLocationAuthorization(_ status: CLAuthorizationStatus) {
        guard let manager = locationManager else { return }
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleLocationAuthorization(manager.authorizationStatus)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        handleLocationAuthorization(status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !fakeGpsDetected, let location = locations.last else { return }
        if #available(iOS 15.0, *),
           let info = location.sourceInformation,
           info.isSimulatedBySoftware {
            fakeGpsDetected = true
            manager.stopUpdatingLocation()
            if let window = mainWindow {
                DispatchQueue.main.async {
                    self.showFakeGpsOverlay(on: window)
                }
            }
        }
    }

    private func showFakeGpsOverlay(on window: UIWindow) {
        guard fakeGpsOverlay == nil else { return }

        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = true
        overlay.accessibilityViewIsModal = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "GPS falso detectado.\nNo puedes usar la app."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .semibold)

        overlay.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -24),
        ])

        window.addSubview(overlay)
        fakeGpsOverlay = overlay
    }

   
    private func applyScreenshotProtection(to window: UIWindow) {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        window.addSubview(field)

        window.layer.superlayer?.addSublayer(field.layer)

        guard let secureLayer = field.layer.sublayers?.last else { return }

        let screenBounds = UIScreen.main.bounds
        field.layer.frame = screenBounds
        secureLayer.frame = CGRect(origin: .zero, size: screenBounds.size)

        secureLayer.addSublayer(window.layer)
        window.layer.frame = CGRect(origin: .zero, size: screenBounds.size)
    }
}
