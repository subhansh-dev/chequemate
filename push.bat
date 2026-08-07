@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Add GitHub Actions CI for iOS compilation"
git push
del %0
