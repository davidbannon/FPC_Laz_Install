#!/usr/bin/bash
set -e

# Copyright (C) 2024 David Bannon

#    License:
#    This code is licensed under MIT License, see the file License.txt
#    or https://spdx.org/licenses/MIT.html  SPDX short identifier: MIT
#    
#    The tarball and source code it manipulates are covered by the FPC/Lazarus licenses.



# ---------------------------------------------------------
# A quick and dirty script to build a working Lazarus
# install on a deb based machine (and PCLinuxOS too).
# Always installs Lazarus from source, looks for a zip in current dir, ~/Downloads
# depends on what ever FPC is on PATH and
# if Qt5 enabled, libqt5pas-dev. Checks for both and tries to
# install from distro repo if not already present.
# Note that repo versions of libqt5pas-dev may not be current.
# Does not consider FPC-main suitable, use 3.2.3 or 3.2.4
# Creates a Lazarus Desktop and icon so should appear in your menus. 

# NOTE - We build with fpc322 because thats how Lazarus does it, as of June 2024.

# Edit below to chose Qt5 (over gtk2) and Lazarus-Fixes, later FPC

# David Bannon - 2024-04-18
# LAZVER="4_0_RC_1"
LAZVER="3_6"		    # as it appears in file names
LAZWIDGET="gtk2"        # Use -w to set QT5 or QT6
FPCVER="3.2.2"          # Now, is not acceptable, so 322 or 324rc1 at present
FPCVER2="3.2.4"         # right now, thats all we accept, can do better.
LAZROOTDIR="$HOME/bin/Lazarus"                # Will have to override if, eg, RasPi
MACOS="false"
PACKAGEMODEE=""		# empty means don't install dependencies
# LAZFINALNAME="lazarus-fixes_3_0"
DOWNLOAD="false"        # If true, will try and get indicated Lazarus from gitlab

LAZZIPPATH=`pwd`


INSTALL_CMD_1="apt"	# Manjero, its "pacman"   
INSTALL_CMD_2="install"     # Manjero, its "-S"
INSTALL_CMD_3=""     # 

# INSTALL_CMD="pacman -S"	        # Manjero

# ------ Best not to change too much below here --------

DESKTOPDIR="$HOME/.local/share/applications"

function ShowHelp {
	echo "Install from source, a lazarus based on src zip in current dir"
	echo "   -d        Download the Lazarus file if necessary."
	echo "   -p        Install dependencies from package manager = deb, rpm, pac"
	echo "   -w widget Lazarus Widget, gtk2, qt5, qt6"
	echo "   -f rel    Lazarus Release, from file name, after lazarus-lazarus_  3_6"
	echo "   -m        Its a Mac"
	echo "   -h        This help page"
	echo "If using -p, its a good idea to ensure your package manager is up todate."
	exit;
}

while getopts "dp:w:f:mh" opt; do
    case $opt in
        d) DOWNLOAD="true"            # 
            ;;
        p) PACKAGEMODE="$OPTARG"      # -p deb | rpm | pac
            ;;
        w) LAZWIDGET="$OPTARG"        # -w gtk2 | qt5 | qt6
	        ;;
	    f) LAZVER="$OPTARG"           # -w 3_6  | -w 4_0_RC_1
	        ;;
	    m) MACOS="true"
	        ;;
	h) ShowHelp 
	   ;;			      # and exit !	
    esac
done

LAZDOWNLOAD="https://gitlab.com/freepascal.org/lazarus/lazarus/-/archive/lazarus_$LAZVER/lazarus-lazarus_""$LAZVER"".zip"
LAZFINALNAME="lazarus_""$LAZVER"
LAZZIPNAME=`basename "$LAZDOWNLOAD"`

if [ $(uname -m) == "aarch64" ]; then      # WE assume RasPi, NOT SAFE !
    LAZROOTDIR="$HOME/Ext/64bit/Lazarus"    
fi

function FPCInstalled () {
#   expect eg "3.2.2", maybe 3.2.3 or 3.2.4  ?
    echo `fpc -iV`
}

