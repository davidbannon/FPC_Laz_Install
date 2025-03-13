FPC-Lazarus Installer
===========



These are some quite idocyntric tools for my own use **on Linux**. But you are welcome to use them, if its eases your journey into the Free Pascal Compiler and Lazarus, that would be good. Supported, in one way or another is

* Linux x86_64 - 64bit

* Linux i686 - 32bit

* Linux armhf - 32bit (eg Raspberry Pi)  (Lazarus build only, not FPC)

* Linux ARM64, aarch64 - 64bit (eg Raspberry Pi)



With what is here, you can install just the compiler you want to use and use it to build and setup Lazarus with just two scripts.  Its used, by me, on a variety of distros. And, its very easy to discard when you are done. The tarballs are initially built on systems running a version of **glibc earlier than 2.34** so should be usable on all systems you are likely to come across.



In the Releases section here, right of screen, you will find tar balls for a binary install of FPC (along with source used to build it) -





* fpc-3-2-0.tgz  -   FPC 3.2.0 for x86_64

* fpc-3-2-2.tgz  -   FPC 3.2.2 for x86_64

* fpc-3-2-2_32.tgz  -  FPC 3.2.2 for i686, ie 32bit intel

* fpc-3-2-2_armhf.tgz  - FPC 3.2.2 for armhf, ie 32bit Raspberry Pi etc

* fpc-3-2-4rc1.tgz  -  FPC 3.2.4-brance for x86_64 (ie, sort of 3.2.4rc1 ?)

* fpc-3-2-4rc1_arm64.tgz  -  FPC 3.2.4rc1 for aarch64, 64bit Raspberry Pi

* fpc-3-2-4rc1_armhf.tgz  -  FPC 3.2.4rc1 for armhf, 32bit Raspberry Pi



* scripts.zip -   a small zip containg the two scripts described below.



Note : both scripts respond to -h with a short held screen.



**Quick Start FPC**
--------
(eg x86_64) Download from Releases (my recommendation at the moment)  fpc-3-2-4rc1.tgz file and the scripts.zip. Unzip the scripts (not the tgz) all into your Downloads directory. eg

    $> cd ~/Downloads
    $> wget https://github.com/davidbannon/FPC_Laz_Install/releases/download/v2.0/scripts.zip
    $> unzip scripts.zip
    $> wget https://github.com/davidbannon/FPC_Laz_Install/releases/download/v2.0/fpc-3-2-4rc1.tgz


Type  (-f says use 324rc1 file; -d do defaults, -a append path to .rcbash; -r says resolve dependencies) -

    $> bash ./fpc-tar.bash -f 324rc1 -a -r <enter>
You will be asked to give the root password to install necessary dependencies and then advised to run -

    $> source ~/.bashrc <enter>
to set a path to your new compiler. Its in $HOME/bin/FPC/fpc-3.2.4





**ARM ?** because, on ARM, I usually install the compiler and Lazarus on a seperate disk to avoid problems with the SDCard, on arm, you MUST specify where to install to with the -i option. For example, if you are happy putting the compiler in $HOME/bin (ie on the SDCard) use, perhaps -



    $> bash ./fpc-tar.bash -f 324rc1 -a -r -i $HOME/bin/FPC<enter>


note : while there are tarballs for armhf the script will not, yet install them. In my my case, when I run a 32bit Arm OS its on 64bit hardware and my script does not understand. But untaring it all into an appropropiate place manually is not that hard,





**Quick Start Lazarus**
--------
If you have an appropriate compiler installed, perhaps above, perhaps some other way, you can use the second script from scripts.zip to (if necessary) download, compile and configure Lazarus. -

>$  `bash ./make-lazarus.bash -r -f 3_8  -d <enter>`

In this example, we use -r to resolve dependencies, -f 3_8 to request Lazarus rlease 3.8, -d telling the script to download Lazarus Source from the official gitlab repository. Again, you will have to give the root password to install dependencies.

In the Lazarus install, you can choose Qt5 with -w qt5, newer systems may also handle Qt6 in the same way.



If you already have the Lazarus source downloaded, as a zip file, if it is in your Downloads directory, the script will find and use it. Start Lazarus from your menu or use the script, $HOME/bin/lazarus.bash



**Generally**
--------
In both cases, if you know the dependencies are OK, leave out the -r. You can install the dependencies yourself before you start, thus avoiding typing in the root password in my script.



Both scripts have some basic help, use -h .



Both scripts will do some default action with no options, it might be right for you, possibly not.





**Background**
--------
I do a lot of testing of my own code on multiple VMs and endlessly run out of disk space. So, I delete a VM, and, inevitably, shortly after, need it again, often with an install of FPC and Lazarus.  As we wait for the next release of FPC, that install usually means building a (slightly patched) FPC 3.2.2 and FPC 3.2.4rc1. And then building Lazarus, (my preference) again from source. To build FPC3.2.2 you need FPC3.2.0, to build 3.2.4rc1, you need 3.2.2. Overall, time and, importantly, disk space consuming.



My solution is to have a prebuilt set of everything needed for FPC 3.2.0, 3.2.2 and 3.2.4rc1 stored, each in their own tarball and a script to put that content back where it needs to be and setup PATH and config. And another script that will build a Lazarus just as easily. I always build Lazarus from source, great test that FPC is setup correctly.



