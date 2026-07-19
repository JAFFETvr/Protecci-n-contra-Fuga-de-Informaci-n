# ================================================================
# ProGuard / R8 Rules — Proyecto: DLP Seguro (mi_app_dlp)
# Actividad: Protección contra Fuga de Información
# ================================================================

# ── 1. Flutter Engine ────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-dontwarn io.flutter.**

# ── 2. MainActivity (requerida para carga nativa Flutter) ────────
-keep class com.example.mi_app_dlp.MainActivity {
    public *;
}

# ── 3. Métodos JNI nativos ───────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── 4. Atributos necesarios para reflexión y Firebase ────────────
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions

# ── 5. Firebase Core y Messaging ─────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── 6. Flutter Secure Storage (EncryptedSharedPreferences) ───────
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── 7. Geolocator ────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ── 8. Kotlin Coroutines ─────────────────────────────────────────
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# ── 9. Suprimir advertencias generales ───────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animalsniffer.**

# ── 10. Mantener Enum names (necesarios para serialización) ──────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ================================================================
# NOTA EDUCATIVA:
# Las reglas anteriores PRESERVAN el código de bibliotecas externas
# para evitar crashes. El código Dart compilado en libapp.so NO es
# afectado por ProGuard/R8 (ese es el código del app Flutter).
# R8 ofusca el código Java/Kotlin del wrapper Android.
# Para ofuscar el código Dart, se usa el flag --obfuscate de Flutter.
# ================================================================
