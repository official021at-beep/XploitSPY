#!/bin/bash
echo "[*] Starting advanced automated evasion & deployment setup..."

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
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
GRADLE_EOF

# 2. Create or update proguard-rules.pro for strong obfuscation
PROGUARD_PATH=$(dirname "$BUILD_GRADLE_PATH")/proguard-rules.pro
cat << 'PROGUARD_EOF' > "$PROGUARD_PATH"
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep necessary classes and obfuscate everything else
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Obfuscate internal logic
-repackageclasses 'com.secure.internal'
-allowaccessmodification
PROGUARD_EOF

# 3. Setup git repository if not initialized
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

# 4. Grant permissions and stage all files
chmod -R +x . 2>/dev/null
git add -A

# 5. Commit changes automatically
if git diff-staged --quiet; then
    echo "[!] No changes detected to commit."
else
    COMMIT_MSG="Advanced obfuscation & auto-deploy: $(date +'%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
fi

# 6. Push to GitHub to trigger Render build
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing highly optimized secure code to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease

if [ $? -eq 0 ]; then
    echo "[+] Success! Advanced evasion setup and deployment completed."
else
    git push -u origin "$CURRENT_BRANCH" --force
fi
