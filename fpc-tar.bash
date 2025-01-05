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
# or, on ARM, from where you can see the FPC directory.
# $> cd ~/bin; czf fpc-324rc1_arm64.tgz bin/FPC/SRC/source-release_3_2_4-branch/ bin/FPC/fpc-3.2.4
#
# Note : armhf, ie 32bit tarball exits but not installable with this script. That is
#        because you will probably be running on 64bit hardware and I cannot detect it.

# Use  -h for help
#
# David Bannon, last update 2024/10/30

DEPENDS="false"
TARPATH=`pwd`               # first place we look for the tar ball, then check ~/Downloads
TARBALL="fpc-3-2-4rc1.tgz"    # default filename, override with -t (but -t not working yet)
FPCHOME="$HOME""/bin/FPC"   # Where I keep multiple copies of FPC 
ARMHOME="NOTSET"            # Arm only and required there, to allow an install on faster disk
ARMSYS="NO"
FPCDIR="fpc-3.2.4"          # default below FPCHOME
PACKAGEMODE="unset"
APPENDPATH="no"
INSTALL_CMD=""
CPU=""
CPUTAG="NOT SET"            # tag used in file name, empty in 64bit linux, _32 for 32bit
USERVER="324rc1"            # That is default

function ShowHelp {
	echo "----- Showing Help"
	echo "Install FPC from MY tarball ! Danger, experimental !"
	echo "Expects to find $TARBALL in current directory or ~/Downloads"
	echo "   -p MOD   Resolve dependencies, packaging model = apt, rpm, pacman"
	echo "   -f TAG   FPC version tag, default 324rc1, also eg 3.2.0, 322, 3.2.4rc1"
	echo "   -i path  Path to Install into, required on arm, ignored elsewhere"
	echo "   -a       Append lines to .bashrc to add this to PATH, cumulative !"
	echo "   -h       This help page"
	echo "eg \$> bash ./fpc-tar.bash -p apt -f 3.2.4rc1 -a"
	echo "   \$> bash ./fpc-tar.bash -p apt -i \$HOME/bin/FPC"
	exit;
}


# ------------ OK, what system are we on then ?  ----------------------------
# uname -m may return x86_64, i686, aarch64 (probably raspi)

function GetCPU {
    CPU=`uname -m`
    case "$CPU" in 
        "x86_64")                 # Maybe Linux or Mac
            COMPILER="ppcx64"
            TARGET="x86_64-linux"
            CPUTAG=""
        ;;
        "i686")                   # 32 bit, Linux but other tags possible ...
            COMPILER="ppc386"
            TARGET="i386-linux"
            CPUTAG="_32"          # thats, eg, between "fpc-3-2-2" and ".tgz"
        ;;
        "aarch64")                # 64bit RasPi (note - not tested with Apple Silicon)
            COMPILER="ppca64"
            # BASEDIR="$HOME/Ext/64bit/FPC"  # this is on a USB key to get i/o stuff off SDCard
            TARGET="aarch64-linux"           # check this Davo
            CPUTAG="_arm64"
            ARMSYS="YES"
        ;;
    esac

    if [ "$CPUTAG" == "NOT SET" ]; then
        echo "ERROR - cannot handle $CPU, exiting"
        exit
    fi
}

function ResolveDepends {
    CMD_LINE="sudo $INSTALL_CMD gcc make binutils"
    echo "Resolve Dependency requested, need root access to run this command -"
    echo "> $CMD_LINE"
    # interesting !  Ubuntu apparently now prevents use of su -c  ? and Debian does not allow sudo by default !
    $CMD_LINE
    if [ ! "$?" == "0" ]; then
        echo "Error reported trying to install dependencies, maybe try yourself with -"
        echo ">  $CMD_LINE"
        exit
    fi
}

# checks for and, if necessary sets path to tarball, exits if we cannot proceed
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
           INSTALL_CMD="apt install"
           ;;
        rpm | dnf)
           INSTALL_CMD="dnf install"
           ;;
         pacman| pac | arch)
           INSTALL_CMD="pacman -S --needed"
           ;;
    esac
    if [ "$INSTALL_CMD" == "" ]; then
        echo "Need to specify a package manager, exiting ...."
        ShowHelp
    fi
}

function CheckUserVer {
    TARBALL=""
    case $USERVER in	# I want distinctly different file names but FPC needs correct dir names
	320 | 3.2.0)
	    TARBALL="fpc-3-2-0""$CPUTAG"".tgz"
	    FPCDIR="fpc-3.2.0"
	    ;;
	322 | 3.2.2)
	    TARBALL="fpc-3-2-2""$CPUTAG"".tgz"
	    FPCDIR="fpc-3.2.2"
      	    ;;
	324rc1 | 3.2.4rc1)
	    TARBALL="fpc-3-2-4rc1""$CPUTAG"".tgz"
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

GetCPU                          # exits if cannot handle cpu

while getopts "p:at:f:i:h" opt; do
	case $opt in
        p) PACKAGEMODE="$OPTARG"       
            ;;
	f) USERVER="$OPTARG"
		;;
	a) APPENDPATH="yes"
		;;
	i) ARMHOME="$OPTARG"
		;;
	h) 
           ShowHelp 
	   ;;	   # and exit !
   	\?) echo "Invalid option $OPTARG"
     		ShowHelp
		;;		
    esac
done

CheckUserVer	# will exit if provided ver unsuitable

if [ $ARMSYS == "YES" ]; then
    if [ $ARMHOME == "NOTSET" ]; then
        echo "Arm system requires the -i path option because you might need to"
        echo "install on a faster and more reliable disk system other than the SDCard."
        echo "  eg   \$>  bash ./fpc-tar.bash -i \$HOME/bin/FPC"
        exit
    else
        FPCHOME="$ARMHOME"
    fi
    # ToDo : if we are running 32bit (on 64bit hardware?) we should change $CPUTAG to _armhf !
    #        not sure about a reliable test ? file /usr/bin/ls | grep armhf ??
fi

FPCPATH="$FPCHOME"/"$FPCDIR"    #  full path to dir were this version is put by tar

echo "----- CPU is $CPU and tarball is $TARBALL"

GetTarBallPath			# exits if no tarball found
echo "----- TARBALL is $TARPATH/$TARBALL"
echo "----- FPCPATH is $FPCPATH"

if [ "$PACKAGEMODE" == "unset" ]; then
        echo "----- Assuming dependencies are OK"
else
	SetInstallMode
    	ResolveDepends
fi
if [ $ARMSYS == "YES" ]; then
    mkdir -p $ARMHOME			# should check that it exists now ...
    cd "$ARMHOME"
else
    cd "$HOME"                            # The tarballs always starts from $HOME except with Arm
fi
tar xzf "$TARPATH"/"$TARBALL"
cd "$FPCPATH"
#                  $FPCHOME is, eg, .../FPC
bin/fpcmkcfg -d basepath="$FPCHOME/fpc-""\$fpcversion" > "$HOME"/.fpc.cfg
if [ "$APPENDPATH" == "yes" ]; then
	echo "export OLD_PATH=\"\$PATH\"" >> ~/.bashrc
	echo "export PATH=\"$FPCPATH\"/bin:\"\$PATH\"" >> ~/.bashrc
	echo "----- Dont forget to run \"source ~/.bashrc\" "
fi
echo "----- Finished ! $PWD"


