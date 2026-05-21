# Spectra Panel: Developer Maintenance & Update Guide

This document is for the owner (NOTAPSXD) or an AI assistant to perform future updates to the Spectra Panel without breaking user data.

---

## 1. Project Structure
- **Source Folder:** `/home/ubuntu/spectra-panel/hvm/`
- **Main Script:** `spectra.py` (The logic)
- **UI Templates:** `templates/`
- **Static Assets:** `static/`
- **Distribution Folder:** `/home/ubuntu/spectra-panel-git/` (Pushes to GitHub)

---

## 2. How to Update the Code
1.  Open `/home/ubuntu/spectra-panel/hvm/spectra.py`.
2.  Make your logic changes or UI updates.
3.  **Important:** Do NOT change the database paths or `.env` loading logic, or users might lose their data.

---

## 3. How to Re-Compile to .bin
Once your changes are done, run this exact command to create the new secure binary:

```bash
cd /home/ubuntu/spectra-panel/hvm/
python3 -m nuitka \
    --follow-imports \
    --standalone \
    --onefile \
    --output-dir=build \
    --include-data-dir=/home/ubuntu/spectra-panel/hvm/static=static \
    --include-data-dir=/home/ubuntu/spectra-panel/hvm/templates=templates \
    spectra.py
```

*Note: This will take 5-10 minutes. The new file will be at `build/spectra.bin`.*

---

## 4. How to Push Update to GitHub
After compilation is finished, move the file to your Git folder and push:

```bash
# 1. Copy the new binary
cp /home/ubuntu/spectra-panel/hvm/build/spectra.bin /home/ubuntu/spectra-panel-git/

# 2. Go to Git folder
cd /home/ubuntu/spectra-panel-git/

# 3. Push to GitHub
git add .
git commit -m "Update: [Brief description of changes]"
git push -u origin main -f
```

---

## 5. How Users Update (No Data Loss)
The installer is designed to preserve data. When a user runs the install command again:
1. It downloads the **new** `spectra.bin`.
2. It **keeps** the existing `.env` (License key & Secrets).
3. It **keeps** the existing `spectra_panel.db` (User accounts & VPS data).
4. It restarts the service with the new code.

**User Update Command:**
```bash
bash <(curl -fsSL https://github.com/NOTAPSXD/Spectra-Panel/raw/main/installer.sh)
```

---

## 6. Master API (Next.js)
If you need to change license logic (expiration, banning), update the code in:
`/home/ubuntu/spectra-next-api/`
And push to: `https://github.com/NOTAPSXD/Spectra-api` (Vercel will auto-deploy).

---
**Guide Created:** May 21, 2026
**Owner:** NOTAPSXD
