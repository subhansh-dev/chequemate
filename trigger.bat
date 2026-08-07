@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Trigger fresh CI build"
git push
del %0
