```
   ____ ___  (_)____/ /_
  / __ `__ \/ / ___/ __/
 / / / / / / (__  ) /_  
/_/ /_/ /_/_/____/\__/
                        
```

**A simple prompt engine for *Fish shell***

---

## Features
* **Async Git Status:** Runs in the background, so your terminal never freezes or slows down
* **Native Git Reference Processing:** It reads git refs and hashes manually for maximum speed
* **Instant Multi-Shell Sync:** When your git status changes, it updates across all open tabs immediately
* **"Make It Yourself":** No locked-in or forced configs. You decide exactly how your prompt looks

## Requirements
**Fish** >= 3.2.0

**Git**

## Installation
---
**Install command:**


```fish
set -l tmr $TMPDIR/mist.git
git clone --{bare,depth 1} https://github.com/H-Emanoel/mist $tmr
git --git-dir=$tmr archive HEAD \
mist-git.fish mist-widgets.fish mist-decors.fish \
       | tar -x -C $__fish_config_dir/conf.d
rm -rf $tmr
```

**Uninstall:**

```fish
rm $__fish_config_dir/mist-{git,widgets,decors}.fish
```

**Note:** Prun was developed thinking only in Linux enviroments and was only in Android, probaly don't work in other systems

## Avaliable commands

|command|description|
|:---:|:---:|
|mist_date|Formats and displays the current system date and time|
|mist_git|format git informations|
|mist_line|Draws a horizontal line across the terminal width|
|mist_login|Displays the current user, hostname and distro symbol|
|mist_pwd|Formats the current working directory path|

**See:** `<command --help>` to see detaild usage