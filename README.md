```
                 __         __
    ____ ___    ╱_╱╲_____  ╱ ╱╲
   ╱ __ `__ ╲  ╱ ╱╲╱ ___╱╲╱ __╱╲
  ╱ ╱╲╱ ╱╲╱ ╱╲╱ ╱ (__  )╲╱ ╱╲_╲╱
 ╱_╱ ╱_╱ ╱_╱ ╱ ╱ ╱____╱ )╲__╱╲
 ╲_╲╱╲_╲╱╲_╲╱╲_╲╱╲____╲╱  ╲_╲╱   
                        
```

> A simple prompt engine for Fish shell

## Features
* Async Git Status: Runs in the background, so your terminal never freezes or slows down
* Native Git Reference Processing: It reads git refs and hashes manually for maximum speed
* Instant Multi-Shell Sync: When your git status changes, it updates across all open tabs immediately
* "Make It Yourself": No locked-in or forced configs. You decide exactly how your prompt looks

## Installation

### Requirements
* **Fish** >= 3.2.0

* **Git** >= 2.17

* **NerdFont**

Install command:


```fish
for file in mist-{git,widgets,decors}.fish
  curl -s https://raw.githubusercontent.com/H-Emanoel/mist/master/$file -o $__fish_config_dir/conf.d/$file
end
```

Uninstall:

```fish
rm $__fish_config_dir/mist-{git,widgets,decors}.fish
set -eU (set -nU | grep __mist_)
```

> [!NOTE]
> Mist was developed unsig Linux/Android-only features, like `/proc` files, it don't work properly in other systems

## Usage

### Commands

|Command|Description|
|:---|:---|
|mist_date|Formats and displays the current system date and time|
|mist_git|Format git informations|
|mist_line|Draws a horizontal line across the terminal width|
|mist_login|Displays the current user, hostname and distro symbol|
|mist_pwd|Formats the current working directory path|

Most of the commands uses `%` based symtax. Example:

```fish
mist_login "%u"
mist_git "at %r%C" %A%B # outputs:
user at main+ ↑
```

Strings with only empty specifiers are hidden, so outside a repo, the sample will only output the `username`

### Common flags

* **-h, --help**: Show more datails
* **-n, --newline**: Prints each format string into a new line, creating a array. Useful for colored output

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

## License

MIT