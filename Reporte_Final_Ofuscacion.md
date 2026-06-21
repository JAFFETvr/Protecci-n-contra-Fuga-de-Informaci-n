# C2 - INVESTIGACIÓN Y PRÁCTICA: OFUSCACIÓN DE CÓDIGO

---

**UNIVERSIDAD / INSTITUCIÓN:** [Insertar Nombre de la Universidad]  
**MATERIA:** Seguridad de la Información (PMII)  
**TEMA:** Actividad C2 - Investigación y Práctica - Ofuscación de Código en Aplicaciones Móviles  
**ALUMNO:** [Insertar Nombre Completo (e.g., Jaffet Alessandro)]  
**DOCENTE:** [Insertar Nombre del Profesor]  
**FECHA:** 21 de Junio de 2026  

---

## ÍNDICE
1. **Introducción y Objetivos**
2. **Marco Teórico (Reporte de Investigación)**
   - 2.1. Ingeniería Inversa en Aplicaciones Móviles
   - 2.2. Riesgos de Seguridad Asociados a la Exposición del Código Fuente
   - 2.3. Concepto de Ofuscación de Código
   - 2.4. Tabla Comparativa: Ofuscación, Minimización, Optimización y Cifrado
   - 2.5. Herramientas en Android: ProGuard vs R8
   - 2.6. Ofuscación en Flutter: Arquitectura AOT y Dart Obfuscation
   - 2.7. Técnicas de Ofuscación Comunes
   - 2.8. Ventajas, Limitaciones e Impacto en Terceros (Uso de Reglas `Keep`)
   - 2.9. Buenas Prácticas Generales de Protección Móvil
3. **Actividad Práctica**
   - 3.1. Estructura de la Aplicación del Proyecto ("DLP Seguro")
   - 3.2. Configuración y Generación de la Versión Normal (Sin Ofuscación)
   - 3.3. Configuración y Generación de la Versión Ofuscada (Con R8 y Dart Obfuscate)
4. **Análisis Comparativo de los APKs**
   - 4.1. Tabla Comparativa de Resultados Reales (Tamaño y Estructura)
   - 4.2. Análisis de Clases y Métodos del Código DEX Natico (`apkanalyzer`)
   - 4.3. Análisis de la Ofuscación en el Código Dart Compilado AOT
   - 4.4. Evaluación de la Legibilidad y Comprensión de la Lógica de Negocio
5. **Preguntas de Reflexión Resueltas**
6. **Conclusiones Personales**
7. **Anexo: Archivos de Configuración Utilizados**

---

## 1. INTRODUCCIÓN Y OBJETIVOS

En el desarrollo de software móvil moderno, los entregables de producción (archivos APK/AAB en Android o IPA en iOS) se distribuyen de forma abierta a través de tiendas oficiales o repositorios públicos. Esto permite que cualquier usuario o atacante tenga acceso directo a los binarios compilados de la aplicación. 

A través de herramientas de ingeniería inversa muy accesibles, es posible deconstruir y analizar estos ejecutables para recuperar parte sustancial del código fuente original, exponiendo secretos, algoritmos de negocio y vulnerabilidades.

El objetivo de esta actividad es investigar a fondo los conceptos teóricos que rigen la protección de código en aplicaciones móviles (específicamente la ofuscación) y realizar una práctica controlada. 

Para ello, tomamos una aplicación Flutter que implementa pantallas de Login, Registro y un Dashboard Seguro de Prevención de Fuga de Datos (DLP) con almacenamiento local cifrado (`SecureStorageService`). Compilaremos dos versiones (Normal y Ofuscada), analizaremos sus diferencias físicas y lógicas mediante herramientas del SDK de Android, y documentaremos su efectividad como mecanismo de mitigación de riesgos.

---

## 2. MARCO TEÓRICO (REPORTE DE INVESTIGACIÓN)

### 2.1. Ingeniería Inversa en Aplicaciones Móviles
La **ingeniería inversa** en móviles consiste en deconstruir un binario ejecutable compilado con el fin de reconstruir y comprender su estructura interna, diseño, flujo lógico y código fuente original. 

