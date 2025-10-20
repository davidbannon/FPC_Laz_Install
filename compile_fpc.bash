#!/bin/bash

# Small script to install FPC from source. Assumes an existing FPC322 is available.
# Assumes there is a zip of source in ~/Downloads
# Warning, this is NOT a very smart script ! Note carefull, not flexible !
# 
# The resulting compiler should be called using its fpc.bash to ensure it uses the
# correct config. Or an appropriate PATH set.
#
# On the Mac, we also build and install an aarch64 cross compiler.

# DRB, June 2024 - new code not extensivly tested on Linux yet, should be OK. x86 needs work, added RasPi 64
# Oct 2025 - allow for fact that the source-release_3_2_4_rc1.zip delivers fpc-3.2.3

# We put source into a dir named so we know its history (baseed on zip file name) but 
# we also make a symlink to that dir with just official version, ie fpc-3.2.4

VERSION="FPC324rc1"               # allowed are FPC323 (fixes), FPC322, FPC324rc1 and FPC331 (ie main)
# BASEDIR="$HOME/bin/FPC-esp32"        # specific versions below this, add something here for "specials"
BASEDIR="$HOME/bin/FPC"                # Thats my default
FPC_NUM=""                        # ver number it thinks itself is. Not necessarily part of file name !
# CROSS="riscv32-freertos"        # normally blank, we know about riscv32-freertos
CPU=""                            # leave empty to probe OS, set to arm to force 32bit ARM on 64bit hardware
MACEXTRA=""                       # empty unless we are on a Mac
ZIPDIR=`pwd`					  # if not there, we will look in ~/Downloads

case "$VERSION" in
    "FPC322")
        FPC_NUM="3.2.2"
        FPC_ZIP="source-release_3_2_2"    # Name of a zip file we expect to find in Downloads    
    ;;
    "FPC323")
        FPC_NUM="3.2.3"
	    FPC_ZIP="source-fixes_3_2"    # we expect to find this in ~/Downloads
	;;
	"FPC331")
	    FPC_NUM="3.3.1"
	    FPC_ZIP="source-main"
	;;
	"FPC324rc1")
	    FPC_ZIP="source-release_3_2_4_rc1"
	    FPC_NUM="3.2.3"
	;;
esac    
if [ "$FPC_NUM" == "" ]; then
    echo "Error, invalid VERSION provided : $VERSION"
    exit
fi

# ------------ OK, what system are we on then ?  ----------------------------
# uname -m may return x86_64, i686, aarch64 (probably raspi)

if [ "$CPU" == "" ]; then
    CPU=`uname -m`
fi
case "$CPU" in 
    "x86_64")                 # Maybe Linux or Mac
        COMPILER="ppcx64"
        TARGET="x86_64-linux"
    ;;
    "i686")                   # 32 bit, Linux but other tags possible ...
        COMPILER="ppc386"
        TARGET="i386-linux"
    ;;
    "aarch64")                # 64bit RasPi (note, don't support Apple Silicon here)
        COMPILER="ppca64"
#        BASEDIR="$HOME/ExtDrv/64bit/FPC"    # this is on a USB key to get i/o stuff off SDCard
        BASEDIR="$HOME/ExtDrv/FPC"           # the symlink, ExtDrv, should include eg 64bit PLEASE !
        TARGET="aarch64-linux"           # check this Davo
    ;;
    "arm")
        COMPILER="ppcarm"
        BASEDIR="$HOME/ExtDrv/FPC"
        TARGET="arm-linux"
    ;;
esac


# if [ "$unamestr" == "Linux" ]; then    # eg Linux, if not Linux we assume MacOS ??
if [ $(uname) == "Linux" ]; then
    OS="linux"
    MACEXTRA=""
else
    OS="MacOS"
    MACEXTRA=" OPT=\"-XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk\" "
fi

FPC_VER="fpc-""$FPC_NUM"
SRC_DIR="$BASEDIR"/SRC/"$FPC_VER"
FPC_DIR="$BASEDIR"/"$FPC_VER"
#UNITDIR="$FPC_DIR"/units/x86_64-linux
UNITDIR="$FPC_DIR"/units/"$CPU"-"$OS"




function InstallSRC {
    mkdir -p "$FPC_DIR"
    # mkdir -p "$SRC_DIR"
    mkdir -p "$BASEDIR"/SRC
    cd "$BASEDIR"/SRC
	if [ -f "$ZIPDIR/$FPC_ZIP".zip ]; then
		ZIPFILE="$ZIPDIR/$FPC_ZIP".zip
	else
		ZIPFILE="$HOME/Downloads/$FPC_ZIP".zip
	fi
    # unzip ~/Downloads/"$FPC_ZIP".zip  > zip.log
	unzip "$ZIPFILE" > zip.log     
    # unzip ~/Kits/FPC/"$FPC_ZIP".zip  > zip.log   
    echo "----- Unzipped"
    ln -s "$FPC_ZIP" "$FPC_VER"
    cd "$FPC_VER"
    if [ -e "Makefile" ]; then
	    echo "===== SRC Makefile present, continuing ====="
    else
	    echo "===== ERROR, there should be a Makefile here at $PWD ====="
    	ls -l
    	exit
    fi
}

