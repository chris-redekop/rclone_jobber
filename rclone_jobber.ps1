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

################################# parameters #################################

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $source, #the directory to back up (without a trailing slash)
    [Parameter(Mandatory = $true, Position = 1)]
    [string] $dest, #the directory to back up to (without a trailing slash or "last_snapshot") destination=$dest/last_snapshot
    [Parameter(Position = 2)]
    [string] $move_old_files_to = "dated_directory", #move_old_files_to is one of:
    # "dated_directory" - move old files to a dated directory (an incremental backup)
    # "dated_files"     - move old files to old_files directory, and append move date to file names (an incremental backup)
    # ""                - old files are overwritten or deleted (a plain one-way sync backup)
    [Parameter(Position = 3)]
    [string] $options = "--dry-run", #rclone options like "--filter-from=filter_patterns --checksum --log-level="INFO" --dry-run"
    #do not put these in options: --backup-dir, --suffix, --log-file
    [Parameter(Position = 4)]
    [string] $job_name = $dest
)

Write-Host "source = '$source', dest = '$dest', move_old_files_to = '$move_old_files_to', options = '$options', job_name = '$job_name'"

################################ set variables ###############################
# $new is the directory name of the current snapshot
# $timestamp is time that old file was moved out of new (not time that file was copied from source)

$new = "current"
$timestamp = Get-Date -UFormat %F_%T

Write-Host "new = '$new', timestamp = '$timestamp'"

################################## functions #################################

function print_message {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $urgency,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $msg
    )

    $message = "${urgency}: $job_name $msg"

    Write-Host "$(Get-Date -UFormat %F_%T) $message"
}

################################# range checks ################################
# if source is empty string
if (!$source) {
    print_message "ERROR" "aborted because source is empty string."
    exit 1
}

# if dest is empty string
if (!$dest) {
    print_message "ERROR" "aborted because dest is empty string."
    exit 1
}

############################### move_old_files_to #############################
# deleted or changed files are removed or moved, depending on value of move_old_files_to variable
# default move_old_files_to="" will remove deleted or changed files from backup
if ($move_old_files_to -eq "dated_directory") {
    # move deleted or changed files to archive/$(date +%Y)/$timestamp directory
    $backup_dir = "--backup-dir=$dest/archive/$(date +%Y)/$timestamp"
}
elseif ($move_old_files_to -eq "dated_files") {
    # move deleted or changed files to old directory, and append _$timestamp to file name
    $backup_dir = "--backup-dir=$dest/old_files --suffix=_$timestamp"
}
elseif ($move_old_files_to -ne "") {
    print_message "WARNING" "Parameter move_old_files_to=$move_old_files_to, but should be dated_directory or dated_files.\
  Moving old data to dated_directory."
    $backup_dir = "--backup-dir=$dest/$timestamp"
}

################################### back up ##################################
$cmd = "rclone sync $source $dest/$new $backup_dir $options"

# progress message
print_message "INFO" "Back up in progress $timestamp $job_name"
print_message "INFO" "$cmd"

################################### back up ##################################
Invoke-Expression $cmd
$exit_code = $?

############################ confirmation and logging ########################

if ($exit_code -eq 0) {
    $confirmation = "$(date +%F_%T) completed $job_name"
    print_message "INFO" "$confirmation"
    exit 0
}
else {
    print_message "ERROR" "failed.  rclone exit_code=$exit_code"
    exit 1
}