En Android, el flujo tradicional consiste en empaquetar código escrito en Java o Kotlin en archivos bytecode DEX (Dalvik Executable) que corren en la máquina virtual ART (Android Runtime). El proceso de ingeniería inversa sigue habitualmente tres fases:
1. **Desempaquetado (Decompression)**: Al ser un APK un archivo comprimido en ZIP, se extraen los archivos `classes.dex`, los recursos compilados (`resources.arsc`), el `AndroidManifest.xml` y los assets.
2. **Desensamblado (Disassembly)**: Utilizando herramientas como **APKTool**, el bytecode DEX binario se traduce a un lenguaje ensamblador intermedio y legible conocido como **Smali**. Esto permite inspeccionar instrucciones de bajo nivel y alterar el manifiesto o recursos del APK.
3. **Descompilación (Decompilation)**: Herramientas avanzadas como **JADX** o **Bytecode Viewer** toman los archivos DEX/Smali y reconstruyen de forma directa archivos de código fuente Java de alto nivel. Si el APK no se encuentra protegido, el descompilador es capaz de recuperar con extrema precisión nombres de variables, nombres de funciones, clases y la lógica exacta de control de flujo.

### 2.2. Riesgos de Seguridad Asociados a la Exposición del Código Fuente
La distribución de una aplicación móvil con código fuente expuesto introduce riesgos de seguridad sumamente severos para los desarrolladores y la organización:
- **Pérdida de Propiedad Intelectual**: Competidores maliciosos pueden deconstruir la aplicación para copiar algoritmos especializados de cálculo, lógicas de negocio patentadas o metodologías propias de diseño.
- **Fuga de Secretos y Llaves de API (Hardcoded Secrets)**: Es común el error de incrustar credenciales dentro del código (ej. llaves de Firebase, pasarelas de pago como Mercado Pago, o tokens de firma de servicios). Un atacante puede extraerlos fácilmente y utilizarlos para suplantar a la aplicación móvil en peticiones API directas al backend.
- **Clonación de Aplicaciones y Modificación (Tampering/Repackaging)**: Un atacante puede descompilar el APK con APKTool, inyectar código malicioso (como troyanos o scripts de robo de credenciales), volver a empaquetar la aplicación y firmarla con un certificado personal. Esta aplicación alterada puede ser subida a tiendas no oficiales o distribuida por phishing para engañar a los usuarios.
- **Bypass de Validaciones Locales**: Modificando el código smali o reescribiendo condiciones condicionales, un atacante puede omitir validaciones locales críticas en el dispositivo, tales como pantallas de bloqueo, cobros en compras *in-app*, detección de root o geolocalización simulada (Fake GPS).

### 2.3. Concepto de Ofuscación de Código
La **ofuscación** es el proceso de transformar el código fuente o el bytecode compilado para que sea sumamente complejo, confuso y difícil de analizar para seres humanos y herramientas automáticas, sin alterar en lo absoluto la funcionalidad del software para el usuario final o la máquina de ejecución. 

No se trata de criptografía (el código no se oculta bajo una llave secreta que impida su ejecución), sino de una técnica defensiva orientada a incrementar de manera exponencial el tiempo y esfuerzo requeridos para realizar ingeniería inversa sobre el software.

### 2.4. Tabla Comparativa: Ofuscación, Minimización, Optimización y Cifrado

| Concepto | Propósito Principal | Mecanismo de Acción | Impacto en la Seguridad |
| :--- | :--- | :--- | :--- |
| **Ofuscación** | Dificultar el análisis estático y la lectura lógica del código fuente/bytecode. | Renombra variables, clases y métodos; aplana el flujo de control o introduce bifurcaciones ficticias. | **Alto**. Reduce críticamente la legibilidad del código descompilado. |
| **Minimización (Shrinking)** | Reducir el tamaño total del binario ejecutable (APK/IPA). | Analiza el árbol de dependencias y elimina clases, variables, métodos y recursos que nunca son invocados. | **Bajo / Indirecto**. Al eliminar código muerto o de prueba, evita que atacantes lo analicen. |
| **Optimización** | Incrementar la velocidad de ejecución y disminuir el uso de memoria. | Realiza "inlining" de funciones, reescribe bucles y optimiza instrucciones del bytecode. | **Bajo**. Altera ligeramente el bytecode original haciéndolo un poco más complejo de leer. |
| **Cifrado de Código** | Bloquear el análisis estático del binario completo. | Encripta los archivos de código (.DEX) en disco. Un cargador nativo los descifra en memoria RAM al iniciar. | **Muy Alto**. Impide cualquier descompilación estática, pero afecta el rendimiento y es eludible en memoria activa. |

