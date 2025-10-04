# Offline Build Instructions

The system is now configured for **completely offline deployment** - no internet connection required!

## What's Included

All required apps are included locally in the repository:
- **frappe**: Framework (downloaded during initial `bench init` from cached base image)
- **erpnext**: ERP application (local copy in `/erpnext/`)
- **epibus**: Industrial automation integration (local copy in `/epibus/`)
- **epitag**: Tag management system (local copy in `/epitag/`)

## Build Process

The custom Docker image (`frappe-epibus:latest`) is built entirely from local sources:

```bash
./development/build-epibus-image.sh
```

### What Happens During Build

1. **Base Images**: Uses pre-pulled `frappe/build:version-15` and `frappe/base:version-15`
2. **Local Apps**: All apps are copied from local directories:
   - `COPY erpnext /opt/erpnext`
   - `COPY epitag /opt/epitag`
   - `COPY epibus /opt/epibus`
3. **Installation**: Apps are installed using `pip install -e` from local sources
4. **No Network Calls**: No `git clone` or `bench get-app` with remote URLs

## Pre-Deployment Checklist

Before taking this system to an isolated network:

### 1. Pull Required Base Images (on internet-connected machine)

```bash
docker pull frappe/build:version-15
docker pull frappe/base:version-15
docker pull mariadb:10.6
docker pull redis:6.2-alpine
docker pull traefik:v2.11
```

### 2. Build Custom Image

```bash
./development/build-epibus-image.sh
```

### 3. Save Images for Transfer

```bash
# Save all required images to tar files
docker save frappe-epibus:latest -o frappe-epibus-latest.tar
docker save frappe/build:version-15 -o frappe-build-v15.tar
docker save frappe/base:version-15 -o frappe-base-v15.tar
docker save mariadb:10.6 -o mariadb-10.6.tar
docker save redis:6.2-alpine -o redis-6.2-alpine.tar
docker save traefik:v2.11 -o traefik-v2.11.tar

# Or save all at once
docker save \
  frappe-epibus:latest \
  frappe/build:version-15 \
  frappe/base:version-15 \
  mariadb:10.6 \
  redis:6.2-alpine \
  traefik:v2.11 \
  -o all-images.tar
```

### 4. Transfer to Offline System

Copy these files to the isolated system:
- `all-images.tar` (or individual .tar files)
- Entire `intralogisticsai/` directory

### 5. Load Images on Offline System

```bash
# Load all images
docker load -i all-images.tar

# Or load individual images
docker load -i frappe-epibus-latest.tar
docker load -i frappe-build-v15.tar
docker load -i frappe-base-v15.tar
docker load -i mariadb-10.6.tar
docker load -i redis-6.2-alpine.tar
docker load -i traefik-v2.11.tar
```

### 6. Verify Images

```bash
docker images | grep -E "frappe|mariadb|redis|traefik"
```

Expected output:
```
frappe-epibus          latest       ...   ...   1.85GB
frappe/build           version-15   ...   ...   2.1GB
frappe/base            version-15   ...   ...   1.5GB
mariadb                10.6         ...   ...   400MB
redis                  6.2-alpine   ...   ...   28MB
traefik                v2.11        ...   ...   85MB
```

## Deployment on Isolated Network

Once images are loaded, deploy normally:

```bash
cd /home/intralogisticsuser/intralogisticsai
./deploy.sh
```

The deployment will:
- ✅ Use local `frappe-epibus:latest` image (no pull from registry)
- ✅ Use locally loaded base images
- ✅ Not require internet for any operations

## Updating Apps on Isolated System

To update apps when offline:

1. **On Internet-Connected System:**
   ```bash
   cd erpnext
   git pull origin version-15
   cd ../epitag
   git pull origin main
   cd ../epibus
   git pull origin main
   ```

2. **Rebuild Image:**
   ```bash
   ./development/build-epibus-image.sh --no-cache
   ```

3. **Save and Transfer:**
   ```bash
   docker save frappe-epibus:latest -o frappe-epibus-latest-updated.tar
   # Transfer to isolated system
   ```

4. **On Isolated System:**
   ```bash
   docker load -i frappe-epibus-latest-updated.tar
   ./deploy.sh stop
   ./deploy.sh
   ```

## Repository Structure for Offline Build

```
intralogisticsai/
├── epibus/              # EpiBus app (local)
├── erpnext/             # ERPNext app (local)
├── epitag/              # EpiTag app (local)
├── images/
│   └── layered/
│       └── Containerfile   # Updated for offline build
├── development/
│   └── build-epibus-image.sh
└── deploy.sh
```

## Important Notes

- **Internet Required**: Only for the initial build and image preparation on an internet-connected machine
- **Offline Operation**: Once images are saved and loaded, no internet required
- **Updates**: App updates require rebuilding the image on an internet-connected machine, then transferring
- **Base Images**: Frappe base images rarely change, can be cached long-term
- **PLC Communication**: Works completely offline on local network (192.168.0.x)

## Troubleshooting Offline Deployment

### "Image not found" error
```bash
# Check if images are loaded
docker images

# Load missing images
docker load -i <image-file>.tar
```

### "Cannot pull image" error
```bash
# Ensure .env has correct settings
cat .env | grep PULL_POLICY
# Should show: PULL_POLICY=never
```

### Need to rebuild image
```bash
# Verify all local app directories exist
ls -la epibus/ erpnext/ epitag/

# Rebuild
./development/build-epibus-image.sh --no-cache
```
