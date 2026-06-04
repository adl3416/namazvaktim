# Keep Flutter and plugin registration classes used by reflection.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep line numbers/source info for better crash diagnostics in mapping.
-keepattributes SourceFile,LineNumberTable,Signature,*Annotation*,InnerClasses,EnclosingMethod

# Preserve generic type information used by Gson/TypeToken in release builds.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep flutter_local_notifications Android model classes used during (de)serialization.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Suppress Play Core task warnings referenced by Flutter's deferred component manager.
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
