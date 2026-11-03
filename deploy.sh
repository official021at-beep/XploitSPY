#!/bin/bash

echo "[*] Starting advanced automated deployment process..."

# 1. Check & fix execution permissions for git and local environment
if [ ! -d ".git" ]; then
    echo "[!] Not a git repository. Initializing git..."
    git init
    git remote add origin https://github.com/official021at-beep/XploitSPY.git 2>/dev/null
fi

# 2. Fix potential permission issues or missing dependencies automatically
echo "[*] Checking and granting necessary permissions..."
chmod -R +x . 2>/dev/null

# 3. Handle untracked or conflict issues gracefully
echo "[*] Staging all modified and new files..."
git add -A

# 4. Check if there are changes to commit
if git diff-staged --quiet; then
    echo "[!] No changes detected to commit."
else
    COMMIT_MSG="Auto-fix & deploy update: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "[*] Committing changes: '$COMMIT_MSG'"
    git commit -m "$COMMIT_MSG"
fi

# 5. Push to remote repository with automatic branch detection & force option if needed
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="master"
fi

echo "[*] Pushing code to remote branch ($CURRENT_BRANCH)..."
git push origin "$CURRENT_BRANCH" --force-with-lease

if [ $? -eq 0 ]; then
    echo "[+] Success! Code successfully deployed and pushed to GitHub. Render will update automatically."
else
    echo "[!] Warning: Standard push failed. Attempting force sync..."
    git push -u origin "$CURRENT_BRANCH" --force
    if [ $? -eq 0 ]; then
        echo "[+] Force push successful!"
    else
        echo "[❌] Critical Error: Push failed. Check your internet connection or repository credentials."
    fi
fi