Everything ends up in $HOME/bin/FPC or $HOME/bin/Lazarus and is easily deleted when unneeded. (And possibly $HOME/.local/share/applications/lazarus.desktop and $HOME/bin/lazarus.bash).



**Free Pascal Compiler**
--------
In the releases section, you will find several FPC<version>.tgz files, I suggest you want fpc-3-2-4rc1.tgz (on x86_64), and a small zip containing two scripts. Download a fpc tarball (do not untar it, the script will do that fo you) and the zip, unzip it and end up with these files -



fpc-3-2-4rc1.tgz - that contains two directory trees, one for compiler, one for source.

fpc-tar.bash - a script to untar the above and setup the result ready for use.

make-lazarus.bash - a script install Lazarus, we'll look at this later.



To "install" FPC, you would do this in the directory with those files. First, look at the options -



    $> bash ./fpc-tar.bash -h <enter>


Then run it eg (assuming you are on a deb based system and have the fpc-3-2-4rc1.tgz file present -



    $> bash ./fpc-tar.bash -f 324rc1 -a -r <enter>


Because you provided **-p deb** it will try to resolve the FPC dependencies, works with Debian, RPM or pacman systems. You will be asked for the root password to install those dependencies. If you know dependencies are OK (perhaps you have another FPC install?), leave this section out.



The **-a** says append necessary lines to your .bashrc to set a path to the new compiler. You should only do that once, silly to keep adding lines here. If you run the script again, and you can, leave off the -a.



The **-f  324rc1** is a reference to the tgz file. If you want FPC 3.2.2 instead, you could use '3.2.2' or '322. FPC 3.2.0 requires 320 or 3.2.0.



This install only takes a few minutes, mostly while dependencies are loaded or at least checked. The compiler is installed in your home directory, $HOME/bin/FPC/fpc-<version>. You can have all three versions installed, switch between then by altering your PATH.



After the install is finished, you need to use those two additional lines in your .bashrc so the compiler is on your path -



    $> source ~/.bashrc <enter>


Test your compiler with this -



    $> fpc -vh <enter>


You will get an error message because you did not provide something to compile but you will see the compiler version and which fpc.cfg its using. Make no mistake, that .cfg file is IMPORTANT!



**Lazarus**
--------
OK, so, now you want to install Lazarus with your shiny new compiler ?



Back in the directory with those three files, one was called make-lazarus.bash. It will, if necessary, download the Lazarus Source Code, unzip it into your home directory, compile it and do all the necessary setup things. And, of course, it will also, if necessary, resolve the dependencies.



Again, look at the options -



    $> bash ./make-lazarus.bash -h <enter>


then run it, eg, assuming, this time, you are on a rpm based system and want to use the current lazarus 3.6 -



    $> bash ./make-lazarus.bas -p rpm -f 3_8  -d <enter>


Again, **-r** says you want dependencies resolve. Again, you will be asked for the root password to install those dependencies.



**-f 3_6** says look for the Lazarus download, lazarus-lazarus_3_6.zip (that how it comes from gitlab). If its in the current working directory or in your ~/Downloads directory, off we go !  You can ask for Lazarus '3_6', '3_8',  'main' or 'fixes_4', that are git tag or branch names.



The **-d** says, if the above step did not find a previously downloaded file, go and get it. Its stays in the current directory so you can reuse it if you wan to run this installer again. The downloaded file must be in zip format and, if necessary, is downloaded from the official FPC/Website.



By default, a gtk2 version of Lazarus is made, "**-w qt5**" will make Qt5 one, recent systems make even make a Qt6 one **"-w qt6**".



The build takes a fair bit longer than FPC because its actually compiling the source code this time. But probably not long enough for you to do much (see https://xkcd.com/303/) .

You might be asked if you want a Desktop file created, you do, and a script to start Lazarus (in ~/bin), you do.



When its finished, you can start Lazarus, maybe from your main menu system (although some desktops require a logoff/on before it appears) or run the script, ~/bin/lazarus.bash .



You can install as many different versions of Lazarus as you like this way, each in its own directory down in $HOME/bin/Lazarus/.



**Some notes about particular systems -**
--------


**Gnome and recent KDE** systems, using Wayland and Qt5 or Qt6 - unless you start Lazarus from the script, ~/bin/lazarus.bash or from the menu (that uses the same script), you will use Wayland and you really don't want to. So, if you have built a Qt5 or Qt6 one on a system that uses Wayland, don't start lazarus directly with the suggested "cd ~/bin/Lazarus/lazarus_3_6; ./lazarus", you will be unhappy with the layout.



**Mageia** - strange package names. Requires lib64x11-devel. Does not have Qt6, its repo Qt5Pas is way out of date.  Manually install libQt5Pas-dev before running the make-lazarus script and run it without the -p. Or just make the gtk2 version.



**Artix (Arch based)**. Has a viable qt5pas, does not need any (gtk2) dependencies to build Lazarus. All worked well but colour theme totally unusable. Black, even the white bits are black. Menu not refreshed until re-login. Very strange.



**PCLinuxOS** - no, it will not work ! The poor OS does not know if its debian or rpm based.




