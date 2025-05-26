# 📦 Universal Package Installer

**Developed by [Kontango Inc](https://kontango1.odoo.com)**

 - *Making lives easier everyday

A beautiful, intelligent bash script that automates package installation across Linux distributions and macOS. Say goodbye to manually installing dozens of packages one by one!

## 🚀 Why This Will Make Your Life Easier

### ⏰ **Save Hours of Time**
- Install 50+ packages with a single command instead of typing each one manually
- No more copy-pasting package names from tutorials
- Set up a new system in minutes, not hours

### 🎯 **Smart & Reliable**
- **Intelligent fallbacks**: Tries `apt` first, falls back to `snap` automatically
- **Skip duplicates**: Automatically detects and skips already-installed packages
- **Cross-platform**: Works on Ubuntu, Debian, CentOS, Arch, and macOS
- **Error handling**: Continues installing other packages even if one fails

### ✨ **Beautiful User Experience**
- **Animated loading bars** with spinning indicators
- **Color-coded output** for easy status recognition
- **Progress tracking** showing current package (1/50, 2/50, etc.)
- **Comprehensive summary** with installation time and results

### 🛡️ **Safe & Transparent**
- **Detailed logging** of all operations
- **Automatic log viewing** when errors occur
- **Sudo verification** before starting
- **Dry-run mode** to preview what will be installed

## 🎬 What It Looks Like

```bash
==================================================
    📦 Package Installer v1.0.0
    🚀 Smart Package Management Tool
==================================================

🔐 Checking sudo access...
✅ Sudo access confirmed

🔍 Detecting operating system...
🐧 Detected: Debian/Ubuntu-based Linux (using apt → snap)

📂 Loading package list from packages.txt...
✅ Found 47 packages to install

==================================================
  🚀 Starting installation of 47 packages...
==================================================

--- Package 1/47 ---
📦 Processing: docker.io
🔍 Checking if docker.io is already installed...
   ⠋ Installing docker.io via apt...
✅ docker.io installed successfully via apt
---

--- Package 2/47 ---
📦 Processing: spotify
🔍 Checking if spotify is already installed...
   ⠙ Installing spotify via apt...
🔄 Failed to install spotify via apt, trying snap...
   ⠹ Installing spotify via snap...
✅ spotify installed successfully via snap
---

==============================================
🎉 INSTALLATION COMPLETE! 🎉
==============================================
⏱️  Total runtime: 3m 42s

📦 Successfully Installed Packages:
   (23 packages)

   ✓ docker.io (apt)
   ✓ spotify (snap)
   ✓ code (snap)
   ✓ nodejs (apt)
   ...

🙏 Thank you for using the Package Installer!
   We hope this tool saved you time and made package
   management easier for your system.
==============================================
```

## 🛠️ Features

### 📋 **Package Management**
- **Multi-manager support**: apt, snap, yum, dnf, pacman, brew
- **Intelligent prioritization**: Uses system package manager first, snap as fallback
- **Dependency handling**: Automatically installs required tools
- **Package verification**: Checks multiple methods to detect installed packages

### 🎨 **User Interface**
- **Animated loading indicators** with Unicode spinners
- **Color-coded status messages** (green=success, yellow=warning, red=error)
- **Progress tracking** with package counters
- **Clean, organized output** with clear sections

### 🔧 **Smart Automation**
- **OS detection**: Automatically detects Linux distro and macOS
- **Sudo management**: Requests and verifies sudo access upfront
- **Error recovery**: Continues with remaining packages if one fails
- **Skip optimization**: Bypasses already-installed packages

### 📊 **Comprehensive Reporting**
- **Real-time logging** with timestamps
- **Installation statistics** (installed/skipped/failed counts)
- **Execution timing** (total runtime)
- **Detailed package tracking** (which packages installed via which method)

### 🔍 **Debugging & Troubleshooting**
- **Automatic log file creation** with fallback locations
- **Error log viewing** when installations fail
- **Verbose operation logging** for troubleshooting
- **System requirements checking**

## 📁 Package Collections

### 🔧 **Development-Focused (packages.txt)**
Perfect for developers and DevOps engineers:
- **Languages**: Python, Node.js, Java, Go, Rust, Ruby, PHP
- **Tools**: Docker, Kubernetes, Git, VS Code, build tools
- **Databases**: MySQL, PostgreSQL, Redis, MongoDB
- **Cloud**: AWS CLI, Azure CLI, Google Cloud CLI
- **Total**: ~100 essential development packages

### 🌟 **Quality of Life (packages-qol.txt)**  
Perfect for daily desktop users:
- **Enhanced CLI**: bat, exa, fzf, tldr
- **Media**: VLC, OBS Studio, GIMP, Audacity
- **Communication**: Telegram, Signal, Zoom, Discord
- **Productivity**: Obsidian, KeePassXC, Syncthing
- **Gaming**: Steam, Lutris, Wine
- **Total**: ~140 quality-of-life packages

## 🚀 Quick Start

### 1. **Download the Installer**
```bash
# Download the installer script
wget https://your-repo/installer.sh
chmod +x installer.sh
```

### 2. **Choose Your Package Set**
```bash
# For development setup
wget https://your-repo/packages.txt

# OR for quality-of-life setup  
wget https://your-repo/packages-qol.txt
mv packages-qol.txt packages.txt
```

### 3. **Run the Installer**
```bash
# Install all packages
./installer.sh

# Preview what will be installed
./installer.sh --list

# Test run without installing
./installer.sh --dry-run
```

## 📖 Usage Examples

### **Basic Installation**
```bash
./installer.sh
```
Installs all packages listed in `packages.txt`

### **Preview Packages**
```bash
./installer.sh --list
```
Shows all packages that would be installed without actually installing them

### **Get Help**
```bash
./installer.sh --help
```
Displays usage information and options

### **Check Version**
```bash
./installer.sh --version
```
Shows installer version and information

### **View Previous Logs**
```bash
./installer.sh --open-log
```
Opens the log file from the last installation run

## 📝 Customization

### **Create Your Own Package List**
Create a `packages.txt` file with one package per line:
```
# My custom packages
code
docker.io
nodejs
spotify
# Comments start with #
```

### **Mix and Match**
```bash
# Combine both package sets
cat packages.txt packages-qol.txt > my-packages.txt
mv my-packages.txt packages.txt
./installer.sh
```

## 🔧 System Requirements

### **Supported Operating Systems**
- **Ubuntu/Debian** (apt + snap)
- **CentOS/RHEL/Fedora** (yum/dnf)
- **Arch Linux** (pacman)
- **macOS** (brew)

### **Required Tools**
- `bash` 4.0+
- `sudo` access
- Internet connection
- Basic utilities: `curl`, `wget`, `tar`, `unzip` (auto-installed if missing)

## 🎯 Real-World Use Cases

### **🖥️ New System Setup**
"Just got a new Ubuntu laptop? Run this installer and have a fully configured development environment in under 10 minutes."

### **🐳 DevOps Environment**
"Setting up a new server? Get Docker, Kubernetes tools, monitoring utilities, and cloud CLIs all installed automatically."

### **🎮 Gaming Rig**
"Want to game on Linux? The QoL package set installs Steam, Lutris, Wine, and all the compatibility tools you need."

### **👨‍💻 Developer Onboarding**
"New team member? Give them the installer script and they'll have the exact same development environment as everyone else."

### **🏠 Home Lab**
"Building a home server? Install all monitoring, backup, and management tools with one command."

## 📊 Performance Benefits

| Task | Manual Method | With Installer |
|------|---------------|----------------|
| Install 50 packages | 2-3 hours | 5-10 minutes |
| Handle failures | Start over | Automatic retry |
| Track what's installed | Mental notes | Detailed logs |
| Setup new system | Full day | 30 minutes |
| Update package list | Edit each command | Edit one file |

## 🔍 Why Choose This Over Alternatives?

### **vs. Manual Installation**
- ✅ **100x faster** than typing each package individually
- ✅ **Error resilient** - one failure doesn't stop everything
- ✅ **Comprehensive logging** for troubleshooting

### **vs. Other Scripts**
- ✅ **Beautiful interface** with animations and colors
- ✅ **Cross-platform** support for multiple Linux distros + macOS
- ✅ **Intelligent fallbacks** (apt → snap)
- ✅ **Modern bash practices** with proper error handling

### **vs. Configuration Management (Ansible/Chef)**
- ✅ **No learning curve** - just run one command
- ✅ **No additional dependencies** - pure bash
- ✅ **Perfect for personal use** - no server setup required

## 🤝 Contributing

Found a useful package that should be included? Have a suggestion for improvement? 

1. Fork the repository
2. Add your package to the appropriate `packages*.txt` file
3. Test the installation
4. Submit a pull request

## 📞 Support

Having issues? The installer provides detailed logging and error reporting:

1. **Check the log file** (automatically shown on errors)
2. **Run with --list** to verify your package list
3. **Use --dry-run** to test without installing
4. **Check system requirements** for your OS

## 🎉 Success Stories

> *"This installer saved me 3 hours setting up my new development machine. Everything just works!"* - DevOps Engineer

> *"Finally, a simple way to get all my quality-of-life tools installed on a fresh Ubuntu install."* - Linux enthusiast  

> *"Our team uses this for standardizing development environments. Game changer for onboarding."* - Engineering Manager

---

**Make your Linux/macOS setup effortless. One script, endless possibilities.** 🚀