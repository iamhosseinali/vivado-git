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

        # Generate sdk .gitattributes file
        set sa_file [open "sdk/.gitattributes" "w"]
        puts $sa_file "# Enforce LF for sensitive files
*.c     text eol=lf
*.cpp   text eol=lf
*.h     text eol=lf
*.mk    text eol=lf
*.tcl   text eol=lf
*.sh    text eol=lf

# Fallback: auto-detect for the rest
* text=auto"
        close $sa_file
       
        # Generate README file
        set r_file [open "README.md" "w"]
        puts $r_file {# Clone and Recreation
This project was built with vivado 2019.1, so make sure you are using this exact version.  
PL projects often come with some custom IPs, these IPs can be HDL or HLS, sth like this: 
```
ip_repo
    ├───HDL
    │   ├───HDL_IP_1
    │   └───HDL_IP_2
    └───HLS
        ├───HLS_IP_1
        └───HLS_IP_2
```

All of these IPs have their own git and are added to the project as git submodules, so to clone the project properly run: 

```  git clone --recurse-submodules <repo_url> ```

After cloning and before running the project_name.tcl to recreate the whole vivado project, firstly recreate the HLS IPs projects. 

## Recreating the HLS project
Step 1: Open Vivado HLS Command Prompt. 

Step 2: Change the directory to ip_repo\HLS folder, e.q.

``` cd c:\...\project_name\ip_repo\HLS ``` 


Step 3: source the script.tcl: 

``` vivado_hls -f HLS_IP_1\solution1\script.tcl ``` 


Step 4: Open Vivado HLS and open your recreated project. 

Step 5: Run C Synthesis and Export RTL. 

## Recreating the PL Project
Make sure all the dependencies including HLS and HDL repos are correctly placed under the right directory, then in vivado command prompt or TCL Consol of the GUI run: 

``` source c:\...\project_name\project_name.tcl ```

Wait untill recreation is completed. 

## Recreating the SDK project
Step 1: Launch Xilinx SDK not from Vivao project but instead individually. 

Step 2: Set the Workspace to ``` project_name\sdk ```

Step 3: Import the BSP, Application, and hw_platform projects into the workspace.

Step 4: Regenerate the BSP to resolve errors caused by missing .o and .a files — these are ignored in Git because they're auto-generated.

Step 5: If applicable, replace modified BSP source files (found in the custom_bsp_sources folder) with the originals in the BSP project. Then, Build All.

Step 6: Run:

``` git add --renormalize . ```

This ensures Git respects the .gitattributes file and normalizes line endings.


Refer to this [repo](https://github.com/iamhosseinali/vivado-git) and look for the right branch based on your vivado version to use vivado and git together like the project above.
}
        close $r_file

        # Initialize the repo
        exec git {*}$args
        exec git add --all
    }

    proc git_commit {args} {
        set proj [current_project]
        if {$proj eq ""} {
            puts "No current project open."
            return
        }

        set proj_file "$proj.tcl"
        write_project_tcl_git -no_copy_sources -force -no_layout $proj_file
        puts "Generated: $proj_file"

        # Try to stage the file, log warnings but don't abort
        if {[catch {exec git add $proj_file} addResult]} {
            puts "Git add warning:\n$addResult"
        } else {
            puts "Staged $proj_file"
        }

        # Show exact args and commit
        puts "ARGS: $args"

        if {[catch {exec git {*}$args} commitOut]} {
            puts "Git commit failed:\n$commitOut"
        } else {
            puts "Git commit succeeded:\n$commitOut"
        }
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
