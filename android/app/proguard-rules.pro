# ─── Flutter ────────────────────────────────────────────────────────────
# Flutter's engine relies on reflection to wire plugins; keep the whole
# framework + embedding APIs untouched. Without these lines R8 strips
# classes the engine still dlopen()s → release crashes with
# "Didn't find class io.flutter.plugin.X".
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── Native image_picker (camera/gallery) ───────────────────────────────
-keep class androidx.camera.** { *; }

# ─── flutter_secure_storage ─────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── Prevent removal of Google Play Core / split install classes
#     (Flutter reports warnings about these if deferred components aren't
#     used; safer to keep them than to fight the warning) ───────────────
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ─── Keep classes annotated with Kotlin metadata ───────────────────────
-keep class kotlin.Metadata { *; }
-keepclassmembers class ** {
    @kotlin.Metadata *;
}

# ─── Don't fail on harmless missing warnings ───────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.slf4j.**
