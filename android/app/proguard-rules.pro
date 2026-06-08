# Keep Flutter platform classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# AppsFlyer
-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Webview JS interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Kotlin reflection used by some firebase modules
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Play Core (deferred components) — not used, suppress R8 missing-class errors
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
