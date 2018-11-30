# Axmud v1.1.343 installer script for MS Windows
#
# Copyright (C) 2011-2018 A S Lewis
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
#   - On an MS Windows machine, download and install NSIS from
#
#       http://nsis.sourceforge.net/Download/
#
#   - If you don't have a suitable editor (Notepad is not good enough), download
#       and install one, e.g. Notepad++ from
#
#       https://notepad-plus-plus.org/
#
#   - Download the 32-BIT PORTABLE edition of Strawberry Perl. Note that Axmud
#       will not work the 64-bit edition, even on a 64-bit machine. Download
#       from
#
#       http://strawberryperl.com/
#
#   - Extract the .zip file to the same folder, e.g. the standard Downloads
#       folder
#   - Rename the extracted folder to 'strawberry' (all lower-case). This step is
#       very important
#
#   - Download the installer for the eSpeak engine from
#
#       http://espeak.sourceforge.net/
#
#   - Copy the installer to the same folder, e.g. the standard Downloads folder
#   - Rename it to 'setup_espeak'
#
#   - Download the Axmud source code (the file ending .tar.gz) from
#       https://sourceforge.net/projects/axmud/
#   - Extract the .tar.gz file to a convenient location, e.g. the standard
#       Downloads folder (renaming the extracted folder is not necessary)
#
#   - Navigate into the .../strawberry folder
#   - Make two copies of the portableshell.bat file, and name them
#       'runaxmud.bat' and 'blindaxmud.bat'
#   - In both files, remove the lines beginning 'echo...'
#   - In runaxmud.bat, add this line just before the 'cmd /K' line:
#
#       perl strawberry\perl\site\bin\axmud.pl
#
#   - In blindaxmud.bat, add this line just before the 'cmd /K' line:
#
#       perl strawberry\perl\site\bin\baxmud.pl
#
#   - Open a command prompt, and navigate to .../strawberry
#   - Run portableshell.bat
#   - From that command prompt, install various Perl modules and libraries:
#
#       cpan Archive::Extract IO::Socket::INET6 IPC::Run Net::OpenSSH Regexp::IPv6
#       cpanm --force --build-args SHELL=cmd.exe --install-args SHELL=cmd.exe File::ShareDir::Install
#       ppm set repository sisyphusion http://sisyphusion.tk/ppm
#       ppm set save
#       ppm install Cairo Glib Pango Gtk2 Gnome2::Canvas
#
#   - Using the same command prompt, navigate into the Axmud folder
#   - Install Axmud in the usual way
#
#       perl Makefile.PL
#       gmake
#       gmake install
#
#   - You can now close the command prompt window
#
#   - The Axmud folder contains an /nsis folder, which contains this file
#   - In this file, opeupdate the version number just below, e.g.
#
#       OutFile "install-axmud-1.1.343.exe"
#
#   - Compile the installer (e.g. by right-clicking this file and selecting
#       'Compile NSIS script file')

# Header files
# -------------------------------

    !include "MUI2.nsh"
    !include "Sections.nsh"

# General
# -------------------------------

    ;Name and file
    Name "Axmud"
    OutFile "install-axmud-1.1.343.exe"

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

    !define MUI_FINISHPAGE_RUN "$INSTDIR\strawberry\runaxmud.bat"
    !define MUI_FINISHPAGE_RUN_TEXT "Run Axmud"
    !define MUI_FINISHPAGE_RUN_NOTCHECKED
    !define MUI_FINISHPAGE_SHOWREADME "..\README"
    !define MUI_FINISHPAGE_SHOWREADME_TEXT "Read quick help"
    !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
    !define MUI_FINISHPAGE_LINK "Visit the Axmud website for the latest news \
        and support"
    !define MUI_FINISHPAGE_LINK_LOCATION "http://axmud.sourceforge.net/"
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
    File /r ..\..\strawberry

    # Start Menu
    CreateDirectory "$SMPROGRAMS\Axmud"
    CreateShortCut "$SMPROGRAMS\Axmud\Axmud (all users).lnk" \
        "$INSTDIR\strawberry\runaxmud.bat" "" "$INSTDIR\axmud_icon.ico"
    CreateShortCut "$SMPROGRAMS\Axmud\Axmud (visually-impaired users).lnk" \
        "$INSTDIR\strawberry\blindaxmud.bat" "" "$INSTDIR\axmud_icon.ico"

    # Desktop icon
    CreateShortcut "$DESKTOP\Axmud.lnk" "$INSTDIR\strawberry\runaxmud.bat" "" \
        "$INSTDIR\axmud_icon.ico"

    # Store installation folder
    WriteRegStr HKCU "Software\Axmud" "" $INSTDIR

    # Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "eSpeak" SecSpeak

    SetOutPath "$TEMP"

    File "..\..\setup_espeak.exe"

    ExecWait "$TEMP\setup_espeak.exe"

SectionEnd

# Descriptions
# -------------------------------

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecClient} "The Axmud client itself"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSpeak} \
        "Install the eSpeak engine if you need text-to-speech"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

# Uninstaller sections
# -------------------------------

Section "Uninstall"

    Delete "$INSTDIR\Uninstall.exe"

    RMDir "$INSTDIR"

    DeleteRegKey /ifempty HKCU "Software\Axmud"

SectionEnd
