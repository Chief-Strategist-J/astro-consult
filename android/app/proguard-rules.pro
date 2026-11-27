# VideoSDK's native (Rust) library looks these classes up by name over JNI. If R8 renames or strips
# them, nativeInitAndroid panics at startup (SIGTRAP) and the app dies when a call starts.
-keep class live.videosdk.** { *; }
-keep class videosdk.org.webrtc.** { *; }
-keep class videosdk.org.jni_zero.** { *; }
-keep class org.rustls.platformverifier.** { *; }
-keep class org.webrtc.** { *; }
-keepclasseswithmembernames class * { native <methods>; }
-dontwarn com.google.mlkit.**
-dontwarn org.webrtc.**
-dontwarn videosdk.org.**
