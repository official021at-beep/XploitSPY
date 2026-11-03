-optimizationpasses 7
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
-printmapping mapping.txt

# Remove all logs and debug signatures
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}

# Keep necessary Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Aggressive renaming and repackaging to break static signatures
-repackageclasses 'androidx.core.app.internal'
-allowaccessmodification
-overloadaggressively
-mergeinterfacesaggressively
