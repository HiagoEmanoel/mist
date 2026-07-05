# @fish-lsp-disable 4004
function mist_info
    # Salva o status imediatamente para não perdê-lo
    set -l last_status $pipestatus

    # format info string
    set -l options h/help n/newline
    argparse $options -- $argv
    or return

    if set -q _flag_h
        printf "%b\n" \
            "Usage: \e[1;33mmist_info\e[0m [OPTIONS] [FORMAT]" \
            "" \
            "\e[1mOptions:\e[0m" \
            "  \e[33m-h, --help\e[0m     Show this help message" \
            "  \e[33m-n, --newline\e[0m  Print with newline" \
            "" \
            "\e[1mFormat Specifiers:\e[0m" \
            "  \e[32m%b\e[0m  Battery Level  \e[32m%s\e[0m  Last Status" \
            "  \e[32m%w\e[0m  Network Name   \e[32m%u\e[0m  Memory Usage %" \
            "  \e[32m%m\e[0m  Memory (Used/Total)" \
            "  \e[32m%%\e[0m  Just a %"
        return
    end

    # Set -f the default output
    test -n "$argv"
    and set -f output $argv
    or set -f output "%b | %w | %s | %u"

    set -l men_usage "$__mist_info_data[2]"
    set -l men_total "$__mist_info_data[3]"
    set -l battery "$__mist_info_data[4]"
    set -l network "$__mist_info_data[5]"

    # filter the specifiers and make them unique
    set -f specifiers (string match -rga -- '(?<!%)%([bwsum])' $output)
    set specifiers (string match -rga -- '(\w)(?:\s*\1)*' (path sort $specifiers))

    for spec in $specifiers
        set -l val
        switch $spec
            case b
                set val "$battery"
            case w
                set val "$network"
            case s
                set val "$last_status"
            case u
                # Porcentagem de uso de memória com uma casa decimal
                if test -n "$men_total" -a "$men_total" -gt 0
                    set -l pct (math -s1 "$men_usage / $men_total * 100")
                    set val "$pct%"
                else
                    set val "0.0%"
                end
            case m
                # Valor em atual/total
                set val "$men_usage/$men_total"
        end
        set output (string replace -ra -- "(?<!%)%$spec" "$val" $output)
    end

    set output (string replace -ra -- '%(%+)' '$1' $output)

    set -q _flag_n
    and printf "%b\n" $output
    or printf "%b" "$output"
end
