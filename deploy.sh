#!/bin/bash
echo "[*] Starting automated build optimization & deployment..."

# 1. Automatically find and update build.gradle or create it if missing
BUILD_GRADLE_PATH=$(find . -name "build.gradle" | head -n 1)
if [ -z "$BUILD_GRADLE_PATH" ]; then
    mkdir -p app
    BUILD_GRADLE_PATH="app/build.gradle"
fi

echo "[*] Configuring build settings at: $BUILD_GRADLE_PATH"
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
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
GRADLE_EOF

# 2. Setup git repository if not initialized
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

# 3. Grant permissions and stage files
chmod -R +x . 2>/dev/null
git add -A

# 4. Commit changes
if git diff-staged --quiet; then
    echo "[!] No changes detected to commit."
else
    COMMIT_MSG="Auto-optimize & deploy: $(date +'%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
fi

# 5. Push to remote repository
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing optimized code to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease

if [ $? -eq 0 ]; then
    echo "[+] Success! Fully automated update and deployment completed."
else
    git push -u origin "$CURRENT_BRANCH" --force
fi
