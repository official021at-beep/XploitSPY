#!/bin/bash
echo "[*] Initializing XploitSPY Deployment Fix..."

# 1. Server files ko root me copy karein taaki Railway seedha run kar sake
if [ -d "server" ]; then
    cp -r server/* . 2>/dev/null || true
    echo "[+] Server files synced to root directory."
fi

# 2. Ensure package.json has correct dependencies and start script
cat << 'JSON_EOF' > package.json
{
  "name": "xploitspy-server",
  "version": "3.0.0",
  "description": "XploitSPY Core System Management",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "socket.io": "^4.7.5",
    "ejs": "^3.1.9",
    "geoip-lite": "^1.4.7"
  }
}
JSON_EOF

# 3. Railway nixpacks configuration
cat << 'EOF_NIX' > nixpacks.toml
[phases.build]
cmds = ["npm install"]

[start]
cmd = "node index.js"
EOF_NIX

# 4. Git sync and push to Railway
chmod -R +x . 2>/dev/null
git add -A
git commit -m "Sync server files to root for clean Railway deployment: $(date +'%Y-%m-%d %H:%M:%S')" 2>/dev/null || true
git push origin master --force

if [ $? -eq 0 ]; then
    echo "[+] Success! XploitSPY core deployed successfully to root."
fi
