# Axmud v2.0.0 installer script for MS Windows
#
# Copyright (C) 2011-2024 A S Lewis
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#
#
# Build instructions:
#   - Note that, as of 2020, the sisyphusion repository no longer exists, so
#       there is no longer any known method for running Axmud with ActivePerl or
#       with Strawberry Perl. Axmud MUST BE INSTALLED USING MSYS2.
#
#   - Download and install NSIS from
#
#       http://nsis.sourceforge.io/Download/
#
#   - If you don't have a suitable editor (Notepad is not good enough), download
#       and install one, e.g. Notepad++ from
#
#       https://notepad-plus-plus.org/
#
#   - Download MSYS2 from
#
#       https://www.msys2.org/
#
#   - Install MSYS2, but do not use the default installation folder (C:\msys64);
#       instead, create a folder with any name in the root folder, and install
#       it there (e.g. C:\foobar\msys64). Replace 'foobar' with any folder name
#       that doesn't already exist
#
#   - Open the mingw64 terminal (C:\foobar\msys64\mingw64.exe), and type these
#       commands, restarting the terminal after the first command if prompted;
#
#       pacman -Syu
#       pacman -Su
#
#   - Close the mingw64 terminal
#
#   - Open the msys2 terminal (C:\foobar\msys64\msys2.exe), and type these
#       commands:
#
#       pacman -S gcc base-devel
#       pacman -S --needed --noconfirm mingw-w64-x86_64-perl
#
#   - Close the msys2 terminal
#
#   - Navigate to the folder containing the 'pl2bat' files,
#       C:\foobar\msys64\mingw64\bin\core_perl
#
#   - Copy the files 'pl2bat' and 'pl2bat.bat' into the folder above, i.e.
#       C:\foobar\msys64\mingw64\bin
#
#   - Open the mingw64 terminal again (C:\foobar\msys64\mingw64.exe), and type
#       these commands
#
#       wget https://github.com/kerenok/perl-Gtk3-windows-installer/archive/master.zip
#       pacman -S unzip
#       unzip master.zip
#       cd perl*
#
#   - Navigate to the folder
#       C:\foobar\msys64\home\YOURNAME\perl-Gtk3-windows-installer-master, and
#       right-click the file 'install-perl-Gtk3-minw64.pl' in Notepad++
#
#   - Immediately after the following line:
#
#       install_perl_module('Gtk3');
#
#   - ...add the following line, paying careful attention to capitalisation and
#       punctuation:
#
#       install_perl_module('GooCanvas2');
#
#   - Save the file and close Notepad++
#
#   - Now, in the mingw terminal, execute that file (which will take several
#       minutes) by typing this command:
#
#       ./instsall-perl-Gtk3-mingw64.pl
#
#   - The 'Raume auf!' message confirms success
#
#   - Close the existing mingw64 terminal, open a NEW mingw64 terminal
#       (C:\foobar\msys64\mingw64.exe), and type these commands:
#
#       cpan install CPAN::DistnameInfo
#       cpan install Archive::Extract Archive::Zip File::Copy::Recursive File::HomeDir File::ShareDir JSON Math::Round Net::OpenSSH Regexp::IPv6
#       cpanm --force --build-args SHELL=cmd.exe --install-args SHELL=cmd.exe File::ShareDir::Install
#       cpanm install --force IPC::Run
#       pacman -S perl-Socket6
#
#   - Find the file C:\foobar\msys64\mingw64\lib\perl5\site_perl\5.32.1\GooCanvas2.pm (the Perl
#       version may be different than 5.32.1, in which case use that folder instead)
#
#   - Right-click the file, select Properties, and in the dialogue windo uncheck the Read-only
#       button
#
#   - Now open the file in Notepad++, and replace the 2.0 with 3.0 in this line:
#
#           version => '2.0';
#
#   - In the mingw64 terminal, type this command
#
#       pacman -S mingw-w64-x86_64-goocanvas
#
#   - Close the terminal
#
#   - The C:\foobar\msys64 folder now contains about 2.6GB of data. If you like,
#       you can use all of it (which would create an extremely large nistaller).
#       In most cases, though, you will probably want to remove everything
#       that's not necessary
#
#   - This table shows which files and folders are in the official Axmud
#       installer (which is about 140MB). Files/folders ending in * represent
#       multiple files/folders which must be retained. Everything else can be
#       deleted
#
#   - Note that version numbers will change over time; retain which version of
#       the file/folder is available
#
#       C:\foobar\msys64\dev
#
#       C:\foobar\msys64\etc
#
#       C:\foobar\msys64\home
#
#       C:\foobar\msys64\installerResources
#
#       C:\foobar\msys64\bin\core_perl
#       C:\foobar\msys64\bin\site_perl
#       C:\foobar\msys64\bin\vendor_perl
#       C:\foobar\msys64\bin\gdbus*
#       C:\foobar\msys64\bin\gdk*
#       C:\foobar\msys64\bin\gettext*
#       C:\foobar\msys64\bin\gio*
#       C:\foobar\msys64\bin\g-ir-*
#       C:\foobar\msys64\bin\glib*
#       C:\foobar\msys64\bin\gobject-query
#       C:\foobar\msys64\bin\gsettings
#       C:\foobar\msys64\bin\gspawn*
#       C:\foobar\msys64\bin\gtk*
#       C:\foobar\msys64\bin\json*
#       C:\foobar\msys64\bin\libatk-1.0-0.dll
#       C:\foobar\msys64\bin\libbrotli*
#       C:\foobar\msys64\bin\libbz2-1.dll
#       C:\foobar\msys64\bin\libcairo*
#       C:\foobar\msys64\bin\libcrypto-3-x64.dll
#       C:\foobar\msys64\bin\libdatrie-1.dll
#       C:\foobar\msys64\bin\libdeflate*
#       C:\foobar\msys64\bin\libepoxy-0.dll
#       C:\foobar\msys64\bin\libexpat-1.dll
#       C:\foobar\msys64\bin\libffi-8.dll
#       C:\foobar\msys64\bin\libfontconfig-1.dll
#       C:\foobar\msys64\bin\libfreetype-6.dll
#       C:\foobar\msys64\bin\libfribidi-0.dll
#       C:\foobar\msys64\bin\libgcc-s-seh-1.dll
#       C:\foobar\msys64\bin\libgdk-pixbuf-2.0-0.dll
#       C:\foobar\msys64\bin\libgdk-3-0.dll
#       C:\foobar\msys64\bin\libgettext*
#       C:\foobar\msys64\bin\libgif-7.dll
#       C:\foobar\msys64\bin\libgio-2.0-0.dll
#       C:\foobar\msys64\bin\libgirepository-1.0-1.dll
#       C:\foobar\msys64\bin\libglib-2.0-0.dll
#       C:\foobar\msys64\bin\libgmodule-2.0-0.dll
#       C:\foobar\msys64\bin\libgobject-2.0-0.dll
#       C:\foobar\msys64\bin\libgoocanvas-3.0-9.dll
#       C:\foobar\msys64\bin\libgraphite2.dll
#       C:\foobar\msys64\bin\libgthread-2.0-0.dll
#       C:\foobar\msys64\bin\libgtk-3-0.dll
#       C:\foobar\msys64\bin\libharfbuzz*
#       C:\foobar\msys64\bin\libiconv-2.dll
#       C:\foobar\msys64\bin\libintl-8.dll
#       C:\foobar\msys64\bin\libjpeg-8.dll
#       C:\foobar\msys64\bin\libjson-glib-1.0-0.dll
#       C:\foobar\msys64\bin\liblzma-5.dll
#       C:\foobar\msys64\bin\libncurses*
#       C:\foobar\msys64\bin\libpango*
#       C:\foobar\msys64\bin\libpcre*
#       C:\foobar\msys64\bin\libpixman-1.0.dll
#       C:\foobar\msys64\bin\libpkgconf-4.dll
#       C:\foobar\msys64\bin\lippng*
#       C:\foobar\msys64\bin\libquadmath-0.dll
#       C:\foobar\msys64\bin\libreadline8.dll
#       C:\foobar\msys64\bin\librsvg-2-2.dll
#       C:\foobar\msys64\bin\libssl-3-x64.dll
#       C:\foobar\msys64\bin\libstdc++-6.dll
#       C:\foobar\msys64\bin\libthai-0.dll
#       C:\foobar\msys64\bin\libturbojpeg.dll
#       C:\foobar\msys64\bin\libwebp*
#       C:\foobar\msys64\bin\libwinpthread-1.dll
#       C:\foobar\msys64\bin\libxml2-2.dll
#       C:\foobar\msys64\bin\mingw32-make
#       C:\foobar\msys64\bin\msg*
#       C:\foobar\msys64\bin\openssl
#       C:\foobar\msys64\bin\pango*
#       C:\foobar\msys64\bin\perl*
#       C:\foobar\msys64\bin\pkg*
#       C:\foobar\msys64\bin\pl2bat*
#       C:\foobar\msys64\bin\wperl
#       C:\foobar\msys64\bin\zlib1.dll
#
#       C:\foobar\msys64\etc\gtk-3.0
#       C:\foobar\msys64\etc\ssl
#       C:\foobar\msys64\etc\gdbinit
#
#       C:\foobar\msys64\tmp\   [Note - empty this folder]
#
#       C:\foobar\msys64\include\cairo
#       C:\foobar\msys64\include\gdiplus
#       C:\foobar\msys64\include\gdk-pixbuf-2.0
#       C:\foobar\msys64\include\gio-win32-2.0
#       C:\foobar\msys64\include\glib-2.0
#       C:\foobar\msys64\include\gobject-introspection-1.0
#       C:\foobar\msys64\include\goocanvas-3.0
#       C:\foobar\msys64\include\gtk-3.0
#       C:\foobar\msys64\include\json-glib-1.0
#       C:\foobar\msys64\include\openssl
#       C:\foobar\msys64\include\pango-1.0
#       C:\foobar\msys64\include\pkgconf
#       C:\foobar\msys64\include\readline
#
#       C:\foobar\msys64\lib\gdk-pixbuf-2.0
#       C:\foobar\msys64\lib\gettext
#       C:\foobar\msys64\lib\gio
#       C:\foobar\msys64\lib\girepository-1.0
#       C:\foobar\msys64\lib\glib-2.0
#       C:\foobar\msys64\lib\gobject-introspection
#       C:\foobar\msys64\lib\gtk-3.0
#       C:\foobar\msys64\lib\perl5
#       C:\foobar\msys64\lib\pkgconfig
#       C:\foobar\msys64\lib\terminfo
#       C:\foobar\msys64\lib\thread2.8.8
#       C:\foobar\msys64\lib\tk8.6
#
#       C:\foobar\msys64\share\gettext*
#       C:\foobar\msys64\share\gir-1.0
#       C:\foobar\msys64\share\glib-2.0
#       C:\foobar\msys64\share\gobject-introspection-1.0
#       C:\foobar\msys64\share\gtk-3.0
#       C:\foobar\msys64\share\pkgconfig
#       C:\foobar\msys64\share\terminfo
#       C:\foobar\msys64\share\themes
#       C:\foobar\msys64\share\thumbnailers
#
#       C:\foobar\msys64\usr\bin\core_perl
#       C:\foobar\msys64\usr\bin\site_perl
#       C:\foobar\msys64\usr\bin\vendor_perl
#       C:\foobar\msys64\usr\bin\bash
#       C:\foobar\msys64\usr\bin\chmod
#       C:\foobar\msys64\usr\bin\cut
#       C:\foobar\msys64\usr\bin\cyg*
#       C:\foobar\msys64\usr\bin\dir
#       C:\foobar\msys64\usr\bin\env
#       C:\foobar\msys64\usr\bin\find
#       C:\foobar\msys64\usr\bin\findfs
#       C:\foobar\msys64\usr\bin\gawk*
#       C:\foobar\msys64\usr\bin\getent
#       C:\foobar\msys64\usr\bin\gettext*
#       C:\foobar\msys64\usr\bin\gpg*
#       C:\foobar\msys64\usr\bin\grep
#       C:\foobar\msys64\usr\bin\hostid
#       C:\foobar\msys64\usr\bin\hostname
#       C:\foobar\msys64\usr\bin\iconv
#       C:\foobar\msys64\usr\bin\id
#       C:\foobar\msys64\usr\bin\ln
#       C:\foobar\msys64\usr\bin\locale
#       C:\foobar\msys64\usr\bin\ls
#       C:\foobar\msys64\usr\bin\make*
#       C:\foobar\msys64\usr\bin\mintty
#       C:\foobar\msys64\usr\bin\mkdir
#       C:\foobar\msys64\usr\bin\msys-2.0.dll
#       C:\foobar\msys64\usr\bin\msys-argp-0.dll
#       C:\foobar\msys64\usr\bin\msys-assuan-0.dll
#       C:\foobar\msys64\usr\bin\msys-bz2-1.dll
#       C:\foobar\msys64\usr\bin\msys-gcc_s-seh-1.dll
#       C:\foobar\msys64\usr\bin\msys-gcrypt-20.dll
#       C:\foobar\msys64\usr\bin\msys-gdbm*
#       C:\foobar\msys64\usr\bin\msys-gmp-10.dll
#       C:\foobar\msys64\usr\bin\msys-gpg-error-0.dll
#       C:\foobar\msys64\usr\bin\msys-gpgme-11.dll
#       C:\foobar\msys64\usr\bin\msys-gpgmepp-6.dll
#       C:\foobar\msys64\usr\bin\msys-iconv-2.dll
#       C:\foobar\msys64\usr\bin\msys-intl-8.dll
#       C:\foobar\msys64\usr\bin\msys-mpfr-6.dll
#       C:\foobar\msys64\usr\bin\msys-ncurses++w6.dll
#       C:\foobar\msys64\usr\bin\msys-ncursesw6.dll
#       C:\foobar\msys64\usr\bin\msys-pcre-1.dll
#       C:\foobar\msys64\usr\bin\msys-pcre2-8-0.dll
#       C:\foobar\msys64\usr\bin\msys-perl5_36.dll
#       C:\foobar\msys64\usr\bin\msys-pkgconfig-4.dll
#       C:\foobar\msys64\usr\bin\msys-readline8.dll
#       C:\foobar\msys64\usr\bin\msys-sqlite3-0.dll
#       C:\foobar\msys64\usr\bin\msys-ssh2-1.dll
#       C:\foobar\msys64\usr\bin\msys-ssl-3.dll
#       C:\foobar\msys64\usr\bin\msys-stdc++06.dll
#       C:\foobar\msys64\usr\bin\msys-z.dll
#       C:\foobar\msys64\usr\bin\mv
#       C:\foobar\msys64\usr\bin\openssl
#       C:\foobar\msys64\usr\bin\perl*
#       C:\foobar\msys64\usr\bin\rm
#       C:\foobar\msys64\usr\bin\rmdir
#       C:\foobar\msys64\usr\bin\sed
#       C:\foobar\msys64\usr\bin\telnet
#       C:\foobar\msys64\usr\bin\test
#       C:\foobar\msys64\usr\bin\tzset
#       C:\foobar\msys64\usr\bin\uname
#       C:\foobar\msys64\usr\bin\vercmp
#       C:\foobar\msys64\usr\bin\wc
#       C:\foobar\msys64\usr\bin\which
#
#       C:\foobar\msys64\usr\lib\gettext
#       C:\foobar\msys64\usr\lib\openssl
#       C:\foobar\msys64\usr\lib\perl5
#       C:\foobar\msys64\usr\lib\pkgconfig
#       C:\foobar\msys64\usr\lib\terminfo
#
#       C:\foobar\msys64\usr\share\cygwin
#       C:\foobar\msys64\usr\share\makepkg*
#       C:\foobar\msys64\usr\share\mintty
#       C:\foobar\msys64\usr\share\Msys
#       C:\foobar\msys64\usr\share\pacman
#       C:\foobar\msys64\usr\share\perl5
#       C:\foobar\msys64\usr\share\pkgconfig
#       C:\foobar\msys64\usr\share\terminfo
#
#       C:\foobar\msys64\usr\ssl\
#
#       C:\foobar\msys64\mingw64*
#       C:\foobar\msys64\msys2*
#
#   - Download the installer for the eSpeak engine from
#
#       http://espeak.sourceforge.io/
#
#   - Copy the installer to C:\foobar, and rename it to 'setup_espeak'
#
#   - Download both the 32bit and 64bit installers for the espeak-ng engine from
#
#       https://github.com/espeak-ng/espeak-ng/releases
#
#   - Copy the installers to C:\foobar, and rename them to 'espeak-ng-X64.msi'
#       and 'espeak-ng-X86.msi' (noting the capital X)
#
#   - Download the build for the Festival engine (e.g. 'festival-2.5-win.7z')
#       from
#
#       https://sourceforge.net/projects/e-guidedog/files/related-third-party-software/0.3/
#
#   - Extract the .7z file into C:\foobar, and rename the extracted folder as
#       'festival' (must be lower case)
#
#   - Download the Axmud source code (the file ending _windows.tar.gz) from
#       https://sourceforge.io/projects/axmud/
#
#   - Copy the extracted folder to C:\foobar\msys64\home\YOURNAME, creating a
#       folder called (for example) C:\foobar\msys64\home\YOURNAME\axmud
#
#   - Find the file C:\foobar\msys64\home\YOURNAME\axmud\nsis\ipc_run\Run.txt
#       and copy it to C:\foobar\msys64\mingw64\lib\perl5\site_perl\5.32.1\IPC
#       (the Perl version may be different than 5.32.1, in which case use that
#       folder instead)
#
#   - In that folder, remove the existing Run.pm file, and then rename the
#       Run.txt to Run.pm (using Notepad++ if that's convenient)
#
#   - In the Windows Start menu, type 'cmd', then right-click 'Command prompt'
#       and select 'Run as administrator'
#
#   - In the new terminal window, type these commands
#
#       cd C:\foobar\msys64\mingw64\bin
#       mklink make mingw32-make.exe
#       exit
#
#   - Open the mingw64 terminal again (C:\foobar\msys64\mingw64.exe), and type
#       these commands
#
#       cd axmud
#       perl Makefile.PL
#       make
#       make install
#
#   - If you like you can now remove these files/folders:
#
#       C:\foobar\msys64\home\YOURNAME\axmud\blib
#       C:\foobar\msys64\home\YOURNAME\axmud\.cpanm
#       C:\foobar\msys64\home\YOURNAME\axmud\.cpan-w64
#
#   - In the folder C:\foobar\msys64\home\YOURNAME\axmud\nsis, find the
#       following files, and MOVE them into the folder above (i.e. into
#       C:\foobar\msys64\home\YOURNAME\axmud)
#
#           axmud_mswin.sh
#           baxmud_mswin.sh
#           blindaxmud.bat
#           runaxmud.bat
#
#   - Now COPY all of the remaining files (not folders) from
#       C:\foobar\msys64\home\YOURNAME\axmud\nsis to C:\foobar
#   - Right-click C:\foobar\axmud_install.nsi, and select 'Compile NSIS script'
#   - After a few minutes, the .exe installer appears in the same folder

