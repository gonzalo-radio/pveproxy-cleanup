> [!CAUTION]
>  This code has been generated with AI tools

# pveproxy-cleanup

Kills pveproxy and spiceproxy worker processes stuck in shutdown state.

## Build

On the development machine:

```bash
./build.sh
```

This will:
- Compile the Go binary
- Create a distribution directory with all necessary files
- Package everything into `pveproxy-cleanup-1.0.0.tar.gz`

You can set a custom version:
```bash
VERSION=2.0.0 ./build.sh
```

## Installation

On the target system:

1. Copy the tarball to the target system
2. Extract it:
```bash
tar -xzf pveproxy-cleanup-1.0.0.tar.gz
```

3. Run the installation script as root:
```bash
sudo ./install.sh
```

This will:
- Install the binary to `/usr/local/bin/pveproxy-cleanup`
- Install systemd service and timer to `/etc/systemd/system/`
- Enable and start the timer (runs every 5 minutes)

## Usage

The binary can be run manually:

```bash
# Default (verbose) - shows when processes are found and killed
pveproxy-cleanup

# Quiet mode - no output
pveproxy-cleanup -q

# Verbose mode - shows when processes are found and killed
pveproxy-cleanup -v

# Debug mode - shows all operations including analyzed processes
pveproxy-cleanup -d

# Dry-run mode - don't kill processes, implies debug
pveproxy-cleanup --dry
```

## Systemd Management

```bash
# Check timer status
systemctl status pveproxy-cleanup.timer

# Check service status
systemctl status pveproxy-cleanup

# View logs
journalctl -u pveproxy-cleanup

# View logs (follow)
journalctl -u pveproxy-cleanup -f

# Stop timer
systemctl stop pveproxy-cleanup.timer

# Disable timer
systemctl disable pveproxy-cleanup.timer

# Manually trigger cleanup
systemctl start pveproxy-cleanup
```

## How it works

1. Scans `/proc` for all processes
2. Reads each process's `/proc/[pid]/cmdline`
3. Finds processes containing "pveproxy worker (shutdown)" or "spiceproxy worker (shutdown)"
4. Sends SIGTERM (15) to matched processes (unless `--dry` is used)
5. Waits 10 seconds
6. Sends SIGKILL (9) to processes still running (unless `--dry` is used)

## Uninstall

```bash
systemctl stop pveproxy-cleanup.timer
systemctl disable pveproxy-cleanup.timer
rm /usr/local/bin/pveproxy-cleanup
rm /etc/systemd/system/pveproxy-cleanup.service
rm /etc/systemd/system/pveproxy-cleanup.timer
systemctl daemon-reload
```
