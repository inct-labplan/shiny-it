# Deploy — shiny-it

Technical reference for the containerized runtime (`docker compose`) and the
automated deploy to the IPP VM over the UFRN VPN.

---

## 1. Architecture overview

```text
push to main ─▶ GitHub Actions runner
                  │  1. OpenVPN  ──────────────▶  UFRN VPN (vpncom1.info.ufrn.br:1194/udp)
                  │  2. sshpass ssh  ──────────▶  IPP VM (private, only reachable via VPN)
                  │  3. git reset --hard origin/main
                  │  4. docker compose up -d --build
                  ▼
            IPP VM ── container `shiny-it` ── Shiny on 0.0.0.0:3838
```

- **No build in CI.** The runner only opens the tunnel and drives `git` + `docker compose`
  over SSH. The image is **built on the VM**.
- The app is fully self-contained: it reads pre-built Parquet at startup and uses **no
  environment variables**, so there is no `.env` step (unlike the CKAN deploy).

---

## 2. Container runtime

### 2.1 `Dockerfile`

| Line | What & why |
| --- | --- |
| `FROM rocker/geospatial:4.5.2` | Base ships R **4.5.2** + **GDAL/GEOS/PROJ/UDUNITS** prebuilt — removes the slowest, most failure-prone part of installing `sf`/`terra`/`units`. |
| `ENV RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` | Disables the project-local `renv` bootstrap. Deps are installed into the **system library** and the app runs against it. |
| `COPY renv.lock renv.lock` → `renv::restore` | Restore runs **before** copying app code so this expensive layer is cached and only re-runs when `renv.lock` changes. |
| `. /etc/os-release && RENV_CONFIG_REPOS_OVERRIDE=…/${VERSION_CODENAME}/latest` | Points `renv` at **Posit Public Package Manager binaries for the base image's exact Ubuntu codename** (currently `noble`). This is what makes the restore fast — a mismatched codename silently falls back to source compilation. Deriving it from `/etc/os-release` keeps it correct across future base-image bumps. |
| `COPY . .` | App code + runtime data. Changes often, so it lands **after** the slow deps layer. |
| `EXPOSE 3838` / `CMD … runApp(host='0.0.0.0', port=3838)` | Binds all interfaces (required inside a container) on the default Shiny port. |

**Image size:** ~5.2 GB (geospatial base + ~140 R packages).

> ⚠️ **Codename pitfall:** if you ever hardcode the PPM URL (e.g. `…/jammy/…`) and it
> doesn't match the base image OS, the build still *succeeds* but compiles every package
> from source — turning a ~3-minute restore into 30+ minutes. Keep it derived from
> `/etc/os-release`.

### 2.2 `.dockerignore`

Keeps the build context small and the image lean by excluding everything not needed at runtime:

- `.git`, `*.Rproj`, `.Rproj.user`
- `renv/library`, `renv/staging`, `renv/local` (reinstalled from `renv.lock`)
- **Data-generation only:** `dados_tro/` (~149 MB), `generate_indicadores/`,
  `download_ibge.R`, `indicadores.xlsx`
- Dev/CI: `tests/`, `rsconnect/`, `deploy.R`, the Docker files themselves

### 2.3 `docker-compose.yml`

