#!/usr/bin/env python3
"""
EpiBus Installation Script for Frappe Docker
This script sets up a complete development environment with EpiBus app integration.
"""

import argparse
import os
import subprocess
import sys
import time

def cprint(*args, level: int = 1):
    """
    logs colorful messages
    level = 1 : RED
    level = 2 : GREEN
    level = 3 : YELLOW
    """
    CRED = "\033[31m"
    CGRN = "\33[92m"
    CYLW = "\33[93m"
    reset = "\033[0m"
    message = " ".join(map(str, args))
    if level == 1:
        print(CRED, message, reset)
    if level == 2:
        print(CGRN, message, reset)
    if level == 3:
        print(CYLW, message, reset)

def run_command(cmd, cwd=None, check=True):
    """Run a command and handle errors"""
    try:
        result = subprocess.run(cmd, shell=True, cwd=cwd, check=check, 
                              capture_output=True, text=True)
        if result.stdout:
            print(result.stdout)
        return result
    except subprocess.CalledProcessError as e:
        cprint(f"Command failed: {cmd}", level=1)
        cprint(f"Error: {e.stderr}", level=1)
        if check:
            sys.exit(1)
        return e

def wait_for_service(service_name, max_wait=300):
    """Wait for a Docker service to be healthy"""
    cprint(f"Waiting for {service_name} service to be ready...", level=3)
    
    start_time = time.time()
    while time.time() - start_time < max_wait:
        try:
            result = run_command(
                f"docker compose ps --format json {service_name}", 
                check=False
            )
            if result.returncode == 0 and "running" in result.stdout.lower():
                cprint(f"{service_name} is ready!", level=2)
                return True
        except:
            pass
        
        time.sleep(5)
    
    cprint(f"Timeout waiting for {service_name}", level=1)
    return False

def main():
    parser = argparse.ArgumentParser(description="Install EpiBus with Frappe Docker")
    parser.add_argument("--site-name", default="localhost", 
                       help="Site name (default: localhost)")
    parser.add_argument("--admin-password", default="admin",
                       help="Admin password (default: admin)")
    parser.add_argument("--db-password", default="123",
                       help="Database root password (default: 123)")
    parser.add_argument("--skip-build", action="store_true",
                       help="Skip Docker build and start directly")
    
    args = parser.parse_args()
    
    # Check if we're in the right directory
    if not os.path.exists("compose.yaml"):
        cprint("Error: Must be run from frappe_docker root directory", level=1)
        sys.exit(1)
    
    # Check if epibus directory exists
    if not os.path.exists("epibus"):
        cprint("Error: epibus directory not found. Please ensure epibus app is present.", level=1)
        sys.exit(1)
    
    cprint("Starting EpiBus Integration Setup...", level=2)
    
    if not args.skip_build:
        # Start services
        cprint("Starting Docker services...", level=2)
        platform_override = ""
        if os.uname().machine == "arm64" and os.uname().sysname == "Darwin":
            platform_override = "-f overrides/compose.mac-m4.yaml"
            cprint("Detected Mac M-series, using ARM64 optimizations", level=3)
        
        compose_cmd = f"""
        docker compose \\
          -f compose.yaml \\
          -f overrides/compose.epibus.yaml \\
          {platform_override} \\
          up -d
        """.strip()
        
        cprint(f"Running: {compose_cmd}", level=3)
        run_command(compose_cmd)
        
        # Wait for configurator to complete
        cprint("Waiting for configurator to complete...", level=3)
        wait_for_service("configurator")
        
        # Wait for backend to be ready
        wait_for_service("backend")
    
    # Create site with EpiBus
    cprint(f"Creating site: {args.site_name}", level=2)
    
    # First create site with just ERPNext
    site_check = run_command(
        f"docker compose exec backend bench list-sites",
        check=False
    )
    
    if args.site_name in site_check.stdout:
        cprint(f"Site {args.site_name} already exists, skipping creation", level=3)
    else:
        # Create new site with just ERPNext first
        create_site_cmd = f"""
        docker compose exec backend bench new-site {args.site_name} \\
          --admin-password {args.admin_password} \\
          --db-root-password {args.db_password} \\
          --install-app erpnext
        """.strip()
        
        cprint(f"Creating site with ERPNext: {create_site_cmd}", level=3)
        run_command(create_site_cmd)
    
    # Now add epibus to apps.txt and install it
    cprint("Adding EpiBus to bench...", level=3)
    run_command("docker compose exec backend bash -c 'echo epibus >> sites/apps.txt'")
    
    # Restart services to pick up epibus
    cprint("Restarting services to recognize EpiBus...", level=3)
    run_command("docker compose restart backend websocket queue-short queue-long scheduler")
    
    # Wait for backend to restart
    wait_for_service("backend")
    
    # Install EpiBus on the site
    cprint("Installing EpiBus app on site...", level=2)
    run_command(
        f"docker compose exec backend bench --site {args.site_name} install-app epibus"
    )
    
    # Get access URLs
    cprint("Getting service URLs...", level=2)
    
    # Get frontend port
    frontend_result = run_command(
        "docker compose ps frontend --format 'table {{.Ports}}'",
        check=False
    )
    
    if frontend_result.returncode == 0:
        lines = frontend_result.stdout.strip().split('\n')
        if len(lines) > 1:  # Skip header
            port_info = lines[1]
            if ":" in port_info and "->" in port_info:
                port = port_info.split('->')[0].split(':')[-1]
                cprint(f"✅ Frappe/ERPNext with EpiBus: http://localhost:{port}", level=2)
    
    # Check CODESYS
    codesys_script = "./get-codesys-port.sh"
    if os.path.exists(codesys_script):
        cprint("CODESYS Information:", level=2)
        run_command(codesys_script, check=False)
    
    # Final status
    cprint("\n=== EpiBus Installation Complete! ===", level=2)
    cprint(f"Site: {args.site_name}", level=3)
    cprint(f"Admin Username: Administrator", level=3)
    cprint(f"Admin Password: {args.admin_password}", level=3)
    cprint("\nServices Status:", level=3)
    run_command("docker compose ps")

if __name__ == "__main__":
    main()