#!/usr/bin/bash
set -e

# Copyright (C) 2024, 2025 David Bannon

#    License:
#    This code is licensed under MIT License, see the file License.txt
#    or https://spdx.org/licenses/MIT.html  SPDX short identifier: MIT
#    
#    The tarball and source code it manipulates are covered by the FPC/Lazarus licenses.



# ---------------------------------------------------------
# A quick and dirty script to build a working Lazarus
# install on a deb based machine (and PCLinuxOS too).
# Always installs Lazarus from source, looks for a zip in current dir and ~/Downloads
# depends on what ever FPC is on PATH and
# if Qt5 enabled, libqt5pas-dev. Checks for both and tries to
# install from distro repo if not already present.
# Note that repo versions of libqt5pas-dev may not be current.
# Does not consider FPC-main suitable, use 3.2.4  (Hmm, why ??)
# Creates a Lazarus Desktop and icon so should appear in your menus. 

# NOTE - all recent Lazarus will build with FPC324 (despite officially recommending 322)

# David Bannon - 2025-03-06
LAZVER="4_2"		    # as it appears in file names, this is default !
LAZZIPNAME=""           # full name of the lazarus zip (no path)
LAZGITHUB="https://gitlab.com/freepascal.org/lazarus/lazarus/-/archive/"            
LAZDOWNURL=""           # The URL to download, varies between main, branch and tag !
LAZWIDGET="gtk2"        # Use -w to set QT5 or QT6
# LAZDEBUG=""             # Has true if we want to build a debug version of Lazarus (its the default !)
FPCVER="3.2.2"          # March 2025, 3.2.2 will work but I recommend 3.2.4
FPCVER2="3.2.4"         # This is the 3.2.4-branch, when released will have same tag.
LAZROOTDIR="$HOME/bin/Lazarus"             # Will have to override if, eg, RasPi
LAZROOTDIRPI="$HOME/Ext/64bit/Lazarus"     # Alt, better disk location for RasPi on _my_ system
MACOS="false"                              # Has not been tested for awhile !
DOWNLOAD="false"        # If true, will try and get indicated Lazarus from gitlab if necessary
MVLAZDIR="false"        # True is we need to fix a lazarus-lazarus situation ! (Tag only ?)
LAZZIPPATH=`pwd`        # we look for a zip fime in current dir, failing that, in ~/Downloads

INSTALL_CMD=""      # is set to distro install command if user sets -r

# =============== This function may need updating as new releases appear.

function CleanLazVersion {
	#echo "in CleanLazVersion LAZVER = $LAZVER"
	case "$LAZVER" in
		3_6 | 3_8 | 4_0 | 4_2)    # Tags.  !
			LAZZIPNAME="lazarus-lazarus_""$LAZVER".zip
			LAZDOWNURL="$LAZGITHUB"lazarus_"$LAZVER"/"$LAZZIPNAME"
			LAZFINALNAME="lazarus_""$LAZVER"                # note underscore
			MVLAZDIR="true"
			;;
		main)
			LAZZIPNAME="lazarus-main.zip"
			LAZDOWNURL="$LAZGITHUB"main/"$LAZZIPNAME"
			LAZFINALNAME="lazarus-""$LAZVER"               # hypen, will be same as unzipped dir
			;;
		fixes_4)            # This is a branch
			LAZZIPNAME="lazarus-""$LAZVER"".zip"
			LAZDOWNURL="$LAZGITHUB"/"$LAZVER"/"$LAZZIPNAME"
			LAZFINALNAME="lazarus-""$LAZVER"               # hypen, will be same as unzipped dir
			;;		
	esac
	if [ "$LAZZIPNAME" == "" ]; then
		echo "Cannot use a lazarus tag, branch or release like [$LAZVER], exiting ...."
		ShowHelp
    fi	
}

# https://gitlab.com/freepascal.org/lazarus/lazarus/-/archive/main/lazarus-main.zip
# https://gitlab.com/freepascal.org/lazarus/lazarus/-/archive/fixes_4/lazarus-fixes_4.zip
# A Tag, eg 3.8, 40rc2 etc
# https://gitlab.com/freepascal.org/lazarus/lazarus/-/archive/lazarus_4_0RC2/lazarus-lazarus_4_0RC2.zip		