function SetInstallMode {
    case "$PACKAGEMODE" in
	apt | deb | debian)
	   GTK2DEPS="libx11-dev libgtk2.0-dev"
	   QT5DEPS="libqt5pas-dev"
	   QT6DEPS="libqt6pas-dev"
	   INSTALL_CMD="apt install" 
	   ;;
	rpm | dnf)
	   QT5DEPS="qt5pas-devel"
	   QT6DEPS="qt6pas-devel"
	   GTK2DEPS="libX11-devel gtk2-devel"
	   INSTALL_CMD="dnf install" 
	   ;;
	 pacman| pac | arch)
	   QT5DEPS="qt5pas"             # yes, Nov 2024, repo version is current
	   QT6DEPS="qt6pas"             # no, Nov, 2024, repo version one rev beehind, maybe OK ?
	   GTK2DEPS="gtk2 libx11"       # no -dev packages in Arch !
	   INSTALL_CMD="pacman -S --needed"
	   ;;
    esac
    if [ "$INSTALL_CMD_1" == "" ]; then
	echo "Need to specify a package manager, exiting ...."
	ShowHelp
    fi
    echo "install mode set"
}


# ----------- OK, it starts here -----------

FPCFOUND=$(FPCInstalled)

if [ ! "$PACKAGEMODE" == "" ]; then
    if [ "MACOS" == "true" ]; then
        echo " Sorry, Mac dependencies are your problem, -m means Mac. Exiting"
        ShowHelp
    fi
    SetInstallMode		# does not return if not set properly
    case "$LAZWIDGET" in
    gtk2)
	    CMD_LINE="sudo $INSTALL_CMD $GTK2DEPS"
	    ;;
	qt5)
	    CMD_LINE="sudo $INSTALL_CMD $QT5DEPS"
	    ;;
	qt6)
	    CMD_LINE="sudo $INSTALL_CMD $QT6DEPS"
	    ;;
    esac
    echo "root required to run \"$CMD_LINE\""
    $CMD_LINE
    if [ ! "$?" == "0" ]; then
        echo "========================================="
        echo "Error reported trying to install dependencies, maybe try yourself with -"
	echo ">  $CMD_LINE"
	exit
    fi
    echo "deps resolved"
else
    echo "===== Assuming Dependencies are OK"
fi

if [ "$FPCVER" != "$FPCFOUND" ]; then
    if [ "$FPCVER2" != "$FPCFOUND" ]; then
        echo "===== SORRY, no suitable FPC found, exiting"
        exit;
    else
        FPCVER="$FPCVER2"
    fi
fi    

echo "----- OK, we have FPC $FPCVER"

if [ ! -d "$LAZROOTDIR/LazConfigs" ]; then
    echo "----- Creating Config Dir $LAZROOTDIR/LazConfig"
    mkdir -p "$LAZROOTDIR/LazConfigs"
    if [ ! -d "$LAZROOTDIR/LazConfigs" ]; then
        echo "Sorry, cannot create config dir $LAZROOTDIR/LazConfigs "
        exit
    fi
fi

echo "----- OK, we have a config dir $LAZROOTDIR/LazConfigs"

if [ ! -e "$LAZZIPPATH"/"$LAZZIPNAME" ]; then
    if [ ! -e "$HOME/Downloads/""$LAZZIPNAME" ]; then     # sad, its not there
        echo "----- Lazarus file not present at $HOME/Downloads/""$LAZZIPNAME"
	if [ "$DOWNLOAD" == "true" ]; then
	    echo "----- We will try to download $LAZDOWNLOAD"
            cd "$HOME/Downloads"
            wget "$LAZDOWNLOAD"
            if [ ! -e "$HOME/Downloads/""$LAZZIPNAME" ]; then     # still not there ?
               echo "Sorry, cannot download $LAZDOWNLOAD"
               echo "Downloading Disabled"
               exit
	    fi
	else 
	    echo "----- Please put Lazarus downloaded zip file in Downloads or use -d"
	    exit
	fi
    fi
    LAZZIPPATH="$HOME/Downloads"            # 'cos we found one or put one there.

fi

echo "----- OK, we have Lazarus Source $LAZZIPPATH/$LAZZIPNAME"

if [ -d "$LAZROOTDIR""/LazConfigs/""$LAZFINALNAME" ]; then
	echo "----- WARNING, Laz Config Dir Exists"
fi

echo "----- Changing to $LAZROOTDIR to unzip $LAZZIPPATH/$LAZZIPNAME"
cd "$LAZROOTDIR"

if [ -d "$LAZFINALNAME" ]; then
    if [ "$LAZFINALNAME" == "" ]; then         # Just a safety measure.
        echo "ERROR !!! LAZFINALNAME is empty and I was about to rm -Rf it !"
        exit
    fi
    echo "----- OK, removing existing Lazarus install"
    rm -Rf "$LAZFINALNAME"
