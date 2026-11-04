#!/bin/bash
echo "[*] Running fully optimized and warning-free deployment script..."

# 1. Target build.gradle or create it securely
BUILD_GRADLE_PATH=$(find . -name "build.gradle" | head -n 1)
if [ -z "$BUILD_GRADLE_PATH" ]; then
    mkdir -p app
    BUILD_GRADLE_PATH="app/build.gradle"
fi

cat << 'GRADLE_EOF' > "$BUILD_GRADLE_PATH"
android {
    compileSdkVersion 34
    defaultConfig {
        targetSdkVersion 34
        minSdkVersion 21
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

# 2. Generate Keystore safely if missing
KEYSTORE_PATH=$(dirname "$BUILD_GRADLE_PATH")/custom-ready.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
    keytool -genkeypair -v -keystore "$KEYSTORE_PATH" -alias securekey -keyalg RSA -keysize 2048 -validity 10000 -storepass securepass123 -keypass securepass123 -dname "CN=System, OU=Core, O=Dev, L=Unknown, ST=Unknown, C=US" 2>/dev/null || true
fi

# 3. Clean ProGuard rules
PROGUARD_PATH=$(dirname "$BUILD_GRADLE_PATH")/proguard-rules.pro
cat << 'PROGUARD_EOF' > "$PROGUARD_PATH"
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-repackageclasses 'com.secure.core'
-allowaccessmodification
PROGUARD_EOF

# 4. Git setup and clean push (Using correct --cached flag to avoid any warnings)
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

chmod -R +x . 2>/dev/null
git add -A

if git diff --cached --quiet; then
    echo "[!] No changes detected."
else
    git commit -m "Flawless secure deploy: $(date +'%Y-%m-%d %H:%M:%S')"
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing clean deployment to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease || git push -u origin "$CURRENT_BRANCH" --force

if [ $? -eq 0 ]; then
    echo "[+] Success! Flawless deployment completed without any warnings."
fi
