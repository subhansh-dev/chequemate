@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Fix Package.swift encoding and tools version"
git push
del %0
