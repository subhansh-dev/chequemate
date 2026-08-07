@echo off
cd /d C:\Users\Admin\Desktop\huewaves
git add -A
git commit -m "Complete redesign: Liquid Glass + Supabase auth + premium UI"
git push
del %0
