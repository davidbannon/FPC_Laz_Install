#!/usr/bin/bash
#set -e

# Copyright (C) 2024 David Bannon

#    License:
#    This code is licensed under MIT License, see the file License.txt
#    or https://spdx.org/licenses/MIT.html  SPDX short identifier: MIT
#    
#    The tarball and source code it manipulates are covered by the FPC/Lazarus licenses.


# A script to 'install' a premade tarball containing a fpc copiler and src
# It can install dependencies, append a path to your .bashrc, create .fpc.cfg
# To make initial tarball, on system with working install, do from $HOME, eg
# $> tar czf fpc-324rc1.tgz bin/FPC/SRC/source-release_3_2_4-branch/ bin/FPC/fpc-3.2.4
#
# Use  -h for help
#
# David Bannon, last update 2024/10/30

DEPENDS="false"
TARPATH=`pwd`               # first place we look for the tar ball, then check ~/Downloads
TARBALL="fpc-3-2-4rc1.tgz"    # default filename, override with -t (but -t not working yet)
FPCHOME="$HOME""/bin/FPC"   # Where I keep multiple copies of FPC
FPCDIR="fpc-3.2.4"          # default below FPCHOME
PACKAGEMODE="unset"
APPENDPATH="no"
INSTALL_CMD_1=""
INSTALL_CMD_2=""

function ShowHelp {
	echo "----- Showing Help"
	echo "Install FPC from MY tarball ! Danger, experimental !"
	echo "Expects to find $TARBALL in current directory or ~/Downloads"
	echo "   -p MOD   Resolve dependencies, packaging model = apt, rpm, pacman"
	echo "   -f TAG   FPC version tag, default 324rc1, also eg 3.2.0, 322, 3.2.4rc1"
	echo "   -a       Append lines to .bashrc to add this to PATH, cumulative !"
	echo "   -h       This help page"
	echo "eg \$> bash ./fpc-tar.bash -p apt -f 3.2.4rc1 -a"
	exit;
}


function ResolveDepends {
    echo "Resolve Dependency requested, need root access to install gcc, make, binutils"
    # interesting !  Ubuntu apparently now preevents use of su -c
    sudo "$INSTALL_CMD_1" "$INSTALL_CMD_2" gcc make binutils		# hope same names everywhere ??
    if [ ! "$?" == "0" ]; then
        echo "Error reported trying to install dependencies, maybe try yourself with -"
        echo ">  sudo $INSTALL_CMD_1 $INSTALL_CMD_2 libx11-dev libgtk2.0-dev"
        exit
    fi
}

# checks for and, if necessary sets path to tarball, exist if we cannot proceed
function GetTarBallPath {
    if [ ! -e "$TARPATH"/"$TARBALL" ]; then
        if [ ! -e "$HOME/Downloads/""$TARBALL" ]; then     # sad, its not there
            echo "tarball file not found : $TARBALL - exiting ..."
            ShowHelp
        else
            TARPATH="$HOME/Downloads"            # 'cos we found one there.
        fi
    fi
}

function SetInstallMode {
    case "$PACKAGEMODE" in
        apt | deb | debian)
           INSTALL_CMD_1="apt"
           INSTALL_CMD_2="install"
           ;;
        rpm | dnf)
           INSTALL_CMD_1="dnf"
           INSTALL_CMD_2="install"
           ;;
         pacman| pac | arch)
           INSTALL_CMD_1="pacman"
           INSTALL_CMD_2="-S"
           ;;
    esac
    if [ "$INSTALL_CMD_1" == "" ]; then
        echo "Need to specify a package manager, exiting ...."
        ShowHelp
    fi
}

function CheckUserVer {
    TARBALL=""
    case $USERVER in	# I want distinctly different file names but FPC needs correct dir names
	320 | 3.2.0)
	    TARBALL="fpc-3-2-0.tgz"
	    FPCDIR="fpc-3.2.0"
	    ;;
	322 | 3.2.2)
	    TARBALL="fpc-3-2-2.tgz"
	    FPCDIR="fpc-3.2.2"
      	    ;;
	324rc1 | 3.2.4rc1)
	    TARBALL="fpc-3-2-4rc1.tgz"
	    FPCDIR="fpc-3.2.4"
	    ;;
    esac
    if [ "$TARBALL" == "" ]; then
	echo "===== Sorry, I don't know how to handle version tag $USERVER, please"
	echo "===== use the tags that apply to FPC tarballs that you can get from"
	echo "===== same place as you got this script, eg 320, 3.2.2, 324rc1 etc."
	ShowHelp
    fi
}

# ------------- It starts here ---------------------


while getopts "p:at:f:h" opt; do
	case $opt in
        p) PACKAGEMODE="$OPTARG"       
            ;;
	f) USERVER="$OPTARG"
		CheckUserVer	# will exit if provided ver unsuitable
		;;
	a) APPENDPATH="yes"
		;;
	h) 
           ShowHelp 
	   ;;	   # and exit !
   	\?) echo "Invalid option $OPTARG"
     		ShowHelp
		;;		
    esac
done


FPCPATH="$FPCHOME"/"$FPCDIR"    #  full path to dir were this version is put by tar

GetTarBallPath			# exits if no tarball found
echo "----- TARBALL is $TARPATH/$TARBALL"
echo "----- FPCPATH is $FPCPATH"

if [ "$PACKAGEMODE" == "unset" ]; then
        echo "----- Assuming dependencies are OK"
else
	SetInstallMode
    	ResolveDepends
fi

cd "$HOME"                            # The tarballs always starts from $HOME
tar xzf "$TARPATH"/"$TARBALL"
cd "$FPCPATH"
bin/fpcmkcfg -d basepath="$FPCHOME/fpc-""\$fpcversion" > "$HOME"/.fpc.cfg
if [ "$APPENDPATH" == "yes" ]; then
	echo "export OLD_PATH=\"\$PATH\"" >> ~/.bashrc
	echo "export PATH=\"$FPCPATH\"/bin:\"\$PATH\"" >> ~/.bashrc
	echo "----- Dont forget to run \"source ~/.bashrc\" "
fi
echo "----- Finished ! $PWD"


