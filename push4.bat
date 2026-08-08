@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Convert to standard Swift package format"
git push
del %0