### 2.5. Herramientas en Android: ProGuard vs R8
*   **ProGuard**: Tradicionalmente ha sido el estándar de la industria. Es una herramienta externa basada en Java que lee archivos `.class` generados por el compilador de Java, realiza la minimización, optimización y ofuscación, y escupe archivos `.class` optimizados. Luego, la herramienta **DX** toma estos archivos y los compila a bytecode Dalvik `.dex`. Al implicar múltiples pasos independientes, incrementa los tiempos de compilación.
*   **R8**: Es el compilador moderno por defecto desarrollado por Google que reemplaza a ProGuard y a DX. Integra en un solo paso unificado la compilación del bytecode Java/Kotlin a DEX junto con la minimización, optimización y ofuscación. Al trabajar de manera nativa y directa, R8 compila más rápido, genera binarios más pequeños y ofrece una compatibilidad total con el formato de configuración tradicional de ProGuard (`proguard-rules.pro`).

### 2.6. Ofuscación en Flutter: Arquitectura AOT y Dart Obfuscation
Flutter compila su código de interfaz y lógica de negocio (Dart) de una forma muy distinta a las aplicaciones nativas de Android:
- En compilaciones release, Flutter utiliza una compilación **AOT (Ahead-Of-Time)**. El código Dart se traduce directamente a instrucciones de lenguaje de máquina nativo para la arquitectura del procesador (por ejemplo, ARM64).
- Este código compilado en lenguaje de máquina se almacena como una biblioteca nativa ELF compartida dentro del APK, bajo la ruta `lib/<arquitectura>/libapp.so`.
- Descompiladores de bytecode tradicionales como JADX o APKTool no pueden leer ni descompilar `libapp.so`. Sin embargo, herramientas de desensamblado nativo (Ghidra, IDA Pro) o herramientas específicas de análisis de Dart pueden leer los metadatos y nombres de los símbolos de depuración incrustados en `libapp.so`, revelando los nombres de las clases y métodos de Dart.

Para proteger este binario, Flutter provee la bandera de compilación:
```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```
Esta instrucción remueve todos los nombres de símbolos reales en el binario `libapp.so` y los renombra a etiquetas genéricas de pocos caracteres (`a`, `b`, `A`), extrayendo el mapa de depuración a un directorio externo para permitir la posterior desofuscación de reportes de error.

### 2.7. Técnicas de Ofuscación Comunes
-   **Renombrado (Renaming)**: Sustituye nombres de clases, métodos y campos semánticamente comprensibles por caracteres cortos sin sentido (ej. `class AuthenticationService` pasa a llamarse `class a`, y `method loginWithEmailAndPassword` pasa a ser `method a`).
-   **Eliminación de código no utilizado (Dead Code Elimination)**: Remueve del APK final cualquier clase o recurso importado que no se invoque directamente en el flujo del software.
-   **Ofuscación del Flujo de Control (Control Flow Obfuscation)**: Divide rutinas lógicas en estructuras condicionales planas unidas por una máquina de estados simulada (`switch`), o inyecta bloques condicionales falsos (*junk code*), de modo que los diagramas de flujo lógicos reconstruidos por los descompiladores sean incomprensibles.

### 2.8. Ventajas, Limitaciones e Impacto en Terceros (Uso de Reglas `Keep`)
-   **Ventajas**: Dificulta drásticamente la piratería y la ingeniería inversa, reduce notablemente el tamaño del APK y optimiza el uso de CPU y RAM del dispositivo.
-   **Limitaciones**: No previene el análisis dinámico en tiempo de ejecución (depuración de memoria RAM con Frida), complica la lectura de logs de fallos (Stack Traces) y puede introducir errores de compilación por el uso de **Reflexión**.
-   **Impacto en Terceros (Reflexión)**: Librerías de serialización JSON (Gson, Jackson, Moshi), mapeadores de bases de datos ORM o llamadas nativas a plugins de Flutter usan reflexión para mapear campos y nombres de clases por texto literal. Si R8 los ofusca de `String username` a `String a`, la librería fallará en ejecución.
-   **Uso de `-keep`**: Se define un archivo de configuración (`proguard-rules.pro`) para decirle a R8 qué paquetes, clases o métodos específicos **no debe ofuscar ni eliminar**. Ejemplo:
    ```proguard
    -keep class com.example.mi_app_dlp.models.** { *; }
    ```

