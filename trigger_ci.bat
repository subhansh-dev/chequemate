@echo off
cd /d C:\Users\Admin\Desktop\huewaves
echo // Huewaves >> download/huewaves.swiftpm/Sources/HuewavesApp.swift
git add -A
git commit -m "Trigger CI with latest code"
git push
del %0
