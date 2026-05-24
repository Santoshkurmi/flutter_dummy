# 1. Keep all Google ML Kit classes and their internal components intact
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

# 2. Prevent R8 from stripping out internal SDK dependencies and transport backends
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.datatransport.** { *; }

# 3. Explicitly keep the specific classes used by mobile_scanner
-keep class com.example.mobile_scanner.** { *; }
-keep class dev.nhancv.mobile_scanner.** { *; }

# 4. Silence harmless warnings from missing metadata or optional dependencies
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**