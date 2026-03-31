# @fish-lsp-disable 4004 3003
if status is-interactive

    # A dictionary implementatiomn for fish shell
    # Work logic:
    # The and  keys are storage in this format:
    # <keys> <values>
    # sample: k3 k2 k1 v1 v2 v3

    function dget
        # Get values form a dictionary
        if test (count $argv) -lt 2
            echo -n "dset: " >&2
            set_color brred
            echo "Too few arguments" >&2
            set_color normal
            echo "usage: dset DICT KEY VALUE1 VALUE2..." >&2
            return 2
        end

        set -l dict_name $argv[1]
        set -l keys $argv[2..]
        set -l dictionary $$dict_name
        set -l dict_size (math (count $dictionary) / 2)
        test $dict_size = 0 && return

        for key in $keys # Get the values
            set -l index (contains -i "$key" $dictionary[..$dict_size])
            test -n "$index" && echo $dictionary[(echo "-$index")]
        end
    end

    function dset
        # Set values to a dictionary
        set -l argc (count $argv)

        if test $argc -gt 3 -o $argc -lt 2
            echo -n "dset: " >&2
            set_color brred
            echo "Expected 2 or 3 arguments" >&2
            set_color normal
            echo "usage: dset DICT KEY VALUE" >&2
            return 2
        end

        set -l dict_name $argv[1]
        set -l dictionary $$dict_name
        set -l key "$argv[2]"

        set -l dict_size (math (count $dictionary) / 2)
        test $dict_size = 0 && set dict_size 1

        if test $argc = 2 # Removes values from dict
            set -l index (contains -i "$key" $dictionary[..$dict_size])

            if test -z "$index"
                return
            end

            set -e dictionary[$index]
            set -e dictionary[(echo "-$index")]
            set -g $dict_name $dictionary
            return
        end

        set -l value "$argv[3]"
        # Addds a new value to dict or change current vaue in an key
        set -l index (contains -i "$key" $dictionary[..$dict_size])

        if test -z "$index"
            set -g $dict_name "$key" $dictionary "$value"
            return
        end

        set dictionary[(echo "-$index")] "$value"
        set -g $dict_name $dictionary
        return
    end

    function dlist
        # List  the values in a dictionary
        set -l argc (count $argv)

        if test $argc = 0
            echo "Usage: DICT1 DICT2..." >&2
        end

        for dict_name in $argv
            set -l dictionary $$dict_name

            set -l dict_size (math (count $dictionary) / 2)
            test $dict_size = 0 && continue

            # Pad the keys and add a : after words
            set key_pad (string pad --right $dictionary[..$dict_size]:)
            set value_pad $dictionary[(echo "-$dict_size")..]

            echo "$dict_name:"

            set -l count 1
            while test $count -le $dict_size
                printf " %s %s\n" $key_pad[$count] $value_pad[$count]
                set count (math $count + 1)
            end
        end
    end
end
