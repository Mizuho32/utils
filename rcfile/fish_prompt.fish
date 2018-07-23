function fish_prompt
    # if previous command status? then
    #  retc = green
    # else
    #  retc = red
    and set retc green; or set retc red

    # current dir
    echo
    set_color -o yellow
    #echo -n :(prompt_pwd)
    echo '['(pwd|sed "s=$HOME=~=")']'

    # show user
    set_color -o green # -o bold
    if test $USER = root -o $USER = toor
        set_color -o red
    else
        set_color -o green
    end
    echo -n $USER
    set_color -o white
    echo -n @
    # show hostname
    if [ -z "$SSH_CLIENT" ] # not ssh
        set_color -o cyan
    else
        set_color -o blue
    end
    echo -n (hostname)

    # Jobs

    set_color normal
    set steav (jobs)
    if [ -n "$steav" ]
      echo
      for job in $steav
        set_color brown
        echo $job
      end
    end

    # prompt
    set_color -o $retc
    if test $USER = root -o $USER = toor
        echo -n ' #'
    else
        echo -n ' $'
    end

    # if tty includes "tty" then tty="tty"
    # else tty="pts"
    tty|grep -q tty; and set tty tty; or set tty pts
    set_color $retc
    if [ $tty = tty ]
        echo -n "X//>"
    else
        echo -n "🐡 "
    end


    # show time
    #set_color normal
    #set_color $retc
    #if [ $tty = tty ]
    #    echo -n '-'
    #else
    #    echo -n '─'
    #end
    #set_color -o green
    #echo -n '['
    #set_color normal
    #set_color $retc
    #echo -n (date +%X)
    #set_color -o green
    #echo -n ]
    
    # Check if acpi exists
    if not set -q __fish_nim_prompt_has_acpi
    	if type acpi > /dev/null ^ /dev/null
    		set -g __fish_nim_prompt_has_acpi ''
    	else
    		set -g __fish_nim_prompt_has_acpi '' # empty string
    	end
    end
    	
    if test "$__fish_nim_prompt_has_acpi"
      if [ (acpi -a 2> /dev/null | grep off) ]
        echo -n '─['
        set_color -o red
        echo -n (acpi -b|cut -d' ' -f 4-)
        set_color -o green
        echo -n ']'
      end
    end
end
