```
                 __         __
    ____ ___    /_/\_____  / /\
   / __ `__ \  / /\/ ___/\/ __/\
  / /\/ /\/ /\/ / (__  )\/ /\_\/
 /_/ /_/ /_/ / / /____/ )\__/\
 \_\/\_\/\_\/\_\/\____\/  \_\/   
                        
```

> A simple prompt engine for Fish shell

## Features
* **Async Git Status:** Runs in the background, so your terminal never freezes or slows down
* **Native Git Reference Processing:** Reads git refs and hashes manually for maximum speed
* **Instant Multi-Shell Sync:** When your git status changes, it updates across all open tabs immediately
* **"Make It Yourself":** No locked-in or forced configs. You decide exactly how your prompt looks

## Installation
The install process will only download the files, without setting up anything.

### Requirements
* ![Static Badge: Fish 3.2+](https://img.shields.io/badge/FISH%203.2%2B-34C534?style=for-the-badge&logo=fishshell&logoColor=white)
* ![Static Badge: Git 2.17+](https://img.shields.io/badge/GIT%202.17%2B-F03C2E?style=for-the-badge&logo=git&logoColor=white)
* ![Static Badge: Nerdfont](https://img.shields.io/badge/NERDFONT%20-FFEB3B?style=for-the-badge&logo=awesomelists&logoColor=black)

### Steps
* Download the files to the config folder:

  ```fish
  for file in mist-{async,widgets,decors}.fish
    set -l url https://raw.githubusercontent.com/H-Emanoel/mist/main/$file
    curl -s $url -o $__fish_config_dir/conf.d/$file
  end
  ```
  
* To uninstall:

  ```fish
  rm $__fish_config_dir/conf.d/mist-{async,widgets,decors}.fish
  set -eU (set -nU | grep __mist_)
  ```
  
> [!NOTE]
> Mist was developed using Linux/Android-only features like `/proc` files, it won't work properly on other systems.

## Usage
### Commands

| Command | Description |
| :--- | :--- |
| mist_date | Formats and displays the current system date and time |
| mist_git | Formats git status information |
| mist_line | Draws a horizontal line across the terminal width |
| mist_login | Displays the current user, hostname, and distro symbol |
| mist_pwd | Formats the current working directory path |
| mist_info | Formats command exit status and execution duration |

Most of the commands use `%` based syntax. Example:

  ```fish
  mist_login "%u"
  mist_info -s "✓" -e "✕" "%s (%t)"
  mist_git "at %r%C" %A%B
  ```
  
Strings with only empty specifiers are hidden, so outside a repository or when duration is below the threshold, empty blocks will not print trailing spaces.

### Common flags

* **-h, --help:** Show details and list all specifiers
* **-n, --newline:** Prints each format string into a new line, creating an array (useful to reduce function calls)

Example:

```fish
set parts (mist_git -n %R%r %C %A%B)
set_color brred # For ref symbol and name
printf $parts[1] 
set_color yellow # For dirty/staging symbol
printf $parts[2]
set_color brblack # For ahead/behind indicator
printf $parts[3]
```

More samples can be found in the [samples folder](https://github.com/HiagoEmanoel/mist/tree/main/samples)

## License
MIT
