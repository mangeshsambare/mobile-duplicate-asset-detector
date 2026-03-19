
---

# 6️⃣ 🚀 How to Publish (Quick Steps)

1. Create repo on GitHub  
2. Add files as above  
3. Run:

```bash
chmod +x scripts/detect-duplicate-images.sh
git add .
git commit -m "Initial commit - duplicate asset detector"
git push


Android
tasks.register<Exec>("checkDuplicateDrawables") {
    group = "verification"
    description = "Detects duplicate drawable resources using a shell script."

    commandLine("bash", "${rootProject.projectDir}/detect-duplicate-images.sh", "./src/main/res/")
    isIgnoreExitValue = false

    doFirst {
        println("🔍 Starting duplicate drawable check...")
    }

    doLast {
        println("✅ Duplicate drawable check completed successfully!")
    }
}

// Optional we can add while building
tasks.named("check") {
    dependsOn("checkDuplicateDrawables")
}

Developers can run:
# Run duplicate check manually
./gradlew checkDuplicateDrawables

# Run as part of standard verification
./gradlew check

# Direct script execution
# Android
./detect-duplicate-images.sh ./app/src/main/res/

# iOS
./detect-duplicate-images.sh ./ios/YourApp/Assets.xcassets/