```yaml
services:
  shiny-it:
    build: .
    image: shiny-it:latest
    container_name: shiny-it
    ports: ["3838:3838"]
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "R", "-e", "close(url('http://127.0.0.1:3838'))"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

- `restart: unless-stopped` — survives VM reboots / crashes.
- `start_period: 60s` — gives the app time to load Parquet + source spatial code before
  the healthcheck counts failures.
- No `env_file` — the app reads no environment variables.

### 2.4 Runtime data contract

The app **stops at startup** (`global.R`) if any of these are missing. All are tracked in git:

| Path | Role |
| --- | --- |
| `indicadores.parquet` | Main indicator table (the data DTO) |
| `map_legend.parquet` | Map legend classes/colors |
| `diretorio_ibge.parquet` | Territorial hierarchy (Brasil ▸ UF ▸ RM ▸ Município) |
| `ibge_malhas/*.parquet` | Spatial geometries (~12 MB) — **were gitignored; now force-tracked** so the git-based deploy ships them |
| `www/` | CSS + logo, served at `/assets` |

**Updating displayed data:** replace `indicadores.parquet` (and `map_legend.parquet` if map
indicators changed), commit, push to `main`. The deploy rebuilds and restarts automatically.
No generation scripts run in production.

### 2.5 Local usage

```bash
docker compose build          # first build ~ slow (pulls 5 GB base + restores deps)
docker compose up -d          # start; app at http://localhost:3838
docker compose logs -f        # follow logs ("Listening on http://0.0.0.0:3838" = ready)
docker compose ps             # health status
docker compose down           # stop & remove
docker compose up -d --build  # rebuild + restart after code/data changes
```

---

## 3. Automated deploy (`.github/workflows/deploy.yml`)

### 3.1 Trigger

```yaml
on: { push: { branches: [main, feat/vpn-gated-deploy] } }
```

`feat/vpn-gated-deploy` is kept as a testing branch; drop it once the flow is proven.

### 3.2 Secrets (repo-level, on `inct-labplan/shiny-it`)

Org-level secrets aren't available to **private** repos on the free plan, so these are set
**per-repo** (duplicated across `ckan-labplan`, `site-governanca`, `shiny-it`).

| Secret | Purpose |
| --- | --- |
| `OVPN_P12_B64` | Client cert `client.p12`, **base64-encoded** (decoded with `base64 -d` in the runner) |
| `OVPN_TLS_KEY` | `tls-auth` static key, stored **verbatim** (multiline) |
| `OVPN_USER` / `OVPN_PASS` | UFRN VPN username / password |
| `VM_HOST` / `VM_PORT` | VM address + SSH port (reachable only through the tunnel) |
| `VM_USERNAME` / `VM_PASSWORD` | SSH credentials (used via `sshpass`) |

> Secret **values can never be read back** from GitHub. To rotate, re-set with
> `gh secret set <NAME> -R inct-labplan/shiny-it`. The cert/key originate from
> `~/vpn-labplan/` (`*.p12`, `*-tls.key`).

### 3.3 Job steps

1. **Install OpenVPN + tooling** — `openvpn openvpn-systemd-resolved sshpass`.
2. **Materialize VPN credentials** — writes `client.p12` (`base64 -d`), `tls.key`, and a
   2-line `auth.txt` (user/pass) to `$RUNNER_TEMP/vpn` (`chmod 600`), plus a CI-adapted
   `client.ovpn` that references those files (no inline secrets). Key config: `remote
   vpncom1.info.ufrn.br 1194 udp4`, `verify-x509-name "ufrnServerCA"`, `pkcs12 client.p12`,
   `tls-auth tls.key 1`.
3. **Connect to VPN** — up to **3 attempts** (fresh `openvpn --daemon` each time). Per
   attempt, polls `nc -z VM_HOST VM_PORT` for up to ~80 s; on success exits the step, on
   failure dumps `openvpn.log` and kills the daemon. UFRN's UDP handshake is occasionally
   flaky from GitHub runners, hence the retries.
4. **Clone / update repo and deploy over VPN** — a script is piped over the encrypted SSH
   channel via **stdin** (`bash -s`) so the token never appears on a command line:
   - `REPO_DIR="$HOME/shiny-it"`; clone with a short-lived `x-access-token` URL if absent.
   - `git fetch --all` → `git reset --hard origin/main`.
   - **Scrub the token** from the stored remote (`set-url origin <clean-url>`).
   - `docker compose up -d --build` then `docker image prune -f`.
5. **Disconnect VPN** — `if: always()`, kills the daemon by PID.

### 3.4 Security properties

- The `GITHUB_TOKEN` is run-scoped, passed only over SSH stdin, and scrubbed from the VM
  remote afterward — nothing sensitive persists on the VM.
- VPN credentials live only in `$RUNNER_TEMP` and are discarded with the ephemeral runner.
- `permissions: contents: read` — the workflow's token is read-only.

---

## 4. VM prerequisites

The deploy assumes the VM already has:

- **Docker Engine + Compose plugin** (`docker compose` v2). Verify: `docker compose version`.
- The deploy user can run `docker` (in the `docker` group or via sudo-less setup).
- **SSH password auth** enabled for `VM_USERNAME` (the flow uses `sshpass`, not keys).
- Outbound HTTPS to GitHub + `packagemanager.posit.co` (deps) and Docker Hub (base image).
- Disk headroom for a ~5 GB image (+ build cache). `docker image prune -f` runs each deploy
  to limit dangling-layer growth.
- Whatever fronts port `3838` (reverse proxy / firewall) — **not** handled here.

---

## 5. Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| Build takes 30+ min on package install | PPM codename mismatch → source compiles. Confirm base OS (`. /etc/os-release`) matches the PPM URL. |
| First build "hangs" ~30 min with no package output | One-time pull/extract of the ~5 GB geospatial base (slow on WSL2). Subsequent builds reuse it. |
| App container exits at startup | Missing runtime Parquet — check `docker compose logs` for `Arquivo … não encontrado`. Ensure `ibge_malhas/*.parquet` are committed. |
| Maps render empty but charts work | `ibge_malhas/` not shipped (gitignored again?). `git ls-files ibge_malhas/` must list the parquet. |
| `VPN did not establish … after 3 attempts` | UFRN UDP flakiness or wrong `OVPN_*` secrets; re-run, then inspect the dumped `openvpn.log`. |
| SSH step fails | Wrong `VM_*` secrets, or VM not reachable through the tunnel (check the `nc` probe target). |
| Screenshot button does nothing | `chromium` isn't installed in the image (`shinyscreenshot`/`webshot2`). Optional; add `chromium` via `apt-get` in the Dockerfile to enable. |

---

## 6. End-to-end verification

**Local:** `docker compose up -d` → open `http://localhost:3838` → confirm the **map tab**
renders polygons (proves malhas shipped + GDAL works) and the **chart tab** renders; check
`docker compose ps` shows `healthy`.

**Deploy:** push to the test branch, watch the Actions run (VPN up → repo reset → compose
up). On the VM: `docker compose ps` shows `shiny-it` healthy; reach the app over its exposed
port.
