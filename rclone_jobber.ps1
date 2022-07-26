#!/usr/bin/env sh
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

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $source,
    [Parameter(Mandatory = $true, Position = 1)]
    [string] $dest,
    [Parameter(Position = 2)]
    [string] $options = "--dry-run",
    # do not put these in options: --backup-dir, --suffix, --log-file
    [Parameter(Position = 3)]
    [string] $job_name = $dest
)

Write-Output "source = '$source', dest = '$dest', move_old_files_to = '$move_old_files_to', options = '$options', job_name = '$job_name'"

$new = "current"
$timestamp = Get-Date -UFormat %Y-%m-%d_%T
$backup_dir = "--backup-dir=$dest/archive/$(Get-Date -UFormat %Y)/$timestamp"

Write-Output "new = '$new', timestamp = '$timestamp'"

function print_message {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $urgency,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $msg
    )

    $message = "${urgency}: $job_name $msg"

    Write-Output "$(Get-Date -UFormat %Y-%m-%d_%T) $message"
}

if (!$source) {
    print_message "ERROR" "aborted because source is empty string."
    exit 1
}

if (!$dest) {
    print_message "ERROR" "aborted because dest is empty string."
    exit 1
}


$cmd = "rclone sync $source $dest/$new $backup_dir $options"

print_message "INFO" "Back up in progress $timestamp $job_name"
print_message "INFO" "$cmd"

$exit_code = Invoke-Expression ("$cmd" + ';$LastExitCode')

if ($exit_code -eq 0) {
    $confirmation = "Completed $job_name"
    print_message "INFO" "$confirmation"
    exit 0
}
else {
    print_message "ERROR" "Failed.  rclone exit_code=$exit_code"
    exit 1
}
