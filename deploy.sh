#!/bin/bash

# 1. Build Flutter web
flutter build web

# 2. Create temp folder to hold build
mkdir -p temp_deploy
cp -r build/web/* temp_deploy/

# 3. Switch to gh-pages branch (create if missing)
git checkout gh-pages 2>/dev/null || git checkout --orphan gh-pages

# 4. Clean branch
git rm -rf . > /dev/null 2>&1
cp -r temp_deploy/* .

# 5. Commit and push
git add .
git commit -m "🚀 Deploy latest Flutter web build"
git push origin gh-pages --force

# 6. Switch back to main
git checkout main

# 7. Clean up
rm -rf temp_deploy

echo "✅ Deployment complete! Check your site at https://gregambrown.github.io/garrison/"
