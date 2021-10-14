# archivist-sh

![CI](https://github.com/ashnel3/archivist-sh/actions/workflows/main.yml/badge.svg)

Shell website archivist! *- (v0.2.0a)*

<br />

Backup websites, ftp servers, and binaries. 

Easily test your user-scripts, page types, or web-extensions.

### 1.0.0 Road-map:
- [x] Task Before & after hooks
- [x] Backup & tracking *- (80%)*
- [ ] Diffing & logging
- [ ] Bash completion
- [ ] Custom scripts
- [ ] Installer & uninstaller
- [ ] Docker
- [ ] Dynamic file detection & automatic filtering?
- [ ] Windows installer & task scheduling

### Requirements:
Requirements: make, diff, wget, shasum, tar & bats-core optionally for testing

Targeting: Bash 3.2.57+

- Installation on Windows w/ chocolatey: `choco install git wget make`

  - Installing bats-core on Windows: <a href="https://bats-core.readthedocs.io/en/stable/installation.html#installing-bats-from-source-onto-windows-git-bash" rel="noopener" target="_blank">installation - bats-core</a> - *(optional)*

  ```bash
  git clone https://github.com/bats-core/bats-core.git
  cd bats-core
  ./install.sh $HOME
  ```

- Installation on Linux w/ apt: `apt-get install coreutils make wget`

  - Installing bats-core on Linux: <a href="https://bats-core.readthedocs.io/en/stable/installation.html#installing-bats-from-source" rel="noopener" target="_blank">installation - bats-core</a> - *(optional)*

  ```bash
  git clone https://github.com/bats-core/bats-core.git
  cd bats-core
  sudo ./install.sh /usr/local
  ```

- Installation on Bsd w/ pkg: `pkg install gmake wget bats-core parallel`

- Installation on MacOs /w homebrew: `brew install coreutils wget make bats-core`

### Usage:
```bash
usage: archivist [add|set|remove|run] [options]
description: archivist.sh - Backup & track websites over time.

    example: add --task=my_website https://my_website.com

    -t, --task     - Select task
    -e, --enable   - Enable task
    -d, --disable  - Disable task
    -a, --accept   - Configure allowed files
    -x, --exclude  - Configure excluded paths
    -i, --interval - Configure task run interval in hours
    -r, --reject   - Configure rejected files
    --help         - Display this message
    -v, --version  - Display version
```

**CLI examples**:
```bash
# Only download rar files & preform no recursion.
archivist add --task=rars -a="rar" -r="html" -x=* https://my_website.com 

# Recursively download all source code 
# Exclude media folder & avoid dynamically named files
archivist add --task=source -a="css,js" -x="media" -r="html,xml" https://my_website.com 

# Disable a task
archivist set --task=source --disable

# Run all tasks
archivist run

# Run specific tasks
archivist run -t="rars,source"
```

**Hook examples**:
```bash
before() {
    # This will run after the download...
}

after() {
    if [[ "$1" == "true" ]]; then
        echo "Yay Update!"
    else
        echo "No changes"
    fi
}

# Task main
...
```