function BuildSRC {
    touch build.log
    # make clean all OPT="-XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/"
    if [ "$OS" == "MacOS" ]; then
    	make all "$MACEXTRA"     > build.log
    else
	    make all > build.log
    fi  
    # make all     > build.log                 
    # make install INSTALL_PREFIX="$FPC_DIR" INSTALL_UNITDIR="$UNITDIR"
    make install INSTALL_PREFIX="$FPC_DIR"  > install.log
    if [ -e "compiler/""$COMPILER" ]; then
	    echo "===== Compiler  present, continuing ====="
	    cp "compiler/$COMPILER" "$FPC_DIR"/bin/"$COMPILER"
    else
	    echo "===== ERROR, there should be compiler/$COMPILER here at $PWD ====="
	    ls -l compiler
	    exit
    fi
    # on a 32bit intel, thats ppc386, ppca64 on a Pi64, ppcarm on a 32bit armhf
    # next few lines so that the default fpc.cfg works
}

function FinishInstall {   
    cd "$FPC_DIR"
    ln -s lib/fpc/"$FPC_NUM"/units   # so -Fu in config can find rtl
    cd lib
    ln -s fpc/"$FPC_NUM"/units/"$TARGET"   # cos thats where -Fl points
    cd ../.
    mkdir -p etc 
    bin/fpcmkcfg -d basepath="$BASEDIR/fpc-""\$fpcversion" > etc/fpc.cfg 
    
    if [ -e "etc/fpc.cfg" ]; then
	    echo "===== fpc.cfg  present, continuing ====="
    else
	    echo "===== ERROR, there should be etc/fpc.cfg here at $PWD ====="
	    ls -la etc/.
	    exit
    fi
    cd bin
    if [ "$OS" == "MacOS" ]; then
        ln -s ../lib/fpc/"$FPC_NUM"/ppcrossa64 ppca64
    fi
    # this might be useful if you have other fpc.cfg that might get found before the
    # one you want to use.
    echo "#!/bin/sh" > fpc.bash      
    echo "# A script that ensure when we start fpc here, it ignores all other fpc.cfg" >> fpc.bash
    echo "$FPC_DIR""/bin/fpc -n @$FPC_DIR/etc/fpc.cfg \"\$@\"" >> fpc.bash
    chmod u+x fpc.bash
}

# OK, it all starts here -----------------------

echo "MACEXTRA is $MACEXTRA and OS is $OS and TARGET=$TARGET"
echo "Installing into FPC_DIR=$FPC_DIR and compiler name is $COMPILER"
echo "BASEDIR=$BASEDIR and FPC_NUM=$FPC_NUM"

echo "----- Installing SRC"
InstallSRC
echo "----- Building SRC"
BuildSRC
echo "----- Installing Binaries"
FinishInstall

# cat ../etc/fpc.cfg

if [ "$OS" == "MacOS" ]; then
    cd "$SRC_DIR"
    make clean crossinstall  FPC="$FPC_DIR"/bin/ppcx64  OS_TARGET=darwin CPU_TARGET=aarch64 INSTALL_PREFIX="$FPC_DIR" "$MACEXTRA" CPU_SOURCE=x86_64 -j4 > cross.log
    cd "$FPC_DIR"/lib
    ln -s fpc/"$FPC_NUM"/units/aarch64-darwin   # cos thats where -Fl points
    # We must end up so the -Fl in in cfg file, eg
    # -Fl/Users/dbannon/bin/FPC/fpc-$fpcversion/lib/$FPCTARGET
    # can fine both -
    # /Users/dbannon/bin/FPC/fpc-3.2.4/lib/x86_64-darwin
    # /Users/dbannon/bin/FPC/fpc-3.2.4/lib/aarch64-darwin
    
fi

echo "A (possibly) ready to use fpc.cfg has been put in $FPC_DIR/etc - mv to $HOME"

# ==============================  This is for cross compiler to esp32-c3 ===============

if [ "$CROSS" == "riscv32-freertos" ]; then
    echo "======= Making the esp32-c3 cross compiler"
    cd "$SRC_DIR"
    make FPC="$FPC_DIR"/bin/fpc.bash  CPU_TARGET=riscv32 OS_TARGET=freertos  SUBARCH=rv32imc  INSTALL_PREFIX="$FPC_DIR"  "CROSSOPT=-XPriscv32-esp-elf- -Cfsoft" all -j > cross.log
    if [ "$?" != 0 ]; then 
        echo "Building esp32 cross compiler failed. See log"
        exit
    fi
    make crossinstall FPC="$FPC_DIR"/bin/fpc.bash  CPU_TARGET=riscv32 OS_TARGET=freertos  SUBARCH=rv32imc  INSTALL_PREFIX="$FPC_DIR"  > crossinstall.log
    if [ "$?" != 0 ]; then 
        echo "Installing esp32 cross compiler failed. See log"
        exit
    fi    
    cp compiler/ppcrossrv32 ../../fpc-3.3.1/bin/.
fi


echo "======================= Done ================="
echo "check the config, especially eg  -Fl/usr/lib/gcc/x86_64-linux-gnu.... "

