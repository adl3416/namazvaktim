# Keep Flutter and plugin registration classes used by reflection.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep line numbers/source info for better crash diagnostics in mapping.
-keepattributes SourceFile,LineNumberTable
