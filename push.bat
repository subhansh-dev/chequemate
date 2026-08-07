@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Fix Swift compilation errors for iOS"
git push
del %0
