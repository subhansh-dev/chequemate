@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Guest mode: works without credentials + CI fix"
git push
del %0
