# Update GitHub repo — v1.1.55

```bash
cd ~/Projects/erpnext-dev-installer

rm -rf /tmp/erpnext-dev-installer-v1155
mkdir -p /tmp/erpnext-dev-installer-v1155

unzip ~/Downloads/erpnext-dev-installer-v1.1.55.zip -d /tmp/erpnext-dev-installer-v1155

cp /tmp/erpnext-dev-installer-v1155/erpnext-dev.sh .
cp /tmp/erpnext-dev-installer-v1155/README.md .
cp /tmp/erpnext-dev-installer-v1155/ROADMAP.md .
cp /tmp/erpnext-dev-installer-v1155/CHANGELOG.md .
cp /tmp/erpnext-dev-installer-v1155/TESTING.md .
cp /tmp/erpnext-dev-installer-v1155/PRODUCTION-VALIDATION.md .
cp /tmp/erpnext-dev-installer-v1155/LICENSE .
cp /tmp/erpnext-dev-installer-v1155/GITHUB-UPDATE-v1.1.55.md .

chmod +x erpnext-dev.sh
```

## Validate before commit

```bash
bash -n erpnext-dev.sh
./erpnext-dev.sh version
./erpnext-dev.sh --help | grep -n "public-vm-guided-setup"
grep -n "explicit UFW DENY rule present" erpnext-dev.sh
grep -n "Backend validation URLs" erpnext-dev.sh
grep -n "Do not paste additional commands" README.md
grep -n "v1.1.55" CHANGELOG.md
grep -n "v1.1.55" TESTING.md
grep -n "v1.1.55" ROADMAP.md
grep -n "v1.1.55" PRODUCTION-VALIDATION.md
```

## Commit and tag

```bash
git status

git add erpnext-dev.sh README.md ROADMAP.md CHANGELOG.md TESTING.md PRODUCTION-VALIDATION.md LICENSE GITHUB-UPDATE-v1.1.55.md
git add -u

git commit -m "Release v1.1.55 document production validation polish"

git push origin main

git tag v1.1.55
git push origin v1.1.55
```

## Final confirmation

```bash
git status
git tag --list "v1.1.55"
git log --oneline -1
```

Expected result:

```text
working tree clean
v1.1.55
Release v1.1.55 document production validation polish
```
