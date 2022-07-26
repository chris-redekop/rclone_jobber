#!/usr/bin/env bash
# rclone_jobber.sh version 1.5.6
# Tutorial, backup-job examples, and source code at https://github.com/wolfv6/rclone_jobber
# Logging options are headed by "# set log".  Details are in the tutorial's "Logging options" section.

################################### license ##################################
# rclone_jobber.sh is a script that calls rclone sync to perform a backup.
# Written in 2018 by Wolfram Volpi, contact at https://github.com/wolfv6/rclone_jobber/issues
# To the extent possible under law, the author(s) have dedicated all copyright and related and
# neighboring rights to this software to the public domain worldwide.
# This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see http://creativecommons.org/publicdomain/zero/1.0/.
# rclone_jobber is not affiliated with rclone.

source="$1"
dest="$2"
options="${3:---dry-run}"
# do not put these in options: --backup-dir, --suffix, --log-file
job_name="${4:-${dest%:}}"

echo "source = '$source', dest = '$dest', move_old_files_to = '$move_old_files_to', options = '$options', job_name = '$job_name'"

new="current"
timestamp="$(date +%F_%T)"
backup_dir="--backup-dir=$dest/archive/$(date +%Y)/$timestamp"

echo "new = '$new', timestamp = '$timestamp'"

print_message()
{
    urgency="$1"
    msg="$2"

    message="${urgency}: $job_name $msg"

    echo "$(date +%F_%T) $message"

    warning_icon="/usr/share/icons/Adwaita/32x32/emblems/emblem-synchronizing.png"   #path in Fedora 28
    # notify-send is a popup notification on most Linux desktops, install libnotify-bin
    command -v notify-send && notify-send --urgency critical --icon "$warning_icon" "$message"
}

if [ -z "$source" ]; then
    print_message "ERROR" "aborted because source is empty string."
    exit 1
fi

if [ -z "$dest" ]; then
    print_message "ERROR" "aborted because dest is empty string."
    exit 1
fi

if ! test "rclone lsf --max-depth 1 $source"; then  # rclone lsf requires rclone 1.40 or later
    print_message "ERROR" "aborted because source is empty."
    exit 1
fi

# if job is already running (maybe previous run didn't finish)
# https://github.com/wolfv6/rclone_jobber/pull/9 said this is not working in macOS
if pidof -o $PPID -x "$job_name"; then
    print_message "WARNING" "aborted because it is already running."
    exit 1
fi

cmd="rclone sync $source $dest/$new $backup_dir $options"

print_message "INFO" "Back up in progress $timestamp $job_name"
print_message "INFO" "$cmd"

eval $cmd
exit_code=$?

if [ "$exit_code" -eq 0 ]; then            #if no errors
    confirmation="Completed $job_name"
    print_message "INFO" "$confirmation"
    exit 0
else
    print_message "ERROR" "Failed.  rclone exit_code=$exit_code"
    exit 1
fi