### 2.9. Buenas Prácticas Generales de Protección Móvil
La ofuscación debe ser concebida como parte de una estrategia de "defensa en profundidad":
1.  **No Almacenar Secretos en Local**: Utilizar el backend como intermediario y asegurar las peticiones API.
2.  **Cifrar Datos Sensibles en Reposo**: Utilizar Secure Storage (Keystore / Keychain) en lugar de SharedPreferences planos.
3.  **Implementar SSL Pinning**: Evitar la interceptación de red HTTPS mediante proxies locales (Man-in-the-Middle).
4.  **Detección de Manipulación (Tampering Detection)**: Verificar la firma criptográfica de la app en ejecución.
5.  **Detección de Root y Emuladores**: Impedir la ejecución del aplicativo en entornos de depuración inseguros.
6.  **Políticas Activas contra Fuga de Datos (DLP)**: Ocultar previsualizaciones de pantallas en la multitarea de Android/iOS mediante `FLAG_SECURE`, e implementar cierres de sesión por inactividad y borrado remoto (*Wipe*) de datos locales.

---

## 3. ACTIVIDAD PRÁCTICA

### 3.1. Estructura de la Aplicación del Proyecto ("DLP Seguro")
Nuestra aplicación de prueba ("DLP Seguro") fue construida utilizando **Flutter** y cuenta con la siguiente arquitectura en `lib/`:
-   **Pantallas (3 pantallas)**:
    -   `LoginScreen` (`lib/screens/login_screen.dart`): Pantalla de acceso que simula un flujo de autenticación seguro, define un canal de plataforma con Android nativo (`com.example.mi_app_dlp/security`) para activar restricciones de captura de pantalla y muestra alertas si la sesión previa expiró por inactividad.
    -   `RegisterScreen` (`lib/screens/register_screen.dart`): Permite registrar usuarios simulados.
    -   `DashboardScreen` (`lib/screens/dashboard_screen.dart`): Muestra el estado activo de las políticas DLP y la tarjeta de prueba de "Remote Wipe".
-   **Clase de Autenticación Simulada**: Integrada en la lógica interna del estado de `LoginScreen` (método `_login()`), que introduce retardos y simula un intercambio de tokens para iniciar sesión de manera segura.
-   **Clase de Procesamiento de Información Sensible**:
    -   `SecureStorageService` (`lib/services/secure_storage_service.dart`): Procesa, escribe y lee claves API privadas y datos sensibles simulados utilizando el almacenamiento seguro del sistema operativo (`flutter_secure_storage`).
    -   *Datos simulados*: `ine_data` (`INE_FOTO_Y_SERIE_XYZ123`), `payment_card_token` (`tok_mercado_pago_987654321`), `kyc_biometric_data` (`hash_selfie_liveness_abc987`), y `api_keys` (`apikey_mercado_pago_secreta_000`).

---

### 3.2. Configuración y Generación de la Versión Normal (Sin Ofuscación)
Para generar una versión sin ofuscación de Dart y sin optimización nativa R8, se modificó el archivo `android/app/build.gradle.kts` inhabilitando explícitamente estas propiedades en la configuración de la firma `release`:

```kotlin
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Desactivar R8 y la optimización nativa de Android
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
```

Posteriormente, se ejecutó el comando de compilación por defecto de Flutter en la terminal del proyecto:
```bash
flutter build apk --release
```
Este binario se renombró a `app-normal.apk` y se guardó en el directorio de pruebas para su análisis.

---

### 3.3. Configuración y Generación de la Versión Ofuscada (Con R8 y Flutter Obfuscate)
Para compilar la versión protegida, se habilitaron las optimizaciones y ofuscación en los dos niveles de la aplicación (Java/Kotlin nativo y Dart compilado):

