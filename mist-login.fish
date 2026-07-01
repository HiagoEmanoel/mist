# @fish-lsp-disable 2003 4004
function __mist_login_init
    set raw_list \
        "
        alpine               
        amazon               
        android              
        arch                 
        artix                
        centos               
        debian               
        deepin               
        devuan               
        elementary           
        endeavouros          
        endless              
        fedora               
        freebsd              
        gentoo               
        guix                 
        kali                 
        linuxmint            
        mageia               
        magpie               
        manjaro              
        nixos                
        openbsd              
        opensuse             
        opensuse-leap        
        opensuse-tumbleweed  
        parrot               
        parabola             
        pop                  
        puresos              
        raspbian             
        rhel                 
        rocky                
        sabayon              
        slackware            
        solus                
        ubuntu               
        unknown              
        void                 
        zorin                
        "
    set namelist (string match -ra '\w+' $raw_list)
    set symbolist (string match -ra '[^\w\s]' $raw_list)

    if test -n "$ANDROID_ROOT"
        set -f distro android

    else if test -f /etc/os-release
        set -f distro (string match -rg 'ID=(\w+)' < /etc/os-release)
    end

    if test -n "$distro"
        set -f index (contains -i -- $distro $namelist)

        if set -n "$index"
            set -f distrosym $symbolist[$index]
        else
            set -f distrosym 
        end

    else
        set -f distrosym 
    end

    if test "$__mist_login_distrosym" != "$distrosym"
        set -U __mist_login_distrosym $distrosym
    end
end
