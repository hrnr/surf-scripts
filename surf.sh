#!/bin/sh
# 
# Based on script by Peter John Hartman (http://individual.utoronto.ca/peterjh)
# Creative commons licence
#

# dmenu appearence
normbgcolor='#222222'
normfgcolor='#aaaaaa'
selbgcolor='#535d6c'
selfgcolor='#ffffff'

# files
barhistoryf=~/.surf/barhistory.txt
findhistoryf=~/.surf/findhistory.txt
browserhistoryf=~/.surf/history.txt
bookmarksf=~/.surf/bookmarks.txt

# how many history entries to preserve
history_count=100

pid=$1
xid=$2

dmenu="dmenu -nb $normbgcolor -nf $normfgcolor \
       -sb $selbgcolor -sf $selfgcolor"

s_get_prop() { # xprop
    xprop -id $xid $1 | cut -d '"' -f 2
}

s_set_prop() { # xprop value
    [ -n "$2" ] && xprop -id $xid -f $1 8s -set $1 "$2"
}

s_write_bookmarksf() { # file value
    tags="$($dmenu -p 'bookmark tags:' | tr ' ' ':')"
    [ -n "$2" ] && (grep -F -v "$2" "$1" > "$1.temp"; mv "$1.temp" "$1"; echo "t-:$tags $2" >> "$1")
}

s_write_historyf() { # file value preserve_count
    [ -n "$2" ] && (grep -F -v "$2" "$1" | tail -n $3 > "$1.temp"; mv "$1.temp" "$1"; echo "$2" >> "$1")
}

s_clean_historyf() { # file preserve_count
    uniq "$1" | tail -n $2 > "$1.temp"; mv "$1.temp" "$1";
}

case "$pid" in
"_SURF_INFO")
    xprop -id $xid | sed 's/\t/    /g' | $dmenu -l 20
    ;;
"_SURF_FIND")
    find="`tac $findhistoryf 2>/dev/null | $dmenu -p find:`"
    s_set_prop _SURF_FIND "$find"
    s_write_historyf $findhistoryf "$find" $history_count
    ;;
"_SURF_BMARK")
    uri=`s_get_prop _SURF_URI`
    s_write_bookmarksf $bookmarksf "$uri"
    ;;
"_SURF_URI_RAW")
    uri=`echo $(s_get_prop _SURF_URI) | $dmenu -p "uri:"`
    s_set_prop _SURF_GO "$uri"
    ;;
"_SURF_URI")
    s_clean_historyf "$browserhistoryf" 500
    sel=`(s_get_prop _SURF_URI; tac $barhistoryf 2> /dev/null; tac $bookmarksf 2> /dev/null; tac $browserhistoryf 2> /dev/null) |
         $dmenu -l 5 -p "uri [?gwyx]:"`
    [ -z "$sel" ] && exit
    # after ? space is not required
    if echo "$sel" | grep -q '^\?[^ ]'; then
        opt=$(echo "$sel" | cut -c 1)
        arg=$(echo "$sel" | cut -c 2-)
    else
        opt=$(echo "$sel" | cut -d ' ' -f 1)
        arg=$(echo "$sel" | cut -d ' ' -f 2-)
    fi
    save=0
    case "$opt" in
    '?') # google for it
        uri="http://www.google.com/search?q=$arg"
        save=1
        ;;
    "g") # google for it
        uri="http://www.google.com/search?q=$arg"
        save=1
        ;;
    "w") # wikipedia
        uri="http://wikipedia.org/wiki/$arg"
        save=1
        ;;
    "y") # youtube
        uri="http://www.youtube.com/results?search_query=$arg&aq=f"
        save=1
        ;;
    "x") # delete
        for f in $barhistoryf $findhistoryf $bookmarksf $browserhistoryf; do
            grep -F -v "$arg" "$f" > "$f.temp"; mv "$f.temp" "$f"
        done
        exit;
        ;;
    "t-:"*|"h:"*) # bookmark or history -> strip tags
        uri="$arg"
        save=0
        ;;
    *)
        uri="$sel"
        save=1
        ;;
    esac

    # only set the uri; don't write to file
    [ $save -eq 0 ] && s_set_prop _SURF_GO "$uri"
    # set the url and write exactly what the user inputed to the file
    [ $save -eq 1 ] && (s_set_prop _SURF_GO "$uri"; s_write_historyf $barhistoryf "$sel" $history_count)
    ;;
*)
    echo Unknown xprop
    ;;
esac