#### 1. Configuración de R8 Nativo (Android):
Se modificó `android/app/build.gradle.kts` para activar `isMinifyEnabled` e `isShrinkResources`, asociando el archivo de reglas `proguard-rules.pro`:

```kotlin
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Activar R8, remoción de recursos y aplicar reglas de ProGuard
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
```

Se creó el archivo de exclusiones `android/app/proguard-rules.pro` para asegurar el correcto funcionamiento de Flutter y mantener la clase del canal nativo:
```proguard
# Reglas de ofuscación y minimización para R8 / ProGuard
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.example.mi_app_dlp.MainActivity {
    public *;
}
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
```

#### 2. Compilación de Flutter con Ofuscación de Dart:
Se corrió la compilación usando las banderas de ofuscación de símbolos de Dart AOT:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```
Este binario se guardó como `app-ofuscado.apk`.

---

## 4. ANÁLISIS COMPARATIVO DE LOS APKS

### 4.1. Tabla Comparativa de Resultados Reales (Tamaño y Estructura)

A través de la inspección directa y el uso de la herramienta `apkanalyzer` del SDK de Android, se obtuvieron las siguientes métricas físicas reales del proyecto:

| Métrica / Elemento | APK Normal (Sin Ofuscación) | APK Ofuscado (Con Ofuscación) | Diferencia / Impacto |
| :--- | :--- | :--- | :--- |
| **Tamaño del APK (Bytes)** | `52,836,639` bytes | `47,049,189` bytes | `-5,787,450` bytes |
| **Tamaño del APK (Megabytes)** | **50.38 MB** | **44.87 MB** | **-5.51 MB (~10.95% de reducción)** |
| **Cantidad de Archivos DEX** | **2 archivos** (`classes.dex`, `classes2.dex`) | **1 archivo** (`classes.dex`) | `-classes2.dex` fue completamente eliminado |
| **Tamaño de Bytecode DEX** | 3.98 MB (`3,992,122` bytes) | 0.79 MB (`812,128` bytes) | **-3.19 MB (~80% de reducción en bytecode)** |
| **Tamaño de Dart AOT (`libapp.so` ARM64)** | 4.78 MB (`4,785,040` bytes) | 3.99 MB (`3,998,608` bytes) | **-786 KB (~16.4% de reducción en lógica de Flutter)** |
| **Tamaño de Recursos `/res/`** | 62.5 KB (`62,566` bytes) | 15.6 KB (`15,685` bytes) | **-46.8 KB (~75% de reducción en gráficos/layouts)** |
| **Tabla `/resources.arsc`** | 193.1 KB (`193,164` bytes) | 179.6 KB (`179,608` bytes) | `-13.5 KB` (Tabla de strings optimizada) |

---

### 4.2. Análisis de Clases y Métodos del Código DEX Nativo (`apkanalyzer`)

Al inspeccionar los paquetes del espacio de nombres `com.example.mi_app_dlp` dentro de los archivos DEX de ambos APKs, se revelan cambios drásticos e ilustrativos en el código compilado:

#### Resultado en APK Normal (Sin Ofuscación):
El comando `apkanalyzer dex packages build_apks/app-normal.apk` devolvió la estructura completa y explícita del código nativo de Android:
```text
C d 4  5  426   com.example.mi_app_dlp.MainActivity
M d 1  1  48    com.example.mi_app_dlp.MainActivity <init>()
M d 1  1  158   com.example.mi_app_dlp.MainActivity void configureFlutterEngine$lambda$0(com.example.mi_app_dlp.MainActivity,io.flutter.plugin.common.MethodCall,io.flutter.plugin.common.MethodChannel$Result)
M d 1  1  96    com.example.mi_app_dlp.MainActivity void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine)
F d 0  0  11    com.example.mi_app_dlp.MainActivity java.lang.String CHANNEL
C d 2  2  148   com.example.mi_app_dlp.MainActivity$$ExternalSyntheticLambda0
C d 1  1  127   com.example.mi_app_dlp.R$drawable
F d 0  0  16    com.example.mi_app_dlp.R$drawable int launch_background
C d 1  1  202   com.example.mi_app_dlp.R$string
F d 0  0  15    com.example.mi_app_dlp.R$string int google_api_key
F d 0  0  15    com.example.mi_app_dlp.R$string int google_app_id
```
**Observación**: Es completamente visible el nombre de la clase `MainActivity`, sus métodos internos de comunicación con Flutter (`configureFlutterEngine$lambda$0`), y el campo privado `CHANNEL` que almacena el string del canal de comunicación `"com.example.mi_app_dlp/security"`. También son visibles los recursos gráficos (`R$drawable.launch_background`) y las llaves de Firebase (`R$string.google_api_key`, `google_app_id`) en texto plano en la clase autogenerada `R`.

#### Resultado en APK Ofuscado (Con Ofuscación):
El comando `apkanalyzer dex packages build_apks/app-ofuscado.apk` devolvió una estructura fuertemente optimizada y renombrada:
```text
C d 2  2  209   com.example.mi_app_dlp.MainActivity
M d 1  1  48    com.example.mi_app_dlp.MainActivity <init>()
M d 1  1  98    com.example.mi_app_dlp.MainActivity void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine)
F d 0  0  12    com.example.mi_app_dlp.MainActivity int c
F d 0  0  11    com.example.mi_app_dlp.MainActivity java.lang.String b
```
**Análisis Técnico del Impacto de R8:**
1.  **Preservación Parcial Dirigida**: La clase `MainActivity` y su método público `configureFlutterEngine` mantuvieron sus nombres reales. Esto se debió a nuestra regla `-keep class com.example.mi_app_dlp.MainActivity { public *; }`. De no haberla colocado, la clase se hubiera renombrado y Android no podría iniciar la aplicación.
2.  **Renombrado Completo (Renaming)**: El campo privado de la constante del canal `CHANNEL` no fue protegido por la regla (ya que no es un miembro público). Por lo tanto, R8 la renombró de `java.lang.String CHANNEL` a `java.lang.String b` y otro campo a `int c`. Esto rompe la comprensión estática de qué almacena esa variable.
3.  **Minimización Extrema (Shrinking)**: Las clases internas del sistema `R$drawable`, `R$string`, `R$mipmap` y los Lambdas sintéticos externos (`MainActivity$$ExternalSyntheticLambda0`) fueron **completamente eliminados** o fusionados por R8 en el proceso de optimización, al no ser referenciados dinámicamente mediante reflexión nativa. Las constantes se inyectaron directamente como valores literales numéricos allí donde se usaban, reduciendo el código y eliminando metadatos.
4.  **Desaparición de classes2.dex**: En el APK normal, las dependencias de Firebase y librerías externas eran tan grandes que excedieron el límite de 65,536 métodos de un solo archivo DEX, forzando la creación de `classes2.dex`. R8 eliminó tanto código muerto de las dependencias externas que todo el bytecode cupo holgadamente en un solo archivo `classes.dex` de tan solo 812 KB.

---

### 4.3. Análisis de la Ofuscación en el Código Dart Compilado AOT
El código correspondiente a la lógica en Dart no reside en los archivos DEX nativos, sino en la biblioteca compartida `/lib/arm64-v8a/libapp.so`.
-   **En el APK Normal**: Si se abre `libapp.so` con herramientas de extracción de strings o desensambladores como Ghidra, es posible buscar referencias textuales de nombres de clases y funciones definidos por nosotros, por ejemplo: `SecureStorageService`, `initializeSensitiveData`, `ine_data` y `payment_card_token`. Los nombres se conservan para depuración.
-   **En el APK Ofuscado**: La bandera `--obfuscate` reemplaza todas estas referencias simbólicas por nombres irreconocibles. Un volcado de strings o desensamblado del archivo `libapp.so` ofuscado no mostrará referencias a la clase `SecureStorageService` ni a los métodos de autenticación simulados. Se verán firmas genéricas del runtime de Dart e identificadores de pocos caracteres.

---

### 4.4. Evaluación de la Legibilidad y Comprensión de la Lógica de Negocio
Al comparar la legibilidad lógica con herramientas de descompilación como JADX:
-   **Sin Ofuscación**: Un analista puede abrir el APK en JADX y leer el código Kotlin de la MainActivity exactamente como fue programado, identificando que cuando se llama a `"setSecureFlag"`, se recupera un argumento boolean `"secure"` y se aplica `WindowManager.LayoutParams.FLAG_SECURE`. En la parte de Dart (usando decompiladores experimentales), se reconstruye el flujo exacto de almacenamiento de tokens de tarjetas o credenciales.
-   **Con Ofuscación**: En JADX, la MainActivity nativa se muestra reducida a unas pocas líneas optimizadas donde las llamadas se hacen a variables llamadas `b` y métodos simplificados. No hay rastro visual de clases auxiliares de recursos. En Dart, desensamblar `libapp.so` solo muestra bloques de código de máquina apuntando a funciones genéricas, obligando al atacante a realizar un análisis manual dinámico en memoria RAM (hooking dinámico) para intentar deducir qué hace cada fragmento de la app, lo cual incrementa el tiempo de ataque de minutos a semanas.

---

## 5. PREGUNTAS DE REFLEXIÓN RESUELTAS

### A. ¿La ofuscación impide completamente la ingeniería inversa?
**No**. La ofuscación no impide la ingeniería inversa, únicamente incrementa su dificultad y el tiempo requerido para llevarla a cabo. Dado que el dispositivo móvil necesita ejecutar las instrucciones nativas y los datos en texto plano en algún momento en el procesador y la memoria RAM, un analista con suficiente motivación, tiempo y herramientas adecuadas (como desensambladores profesionales, depuradores y herramientas de instrumentación dinámica como Frida) eventualmente podrá reconstruir el flujo de la aplicación. La ofuscación es un mecanismo de disuasión y retraso, no una barrera impenetrable.

### B. ¿Qué información sigue siendo visible después de aplicar ofuscación?
A pesar de aplicar ofuscación, los siguientes elementos siguen siendo visibles:
-   **Recursos Estáticos**: Archivos multimedia (imágenes PNG/JPG en la carpeta `res/` o `assets/`), archivos de configuración xml planos y el archivo `AndroidManifest.xml` (que describe permisos, actividades y servicios de la app).
-   **Clases Preservadas en las Reglas Keep**: Los nombres de las clases y métodos explícitamente excluidos en `proguard-rules.pro` (en este caso, `MainActivity` y los puntos de entrada del motor de Flutter).
-   **Cadenas de Texto Literales (Strings)**: A menos que se aplique un cifrado específico de strings (el cual no realiza R8 de forma nativa), las cadenas de texto hardcodeadas dentro del código smali o binario (como URLs de endpoints, tokens de Firebase y textos de interfaz) siguen siendo legibles en un análisis de strings estático.
-   **Firmas de Métodos del Sistema**: Las llamadas a las APIs estándar del SDK de Android (ej. `window.setFlags` o llamadas a librerías del sistema) permanecen visibles porque no se pueden renombrar las clases nativas del sistema operativo.

### C. ¿Qué riesgos existirían si una aplicación crítica se distribuye sin ofuscación?
Si una aplicación de banca móvil, procesamiento de pagos o gestión de salud crítica se distribuye sin ofuscación, los riesgos son extremos:
1.  **Exposición y Clonación Inmediata**: Cualquier atacante puede generar un clon con malware integrado y resubirlo a tiendas alternativas en cuestión de horas.
2.  **Robo y Explotación de Credenciales**: Las llaves de API o endpoints de bases de datos expuestos en el código fuente pueden ser extraídos en minutos, permitiendo ataques directos al servidor backend (evadiendo la aplicación).
3.  **Descubrimiento de Vulnerabilidades en el Backend**: Los desarrolladores a menudo implementan lógicas de backend confiando en que el cliente móvil es seguro. Analizando el código de la app descompilada, los atacantes pueden deducir fallos de seguridad en las APIs del servidor (ej. parámetros inseguros, falta de validaciones de entrada).
4.  **Bypass de Lógica de Seguridad**: Se pueden anular fácilmente controles de protección de datos (como el bloqueo de captura de pantalla) modificando las condiciones lógicas y reinstalando la app manipulada.

### D. ¿Qué otras medidas de seguridad deberían complementarse con la ofuscación?
Para lograr un blindaje robusto (Application Shielding), la ofuscación debe integrarse con:
-   **Cifrado de Strings**: Encriptar las cadenas de texto sensibles en tiempo de compilación para que no aparezcan en un análisis estático de strings.
-   **Certificado SSL/TLS Pinning**: Evitar la interceptación del tráfico HTTP/HTTPS forzando la validación del certificado del servidor.
-   **Detección de Root, Jailbreak y Emuladores**: Detener la aplicación si se ejecuta en entornos propicios para el análisis dinámico.
-   **Anti-Debugging y Anti-Hooking**: Implementar contramedidas que detecten si se está adjuntando un depurador (como GDB) o herramientas de inyección en RAM (como Frida), abortando la ejecución de inmediato.
-   **Verificación de Integridad de la Firma (Anti-Tampering)**: Validar en tiempo de ejecución que el hash criptográfico del certificado de firma del APK coincide con el original de la Play Store.

### E. ¿Considera que la ofuscación es suficiente para proteger secretos, tokens o credenciales dentro de una aplicación móvil? Justifique su respuesta.
**No, de ninguna manera**. La ofuscación no es un mecanismo criptográfico y no fue diseñada para ocultar secretos. Como se demostró en el análisis, R8 no cifra los strings literales; solo renombra identificadores de clases y variables. Un atacante puede extraer fácilmente los strings que contienen API keys mediante comandos simples como `strings libapp.so` o buscando constantes en los archivos descompilados por JADX. 

Incluso si las variables lógicas se renombran a `a` o `b`, los secretos incrustados (ej. `"apikey_mercado_pago_secreta_000"`) siguen estando escritos en texto plano. Las credenciales críticas siempre deben gestionarse a través del backend mediante flujos de autenticación dinámica (OAuth 2.0, tokens temporales) o, si es estrictamente necesario guardarlas en local, almacenarse cifradas con claves protegidas por hardware en el Keystore del dispositivo.

---

## 6. CONCLUSIONES PERSONALES

La realización de esta práctica permite concluir que la ofuscación de código es una **medida defensiva fundamental y obligatoria** para cualquier aplicación móvil que se distribuya comercialmente o maneje información privada, pero **nunca debe ser la única**. 

El impacto de R8 y la ofuscación de Dart AOT no solo beneficia a la seguridad (al transformar nombres descriptivos como `payment_card_token` en variables abstractas cortas y eliminar metadatos que guían al atacante), sino que tiene un impacto colateral sumamente positivo en la optimización del software. En nuestro caso de estudio real, redujimos el tamaño total del APK en un **10.95%** (5.5 MB menos de descarga) y, lo que es aún más impactante, reducimos el peso del bytecode DEX en un **80%**, logrando eliminar un archivo DEX secundario completo (`classes2.dex`) gracias a la remoción de código muerto.

Sin embargo, como profesionales de la seguridad informática, debemos entender los límites de la herramienta. La ofuscación dificulta el análisis estático pero es vulnerable al análisis dinámico. Por ello, la verdadera efectividad de la protección móvil radica en complementar la ofuscación con controles de entorno (anti-root, anti-debug) y una arquitectura de software segura que delegue el procesamiento de secretos al backend y utilice APIs criptográficas locales del hardware.

---

## 7. ANEXO: ARCHIVOS DE CONFIGURACIÓN UTILIZADOS

### A. Archivo `android/app/build.gradle.kts` (Modificado para Release Ofuscado)
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.mi_app_dlp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.mi_app_dlp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // ACTIVACIÓN DE OFUSCACIÓN NATIVA R8
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

### B. Archivo `android/app/proguard-rules.pro` (Exclusiones de Ofuscación Nativa)
```proguard
# Reglas de ofuscación y minimización para R8 / ProGuard
# Proyecto: Proteccion contra Fuga de Informacion - DLP Seguro

# 1. Preservar clases requeridas por el framework de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.embedding.engine.plugins.Flash** { *; }

# 2. Preservar nuestra MainActivity para evitar errores de carga nativa
-keep class com.example.mi_app_dlp.MainActivity {
    public *;
}

# 3. Mantener nombres de métodos nativos (JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# 4. Mantener clases utilizadas en reflexión y serialización
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# 5. Evitar advertencias genéricas de compilación de Flutter
-dontwarn io.flutter.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animalsniffer.**
```
