# TensorFlow Lite (accessed through JNI / reflection)
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face** { *; }
-dontwarn com.google.mlkit.**

# Flutter deferred components (referenced but unused)
-dontwarn com.google.android.play.core.**