fi
unzip -q "$LAZZIPPATH/""$LAZZIPNAME"
mv `basename -s .zip "$LAZZIPNAME"` "$LAZFINALNAME"

cd "$LAZFINALNAME"

# pwd

echo "--pcp=""$LAZROOTDIR""/LazConfigs/""$LAZFINALNAME" > lazarus.cfg

if [ "$MACOS" == "false" ]; then            # This block all about .desktop file
    if [ ! -d "$HOME/.icons" ]; then 
        mkdir "$HOME/.icons"
    fi
    if [ ! -e "$HOME/.icons/lazarus256x256.png" ]; then
	echo "----- Copying icon from $PWD images/icons/lazarus256x256.png"
        cp "images/icons/lazarus256x256.png" "$HOME"/.icons/.
    fi

    if [ ! -d "$DESKTOPDIR" ]; then
	    mkdir -p "$DESKTOPDIR"
	    if [ ! -d "$DESKTOPDIR" ]; then
	    	echo "===== ERROR, failed to make desktop dir, $DESKTOPDIR"
	    	exit
	    fi
    fi

    if [ -e "$DESKTOPDIR/lazarus.desktop" ]; then
        read -p "Overwrite existing desktop file y/n ?" yesno
        if [ "$yesno" == "y" ]; then
            echo "----- Replacing $DESKTOPDIR/lazarus.desktop"
            rm "$DESKTOPDIR/lazarus.desktop"
        else echo "leaving $DESKTOPDIR/lazarus.desktop alone"
        fi
    fi

    read -p "Create a script to start Lazarus with right PATH y/n ?" yesno
    if [ "$yesno" == "y" ]; then
	echo "----- Creating $HOMEE/bin/lazarus.bash"
        echo "#!/usr/bin/bash"    > $HOME/bin/lazarus.bash
	echo "export PATH=$PATH" >> $HOME/bin/lazarus.bash    # we use existing command line path
	echo "export QT_QPA_PLATFORM=xcb" >> $HOME/bin/lazarus.bash
        echo "$PWD/lazarus"      >> $HOME/bin/lazarus.bash
	echo "# This was the correct path when the script was created. It ensures Lazarus can" >> $HOME/bin/lazarus.bash
	echo "# find the compiler when started from system menu. Feel free to change it to"    >> $HOME/bin/lazarus.bash
	echo "# use a different compiler or to start a different version of Lazarus."          >> $HOME/bin/lazarus.bash 
	chmod u+x "$HOME/bin/lazarus.bash"
    fi

    if [ ! -e "$DESKTOPDIR/lazarus.desktop" ]; then
        echo "[Desktop Entry]" > "$DESKTOPDIR"/lazarus.desktop
        echo "Name=Lazarus"  >> "$DESKTOPDIR"/lazarus.desktop
        echo "GenericName=ide" >> "$DESKTOPDIR"/lazarus.desktop 
        echo "Comment=ide" >> "$DESKTOPDIR"/lazarus.desktop
	if [ "$yesno" == "y" ]; then                                     # that has answer to use script question
            echo "Exec=$HOME/bin/lazarus.bash" >> "$DESKTOPDIR"/lazarus.desktop     # start with the script above
        else
	    echo "Exec=$LAZROOTDIR"/"$LAZFINALNAME""/lazarus" >> "$DESKTOPDIR"/lazarus.desktop   # start directly
	fi
        echo "Icon=""$HOME""/.icons/lazarus256x256.png" >> "$DESKTOPDIR"/lazarus.desktop
        echo "Terminal=false" >> "$DESKTOPDIR"/lazarus.desktop
        echo "Type=Application" >> "$DESKTOPDIR"/lazarus.desktop
        echo "Categories=Utility;Development;" >> "$DESKTOPDIR"/lazarus.desktop
	chmod u+x "$DESKTOPDIR/lazarus.desktop"
	echo "----- Generated a new desktop file"
    fi
fi                 # end of if MACOS


echo "----- Building in $LAZROOTDIR/$LAZFINALNAME, FPCVER is $FPCVER, $LAZWIDGET"
echo "===== This will take a few minutes ...."

make "clean" "LCL_PLATFORM=$LAZWIDGET" "bigide" > build.log

tail build.log
echo "----------------------------------------------------------"
echo "To see compile log, type \"cat $PWD/build.log\""
echo "To start lazarus, use menu or do following -"
echo "   cd $PWD; ./lazarus <enter>"