# ------ Best not to change too much below here --------

DESKTOPDIR="$HOME/.local/share/applications"

function ShowHelp {
	echo "Install from source, a lazarus based on src zip in current dir"
	echo "   -d        Download the Lazarus file if necessary."
	echo "   -r        Resolve dependencies if necessary"
#	echo "   -p        Install dependencies from package manager = deb, rpm, pac"
	echo "   -w widget Lazarus Widget, gtk2, qt5, qt6"
	echo "   -f rel    Lazarus Release, tag from file name, defaults to 4_0, can be -"
	echo "               main; fixes_4; lazarus-lazarus_* etc, use one of :"
	echo "               main, 3_6, 3_8, 4_0, 4_2"
	echo "   -v rel    Same as above."
	echo "   -i dir    Install dir, default $HOME/bin/Lazarus but on a Pi maybe move to better disk" 
	echo "   -I        Install dir is default for RasPi, $LAZROOTDIRPI"    # Very silly on other than RasPI !!   
	echo "   -m        Its a Mac"
#	echo "   -D        Make a Debug version of Lazarus"    # default build of Lazarus is DEBUG
	echo "   -h        This help page"
	echo "If using -r, its a good idea to ensure your package manager is up todate."
	echo "Makes a lazarus.cfg which defines where your lazarus config is kept."
	echo "Looks for a downloaded lazarus zipball in first current dir, then ~/Downloads"
	exit;
}

function SetInstallMode {
	which dnf >&1 >/dev/null && PACKAGEMODE="dnf"     # PACKAGEMODE is a "local variable" !
	which apt-get >&1 >/dev/null && PACKAGEMODE="apt"
	which pacman >&1 >/dev/null && PACKAGEMODE="pacman"
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
	   QT6DEPS="qt6pas"             # no, Nov, 2024, repo version one rev behind, maybe OK ?
	   GTK2DEPS="gtk2 libx11"       # no -dev packages in Arch !
	   INSTALL_CMD="pacman -S --needed"
	   ;;
    esac
    if [ "$INSTALL_CMD" == "" ]; then
	echo "Cannot identify Package Manager, exiting ...."
	ShowHelp
    fi
    echo "INSTALL_CMD set to $INSTALL_CMD"
}

# ----------- OK, it starts here -----------



while getopts "Ii:drp:w:f:v:mh" opt; do
    case $opt in
		i) LAZROOTDIR="$OPTARG"       # User specified install dir
			;;
		I) LAZROOTDIR="$LAZROOTDIRPI" # Thats a better disk IN MY SYSTEMS, suits only PI    	
			;;
		d) DOWNLOAD="true"            # 
            ;;
        r) SetInstallMode             # Will set INSTALL_CMD. else its ""
        	;;
        w) LAZWIDGET="$OPTARG"        # -w gtk2 | qt5 | qt6
	        ;;
	    f|v) LAZVER="$OPTARG"         # -f 3_6  | -f 4_0_RC_1 | main  
	        ;;
	    m) MACOS="true"
	    	LAZWIDGET="cocoa"
	        ;;
	h) ShowHelp 
	   ;;			      # and exit !	
    esac
done

CleanLazVersion         # expands tag to filename and download URL

# No, do not do this automatically any more, use -i or -I
#if [ $(uname -m) == "aarch64" ]; then      # WE assume RasPi, NOT SAFE !
#    LAZROOTDIR="$HOME/Ext/64bit/Lazarus"   # I do this on a Pi to move disk I/O off the SDCard. 
#fi
  
function FPCInstalled () {
#   expect eg "3.2.2", maybe 3.2.3 or 3.2.4, the late 2024 early 2025 3.2.4_branch calls itself 3.2.4
    echo `fpc -iV`
}


FPCFOUND=$(FPCInstalled)

