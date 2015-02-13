#!/bin/sh

# input parameters
url="$1"
user_agent="$2"
referer="$3"
cookie_file="$4"

# ignored extensions regex
ignored_ext='\.swf$'
# mimetypes to show directly
show_mime='(application/pdf)|(application/postscript)'

# download dir
d_dir="~/Downloads"

logfile=~/.surf/downloads.log

# download name tempfile
# tempfile=`mktemp`

if echo "$url" | grep -q -E "$ignored_ext"; then
	exit 0
else
	xterm -title "surf: Downloading" -e /bin/sh -c "cd $d_dir;
	# filename=\"\`curl -J -L -O --user-agent '$user_agent' --referer '$referer' -b '$cookie_file' -c '$cookie_file' --write-out '%{filename_effective}' '$url'\`\"
	wget -v --progress=bar:force --content-disposition --load-cookies '$cookie_file' --referer='$referer' --user-agent='$user_agent' '$url' 2>&1 | tee -a '$logfile'
	filename=\"\`tail -n 10 '$logfile' | grep -E '^Saving to: ‘.*’' | sed -r 's/^Saving to: ‘(.*)’.*/\1/' \`\"
	
	# if echo \"\$filename\" | grep -q -E '$show_mime'; then
	if xdg-mime query filetype \"\$filename\" | grep -q -E '$show_mime'; then
		nohup xdg-open $d_dir/\"\$filename\" > /dev/null 2>&1 &
	fi

	echo -n \"\\033]2;surf: Download completed\\007\"
	sleep 30
	"
fi