################################################################################
#
# This file provides a basic wrapper to use git directly from the tcl console in
# Vivado.
# It requires the write_project_tcl_git.tcl script to work properly.
# Unversioned files will be put in the vivado_project folder
#
# Ricardo Barbedo
#
################################################################################

namespace eval ::git_wrapper {
    namespace export git
    namespace export wproj
    namespace import ::custom_projutils::write_project_tcl_git
    namespace import ::current_project
    namespace import ::common::get_property

    proc git {args} {
        set command [lindex $args 0]

        # Change directory project directory if not in it yet
        set proj_dir [regsub {\/vivado_project$} [get_property DIRECTORY [current_project]] {}]
        set current_dir [pwd]
        if {
            [string compare -nocase $proj_dir $current_dir]
        } then {
            puts "Not in project directory"
            puts "Changing directory to: ${proj_dir}"
            cd $proj_dir
        }

        switch $command {
            "init" {git_init {*}$args}
            "commit" {git_commit {*}$args}
            "default" {exec git {*}$args}
        }
    }

    proc git_init {args} {
        # Generate main gitignore file
        set m_file [open ".gitignore" "w"]
        puts $m_file "vivado_project/*
# Ignore .vscode folder because we might use vscode for editing only
*.vscode"
        close $m_file
        
        # Generate sdk gitignore file
        # Create the directory if it doesn't exist
        if {![file exists "sdk"]} {
            file mkdir "sdk"
        }

        # Now open and write the .gitignore file
        set s_file [open "sdk/.gitignore" "w"]
        puts $s_file "# Build artifacts
*.o
*.a
*.elf
*.elf.size
# Logs and debug
*.log
subdir.mk
*.snap
*.pdomAdded 
*.xmi
*.index
# Folders related to host workspace and project settings
/webtalk
*.metadata
/RemoteSystemsTempFiles"
        close $s_file

        # Initialize the repo
        exec git {*}$args
        exec git add --all
    }

    proc git_commit {args} {
        # Get project name
        set proj_file [current_project].tcl

        # Generate project and add it
        write_project_tcl_git -no_copy_sources -force -no_layout $proj_file
        puts $proj_file
        exec git add $proj_file

        # Now commit everything
        exec git {*}$args
    }

    proc wproj {} {
        # Change directory project directory if not in it yet
        set proj_dir [regsub {\/vivado_project$} [get_property DIRECTORY [current_project]] {}]
        set current_dir [pwd]
        if {
            [string compare -nocase $proj_dir $current_dir]
        } then {
            puts "Not in project directory"
            puts "Changing directory to: ${proj_dir}"
            cd $proj_dir
        }

        # Generate project
        set proj_file [current_project].tcl
        puts $proj_file
        write_project_tcl_git -no_copy_sources -force -no_layout $proj_file
    }
}
