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

# 4. Mantener clases utilizadas en reflexión y serialización (Gson / Firebase si aplica)
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# 5. Evitar advertencias genéricas de compilación de Flutter
-dontwarn io.flutter.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animalsniffer.**