# Header files
# -------------------------------

    !include "MUI2.nsh"
    !include "Sections.nsh"
    !include "x64.nsh"

# General
# -------------------------------

    ;Name and file
    Name "Axmud"
    OutFile "install-axmud-2.0.0.exe"

    ;Default installation folder
    InstallDir "$LOCALAPPDATA\Axmud"

    ;Get installation folder from registry if available
    InstallDirRegKey HKCU "Software\Axmud" ""

    ;Request application privileges for Windows Vista
    RequestExecutionLevel user

    ; Extra stuff here
    BrandingText " "

# Variables
# -------------------------------

#   Var StartMenuFolder

# Interface settings
# -------------------------------

    !define MUI_ABORTWARNING
    !define MUI_ICON "axmud_icon.ico"
    !define MUI_UNICON "axmud_icon.ico"
    !define MUI_HEADERIMAGE
    !define MUI_HEADERIMAGE_BITMAP "axmud_header.bmp"
    !define MUI_HEADERIMAGE_UNBITMAP "axmud_header.bmp"
    !define MUI_WELCOMEFINISHPAGE_BITMAP "axmud_wizard.bmp"

# Pages
# -------------------------------

    !insertmacro MUI_PAGE_WELCOME

    !insertmacro MUI_PAGE_LICENSE "license.txt"

    !insertmacro MUI_PAGE_COMPONENTS

    !insertmacro MUI_PAGE_DIRECTORY

    !define MUI_STARTMENUPAGE_REGISTRY_ROOT "SHCTX"
    !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Axmud"
    !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Startmenu"
    !define MUI_STARTMENUPAGE_DEFAULTFOLDER "Axmud MUD Client"

    !insertmacro MUI_PAGE_INSTFILES

    # 'Run Axmud' option commented out as it doesn't work (for no obvious reason)
