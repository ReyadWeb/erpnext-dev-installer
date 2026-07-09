# Update GitHub repo - v1.1.57

```bash
cd ~/Projects/erpnext-dev-installer

rm -rf /tmp/erpnext-dev-installer-v1157
mkdir -p /tmp/erpnext-dev-installer-v1157

unzip ~/Downloads/erpnext-dev-installer-v1.1.57.zip -d /tmp/erpnext-dev-installer-v1157

cp /tmp/erpnext-dev-installer-v1157/erpnext-dev.sh .
cp /tmp/erpnext-dev-installer-v1157/README.md .
cp /tmp/erpnext-dev-installer-v1157/ROADMAP.md .
cp /tmp/erpnext-dev-installer-v1157/CHANGELOG.md .
cp /tmp/erpnext-dev-installer-v1157/TESTING.md .
cp /tmp/erpnext-dev-installer-v1157/PRODUCTION-VALIDATION.md .
cp /tmp/erpnext-dev-installer-v1157/LICENSE .
cp /tmp/erpnext-dev-installer-v1157/GITHUB-UPDATE-v1.1.57.md .

chmod +x erpnext-dev.sh
```

## Validate before commit

```bash
bash -n erpnext-dev.sh
./erpnext-dev.sh version
./erpnext-dev.sh --help | grep -n "public-vm-guided-setup"
grep -n "v1.1.57" CHANGELOG.md
grep -n "v1.1.57" TESTING.md
grep -n "v1.1.57" ROADMAP.md
grep -n "v1.1.57" PRODUCTION-VALIDATION.md
grep -n "Cloudflare Origin CA / Full (strict): validated" README.md ROADMAP.md PRODUCTION-VALIDATION.md
grep -n "Cloudflare Origin CA validation record" CHANGELOG.md TESTING.md
```

## Commit and tag

```bash
git status

git add erpnext-dev.sh README.md ROADMAP.md CHANGELOG.md TESTING.md PRODUCTION-VALIDATION.md LICENSE GITHUB-UPDATE-v1.1.57.md
git add -u

git commit -m "Release v1.1.57 document Cloudflare Origin CA validation"

git push origin main

git tag v1.1.57
git push origin v1.1.57
```

## Final confirmation

```bash
git status
git tag --list "v1.1.57"
git log --oneline -1
```

Expected:

```text
working tree clean
v1.1.57
Release v1.1.57 document Cloudflare Origin CA validation
```
