# Update GitHub repo — v1.1.56

```bash
cd ~/Projects/erpnext-dev-installer

rm -rf /tmp/erpnext-dev-installer-v1156
mkdir -p /tmp/erpnext-dev-installer-v1156

unzip ~/Downloads/erpnext-dev-installer-v1.1.56.zip -d /tmp/erpnext-dev-installer-v1156

cp /tmp/erpnext-dev-installer-v1156/erpnext-dev.sh .
cp /tmp/erpnext-dev-installer-v1156/README.md .
cp /tmp/erpnext-dev-installer-v1156/ROADMAP.md .
cp /tmp/erpnext-dev-installer-v1156/CHANGELOG.md .
cp /tmp/erpnext-dev-installer-v1156/TESTING.md .
cp /tmp/erpnext-dev-installer-v1156/PRODUCTION-VALIDATION.md .
cp /tmp/erpnext-dev-installer-v1156/LICENSE .
cp /tmp/erpnext-dev-installer-v1156/GITHUB-UPDATE-v1.1.56.md .

chmod +x erpnext-dev.sh
```

## Validate before commit

```bash
bash -n erpnext-dev.sh
./erpnext-dev.sh version
./erpnext-dev.sh --help | grep -n "public-vm-guided-setup"
grep -n "Continue with Cloudflare proxied" erpnext-dev.sh
grep -n "Cloudflare Origin CA path selected" erpnext-dev.sh
grep -n "v1.1.56" CHANGELOG.md
grep -n "v1.1.56" TESTING.md
grep -n "v1.1.56" ROADMAP.md
grep -n "v1.1.56" PRODUCTION-VALIDATION.md
```

## Commit and tag

```bash
git status

git add erpnext-dev.sh README.md ROADMAP.md CHANGELOG.md TESTING.md PRODUCTION-VALIDATION.md LICENSE GITHUB-UPDATE-v1.1.56.md
git add -u

git commit -m "Release v1.1.56 fix Cloudflare proxied DNS guided setup"

git push origin main

git tag v1.1.56
git push origin v1.1.56
```

## Final confirmation

```bash
git status
git tag --list "v1.1.56"
git log --oneline -1
```