#   !define MUI_FINISHPAGE_RUN "$INSTDIR\msys64\home\user\axmud\runaxmud.bat"
#   !define MUI_FINISHPAGE_RUN_TEXT "Run Axmud"
#   !define MUI_FINISHPAGE_RUN_NOTCHECKED
    !define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\msys64\home\user\axmud\share\docs\quick\quick.html"
    !define MUI_FINISHPAGE_SHOWREADME_TEXT "Read quick help"
    !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
    !define MUI_FINISHPAGE_LINK "Visit the Axmud website for the latest news \
        and support"
    !define MUI_FINISHPAGE_LINK_LOCATION "http://axmud.sourceforge.io/"
    !insertmacro MUI_PAGE_FINISH

    !insertmacro MUI_UNPAGE_CONFIRM
    !insertmacro MUI_UNPAGE_INSTFILES

# Languages
# -------------------------------

    !insertmacro MUI_LANGUAGE "English"

# Installer sections
# -------------------------------

Section "Axmud" SecClient

    SectionIn RO
    SetOutPath "$INSTDIR"

    File "axmud_icon.ico"
    File /r msys64

    SetOutPath "$INSTDIR\msys64\home\user\axmud"

    # Start Menu
    CreateDirectory "$SMPROGRAMS\Axmud"
    CreateShortCut "$SMPROGRAMS\Axmud\Axmud (all users).lnk" \
        "$INSTDIR\msys64\home\user\axmud\runaxmud.bat" "" "$INSTDIR\axmud_icon.ico"
    CreateShortCut "$SMPROGRAMS\Axmud\Axmud (visually-impaired users).lnk" \
        "$INSTDIR\msys64\home\user\axmud\blindaxmud.bat" "" "$INSTDIR\axmud_icon.ico"

    # Desktop icon
    CreateShortcut "$DESKTOP\Axmud.lnk" "$INSTDIR\msys64\home\user\axmud\runaxmud.bat" "" \
        "$INSTDIR\axmud_icon.ico"

    # Store installation folder
    WriteRegStr HKCU "Software\Axmud" "" $INSTDIR

    # Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Festival" SecFestival

    SetOutPath "C:"

    File /r festival

SectionEnd

Section "espeak-ng" SecSpeakNG

    SetOutPath "$TEMP"

    ${If} ${RunningX64}
        File "espeak-ng-X64.msi"
        ExecWait 'msiexec /i "$TEMP\espeak-ng-X64.msi"'
    ${Else}
        File "espeak-ng-X86.msi"
        ExecWait 'msiexec /i "$TEMP\espeak-ng-X86.msi"'
    ${EndIf}

SectionEnd

Section "eSpeak" SecSpeak

    SetOutPath "$TEMP"

    File "setup_espeak.exe"

    ExecWait "$TEMP\setup_espeak.exe"

SectionEnd

# Descriptions
# -------------------------------

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecClient} "The Axmud client itself"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecFestival} \
        "Install the Festival text-to-speech engine"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSpeakNG} \
        "Install the espeak-ng text-to-speech engine"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSpeak} \
        "Install the eSpeak text-to-speech engine"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

# Uninstaller sections
# -------------------------------

Section "Uninstall"

    Delete "$INSTDIR\Uninstall.exe"

    RMDir "$INSTDIR"

    DeleteRegKey /ifempty HKCU "Software\Axmud"

SectionEnd
