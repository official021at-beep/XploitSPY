-optimizationpasses 20
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-repackageclasses 'com.android.system.core.secure'
-allowaccessmodification
-overloadaggressively
-mergeinterfacesaggressively
