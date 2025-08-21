# Windows Installation Guide

This guide covers installing IntralogisticsAI on Windows 11 systems, including preparation for both Docker hosts and client workstations.

## Prerequisites

### Windows 11 System Requirements
- **Windows 11 Pro/Home** - **CRITICAL: You *must* have the latest version of Windows 11 installed** for Docker and WSL2 to work properly. Often, new PCs are shipped with outdated versions of Windows. You may have to completely use the Windows Installer to get to the latest version of Windows.
- **16GB+ RAM** (32GB recommended for full lab deployment)
- **100GB+ free disk space** for Docker images and containers
- **Administrator access** for Docker Desktop installation
- **Virtualization enabled** in BIOS/UEFI (required for WSL2)
- **AMD Ryzen 7 or Intel Core i7+** recommended for lab deployment

### Required Software
1. **Windows Subsystem for Linux 2 (WSL2)**
2. **Docker Desktop for Windows**
3. **Git for Windows** (or use Git within WSL2)

## Installation Steps

### Step 1: Enable WSL2

1. **Open PowerShell as Administrator:**
   - Right-click Start button → "Windows Terminal (Admin)"
   - Or search "PowerShell" → Right-click → "Run as administrator"

2. **Install WSL2:**
   ```powershell
   # Enable WSL and install Ubuntu
   wsl --install
   
   # If already installed, ensure WSL2 is default
   wsl --set-default-version 2
   ```

3. **Restart your computer** when prompted.

4. **Complete Ubuntu setup:**
   - After restart, Ubuntu will auto-launch
   - Create a username and password for your Linux environment
   - Update packages:
     ```bash
     sudo apt update && sudo apt upgrade -y
     ```

### Step 2: Install Docker Desktop

