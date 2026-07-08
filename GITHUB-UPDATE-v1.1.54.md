Update GitHub repo
cd ~/Projects/erpnext-dev-installer

rm -rf /tmp/erpnext-dev-installer-v1154
mkdir -p /tmp/erpnext-dev-installer-v1154

unzip ~/Downloads/erpnext-dev-installer-v1.1.54.zip -d /tmp/erpnext-dev-installer-v1154

cp /tmp/erpnext-dev-installer-v1154/erpnext-dev.sh .
cp /tmp/erpnext-dev-installer-v1154/README.md .
cp /tmp/erpnext-dev-installer-v1154/ROADMAP.md .
cp /tmp/erpnext-dev-installer-v1154/CHANGELOG.md .
cp /tmp/erpnext-dev-installer-v1154/TESTING.md .
cp /tmp/erpnext-dev-installer-v1154/PRODUCTION-VALIDATION.md .
cp /tmp/erpnext-dev-installer-v1154/LICENSE .
cp /tmp/erpnext-dev-installer-v1154/GITHUB-UPDATE-v1.1.54.md .

chmod +x erpnext-dev.sh

bash -n erpnext-dev.sh
./erpnext-dev.sh version
./erpnext-dev.sh --help | grep -n "public-vm-guided-setup"
grep -n "Choose another SSL provider" erpnext-dev.sh
grep -n "Cloudflare Origin CA" README.md
grep -n "Production HTTPS provider choice" PRODUCTION-VALIDATION.md
grep -n "v1.1.54" CHANGELOG.md
grep -n "v1.1.54" TESTING.md

Commit and tag
git status

git add erpnext-dev.sh README.md ROADMAP.md CHANGELOG.md TESTING.md PRODUCTION-VALIDATION.md LICENSE GITHUB-UPDATE-v1.1.54.md
git add -u

git commit -m "Release v1.1.54 add guided SSL provider choice"

git push origin main

git tag v1.1.54
git push origin v1.1.54

Final confirmation
git status
git tag --list "v1.1.54"
git log --oneline -1