# echo "--------- FPCFOUND=$FPCFOUND   INSTALL_CMD=$INSTALL_CMD   LAZROOTDIR=$LAZROOTDIR   LAZWIDGET=$LAZWIDGET"
# echo "--------- LAZDOWNURL=$LAZDOWNURL    MVLAZDIR=$MVLAZDIR"

if [ ! "$INSTALL_CMD" == "" ]; then
    if [ "MACOS" == "true" ]; then
        echo " Sorry, Mac dependencies are your problem, -m means Mac. Exiting"
        ShowHelp
    fi
#    SetInstallMode		# does not return if not set properly
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
    echo "WARNING : root required to run \"$CMD_LINE\""
    $CMD_LINE
    if [ ! "$?" == "0" ]; then
        echo "========================================="
        echo "Error reported trying to install dependencies, maybe try yourself with -"
	echo ">  $CMD_LINE"
	exit
    fi
    echo "deps resolved"
else
    echo "===== Assuming Dependencies are OK, try again with -r if you want them resolved."
fi

if [ "$FPCVER" != "$FPCFOUND" ]; then           # OK, not our first choice
    if [ "$FPCVER2" != "$FPCFOUND" ]; then      # and not our second (actually prefered) choice.
        echo "===== SORRY, no suitable FPC found, exiting (found = $FPCFOUND )"
        exit;
    else
        FPCVER="$FPCVER2"
    fi
fi    

echo "----- OK, we have FPC $FPCVER in PATH"

# --------- Lazarus Config Dir -------------

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
    if [ ! -e "$HOME/Downloads/""$LAZZIPNAME" ]; then     # sad, its not there either
        echo "----- Lazarus file not present at $HOME/Downloads/""$LAZZIPNAME"
	if [ "$DOWNLOAD" == "true" ]; then
	    echo "----- We will try to download $LAZDOWNURL"
            cd "$HOME/Downloads"
            wget "$LAZDOWNURL"
            if [ ! -e "$HOME/Downloads/""$LAZZIPNAME" ]; then     # still not there ?
               echo "Sorry, cannot download $LAZDOWNURL"
               echo "Downloading Disabled"
               exit
	    fi
	else 
	    echo "----- Please put $LAZZIPNAME file in Downloads or use -d"
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
echo "----- Will install into $LAZROOTDIR/$LAZFINALNAME"

cd "$LAZROOTDIR"

if [ -d "$LAZFINALNAME" ]; then
    if [ "$LAZFINALNAME" == "" ]; then         # Just a safety measure.
        echo "ERROR !!! LAZFINALNAME is empty and I was about to rm -Rf it !"
        exit
    fi
    echo "----- OK, will remove existing Lazarus install in $LAZROOTDIR/$LAZFINALNAME"
 	read -p "Do you wish to proceed ? y/n ?" yesno
    if [ ! "$yesno" == "y" ]; then 
    	echo "Exiting at your request"
    	exit
    fi   
    rm -Rf "$LAZFINALNAME"
fi


unzip -q "$LAZZIPPATH/""$LAZZIPNAME"

if [ "$MVLAZDIR" == "true" ]; then             # An ugly lazarus-lazarus name issue
	# echo "===== Going to mv from $LAZZIPNAME to $LAZFINALNAME (less the .zip)"
	mv `basename -s .zip "$LAZZIPNAME"` "$LAZFINALNAME"       # with main or fixes not needed
fi

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
	echo "----- Creating $HOME/bin/lazarus.bash"
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
fi                 # end of if NOT MACOS


echo "----- Building in $LAZROOTDIR/$LAZFINALNAME, FPCVER is $FPCVER, $LAZWIDGET"
echo "===== This will take a few minutes ...."

#if [ "$LAZDEBUG" == "true" ]; then          # Lazarus is built debug mode by default
#	make "DEBUG=1" "clean" "LCL_PLATFORM=$LAZWIDGET" "bigide" > build.log
#else
	make "clean" "LCL_PLATFORM=$LAZWIDGET" "bigide" > build.log
#fi

tail build.log
echo "----------------------------------------------------------"
echo "To see compile log, type \"cat $PWD/build.log\""
echo "To start lazarus, use menu or do following -"
echo "   cd $PWD; ./lazarus <enter>"

