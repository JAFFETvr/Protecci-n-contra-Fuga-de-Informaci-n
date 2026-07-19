# SSL/TLS Pinning — Guía de implementación y prueba

Guía práctica de lo que se implementó para la actividad de protección contra
ataques Man-in-the-Middle (MitM), y cómo correrlo y probarlo en un dispositivo
Android real.

## 1. Qué se implementó

| Archivo | Qué hace |
|---|---|
| `lib/services/network_service.dart` | Cliente HTTP (`dio`) con SSL Pinning. Expone `configure(pinningEnabled: bool)` y `getSecure(path)`. |
| `assets/certs/jsonplaceholder.pem` | Certificado real del servidor de prueba (`jsonplaceholder.typicode.com`), extraído con `openssl`. |
| `lib/screens/security_demo_screen.dart` | Nueva pestaña **"SSL Pinning"** con un switch on/off y un botón para probar la conexión. |
| `pubspec.yaml` | Dependencia `dio` + registro del certificado como asset. |

API de prueba: `https://jsonplaceholder.typicode.com` (endpoint usado: `GET /todos/1`).

## 2. Cómo funciona el pinning (por qué está hecho así)

**Con pinning activado:** se crea un `SecurityContext(withTrustedRoots: false)`
que solo confía en el certificado del `.pem` pineado, ignorando el almacén de
confianza del sistema operativo. Cualquier certificado que no sea exactamente
ese (por ejemplo, uno generado al vuelo por un proxy MitM) hace fallar el
handshake TLS.

> **Por qué no basta con `badCertificateCallback` sobre un `HttpClient()`
> normal:** esa función solo se dispara cuando la validación por defecto
> *falla*. Proxies como Charles o HTTP Toolkit funcionan instalando su propia
> CA como confiable en el dispositivo — si el sistema ya confía en ella, la
> validación nunca falla y el callback no se ejecuta, así que el pinning no
> detectaría nada. Por eso se usa un `SecurityContext` acotado que ignora ese
> almacén de confianza por completo.

**Con pinning desactivado:** se usa un `HttpClient()` que acepta
explícitamente cualquier certificado (`badCertificateCallback = (c,h,p) =>
true`). Esto es intencional y reproduce el patrón real de vulnerabilidad: en
Android/iOS, Flutter (`dart:io`) **no** usa el almacén de certificados del
sistema operativo ni los certificados "de usuario" instalados manualmente
—usa una lista de CAs raíz compilada en el engine—, así que sin este ajuste,
un `HttpClient()` "normal" de Flutter ya rechazaría por sí solo el
certificado de cualquier proxy MitM, y no se podría demostrar la
vulnerabilidad. Aceptar cualquier certificado es exactamente el error que
comete una app real insegura (a veces puesto "temporalmente" durante
desarrollo para evitar errores de SSL, y olvidado en producción).

## 3. Correr la app en un dispositivo Android real

1. Activa **Opciones de desarrollador → Depuración USB** en el teléfono.
2. Conéctalo por USB (o configura ADB inalámbrico) y verifica que se detecta:
   ```bash
   flutter devices
   ```
   Si no aparece, revisa `adb devices` — asegúrate de que Android SDK
   platform-tools esté en tu `PATH` (normalmente en
   `~/Library/Android/sdk/platform-tools`).
3. Ejecuta la app en el dispositivo:
   ```bash
   flutter run -d <device-id>
   ```
4. Dentro de la app: **Demo de Seguridad → pestaña "SSL Pinning"**.
5. Prueba primero **sin proxy**, en tu WiFi normal, con el switch en
   cualquier posición, y pulsa "Probar Conexión Segura". Debe responder
   `✅ 200`. Esto confirma que el código funciona antes de meter el proxy.

## 4. Prueba de Concepto (PoC) con proxy MitM

Herramienta recomendada: **HTTP Toolkit** (tiene un modo "Attach to Android
device via ADB" que configura el proxy solo, sin tocar ajustes de WiFi a
mano). Charles Proxy funciona igual de bien con configuración manual.

### Con HTTP Toolkit
1. Instálalo en tu computadora y ábrelo.
2. Conecta el Android por USB con depuración habilitada.
3. Elige **"Android device via ADB"** — instala su certificado y configura el
   proxy automáticamente en el dispositivo.

### Con Charles Proxy (manual)
1. Instala Charles en tu computadora, en la misma red WiFi que el teléfono.
2. En el Android: **Ajustes → WiFi → mantén presionada tu red → Modificar →
   Opciones avanzadas → Proxy → Manual** → IP de tu computadora + puerto
   `8888`.
3. En el navegador del teléfono entra a `chls.pro/ssl` y descarga/instala el
   certificado (Android puede pedirte poner un PIN/patrón de bloqueo si no
   tienes uno configurado).
4. En Charles: **Proxy → SSL Proxying Settings** → añade
   `jsonplaceholder.typicode.com:443` a la lista para que intercepte ese host.

### Ejecutar la prueba

| Estado del switch | Qué deberías ver en la app | Qué deberías ver en el proxy |
|---|---|---|
| **Apagado** (sin pinning) | `✅ 200` con la respuesta del JSON | La petición completa, legible (headers + body) |
| **Encendido** (con pinning) | `🚨 Conexión insegura detectada... Posible ataque MitM.` | Conexión fallida / error de handshake TLS, sin contenido |

## 5. Troubleshooting

- **"No aparece mi dispositivo en `flutter devices`"** → revisa que ADB esté
  en el `PATH` y que aceptaste el diálogo "¿Confiar en esta computadora?" en
  el teléfono.
- **El caso "sin pinning" también falla** → confirma que estás llamando a
  `NetworkService.instance.configure(pinningEnabled: false)` antes del
  request (lo hace la pestaña automáticamente al pulsar el botón) y que el
  proxy tiene SSL Proxying activo para ese host.
- **El caso "con pinning" no falla (el proxy sí ve la petición)** → revisa
  que `assets/certs/jsonplaceholder.pem` sigue registrado en `pubspec.yaml` y
  que hiciste `flutter pub get` después de cualquier cambio en assets.
- **Error genérico de red en ambos casos** → puede ser que el certificado
  pineado haya vencido (ver siguiente punto) o que no haya conexión a
  internet real detrás del proxy.

## 6. Mantenimiento del certificado

El certificado pineado (`assets/certs/jsonplaceholder.pem`) vence el
**29 de agosto de 2026**. Si el pinning empieza a fallar en condiciones
normales (sin proxy) después de esa fecha, hay que volver a extraerlo:

```bash
openssl s_client -connect jsonplaceholder.typicode.com:443 \
  -servername jsonplaceholder.typicode.com -showcerts </dev/null 2>/dev/null \
  | openssl x509 -outform PEM > assets/certs/jsonplaceholder.pem
```

Fingerprint SHA-256 actual, para referencia en el reporte de la actividad:
```
6F:73:ED:49:9D:45:EE:F0:03:73:FD:96:A4:20:B1:19:56:32:65:C1:AF:9A:C0:55:65:30:89:80:95:C7:70:71
```
