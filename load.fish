# @fish-lsp-disable 4004
function __mist_load_get
    # Get the text from file
    set entry $argv[1]
    set file $argv[2]

    if ! test -f "$file"
        echo "mist_load: file \"$file\" not found" >&2
        return 2
    end

    set data (string split \n <$file)
    set header (string split ' ' $data[1])

    set index (math (contains -i -- $entry $header) + 1)
    if test "$index" = 1
        return 1
    end

    echo $index
    string unescape --style=url $data[$index] | string collect
end

function __mist_load_open_editor
    set entry $argv[1]
    set file $argv[2]
    set editor $EDITOR

    if test -z "$editor"
        set editors vi vim nvim micro nano hx emacs mg code subl gedit kate gvim mousepad leafpad
        set avaliable_editors

        for editor in $editors
            command -q $editor
            and set -a avaliable_editors $editor
        end

        set choiced (gum choose $avaliable_editors custom --header="Select your text editor command")
        if test "$choiced" = custom
            echo -n "Command: "
            read choiced
        end

        set -f editor $choiced
        set confirm (gum choose yes no --header="You want to set $choiced  as your default editor?")

        if test "$confirm" = yes
            # @fish-lsp-disable-next-line 2003
            set -U EDITOR $choiced
        end
    end

    set -q TMPDIR
    and set tmpdir $TMPDIR
    or set tmpdir /tmp

    set tmpfile $tmpdir/MIST_EDIT.(random)
    set data (__mist_load_get $entry $file)
    set last_status $status

    if test "$last_status" != 0 -a "$last_status" != 1
        return
    end

    # Get the index and verify new entries
    if test "$last_status" = 1
        read -af header <$file
        set -f index (contains -i -- '*' $header)

        if test -z "$index"
            set index (math (count $header) + 2)
            set new_header $header $entry
        else
            set index (math $index + 1)
            set new_header (string replace '*' $entry "$header")
        end

        echo "" >$tmpfile
    else
        set -f new_header
        set -f index $data[1]
        echo $data[2] >$tmpfile
    end

    # Open the editor and get the new file
    eval "$editor $tmpfile"
    set new_content (read -z <$tmpfile | string replace -r '^[\s\n]+$' '')
    rm -f $tmpfile

    # Delete empty entrys from header
    if test -z "$new_content"
        set target (string escape --style=regex $entry)

        test -z "$header"
        and read header <$file

        set -f new_header (string replace -r "\b$target\b" '*' "$header")
    end

    # Repalce the line of the index by the new data
    if test -n "$new_header"
        gawk -i inplace -v new="$new_header" 'NR==1 {$0=new} 1' $file
    end

    if test -n "$new_content"
        set new_content (string replace -a \n %n "$new_content")
        set new_content (string replace -a %n %%n "$new_content")
        gawk -i inplace -v line=$index -v new=(string replace -a \n %n "$new_content" | string collect) 'NR==line {$0=new} 1' $file
    end
end

function mist_load
    set options e/edit f/file= h/help
    argparse $options -- $argv

    set entry $argv[1]

    if set -q _flag_f
        set file $_flag_f
    else if set -q mist_load_file
        set file $mist_load_file
    else
        set file $__fish_config_dir/data/mist-data
        if ! test -f $file
            mkdir $__fish_config_dir/mist.d
            touch $__fish_config_dir/mist.d/config.txt
        end
    end

    # echo "mist_load: entry \"$entry\" not found" >&2
end
