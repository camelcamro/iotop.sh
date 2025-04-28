
# iotop.sh

A lightweight, portable, no-dependency I/O monitoring tool for Linux systems – designed to monitor disk read/write activity in a flexible and detailed way, even without installing external packages like `iotop`.

---

## 📋 Features

- Pure Bash script – no dependencies
- Monitors disk activity directly via `/proc/diskstats`
- Shows Read and Write speed (KB/s)
- Shows total bytes read and written (in KB)
- Shows ReadIO/s and WriteIO/s (IO operations per second)
- Loop mode for continuous monitoring
- Debug mode for raw `/proc/diskstats` capture
- Optional device filtering (monitor only specific devices)
- Handles wildcards for devices (e.g., `sd*`)
- Option to hide inactive devices
- Fully customizable intervals and cycles
- Clear structured output in console

---

## 🚀 Why was this script created?

Standard tools like `iotop` often require Python environments or root privileges,  
and sometimes are unavailable or hard to install on minimal Linux systems (e.g., embedded devices, NAS systems, OpenWrt).

**`iotop.sh`** provides:
- Instant monitoring of disk I/O.
- Full control over what devices are shown.
- Advanced modes like debug captures and selective display.
- Extremely lightweight: suitable even for very small or busy systems.

---

## ⚙️ How to Use

```bash
./iotop.sh [options]
```

### Options:

| Option | Description |
|:-------|:------------|
| `-d`, `--device DEVICE` | Monitor only a specific device (e.g., `sda`, `mmcblk0`, pattern like `sd*`) |
| `-i`, `--interval SECONDS` | Set refresh interval in seconds (default: 10) |
| `-l`, `--loop 0|1` | Enable (1) or disable (0) loop mode (default: 1) |
| `-a`, `--all 0|1` | Show all entries (1) or only active ones (0) (default: 1) |
| `-s`, `--show_empty 0|1` | Show devices with zero read/write activity (default: 0) |
| `--debug` | Enable debug mode: shows raw `/proc/diskstats` before and after each interval |
| `--cycle NUMBER` | Limit number of cycles (default: -1 = infinite) |
| `-h`, `--help` | Show help and usage information |

---

### Example usages:

```bash
# Live monitor all disks every 5 seconds
./iotop.sh --device=sd* --interval=5 --loop=1

# Monitor only 'sda' without looping
./iotop.sh --device=sda --interval=10 --loop=0

# Debug mode, shows raw /proc/diskstats
./iotop.sh --debug --device=sdb --interval=5

# Limit to 5 cycles, then stop
./iotop.sh --device=mmcblk0 --interval=2 --loop=1 --cycle=5
```

---

## 📈 Output Explained

| Column | Description |
|:-------|:------------|
| Device | The device being monitored (e.g., sda1, mmcblk0p1) |
| Read/sec (KB) | Read throughput per second in Kilobytes |
| Write/sec (KB) | Write throughput per second in Kilobytes |
| BytesRead (KB) | Total bytes read during interval |
| BytesWritten (KB) | Total bytes written during interval |
| ReadIO/s | Number of read IO operations per second |
| WriteIO/s | Number of write IO operations per second |

> ⚡ Note:  
> High ReadIO/s and WriteIO/s can be caused by many small blocks being read/written due to caching effects – this is normal!

---

## 📚 Internals: How It Works

- Reads `/proc/diskstats` twice: before and after the interval.
- Calculates deltas (differences) for reads, writes, sectors read/written.
- Converts sectors into KB (sectors are assumed to be 512 bytes).
- Computes per-second throughput and IO operation rates.
- Optionally outputs debug data showing raw kernel counters.

---

## 🛠️ Requirements

- Bash 3.2+ (tested on Bash 4.x/5.x)
- Linux with access to `/proc/diskstats`
- No root required (unless your /proc permissions are restricted)

---

## ✨ Future Ideas

- Auto-detection of physical vs cached IOs (average IO size analysis)
- Colorful output for high I/O activity
- JSON output option for scripting and automation
- Dynamic unit adjustment (KB → MB → GB depending on traffic)

---

## 🏷 License

MIT License — Free for use and modification.

---

## 🧑‍💻 Author

Customized and enhanced by [YourName or TeamName]
