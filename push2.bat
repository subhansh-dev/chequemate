@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Update CI: clean build, use swift build directly"
git push
del %0