1. **Download Docker Desktop:**
   - Visit [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
   - Download the installer

2. **Install Docker Desktop:**
   - Run the installer as Administrator
   - **IMPORTANT:** Ensure "Use WSL 2 instead of Hyper-V" is checked during installation
   - Complete the installation and restart if prompted

3. **Configure Docker Desktop:**
   - Launch Docker Desktop
   - Go to Settings → General
   - Ensure "Use the WSL 2 based engine" is enabled
   - Go to Settings → Resources → WSL Integration
   - Enable integration with your default WSL distro (Ubuntu)

### Step 3: Install Git (Optional)

Choose one option:

**Option A: Git for Windows (Recommended for beginners)**
```powershell
# Download from https://gitforwindows.org/
# Install with default settings
```

**Option B: Git within WSL2 (Recommended for Docker host)**
```bash
# In WSL2 terminal
sudo apt install git
```

### Step 4: Verify Installation

1. **Test WSL2:**
   ```powershell
   wsl --list --verbose
   # Should show Ubuntu running in version 2
   ```

2. **Test Docker in WSL2:**
   ```bash
   # Open WSL2 terminal (Ubuntu)
   docker --version
   docker compose --version
   docker run hello-world
   ```

## IntralogisticsAI Deployment

### For Docker Host (Server)

1. **Open WSL2 terminal** (Ubuntu)

2. **Clone repository:**
   ```bash
   # Clone to a shared location accessible from Windows
   cd /mnt/c/
   git clone https://github.com/appliedrelevance/intralogisticsai
   cd intralogisticsai
   ```

3. **Configure environment files:**
   ```bash
   # Copy example environment file
   cp example.env .env
   
   # Edit .env file with your settings (optional for basic deployment)
   nano .env
   ```

4. **Set Windows-specific environment:**
   ```bash
   # Required for Windows Docker path handling
   export COMPOSE_CONVERT_WINDOWS_PATHS=1
   
   # Optional: Add to your shell profile for persistence
   echo 'export COMPOSE_CONVERT_WINDOWS_PATHS=1' >> ~/.bashrc
   ```

5. **Deploy the platform:**
   ```bash
   # For complete training lab (requires sudo for hosts file)
   sudo ./deploy.sh lab
   
   # For industrial automation features (direct ports)
   ./deploy.sh with-plc
   
   # For basic ERP only
   ./deploy.sh
   ```

6. **Verify deployment:**
   ```bash
   docker compose ps
   ```

### For Client Workstations

Client workstations only need web browsers to access the platform:

1. **Configure DNS** (if using custom domains):
   - Open `C:\Windows\System32\drivers\etc\hosts` as Administrator
   - Add entries pointing to Docker host IP:
     ```
     192.168.1.100 intralogistics.lab
     192.168.1.100 openplc.intralogistics.lab
     192.168.1.100 dashboard.intralogistics.lab
     ```

2. **Access web interfaces:**
   - **IntralogisticsAI**: `http://intralogistics.lab`
   - **OpenPLC**: `http://openplc.intralogistics.lab`
   - **Traefik Dashboard**: `http://dashboard.intralogistics.lab`
   - **MODBUS TCP**: `192.168.1.100:502` (for PLC connections)
   - **PLC Bridge API**: `http://192.168.1.100:7654`

## Troubleshooting

### Lab Domain Access Issues

**Problem:** Cannot access `intralogistics.lab` after successful deployment

This is the most common issue on Windows. The deployment script should automatically update your hosts file, but if it fails:

**Solution 1: Manual Hosts File Update**
1. Open PowerShell as Administrator
2. Edit the hosts file:
   ```powershell
   notepad C:\Windows\System32\drivers\etc\hosts
   ```
3. Add this line at the end:
   ```
   127.0.0.1 intralogistics.lab openplc.intralogistics.lab dashboard.intralogistics.lab
   ```
4. Save the file and flush DNS:
   ```powershell
   ipconfig /flushdns
   ```

**Solution 2: Use Direct Port Access**
If hosts file modification isn't working, use the direct localhost ports:
```bash
# Check what port the frontend is using
docker compose ps

# Access via localhost (replace 8080 with actual port)
http://localhost:8080
```

**Verification:**
```bash
# In WSL2, test if hosts file was updated correctly
grep "intralogistics.lab" /mnt/c/Windows/System32/drivers/etc/hosts

# Test domain resolution
curl -I http://intralogistics.lab
```

### WSL2 Issues

**Problem:** WSL2 not starting or slow performance
```powershell
# Restart WSL2
wsl --shutdown
wsl

# Check WSL2 memory usage
wsl --list --running
```

**Problem:** Can't access files between Windows and WSL2
```bash
# From WSL2, access Windows files:
cd /mnt/c/Users/YourUsername/

# From Windows, access WSL2 files:
# Open File Explorer → \\wsl$\Ubuntu\home\yourusername\
```

**Problem:** WSL2 runs out of memory during deployment
1. Open `.wslconfig` file in your Windows user directory:
   ```powershell
   notepad %USERPROFILE%\.wslconfig
   ```
2. Add memory limits:
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   ```
3. Restart WSL2:
   ```powershell
   wsl --shutdown
   wsl
   ```

### Docker Issues

**Problem:** Docker commands not found in WSL2
1. Ensure Docker Desktop is running
2. Check WSL Integration: Docker Desktop → Settings → Resources → WSL Integration
3. Restart WSL2: `wsl --shutdown` then `wsl`

**Problem:** Permission denied errors
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Restart WSL2 terminal
```

**Problem:** Docker Desktop won't start
1. Ensure Hyper-V and WSL2 features are enabled:
   ```powershell
   # Run as Administrator
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
2. Restart computer
3. Update WSL kernel: Download from Microsoft WSL2 kernel update page

### Deployment Issues

**Problem:** `./deploy.sh lab` fails with permission errors on hosts file
```bash
# Check if WSL2 can access Windows hosts file
ls -la /mnt/c/Windows/System32/drivers/etc/hosts

# If permission denied, run WSL as Administrator:
# 1. Right-click Windows Terminal → "Run as Administrator"
# 2. Open WSL2 and retry deployment
```

**Problem:** Services fail to start or exit unexpectedly
```bash
# Check service logs
docker compose logs

# Check specific service
docker compose logs backend
docker compose logs openplc

# Restart specific service
docker compose restart backend
```

**Problem:** `deploy.sh` cannot find compose.yaml
```bash
# Ensure you're in the correct directory
pwd
# Should show: /mnt/c/path/to/intralogisticsai

# List files to verify
ls -la
# Should see compose.yaml file
```

### Network Issues

**Problem:** Can't access web interfaces from other machines
1. Check Windows Firewall settings
2. Ensure Docker port forwarding is working:
   ```bash
   # Test from WSL2
   curl -I http://localhost:8080
   
   # Test from Windows
   curl -I http://intralogistics.lab
   ```

**Problem:** Slow network performance
- Configure Docker Desktop memory allocation: Settings → Resources → Advanced
- Allocate at least 4GB RAM to Docker

**Problem:** MODBUS TCP port 502 not accessible
```bash
# Check if port is bound
netstat -an | grep :502

# Test MODBUS connection
telnet localhost 502
```

### Path Issues

**Problem:** Volume mount errors
```bash
# Ensure COMPOSE_CONVERT_WINDOWS_PATHS is set
echo $COMPOSE_CONVERT_WINDOWS_PATHS

# If not set:
export COMPOSE_CONVERT_WINDOWS_PATHS=1
```

### Windows Defender Issues

**Problem:** Deployment extremely slow due to real-time scanning
1. Add Docker Desktop directories to Windows Defender exclusions:
   - `%ProgramData%\Docker`
   - `%ProgramFiles%\Docker`
   - WSL2 virtual disks: `%USERPROFILE%\AppData\Local\Docker\wsl`
2. Add your project directory to exclusions:
   - `C:\path\to\your\intralogisticsai\project`

### Complete Reset Procedure

If all else fails, perform a complete reset:

```bash
# 1. Stop everything
./deploy.sh stop

# 2. Clean Docker completely
docker system prune -af --volumes

# 3. Restart Docker Desktop

# 4. Restart WSL2
wsl --shutdown
wsl

# 5. Verify environment
docker --version
docker compose --version

# 6. Re-deploy
./deploy.sh lab
```

### Getting Help

If you're still experiencing issues:

1. **Check deployment logs**: Run `docker compose logs` to see detailed error messages
2. **Test basic connectivity**: Verify `docker ps` shows healthy containers
3. **Check hosts file**: Ensure `intralogistics.lab` is properly configured
4. **Verify network**: Test `curl -I http://localhost:8080` works first
5. **Review Windows version**: Ensure you have the latest Windows 11 updates

**Log Collection for Support:**
```bash
# Collect system information
docker compose ps > debug-containers.txt
docker compose logs > debug-logs.txt
docker system info > debug-system.txt
cat /mnt/c/Windows/System32/drivers/etc/hosts > debug-hosts.txt
```

## Performance Optimization

### Docker Desktop Settings

1. **Memory allocation:**
   - Settings → Resources → Advanced
   - Allocate 4-8GB RAM (depending on available system memory)

2. **CPU allocation:**
   - Allocate 2-4 CPU cores

3. **WSL2 optimization:**
   - Settings → Resources → WSL Integration
   - Enable integration only with required distributions

### Windows System Settings

1. **Disable unnecessary startup programs**
2. **Ensure virtualization is enabled in BIOS**
3. **Consider disabling Windows Defender real-time scanning for development folders**

## Security Considerations

### Firewall Configuration

Windows Firewall may block Docker networking:

```powershell
# Allow Docker through firewall (run as Administrator)
netsh advfirewall firewall add rule name="Docker Desktop" dir=in action=allow protocol=TCP localport=80,443,8080,502,7654
```

### WSL2 Security

- WSL2 runs in its own network namespace
- Docker containers are isolated from Windows host
- Use strong passwords for Ubuntu user account

## Backup and Recovery

### Backup Docker Data
```bash
# Stop services
docker compose down

# Backup volumes
docker run --rm -v frappe_docker_sites:/data -v $(pwd):/backup alpine tar czf /backup/sites-backup.tar.gz -C /data .
```

### Backup WSL2 Distribution
```powershell
# Export WSL2 distribution
wsl --export Ubuntu C:\Backup\ubuntu-backup.tar

# Import WSL2 distribution
wsl --import Ubuntu C:\WSL\Ubuntu C:\Backup\ubuntu-backup.tar
```

## Beelink NUC Specific Notes

### Beelink SER5 Pro 5825U Optimization
- **Hardware**: AMD Ryzen 7 5825U (8 cores, 4.5GHz), 16GB DDR4, 500GB PCIe SSD
- **Performance**: Excellent for full lab deployment with all services
- **Recommended Docker Settings**:
  - Memory: 8GB allocation to Docker Desktop
  - CPU: 6 cores allocation
  - Storage: 200GB+ for container images

### Windows 11 Pro Features
- Hyper-V enabled by default (required for WSL2)
- Built-in virtualization support
- Professional network management tools

## Additional Resources

- [Docker Desktop for Windows Documentation](https://docs.docker.com/desktop/install/windows-install/)
- [WSL2 Installation Guide](https://docs.microsoft.com/en-us/windows/wsl/install)
- [Git for Windows](https://gitforwindows.org/)
- [Windows Terminal](https://docs.microsoft.com/en-us/windows/terminal/)

## Next Steps

After completing this setup:

1. **For training lab**: Continue with [Lab Setup Guide](lab-setup.md)
2. **For development**: See [Development Guide](../development/README.md)
3. **For production**: See [Production Deployment](../production/README.md)