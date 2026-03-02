# Deploy Guide — rtgarden.com

How to deploy this site (and how to set up a new one using the same pattern).

## How It Works

Push to `main` → GitHub Action rsyncs files to a temp directory on the server → sudo copies them to the web root. The site updates in about 45 seconds.

```
Local files → GitHub (main branch) → Action triggers → rsync to /tmp/ → sudo cp to /var/www/html/
```

## Deploying Changes

Just push to `main`. The Action handles the rest.

If you're working with Claude in Cowork mode, Claude edits files locally and pushes via the browser — no terminal needed.

For bulk changes (like CSS across all 1,450 files), you can also run the manual script:

```bash
cd ~/Desktop/webme/teahouse-of-the-donkey/site
bash DEPLOY.sh
```

## GitHub Action Details

The workflow lives at `.github/workflows/deploy.yml`. It does two things:

1. **rsync** the repo contents to `/tmp/teahouse/` on the server (using `sshpass` for password auth)
2. **SSH** in and `sudo cp` everything from `/tmp/teahouse/` to `/var/www/html/`, then fix ownership and permissions

This two-step approach exists because the deploy user (`rtgarden-admin`) can't write directly to `/var/www/html/` — those files are owned by `www-data`. Rsyncing to a temp directory first, then using sudo to copy, solves the permissions issue.

### Required Secrets

Set these in the repo: Settings → Secrets and variables → Actions → New repository secret

| Secret | Value | Notes |
|--------|-------|-------|
| `SERVER_HOST` | Server IP address | e.g., 159.89.129.150 |
| `SERVER_USER` | SSH username | e.g., rtgarden-admin |
| `SERVER_PASSWORD` | SSH password | Used by sshpass for non-interactive auth |

## Setting Up a New Site with This Pattern

### 1. Create the GitHub repo

```bash
# Or create via github.com → New repository
gh repo create mysite --public
```

### 2. Add the deploy Action

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to mysite

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Install sshpass
        run: sudo apt-get install -y sshpass

      - name: Upload files to server
        env:
          SSHPASS: ${{ secrets.SERVER_PASSWORD }}
        run: |
          sshpass -e rsync -avz \
            -e "ssh -o StrictHostKeyChecking=no" \
            --exclude '.git' \
            --exclude '.github' \
            --exclude '.DS_Store' \
            ./ ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }}:/tmp/mysite/

      - name: Copy to web root with sudo
        env:
          SSHPASS: ${{ secrets.SERVER_PASSWORD }}
        run: |
          sshpass -e ssh -o StrictHostKeyChecking=no \
            ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }} \
            "echo $SSHPASS | sudo -S cp -r /tmp/mysite/* /var/www/html/mysite/ && sudo chown -R www-data:www-data /var/www/html/mysite/ && sudo chmod -R 755 /var/www/html/mysite/ && rm -rf /tmp/mysite"
```

Change `/tmp/mysite/` and `/var/www/html/mysite/` to match your site. For the root site, use `/var/www/html/`.

### 3. Add secrets to the repo

Go to the repo on GitHub → Settings → Secrets and variables → Actions, and add:
- `SERVER_HOST`
- `SERVER_USER`
- `SERVER_PASSWORD`

### 4. Create the target directory on the server

```bash
ssh rtgarden-admin@159.89.129.150
sudo mkdir -p /var/www/html/mysite
sudo chown www-data:www-data /var/www/html/mysite
```

### 5. Push and verify

Push anything to `main` and check the Actions tab. Green checkmark = deployed.

## Gotchas We Hit

- **Never use `--delete` with rsync** if the server has files not in the repo (videos, uploaded images, etc.) — rsync will try to remove them and fail on permissions
- **Direct rsync to `/var/www/html/` fails** because the deploy user doesn't own those files. Always rsync to a temp dir first, then sudo cp.
- **`echo $SSHPASS | sudo -S`** passes the password to sudo non-interactively. The `$SSHPASS` env var is set on the GitHub runner and expands correctly in the SSH command string.
- **StrictHostKeyChecking=no** is needed because the GitHub runner has never connected to your server before. For production, consider using known_hosts instead.

## Server Details

- **Server:** Digital Ocean droplet at 159.89.129.150
- **Web root:** /var/www/html/
- **Web server:** Nginx, serving static files
- **File ownership:** www-data:www-data
- **Deploy user:** rtgarden-admin (has sudo access)
- **Live URL:** https://rtgarden.com
