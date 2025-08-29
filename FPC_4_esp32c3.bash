#!/usr/bin/bash
set -e
# a short script to build & install a main based fpc compiler 
# and then go on to build compiler for ESP32-C3 with one
# of several esp-idf versions.

# You MUST use the appropriate esp-idf tool to setup PATH. ie
# $> source ~/esp448/esp-idf/export.sh

# David Bannon, 29th August 2024

# IMPORTANT ! if your FPC322 is found using $PATH,
# comment out next line. Otherwise set it to where your FPC322 is.
FPC322_PATH="$HOME/bin/FPC/fpc-3.2.2"   # Thats where my FPC322 is.

FPC_VER="3.3.1"             # thats main at present
FPC_DIR=`pwd`               # we install the new stuff in current dir.
                            # assume user understands they need wrte permission

if [ -d "fpc-$FPC_VER" ]; then
	EXISTING="true";
fi
if [ -d source-main ]; then
	EXISTING="true";
fi
if [ "$EXISTING" == "true" ]; then
	echo "----------------------------";
	echo "Either fpc-$FPC_VER or source-main (or both) exist."
	echo "If you proceed, that install will be overwritten !!";
	read -p "Do you wish to proceed ? y/n ?" yesno
    if [ ! "$yesno" == "y" ]; then
    	echo "Exiting at your request"
    	exit
    fi
fi
if ! [ -x "$(command -v riscv32-esp-elf-as)" ]; then
	echo "Nope, cannot find riscv32-esp-elf-as, have you installed esp-idf and set PATH ?";
fi

echo "Installing into $FPC_DIR"
rm -Rf fpc-"$FPC_VER"              
rm -Rf source-main
ls -l
echo "--------------------------------------------------"  > log.txt
echo "           U N Z I P P I N G    S O U R C E"         >> log.txt
echo "--------------------------------------------------"  >> log.txt
unzip ~/Downloads/source-main.zip > log.txt                >> log.txt
cd source-main
if ! [ "$FPC322_PATH" == "" ]; then
	# we must use fpc322 to build initial x86-64 compiler.
	OLD_PATH="$PATH"
	PATH="$FPC322_PATH"/bin:"$PATH"
	echo $PATH
fi
echo "Starting std compiler build" 
echo "--------------------------------------------------"  >> log.txt
echo "           C L E A N I N G   S O U R C E"            >> log.txt
echo "--------------------------------------------------"  >> log.txt
make clean                                                 >> log.txt
echo "--------------------------------------------------"  >> log.txt
echo "           S T A R T I N G    B U I L D"             >> log.txt
echo "--------------------------------------------------"  >> log.txt
make all                                                   >> log.txt
echo "--------------------------------------------------"  >> log.txt
echo "           S T A R T I N G   I N S T A L L "         >> log.txt
echo "--------------------------------------------------"  >> log.txt
make install INSTALL_PREFIX=/home/dbannon/bin/FPC/fpc-"$FPC_VER" >> log.txt
ls -l compiler/ppcx64 
cp compiler/ppcx64 "$FPC_DIR"/fpc-"$FPC_VER"/bin/.
if ! [ "$FPC322_PATH" == "" ]; then
	# set a new PATH with the new compiler at start.
	PATH="$FPC_DIR"/fpc-"$FPC_VER"/bin:"$OLD_PATH"
	echo "$PATH"
else
	PATH="$FPC_DIR"/fpc-"$FPC_VER"/bin:"$PATH"
fi
echo "--------------------------------------------------"  >> log.txt
echo "      S T A R T I N G   C R O S S   I N S T A L L "  >> log.txt
echo "--------------------------------------------------"  >> log.txt
# following line depends on the ESP path settings, hopefull restored.
make crossinstall FPC="$FPC_DIR"/fpc-"$FPC_VER"/bin/fpc  CPU_TARGET=riscv32 OS_TARGET=freertos  SUBARCH=rv32imc  "CROSSOPT=-XPriscv32-esp-elf-  -Cfsoft"  INSTALL_PREFIX="$FPC_DIR"/fpc-"$FPC_VER" >> log.txt
cp compiler/ppcrossrv32 "$FPC_DIR"/fpc-"$FPC_VER"/bin/.
ls -l "$FPC_DIR"/fpc-"$FPC_VER"/bin/ppcrossrv32
cd "$FPC_DIR"/fpc-"$FPC_VER"
ln -s lib/fpc/"$FPC_VER"/units
echo "------- Compilers ------"
ls -l bin/ppc*
echo "------- Units ----------"
ls -l units/.
echo "done !"

