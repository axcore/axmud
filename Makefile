# This Makefile is for the Games::Axmud extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.34 (Revision: 73400) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     AUTHOR => [q[A S Lewis <aslewis@cpan.org>]]
#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => { ExtUtils::MakeMaker=>q[6.52], File::ShareDir::Install=>q[0], Path::Tiny=>q[0] }
#     EXE_FILES => [q[scripts/axmud.pl], q[scripts/baxmud.pl]]
#     INSTALLDIRS => q[site]
#     LICENSE => q[gpl_3]
#     META_MERGE => { meta-spec=>{ version=>q[2] }, no_index=>{ directory=>[q[share/plugins]] }, resources=>{ bugtracker=>{ web=>q[https://github.com/axcore/axmud/issues] }, homepage=>q[https://axmud.sourceforge.io/], repository=>{ type=>q[git], url=>q[https://github.com/axcore/axmud.git], web=>q[https://github.com/axcore/axmud] } } }
#     MIN_PERL_VERSION => q[5.008]
#     NAME => q[Games::Axmud]
#     PREREQ_PM => { Archive::Extract=>q[0], Archive::Tar=>q[0], Archive::Zip=>q[0], Compress::Zlib=>q[0], Encode=>q[0], Fcntl=>q[0], File::Basename=>q[0], File::Copy=>q[0], File::Copy::Recursive=>q[0], File::Fetch=>q[0], File::Find=>q[0], File::HomeDir=>q[0], File::Path=>q[0], File::ShareDir=>q[0], File::ShareDir::Install=>q[0], Glib=>q[0], GooCanvas2=>q[0], Gtk3=>q[0], HTTP::Tiny=>q[0], IO::Socket::INET=>q[0], IO::Socket::INET6=>q[0], IPC::Run=>q[0], JSON=>q[0], Math::Round=>q[0], Math::Trig=>q[0], Module::Load=>q[0], Net::OpenSSH=>q[0], POSIX=>q[0], Regexp::IPv6=>q[0], Safe=>q[0], Scalar::Util=>q[0], Socket=>q[0], Storable=>q[0], Symbol=>q[0], Time::HiRes=>q[0], Time::Piece=>q[0] }
#     TEST_REQUIRES => {  }
#     VERSION_FROM => q[scripts/axmud.pl]

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/x86_64-linux-gnu/perl/5.30/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = x86_64-linux-gnu-gcc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = x86_64-linux-gnu-gcc
LDDLFLAGS = -shared -L/usr/local/lib -fstack-protector-strong
LDFLAGS =  -fstack-protector-strong -L/usr/local/lib
LIBC = libc-2.31.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 4.19.0
RANLIB = :
SITELIBEXP = /usr/local/share/perl/5.30.0
SITEARCHEXP = /usr/local/lib/x86_64-linux-gnu/perl/5.30.0
SO = so
VENDORARCHEXP = /usr/lib/x86_64-linux-gnu/perl5/5.30
VENDORLIBEXP = /usr/share/perl5


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = Games::Axmud
NAME_SYM = Games_Axmud
VERSION = 1.3.007
VERSION_MACRO = VERSION
VERSION_SYM = 1_3_007
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 1.3.007
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1p
MAN3EXT = 3pm
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /usr
SITEPREFIX = /usr/local
VENDORPREFIX = /usr
INSTALLPRIVLIB = /usr/share/perl/5.30
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /usr/local/share/perl/5.30.0
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = /usr/share/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /usr/lib/x86_64-linux-gnu/perl/5.30
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /usr/local/lib/x86_64-linux-gnu/perl/5.30.0
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = /usr/lib/x86_64-linux-gnu/perl5/5.30
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /usr/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /usr/local/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = /usr/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /usr/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /usr/local/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = /usr/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /usr/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /usr/local/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = /usr/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /usr/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /usr/local/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = /usr/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /usr/share/perl/5.30
PERL_ARCHLIB = /usr/lib/x86_64-linux-gnu/perl/5.30
PERL_ARCHLIBDEP = /usr/lib/x86_64-linux-gnu/perl/5.30
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/x86_64-linux-gnu/perl/5.30/CORE
PERL_INCDEP = /usr/lib/x86_64-linux-gnu/perl/5.30/CORE
PERL = "/usr/bin/perl"
FULLPERL = "/usr/bin/perl"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/share/perl/5.30/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.34
MM_REVISION = 73400

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = Games/Axmud
BASEEXT = Axmud
PARENT_NAME = Games
DLBASE = $(BASEEXT)
VERSION_FROM = scripts/axmud.pl
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = 
MAN3PODS = lib/Games/Axmud.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/Games
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/Games

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVEDEP    = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = domanifest.pl \
	lib/Games/Axmud.pm \
	lib/Games/Axmud/Buffer.pm \
	lib/Games/Axmud/Cage.pm \
	lib/Games/Axmud/Client.pm \
	lib/Games/Axmud/Cmd.pm \
	lib/Games/Axmud/EditWin.pm \
	lib/Games/Axmud/FixedWin.pm \
	lib/Games/Axmud/Generic.pm \
	lib/Games/Axmud/Interface.pm \
	lib/Games/Axmud/InterfaceModel.pm \
	lib/Games/Axmud/Mcp.pm \
	lib/Games/Axmud/ModelObj.pm \
	lib/Games/Axmud/Mxp.pm \
	lib/Games/Axmud/Node.pm \
	lib/Games/Axmud/Obj/Area.pm \
	lib/Games/Axmud/Obj/Atcp.pm \
	lib/Games/Axmud/Obj/BasicWorld.pm \
	lib/Games/Axmud/Obj/Blinker.pm \
	lib/Games/Axmud/Obj/ChatContact.pm \
	lib/Games/Axmud/Obj/ColourScheme.pm \
	lib/Games/Axmud/Obj/Component.pm \
	lib/Games/Axmud/Obj/ConnectHistory.pm \
	lib/Games/Axmud/Obj/Desktop.pm \
	lib/Games/Axmud/Obj/Dict.pm \
	lib/Games/Axmud/Obj/Exit.pm \
	lib/Games/Axmud/Obj/File.pm \
	lib/Games/Axmud/Obj/Gauge.pm \
	lib/Games/Axmud/Obj/GaugeLevel.pm \
	lib/Games/Axmud/Obj/Gmcp.pm \
	lib/Games/Axmud/Obj/GridColour.pm \
	lib/Games/Axmud/Obj/Heap.pm \
	lib/Games/Axmud/Obj/Link.pm \
	lib/Games/Axmud/Obj/Loop.pm \
	lib/Games/Axmud/Obj/Map.pm \
	lib/Games/Axmud/Obj/MapLabel.pm \
	lib/Games/Axmud/Obj/MiniWorld.pm \
	lib/Games/Axmud/Obj/Mission.pm \
	lib/Games/Axmud/Obj/Monitor.pm \
	lib/Games/Axmud/Obj/Parchment.pm \
	lib/Games/Axmud/Obj/Phrasebook.pm \
	lib/Games/Axmud/Obj/Plugin.pm \
	lib/Games/Axmud/Obj/Protect.pm \
	lib/Games/Axmud/Obj/Quest.pm \
	lib/Games/Axmud/Obj/RegionPath.pm \
	lib/Games/Axmud/Obj/RegionScheme.pm \
	lib/Games/Axmud/Obj/Regionmap.pm \
	lib/Games/Axmud/Obj/Repeat.pm \
	lib/Games/Axmud/Obj/RoomFlag.pm \
	lib/Games/Axmud/Obj/Route.pm \
	lib/Games/Axmud/Obj/Simple.pm \
	lib/Games/Axmud/Obj/SkillHistory.pm \
	lib/Games/Axmud/Obj/Sound.pm \
	lib/Games/Axmud/Obj/Tab.pm \
	lib/Games/Axmud/Obj/Tablezone.pm \
	lib/Games/Axmud/Obj/Telnet.pm \
	lib/Games/Axmud/Obj/TextView.pm \
	lib/Games/Axmud/Obj/Toolbar.pm \
	lib/Games/Axmud/Obj/Tts.pm \
	lib/Games/Axmud/Obj/WMCtrl.pm \
	lib/Games/Axmud/Obj/Winmap.pm \
	lib/Games/Axmud/Obj/Winzone.pm \
	lib/Games/Axmud/Obj/Workspace.pm \
	lib/Games/Axmud/Obj/WorkspaceGrid.pm \
	lib/Games/Axmud/Obj/WorldModel.pm \
	lib/Games/Axmud/Obj/Zmp.pm \
	lib/Games/Axmud/Obj/Zone.pm \
	lib/Games/Axmud/Obj/ZoneModel.pm \
	lib/Games/Axmud/Obj/Zonemap.pm \
	lib/Games/Axmud/OtherWin.pm \
	lib/Games/Axmud/PrefWin.pm \
	lib/Games/Axmud/Profile.pm \
	lib/Games/Axmud/Pueblo.pm \
	lib/Games/Axmud/Session.pm \
	lib/Games/Axmud/Strip.pm \
	lib/Games/Axmud/Table.pm \
	lib/Games/Axmud/Task.pm \
	lib/Games/Axmud/Win/External.pm \
	lib/Games/Axmud/Win/Internal.pm \
	lib/Games/Axmud/Win/Map.pm \
	lib/Games/Axmud/WizWin.pm \
	lib/Language/Axbasic.pm \
	lib/Language/Axbasic/Expression.pm \
	lib/Language/Axbasic/Function.pm \
	lib/Language/Axbasic/Statement.pm \
	lib/Language/Axbasic/Subroutine.pm \
	lib/Language/Axbasic/Variable.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.34
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = Games-Axmud
DISTVNAME = Games-Axmud-1.3.007


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	LD="$(LD)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE='$(DEFINE) $(PASTHRU_DEFINE)'\
	PASTHRU_INC='$(INC) $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: dynamic
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) config $(INST_BOOT) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config  \
	lib/Games/Axmud.pm
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) -u \
	  lib/Games/Axmud.pm $(INST_MAN3DIR)/Games::Axmud.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = scripts/axmud.pl scripts/baxmud.pl

pure_all :: $(INST_SCRIPT)/axmud.pl $(INST_SCRIPT)/baxmud.pl
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/axmud.pl $(INST_SCRIPT)/baxmud.pl 

$(INST_SCRIPT)/axmud.pl : scripts/axmud.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/axmud.pl
	$(CP) scripts/axmud.pl $(INST_SCRIPT)/axmud.pl
	$(FIXIN) $(INST_SCRIPT)/axmud.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/axmud.pl

$(INST_SCRIPT)/baxmud.pl : scripts/baxmud.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/baxmud.pl
	$(CP) scripts/baxmud.pl $(INST_SCRIPT)/baxmud.pl
	$(FIXIN) $(INST_SCRIPT)/baxmud.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/baxmud.pl



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  blib 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: unknown' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''A S Lewis <aslewis@cpan.org>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''6.52'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::ShareDir::Install: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Path::Tiny: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.34, CPAN::Meta::Converter version 2.150010'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: gpl' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: Games-Axmud' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) '    - share/plugins' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  Archive::Extract: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Archive::Tar: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Archive::Zip: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Compress::Zlib: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Encode: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Fcntl: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Basename: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Copy: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Copy::Recursive: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Fetch: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Find: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::HomeDir: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Path: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::ShareDir: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::ShareDir::Install: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Glib: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  GooCanvas2: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Gtk3: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  HTTP::Tiny: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IO::Socket::INET: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IO::Socket::INET6: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  IPC::Run: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  JSON: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Math::Round: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Math::Trig: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Module::Load: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Net::OpenSSH: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  POSIX: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Regexp::IPv6: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Safe: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Scalar::Util: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Socket: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Storable: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Symbol: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::HiRes: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Time::Piece: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  perl: '\''5.008'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'resources:' >> META_new.yml
	$(NOECHO) $(ECHO) '  bugtracker: https://github.com/axcore/axmud/issues' >> META_new.yml
	$(NOECHO) $(ECHO) '  homepage: https://axmud.sourceforge.io/' >> META_new.yml
	$(NOECHO) $(ECHO) '  repository: https://github.com/axcore/axmud.git' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: v1.3.007' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_serialization_backend: '\''CPAN::Meta::YAML version 0.018'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "unknown",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "A S Lewis <aslewis@cpan.org>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.34, CPAN::Meta::Converter version 2.150010",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "gpl_3"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : 2' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "Games-Axmud",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc",' >> META_new.json
	$(NOECHO) $(ECHO) '         "share/plugins"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "6.52",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::ShareDir::Install" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Path::Tiny" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Archive::Extract" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Archive::Tar" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Archive::Zip" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Compress::Zlib" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Encode" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Fcntl" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Basename" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Copy" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Copy::Recursive" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Fetch" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Find" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::HomeDir" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Path" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::ShareDir" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::ShareDir::Install" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Glib" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "GooCanvas2" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Gtk3" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "HTTP::Tiny" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IO::Socket::INET" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IO::Socket::INET6" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "IPC::Run" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "JSON" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Math::Round" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Math::Trig" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Module::Load" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Net::OpenSSH" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "POSIX" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Regexp::IPv6" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Safe" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Scalar::Util" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Socket" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Storable" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Symbol" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::HiRes" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Time::Piece" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "perl" : "5.008"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "resources" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "bugtracker" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/axcore/axmud/issues"' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "homepage" : "https://axmud.sourceforge.io/",' >> META_new.json
	$(NOECHO) $(ECHO) '      "repository" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "type" : "git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "url" : "https://github.com/axcore/axmud.git",' >> META_new.json
	$(NOECHO) $(ECHO) '         "web" : "https://github.com/axcore/axmud"' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "v1.3.007",' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_serialization_backend" : "JSON::PP version 4.02"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:
ci :
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e '@all = sort keys %{ maniread() };' \
	  -e 'print(qq{Executing $(CI) @all\n});' \
	  -e 'system(qq{$(CI) @all}) == 0 or die $$!;' \
	  -e 'print(qq{Executing $(RCS_LABEL) ...\n});' \
	  -e 'system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;' --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)/auto/$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) umask 02; $(MOD_INSTALL) \
		read "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)/auto/$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLSITEARCH)/perllocal.pod"
	-$(NOECHO) umask 02; $(MKPATH) "$(DESTINSTALLSITEARCH)"
	-$(NOECHO) umask 02; $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLSITEARCH)/perllocal.pod"

doc_vendor_install :: all


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist"

uninstall_from_vendordirs ::


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = "/usr/bin/perl"
MAP_PERLINC   = "-Iblib/arch" "-Iblib/lib" "-I/usr/lib/x86_64-linux-gnu/perl/5.30" "-I/usr/share/perl/5.30"

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : static $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR="" \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:
TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)
	$(NOECHO) $(NOOP)

test :: $(TEST_TYPE)
	$(NOECHO) $(NOOP)

# Occasionally we may face this degenerate target:
test_ : test_dynamic
	$(NOECHO) $(NOOP)

subdirs-test_dynamic :: dynamic pure_all

test_dynamic :: subdirs-test_dynamic
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="Games-Axmud" VERSION="1.3.007">' > Games-Axmud.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT></ABSTRACT>' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>A S Lewis &lt;aslewis@cpan.org&gt;</AUTHOR>' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <PERLCORE VERSION="5,008,0,0" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Archive::Extract" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Archive::Tar" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Archive::Zip" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Compress::Zlib" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Encode::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Fcntl::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Basename" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Copy" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Copy::Recursive" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Fetch" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Find" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::HomeDir" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Path" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::ShareDir" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::ShareDir::Install" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Glib::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="GooCanvas2::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Gtk3::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="HTTP::Tiny" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="IO::Socket::INET" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="IO::Socket::INET6" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="IPC::Run" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="JSON::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Math::Round" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Math::Trig" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Module::Load" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Net::OpenSSH" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="POSIX::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Regexp::IPv6" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Safe::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Scalar::Util" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Socket::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Storable::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Symbol::" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Time::HiRes" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Time::Piece" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-gnu-thread-multi-5.30" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> Games-Axmud.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> Games-Axmud.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'domanifest.pl' '$(INST_LIB)/Games/domanifest.pl' \
	  'lib/Games/Axmud.pm' 'blib/lib/Games/Axmud.pm' \
	  'lib/Games/Axmud/Buffer.pm' 'blib/lib/Games/Axmud/Buffer.pm' \
	  'lib/Games/Axmud/Cage.pm' 'blib/lib/Games/Axmud/Cage.pm' \
	  'lib/Games/Axmud/Client.pm' 'blib/lib/Games/Axmud/Client.pm' \
	  'lib/Games/Axmud/Cmd.pm' 'blib/lib/Games/Axmud/Cmd.pm' \
	  'lib/Games/Axmud/EditWin.pm' 'blib/lib/Games/Axmud/EditWin.pm' \
	  'lib/Games/Axmud/FixedWin.pm' 'blib/lib/Games/Axmud/FixedWin.pm' \
	  'lib/Games/Axmud/Generic.pm' 'blib/lib/Games/Axmud/Generic.pm' \
	  'lib/Games/Axmud/Interface.pm' 'blib/lib/Games/Axmud/Interface.pm' \
	  'lib/Games/Axmud/InterfaceModel.pm' 'blib/lib/Games/Axmud/InterfaceModel.pm' \
	  'lib/Games/Axmud/Mcp.pm' 'blib/lib/Games/Axmud/Mcp.pm' \
	  'lib/Games/Axmud/ModelObj.pm' 'blib/lib/Games/Axmud/ModelObj.pm' \
	  'lib/Games/Axmud/Mxp.pm' 'blib/lib/Games/Axmud/Mxp.pm' \
	  'lib/Games/Axmud/Node.pm' 'blib/lib/Games/Axmud/Node.pm' \
	  'lib/Games/Axmud/Obj/Area.pm' 'blib/lib/Games/Axmud/Obj/Area.pm' \
	  'lib/Games/Axmud/Obj/Atcp.pm' 'blib/lib/Games/Axmud/Obj/Atcp.pm' \
	  'lib/Games/Axmud/Obj/BasicWorld.pm' 'blib/lib/Games/Axmud/Obj/BasicWorld.pm' \
	  'lib/Games/Axmud/Obj/Blinker.pm' 'blib/lib/Games/Axmud/Obj/Blinker.pm' \
	  'lib/Games/Axmud/Obj/ChatContact.pm' 'blib/lib/Games/Axmud/Obj/ChatContact.pm' \
	  'lib/Games/Axmud/Obj/ColourScheme.pm' 'blib/lib/Games/Axmud/Obj/ColourScheme.pm' \
	  'lib/Games/Axmud/Obj/Component.pm' 'blib/lib/Games/Axmud/Obj/Component.pm' \
	  'lib/Games/Axmud/Obj/ConnectHistory.pm' 'blib/lib/Games/Axmud/Obj/ConnectHistory.pm' \
	  'lib/Games/Axmud/Obj/Desktop.pm' 'blib/lib/Games/Axmud/Obj/Desktop.pm' \
	  'lib/Games/Axmud/Obj/Dict.pm' 'blib/lib/Games/Axmud/Obj/Dict.pm' \
	  'lib/Games/Axmud/Obj/Exit.pm' 'blib/lib/Games/Axmud/Obj/Exit.pm' \
	  'lib/Games/Axmud/Obj/File.pm' 'blib/lib/Games/Axmud/Obj/File.pm' \
	  'lib/Games/Axmud/Obj/Gauge.pm' 'blib/lib/Games/Axmud/Obj/Gauge.pm' \
	  'lib/Games/Axmud/Obj/GaugeLevel.pm' 'blib/lib/Games/Axmud/Obj/GaugeLevel.pm' \
	  'lib/Games/Axmud/Obj/Gmcp.pm' 'blib/lib/Games/Axmud/Obj/Gmcp.pm' \
	  'lib/Games/Axmud/Obj/GridColour.pm' 'blib/lib/Games/Axmud/Obj/GridColour.pm' \
	  'lib/Games/Axmud/Obj/Heap.pm' 'blib/lib/Games/Axmud/Obj/Heap.pm' \
	  'lib/Games/Axmud/Obj/Link.pm' 'blib/lib/Games/Axmud/Obj/Link.pm' \
	  'lib/Games/Axmud/Obj/Loop.pm' 'blib/lib/Games/Axmud/Obj/Loop.pm' \
	  'lib/Games/Axmud/Obj/Map.pm' 'blib/lib/Games/Axmud/Obj/Map.pm' \
	  'lib/Games/Axmud/Obj/MapLabel.pm' 'blib/lib/Games/Axmud/Obj/MapLabel.pm' \
	  'lib/Games/Axmud/Obj/MiniWorld.pm' 'blib/lib/Games/Axmud/Obj/MiniWorld.pm' \
	  'lib/Games/Axmud/Obj/Mission.pm' 'blib/lib/Games/Axmud/Obj/Mission.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Games/Axmud/Obj/Monitor.pm' 'blib/lib/Games/Axmud/Obj/Monitor.pm' \
	  'lib/Games/Axmud/Obj/Parchment.pm' 'blib/lib/Games/Axmud/Obj/Parchment.pm' \
	  'lib/Games/Axmud/Obj/Phrasebook.pm' 'blib/lib/Games/Axmud/Obj/Phrasebook.pm' \
	  'lib/Games/Axmud/Obj/Plugin.pm' 'blib/lib/Games/Axmud/Obj/Plugin.pm' \
	  'lib/Games/Axmud/Obj/Protect.pm' 'blib/lib/Games/Axmud/Obj/Protect.pm' \
	  'lib/Games/Axmud/Obj/Quest.pm' 'blib/lib/Games/Axmud/Obj/Quest.pm' \
	  'lib/Games/Axmud/Obj/RegionPath.pm' 'blib/lib/Games/Axmud/Obj/RegionPath.pm' \
	  'lib/Games/Axmud/Obj/RegionScheme.pm' 'blib/lib/Games/Axmud/Obj/RegionScheme.pm' \
	  'lib/Games/Axmud/Obj/Regionmap.pm' 'blib/lib/Games/Axmud/Obj/Regionmap.pm' \
	  'lib/Games/Axmud/Obj/Repeat.pm' 'blib/lib/Games/Axmud/Obj/Repeat.pm' \
	  'lib/Games/Axmud/Obj/RoomFlag.pm' 'blib/lib/Games/Axmud/Obj/RoomFlag.pm' \
	  'lib/Games/Axmud/Obj/Route.pm' 'blib/lib/Games/Axmud/Obj/Route.pm' \
	  'lib/Games/Axmud/Obj/Simple.pm' 'blib/lib/Games/Axmud/Obj/Simple.pm' \
	  'lib/Games/Axmud/Obj/SkillHistory.pm' 'blib/lib/Games/Axmud/Obj/SkillHistory.pm' \
	  'lib/Games/Axmud/Obj/Sound.pm' 'blib/lib/Games/Axmud/Obj/Sound.pm' \
	  'lib/Games/Axmud/Obj/Tab.pm' 'blib/lib/Games/Axmud/Obj/Tab.pm' \
	  'lib/Games/Axmud/Obj/Tablezone.pm' 'blib/lib/Games/Axmud/Obj/Tablezone.pm' \
	  'lib/Games/Axmud/Obj/Telnet.pm' 'blib/lib/Games/Axmud/Obj/Telnet.pm' \
	  'lib/Games/Axmud/Obj/TextView.pm' 'blib/lib/Games/Axmud/Obj/TextView.pm' \
	  'lib/Games/Axmud/Obj/Toolbar.pm' 'blib/lib/Games/Axmud/Obj/Toolbar.pm' \
	  'lib/Games/Axmud/Obj/Tts.pm' 'blib/lib/Games/Axmud/Obj/Tts.pm' \
	  'lib/Games/Axmud/Obj/WMCtrl.pm' 'blib/lib/Games/Axmud/Obj/WMCtrl.pm' \
	  'lib/Games/Axmud/Obj/Winmap.pm' 'blib/lib/Games/Axmud/Obj/Winmap.pm' \
	  'lib/Games/Axmud/Obj/Winzone.pm' 'blib/lib/Games/Axmud/Obj/Winzone.pm' \
	  'lib/Games/Axmud/Obj/Workspace.pm' 'blib/lib/Games/Axmud/Obj/Workspace.pm' \
	  'lib/Games/Axmud/Obj/WorkspaceGrid.pm' 'blib/lib/Games/Axmud/Obj/WorkspaceGrid.pm' \
	  'lib/Games/Axmud/Obj/WorldModel.pm' 'blib/lib/Games/Axmud/Obj/WorldModel.pm' \
	  'lib/Games/Axmud/Obj/Zmp.pm' 'blib/lib/Games/Axmud/Obj/Zmp.pm' \
	  'lib/Games/Axmud/Obj/Zone.pm' 'blib/lib/Games/Axmud/Obj/Zone.pm' \
	  'lib/Games/Axmud/Obj/ZoneModel.pm' 'blib/lib/Games/Axmud/Obj/ZoneModel.pm' \
	  'lib/Games/Axmud/Obj/Zonemap.pm' 'blib/lib/Games/Axmud/Obj/Zonemap.pm' \
	  'lib/Games/Axmud/OtherWin.pm' 'blib/lib/Games/Axmud/OtherWin.pm' \
	  'lib/Games/Axmud/PrefWin.pm' 'blib/lib/Games/Axmud/PrefWin.pm' \
	  'lib/Games/Axmud/Profile.pm' 'blib/lib/Games/Axmud/Profile.pm' \
	  'lib/Games/Axmud/Pueblo.pm' 'blib/lib/Games/Axmud/Pueblo.pm' \
	  'lib/Games/Axmud/Session.pm' 'blib/lib/Games/Axmud/Session.pm' \
	  'lib/Games/Axmud/Strip.pm' 'blib/lib/Games/Axmud/Strip.pm' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/Games/Axmud/Table.pm' 'blib/lib/Games/Axmud/Table.pm' \
	  'lib/Games/Axmud/Task.pm' 'blib/lib/Games/Axmud/Task.pm' \
	  'lib/Games/Axmud/Win/External.pm' 'blib/lib/Games/Axmud/Win/External.pm' \
	  'lib/Games/Axmud/Win/Internal.pm' 'blib/lib/Games/Axmud/Win/Internal.pm' \
	  'lib/Games/Axmud/Win/Map.pm' 'blib/lib/Games/Axmud/Win/Map.pm' \
	  'lib/Games/Axmud/WizWin.pm' 'blib/lib/Games/Axmud/WizWin.pm' \
	  'lib/Language/Axbasic.pm' 'blib/lib/Language/Axbasic.pm' \
	  'lib/Language/Axbasic/Expression.pm' 'blib/lib/Language/Axbasic/Expression.pm' \
	  'lib/Language/Axbasic/Function.pm' 'blib/lib/Language/Axbasic/Function.pm' \
	  'lib/Language/Axbasic/Statement.pm' 'blib/lib/Language/Axbasic/Statement.pm' \
	  'lib/Language/Axbasic/Subroutine.pm' 'blib/lib/Language/Axbasic/Subroutine.pm' \
	  'lib/Language/Axbasic/Variable.pm' 'blib/lib/Language/Axbasic/Variable.pm' 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:
config::
	$(NOECHO) $(RM_RF) $(INST_LIB)/auto/share/dist/$(DISTNAME)

config::
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/COPYING' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/COPYING' \
	  'share/docs/guide/ch01.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch01.html' \
	  'share/docs/guide/ch01.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch01.mkd' \
	  'share/docs/guide/ch02.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch02.html' \
	  'share/docs/guide/ch02.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch02.mkd' \
	  'share/docs/guide/ch03.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch03.html' \
	  'share/docs/guide/ch03.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch03.mkd' \
	  'share/docs/guide/ch04.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch04.html' \
	  'share/docs/guide/ch04.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch04.mkd' \
	  'share/docs/guide/ch05.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch05.html' \
	  'share/docs/guide/ch05.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch05.mkd' \
	  'share/docs/guide/ch06.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch06.html' \
	  'share/docs/guide/ch06.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch06.mkd' \
	  'share/docs/guide/ch07.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch07.html' \
	  'share/docs/guide/ch07.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch07.mkd' \
	  'share/docs/guide/ch08.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch08.html' \
	  'share/docs/guide/ch08.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch08.mkd' \
	  'share/docs/guide/ch09.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch09.html' \
	  'share/docs/guide/ch09.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch09.mkd' \
	  'share/docs/guide/ch10.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch10.html' \
	  'share/docs/guide/ch10.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch10.mkd' \
	  'share/docs/guide/ch11.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch11.html' \
	  'share/docs/guide/ch11.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch11.mkd' \
	  'share/docs/guide/ch12.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch12.html' \
	  'share/docs/guide/ch12.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch12.mkd' \
	  'share/docs/guide/ch13.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch13.html' \
	  'share/docs/guide/ch13.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch13.mkd' \
	  'share/docs/guide/ch14.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch14.html' \
	  'share/docs/guide/ch14.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch14.mkd' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/ch15.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch15.html' \
	  'share/docs/guide/ch15.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch15.mkd' \
	  'share/docs/guide/ch16.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch16.html' \
	  'share/docs/guide/ch16.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch16.mkd' \
	  'share/docs/guide/ch17.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch17.html' \
	  'share/docs/guide/ch17.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch17.mkd' \
	  'share/docs/guide/ch18.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch18.html' \
	  'share/docs/guide/ch18.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/ch18.mkd' \
	  'share/docs/guide/img/ch03/connect_window.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/connect_window.png' \
	  'share/docs/guide/img/ch03/icon_adult.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_adult.png' \
	  'share/docs/guide/img/ch03/icon_config.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_config.png' \
	  'share/docs/guide/img/ch03/icon_console_alert.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_console_alert.png' \
	  'share/docs/guide/img/ch03/icon_other.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_other.png' \
	  'share/docs/guide/img/ch03/icon_sort_a.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_sort_a.png' \
	  'share/docs/guide/img/ch03/icon_sort_random.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_sort_random.png' \
	  'share/docs/guide/img/ch03/icon_sort_z.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/icon_sort_z.png' \
	  'share/docs/guide/img/ch03/setup_wizard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch03/setup_wizard.png' \
	  'share/docs/guide/img/ch04/dict_tab.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/dict_tab.png' \
	  'share/docs/guide/img/ch04/edit_win_buttons.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/edit_win_buttons.png' \
	  'share/docs/guide/img/ch04/edit_win_tabs.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/edit_win_tabs.png' \
	  'share/docs/guide/img/ch04/icon_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_add.png' \
	  'share/docs/guide/img/ch04/icon_application.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_application.png' \
	  'share/docs/guide/img/ch04/icon_broom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_broom.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/img/ch04/icon_compass.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_compass.png' \
	  'share/docs/guide/img/ch04/icon_console.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_console.png' \
	  'share/docs/guide/img/ch04/icon_help.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_help.png' \
	  'share/docs/guide/img/ch04/icon_input.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_input.png' \
	  'share/docs/guide/img/ch04/icon_lock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_lock.png' \
	  'share/docs/guide/img/ch04/icon_phone_vintage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_phone_vintage.png' \
	  'share/docs/guide/img/ch04/icon_quit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_quit.png' \
	  'share/docs/guide/img/ch04/icon_search.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_search.png' \
	  'share/docs/guide/img/ch04/icon_watermark_table.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/icon_watermark_table.png' \
	  'share/docs/guide/img/ch04/main_window.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/main_window.png' \
	  'share/docs/guide/img/ch04/object_viewer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/object_viewer.png' \
	  'share/docs/guide/img/ch04/pref_win_buttons.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/pref_win_buttons.png' \
	  'share/docs/guide/img/ch04/viewer_tooltip.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch04/viewer_tooltip.png' \
	  'share/docs/guide/img/ch07/edit_triggers.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch07/edit_triggers.png' \
	  'share/docs/guide/img/ch07/status_interfaces.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch07/status_interfaces.png' \
	  'share/docs/guide/img/ch07/trigger_attributes.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch07/trigger_attributes.png' \
	  'share/docs/guide/img/ch07/trigger_styles.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch07/trigger_styles.png' \
	  'share/docs/guide/img/ch11/channels_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/channels_task.png' \
	  'share/docs/guide/img/ch11/channels_task_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/channels_task_2.png' \
	  'share/docs/guide/img/ch11/chat_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/chat_task.png' \
	  'share/docs/guide/img/ch11/chat_task_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/chat_task_2.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/img/ch11/chat_task_3.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/chat_task_3.png' \
	  'share/docs/guide/img/ch11/compass_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/compass_task.png' \
	  'share/docs/guide/img/ch11/divert_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/divert_task.png' \
	  'share/docs/guide/img/ch11/icon_roadworks.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/icon_roadworks.png' \
	  'share/docs/guide/img/ch11/incoming_chat.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/incoming_chat.png' \
	  'share/docs/guide/img/ch11/locator_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/locator_task.png' \
	  'share/docs/guide/img/ch11/status_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch11/status_task.png' \
	  'share/docs/guide/img/ch12/initial_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch12/initial_task.png' \
	  'share/docs/guide/img/ch15/automapper_window.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/automapper_window.png' \
	  'share/docs/guide/img/ch15/bent_exit_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/bent_exit_1.png' \
	  'share/docs/guide/img/ch15/bent_exit_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/bent_exit_2.png' \
	  'share/docs/guide/img/ch15/bent_exit_3.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/bent_exit_3.png' \
	  'share/docs/guide/img/ch15/char_visits_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/char_visits_1.png' \
	  'share/docs/guide/img/ch15/char_visits_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/char_visits_2.png' \
	  'share/docs/guide/img/ch15/checked_dir.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/checked_dir.png' \
	  'share/docs/guide/img/ch15/closed_ornament.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/closed_ornament.png' \
	  'share/docs/guide/img/ch15/colour_bg.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/colour_bg.png' \
	  'share/docs/guide/img/ch15/colour_toolbar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/colour_toolbar.png' \
	  'share/docs/guide/img/ch15/complex_exits_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/complex_exits_1.png' \
	  'share/docs/guide/img/ch15/complex_exits_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/complex_exits_2.png' \
	  'share/docs/guide/img/ch15/complex_exits_3.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/complex_exits_3.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/img/ch15/confirm_delete_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/confirm_delete_exit.png' \
	  'share/docs/guide/img/ch15/current_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/current_room.png' \
	  'share/docs/guide/img/ch15/dict_primary_dirs.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/dict_primary_dirs.png' \
	  'share/docs/guide/img/ch15/drag_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/drag_exit.png' \
	  'share/docs/guide/img/ch15/drag_mode_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/drag_mode_button.png' \
	  'share/docs/guide/img/ch15/draw_no_exits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/draw_no_exits.png' \
	  'share/docs/guide/img/ch15/empire_map.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/empire_map.png' \
	  'share/docs/guide/img/ch15/exit_lengths.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/exit_lengths.png' \
	  'share/docs/guide/img/ch15/exit_lengths_buttons.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/exit_lengths_buttons.png' \
	  'share/docs/guide/img/ch15/first_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/first_room.png' \
	  'share/docs/guide/img/ch15/graffiti_mode.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/graffiti_mode.png' \
	  'share/docs/guide/img/ch15/icon_compass.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/icon_compass.png' \
	  'share/docs/guide/img/ch15/icon_connect_click.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/icon_connect_click.png' \
	  'share/docs/guide/img/ch15/icon_wizard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/icon_wizard.png' \
	  'share/docs/guide/img/ch15/impassable_ornament.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/impassable_ornament.png' \
	  'share/docs/guide/img/ch15/locked_ornament.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/locked_ornament.png' \
	  'share/docs/guide/img/ch15/map_modes.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/map_modes.png' \
	  'share/docs/guide/img/ch15/match_many_rooms.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/match_many_rooms.png' \
	  'share/docs/guide/img/ch15/match_one_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/match_one_room.png' \
	  'share/docs/guide/img/ch15/mystery_ornament.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/mystery_ornament.png' \
	  'share/docs/guide/img/ch15/one_way_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/one_way_exit.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/img/ch15/paint_toolbar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/paint_toolbar.png' \
	  'share/docs/guide/img/ch15/path_problem1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/path_problem1.png' \
	  'share/docs/guide/img/ch15/path_problem2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/path_problem2.png' \
	  'share/docs/guide/img/ch15/pathfinding.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/pathfinding.png' \
	  'share/docs/guide/img/ch15/previous_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/previous_room.png' \
	  'share/docs/guide/img/ch15/quick_toolbar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/quick_toolbar.png' \
	  'share/docs/guide/img/ch15/region_exit_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/region_exit_1.png' \
	  'share/docs/guide/img/ch15/region_exit_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/region_exit_2.png' \
	  'share/docs/guide/img/ch15/region_list_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/region_list_1.png' \
	  'share/docs/guide/img/ch15/region_list_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/region_list_2.png' \
	  'share/docs/guide/img/ch15/reset_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/reset_button.png' \
	  'share/docs/guide/img/ch15/room_flag_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_flag_1.png' \
	  'share/docs/guide/img/ch15/room_flag_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_flag_2.png' \
	  'share/docs/guide/img/ch15/room_flag_4.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_flag_4.png' \
	  'share/docs/guide/img/ch15/room_flag_5.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_flag_5.png' \
	  'share/docs/guide/img/ch15/room_guild.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_guild.png' \
	  'share/docs/guide/img/ch15/room_tag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_tag.png' \
	  'share/docs/guide/img/ch15/room_tooltip.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/room_tooltip.png' \
	  'share/docs/guide/img/ch15/selected_current_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/selected_current_room.png' \
	  'share/docs/guide/img/ch15/selected_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/selected_exit.png' \
	  'share/docs/guide/img/ch15/selected_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/selected_room.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/img/ch15/simple_label.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/simple_label.png' \
	  'share/docs/guide/img/ch15/slide_mode_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/slide_mode_1.png' \
	  'share/docs/guide/img/ch15/slide_mode_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/slide_mode_2.png' \
	  'share/docs/guide/img/ch15/toolbar_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/toolbar_1.png' \
	  'share/docs/guide/img/ch15/toolbar_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/toolbar_2.png' \
	  'share/docs/guide/img/ch15/toolbar_3.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/toolbar_3.png' \
	  'share/docs/guide/img/ch15/toolbar_4.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/toolbar_4.png' \
	  'share/docs/guide/img/ch15/unallocated_exit_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/unallocated_exit_1.png' \
	  'share/docs/guide/img/ch15/unallocated_exit_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/unallocated_exit_2.png' \
	  'share/docs/guide/img/ch15/up_down_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/up_down_exit.png' \
	  'share/docs/guide/img/ch15/wild_room_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/wild_room_1.png' \
	  'share/docs/guide/img/ch15/wild_room_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/wild_room_2.png' \
	  'share/docs/guide/img/ch15/wild_room_3.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/ch15/wild_room_3.png' \
	  'share/docs/guide/img/index/axmud_logo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/index/axmud_logo.png' \
	  'share/docs/guide/img/tut01/example_map.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut01/example_map.png' \
	  'share/docs/guide/img/tut01/route_cage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut01/route_cage.png' \
	  'share/docs/guide/img/tut02/connected_rooms.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut02/connected_rooms.png' \
	  'share/docs/guide/img/tut02/empty_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut02/empty_room.png' \
	  'share/docs/guide/img/tut02/nearby_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut02/nearby_room.png' \
	  'share/docs/guide/img/tut02/recognised_rooms.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut02/recognised_rooms.png' \
	  'share/docs/guide/img/tut03/edit_model.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut03/edit_model.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/guide/img/tut03/label_window.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/img/tut03/label_window.png' \
	  'share/docs/guide/index.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/index.html' \
	  'share/docs/guide/index.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/index.mkd' \
	  'share/docs/guide/tut01.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut01.html' \
	  'share/docs/guide/tut01.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut01.mkd' \
	  'share/docs/guide/tut02.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut02.html' \
	  'share/docs/guide/tut02.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut02.mkd' \
	  'share/docs/guide/tut03.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut03.html' \
	  'share/docs/guide/tut03.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut03.mkd' \
	  'share/docs/guide/tut04.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut04.html' \
	  'share/docs/guide/tut04.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/guide/tut04.mkd' \
	  'share/docs/quick/quick.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/quick/quick.html' \
	  'share/docs/quick/quick.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/quick/quick.mkd' \
	  'share/docs/tutorial/ch01.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch01.html' \
	  'share/docs/tutorial/ch01.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch01.mkd' \
	  'share/docs/tutorial/ch02.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch02.html' \
	  'share/docs/tutorial/ch02.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch02.mkd' \
	  'share/docs/tutorial/ch03.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch03.html' \
	  'share/docs/tutorial/ch03.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch03.mkd' \
	  'share/docs/tutorial/ch04.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch04.html' \
	  'share/docs/tutorial/ch04.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch04.mkd' \
	  'share/docs/tutorial/ch05.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch05.html' \
	  'share/docs/tutorial/ch05.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch05.mkd' \
	  'share/docs/tutorial/ch06.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch06.html' \
	  'share/docs/tutorial/ch06.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch06.mkd' \
	  'share/docs/tutorial/ch07.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch07.html' \
	  'share/docs/tutorial/ch07.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch07.mkd' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/tutorial/ch08.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch08.html' \
	  'share/docs/tutorial/ch08.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch08.mkd' \
	  'share/docs/tutorial/ch09.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch09.html' \
	  'share/docs/tutorial/ch09.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch09.mkd' \
	  'share/docs/tutorial/ch10.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch10.html' \
	  'share/docs/tutorial/ch10.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch10.mkd' \
	  'share/docs/tutorial/ch11.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch11.html' \
	  'share/docs/tutorial/ch11.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch11.mkd' \
	  'share/docs/tutorial/ch12.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch12.html' \
	  'share/docs/tutorial/ch12.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch12.mkd' \
	  'share/docs/tutorial/ch13.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch13.html' \
	  'share/docs/tutorial/ch13.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch13.mkd' \
	  'share/docs/tutorial/ch14.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch14.html' \
	  'share/docs/tutorial/ch14.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch14.mkd' \
	  'share/docs/tutorial/ch15.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch15.html' \
	  'share/docs/tutorial/ch15.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch15.mkd' \
	  'share/docs/tutorial/ch16.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch16.html' \
	  'share/docs/tutorial/ch16.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch16.mkd' \
	  'share/docs/tutorial/ch17.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch17.html' \
	  'share/docs/tutorial/ch17.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch17.mkd' \
	  'share/docs/tutorial/ch18.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch18.html' \
	  'share/docs/tutorial/ch18.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch18.mkd' \
	  'share/docs/tutorial/ch19.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch19.html' \
	  'share/docs/tutorial/ch19.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch19.mkd' \
	  'share/docs/tutorial/ch20.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch20.html' \
	  'share/docs/tutorial/ch20.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch20.mkd' \
	  'share/docs/tutorial/ch21.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch21.html' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/docs/tutorial/ch21.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/ch21.mkd' \
	  'share/docs/tutorial/img/index/axmud_logo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/img/index/axmud_logo.png' \
	  'share/docs/tutorial/index.html' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/index.html' \
	  'share/docs/tutorial/index.mkd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/docs/tutorial/index.mkd' \
	  'share/help/COPYING' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/COPYING' \
	  'share/help/axbasic/func/abbrevdir_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/abbrevdir_' \
	  'share/help/axbasic/func/abs' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/abs' \
	  'share/help/axbasic/func/acos' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/acos' \
	  'share/help/axbasic/func/addfirstroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/addfirstroom' \
	  'share/help/axbasic/func/addlabel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/addlabel' \
	  'share/help/axbasic/func/addregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/addregion' \
	  'share/help/axbasic/func/addroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/addroom' \
	  'share/help/axbasic/func/addtempregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/addtempregion' \
	  'share/help/axbasic/func/angle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/angle' \
	  'share/help/axbasic/func/asc' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/asc' \
	  'share/help/axbasic/func/asin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/asin' \
	  'share/help/axbasic/func/atn' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/atn' \
	  'share/help/axbasic/func/ceil' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ceil' \
	  'share/help/axbasic/func/chr_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/chr_' \
	  'share/help/axbasic/func/clientdate_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/clientdate_' \
	  'share/help/axbasic/func/clientname_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/clientname_' \
	  'share/help/axbasic/func/clientversion_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/clientversion_' \
	  'share/help/axbasic/func/closemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/closemap' \
	  'share/help/axbasic/func/cos' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/cos' \
	  'share/help/axbasic/func/cosh' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/cosh' \
	  'share/help/axbasic/func/cot' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/cot' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/func/counttask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/counttask' \
	  'share/help/axbasic/func/cpos' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/cpos' \
	  'share/help/axbasic/func/cposr' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/cposr' \
	  'share/help/axbasic/func/csc' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/csc' \
	  'share/help/axbasic/func/date' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/date' \
	  'share/help/axbasic/func/date_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/date_' \
	  'share/help/axbasic/func/deg' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/deg' \
	  'share/help/axbasic/func/delregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/delregion' \
	  'share/help/axbasic/func/deltempregions' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/deltempregions' \
	  'share/help/axbasic/func/eof' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/eof' \
	  'share/help/axbasic/func/epoch' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/epoch' \
	  'share/help/axbasic/func/exp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/exp' \
	  'share/help/axbasic/func/findtask_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/findtask_' \
	  'share/help/axbasic/func/floor' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/floor' \
	  'share/help/axbasic/func/fp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/fp' \
	  'share/help/axbasic/func/getexit_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexit_' \
	  'share/help/axbasic/func/getexitdest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexitdest' \
	  'share/help/axbasic/func/getexitdrawn_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexitdrawn_' \
	  'share/help/axbasic/func/getexitnum' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexitnum' \
	  'share/help/axbasic/func/getexitstatus_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexitstatus_' \
	  'share/help/axbasic/func/getexittwin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexittwin' \
	  'share/help/axbasic/func/getexittype_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getexittype_' \
	  'share/help/axbasic/func/getlight_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getlight_' \
	  'share/help/axbasic/func/getlostroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getlostroom' \
	  'share/help/axbasic/func/getmapmode_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getmapmode_' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/func/getobject_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getobject_' \
	  'share/help/axbasic/func/getobjectalive' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getobjectalive' \
	  'share/help/axbasic/func/getobjectcount' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getobjectcount' \
	  'share/help/axbasic/func/getobjectnoun_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getobjectnoun_' \
	  'share/help/axbasic/func/getobjecttype_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getobjecttype_' \
	  'share/help/axbasic/func/getregion_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getregion_' \
	  'share/help/axbasic/func/getregionnum' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getregionnum' \
	  'share/help/axbasic/func/getroomdescrip_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomdescrip_' \
	  'share/help/axbasic/func/getroomexits' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomexits' \
	  'share/help/axbasic/func/getroomguild_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomguild_' \
	  'share/help/axbasic/func/getroomnum' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomnum' \
	  'share/help/axbasic/func/getroomobjects' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomobjects' \
	  'share/help/axbasic/func/getroomsource_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomsource_' \
	  'share/help/axbasic/func/getroomtag_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomtag_' \
	  'share/help/axbasic/func/getroomtitle_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/getroomtitle_' \
	  'share/help/axbasic/func/iface_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/iface_' \
	  'share/help/axbasic/func/ifacecount' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacecount' \
	  'share/help/axbasic/func/ifacedata_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacedata_' \
	  'share/help/axbasic/func/ifacedefined' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacedefined' \
	  'share/help/axbasic/func/ifacename_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacename_' \
	  'share/help/axbasic/func/ifacenum' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacenum' \
	  'share/help/axbasic/func/ifacepop_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacepop_' \
	  'share/help/axbasic/func/ifacepos' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacepos' \
	  'share/help/axbasic/func/ifaceselect_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifaceselect_' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/func/ifaceshift_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifaceshift_' \
	  'share/help/axbasic/func/ifacestrings' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacestrings' \
	  'share/help/axbasic/func/ifacetext_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacetext_' \
	  'share/help/axbasic/func/ifacetime' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacetime' \
	  'share/help/axbasic/func/ifacetype_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ifacetype_' \
	  'share/help/axbasic/func/int' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/int' \
	  'share/help/axbasic/func/ip' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ip' \
	  'share/help/axbasic/func/ip_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ip_' \
	  'share/help/axbasic/func/ismap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ismap' \
	  'share/help/axbasic/func/isscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/isscript' \
	  'share/help/axbasic/func/istask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/istask' \
	  'share/help/axbasic/func/iswin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/iswin' \
	  'share/help/axbasic/func/lcase_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/lcase_' \
	  'share/help/axbasic/func/left_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/left_' \
	  'share/help/axbasic/func/len' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/len' \
	  'share/help/axbasic/func/log' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/log' \
	  'share/help/axbasic/func/log10' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/log10' \
	  'share/help/axbasic/func/log2' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/log2' \
	  'share/help/axbasic/func/ltrim_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ltrim_' \
	  'share/help/axbasic/func/match' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/match' \
	  'share/help/axbasic/func/matchi' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/matchi' \
	  'share/help/axbasic/func/max' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/max' \
	  'share/help/axbasic/func/mid_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/mid_' \
	  'share/help/axbasic/func/min' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/min' \
	  'share/help/axbasic/func/mod' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/mod' \
	  'share/help/axbasic/func/ncpos' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ncpos' \
	  'share/help/axbasic/func/ncposr' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ncposr' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/func/openmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/openmap' \
	  'share/help/axbasic/func/pi' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/pi' \
	  'share/help/axbasic/func/popup_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/popup_' \
	  'share/help/axbasic/func/pos' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/pos' \
	  'share/help/axbasic/func/posr' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/posr' \
	  'share/help/axbasic/func/rad' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/rad' \
	  'share/help/axbasic/func/remainder' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/remainder' \
	  'share/help/axbasic/func/repeat_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/repeat_' \
	  'share/help/axbasic/func/right_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/right_' \
	  'share/help/axbasic/func/rnd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/rnd' \
	  'share/help/axbasic/func/round' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/round' \
	  'share/help/axbasic/func/rtrim_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/rtrim_' \
	  'share/help/axbasic/func/scriptname_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/scriptname_' \
	  'share/help/axbasic/func/sec' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/sec' \
	  'share/help/axbasic/func/setlight' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/setlight' \
	  'share/help/axbasic/func/setmapmode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/setmapmode' \
	  'share/help/axbasic/func/setregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/setregion' \
	  'share/help/axbasic/func/setregionnum' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/setregionnum' \
	  'share/help/axbasic/func/setroomnum' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/setroomnum' \
	  'share/help/axbasic/func/setroomtagged' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/setroomtagged' \
	  'share/help/axbasic/func/sgn' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/sgn' \
	  'share/help/axbasic/func/showprofile_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/showprofile_' \
	  'share/help/axbasic/func/sin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/sin' \
	  'share/help/axbasic/func/sinh' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/sinh' \
	  'share/help/axbasic/func/sqr' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/sqr' \
	  'share/help/axbasic/func/str_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/str_' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/func/tan' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/tan' \
	  'share/help/axbasic/func/tanh' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/tanh' \
	  'share/help/axbasic/func/testpat' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/testpat' \
	  'share/help/axbasic/func/testpat_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/testpat_' \
	  'share/help/axbasic/func/time' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/time' \
	  'share/help/axbasic/func/time_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/time_' \
	  'share/help/axbasic/func/timestamp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/timestamp' \
	  'share/help/axbasic/func/trim_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/trim_' \
	  'share/help/axbasic/func/trunc' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/trunc' \
	  'share/help/axbasic/func/ucase_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/ucase_' \
	  'share/help/axbasic/func/unabbrevdir_' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/unabbrevdir_' \
	  'share/help/axbasic/func/val' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/val' \
	  'share/help/axbasic/func/version' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/func/version' \
	  'share/help/axbasic/keyword/addalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addalias' \
	  'share/help/axbasic/keyword/addcongauge' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addcongauge' \
	  'share/help/axbasic/keyword/addconstatus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addconstatus' \
	  'share/help/axbasic/keyword/addgauge' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addgauge' \
	  'share/help/axbasic/keyword/addhook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addhook' \
	  'share/help/axbasic/keyword/addmacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addmacro' \
	  'share/help/axbasic/keyword/addstatus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addstatus' \
	  'share/help/axbasic/keyword/addtimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addtimer' \
	  'share/help/axbasic/keyword/addtrig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/addtrig' \
	  'share/help/axbasic/keyword/beep' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/beep' \
	  'share/help/axbasic/keyword/break' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/break' \
	  'share/help/axbasic/keyword/bypass' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/bypass' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/call' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/call' \
	  'share/help/axbasic/keyword/case' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/case' \
	  'share/help/axbasic/keyword/client' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/client' \
	  'share/help/axbasic/keyword/close' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/close' \
	  'share/help/axbasic/keyword/closewin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/closewin' \
	  'share/help/axbasic/keyword/cls' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/cls' \
	  'share/help/axbasic/keyword/data' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/data' \
	  'share/help/axbasic/keyword/debug' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/debug' \
	  'share/help/axbasic/keyword/def' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/def' \
	  'share/help/axbasic/keyword/delalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/delalias' \
	  'share/help/axbasic/keyword/delgauge' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/delgauge' \
	  'share/help/axbasic/keyword/delhook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/delhook' \
	  'share/help/axbasic/keyword/deliface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/deliface' \
	  'share/help/axbasic/keyword/delmacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/delmacro' \
	  'share/help/axbasic/keyword/delstatus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/delstatus' \
	  'share/help/axbasic/keyword/deltimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/deltimer' \
	  'share/help/axbasic/keyword/deltrig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/deltrig' \
	  'share/help/axbasic/keyword/dim' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/dim' \
	  'share/help/axbasic/keyword/do' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/do' \
	  'share/help/axbasic/keyword/else' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/else' \
	  'share/help/axbasic/keyword/elseif' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/elseif' \
	  'share/help/axbasic/keyword/emptywin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/emptywin' \
	  'share/help/axbasic/keyword/end' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/end' \
	  'share/help/axbasic/keyword/erase' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/erase' \
	  'share/help/axbasic/keyword/error' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/error' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/exit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/exit' \
	  'share/help/axbasic/keyword/flashwin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/flashwin' \
	  'share/help/axbasic/keyword/for' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/for' \
	  'share/help/axbasic/keyword/global' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/global' \
	  'share/help/axbasic/keyword/gosub' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/gosub' \
	  'share/help/axbasic/keyword/goto' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/goto' \
	  'share/help/axbasic/keyword/help' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/help' \
	  'share/help/axbasic/keyword/if' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/if' \
	  'share/help/axbasic/keyword/input' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/input' \
	  'share/help/axbasic/keyword/let' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/let' \
	  'share/help/axbasic/keyword/local' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/local' \
	  'share/help/axbasic/keyword/login' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/login' \
	  'share/help/axbasic/keyword/loop' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/loop' \
	  'share/help/axbasic/keyword/move' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/move' \
	  'share/help/axbasic/keyword/multi' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/multi' \
	  'share/help/axbasic/keyword/next' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/next' \
	  'share/help/axbasic/keyword/nextiface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/nextiface' \
	  'share/help/axbasic/keyword/on' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/on' \
	  'share/help/axbasic/keyword/open' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/open' \
	  'share/help/axbasic/keyword/openentry' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/openentry' \
	  'share/help/axbasic/keyword/openwin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/openwin' \
	  'share/help/axbasic/keyword/option' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/option' \
	  'share/help/axbasic/keyword/paintwin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/paintwin' \
	  'share/help/axbasic/keyword/pause' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pause' \
	  'share/help/axbasic/keyword/peek' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peek' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/peekequals' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekequals' \
	  'share/help/axbasic/keyword/peekexists' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekexists' \
	  'share/help/axbasic/keyword/peekfind' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekfind' \
	  'share/help/axbasic/keyword/peekfirst' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekfirst' \
	  'share/help/axbasic/keyword/peekget' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekget' \
	  'share/help/axbasic/keyword/peekindex' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekindex' \
	  'share/help/axbasic/keyword/peekkeys' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekkeys' \
	  'share/help/axbasic/keyword/peeklast' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peeklast' \
	  'share/help/axbasic/keyword/peekmatch' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekmatch' \
	  'share/help/axbasic/keyword/peeknumber' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peeknumber' \
	  'share/help/axbasic/keyword/peekpairs' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekpairs' \
	  'share/help/axbasic/keyword/peekshow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekshow' \
	  'share/help/axbasic/keyword/peekvalues' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/peekvalues' \
	  'share/help/axbasic/keyword/perl' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/perl' \
	  'share/help/axbasic/keyword/play' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/play' \
	  'share/help/axbasic/keyword/poke' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/poke' \
	  'share/help/axbasic/keyword/pokeadd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeadd' \
	  'share/help/axbasic/keyword/pokedec' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokedec' \
	  'share/help/axbasic/keyword/pokedechash' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokedechash' \
	  'share/help/axbasic/keyword/pokedelete' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokedelete' \
	  'share/help/axbasic/keyword/pokedivide' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokedivide' \
	  'share/help/axbasic/keyword/pokeempty' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeempty' \
	  'share/help/axbasic/keyword/pokefalse' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokefalse' \
	  'share/help/axbasic/keyword/pokeinc' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeinc' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/pokeinchash' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeinchash' \
	  'share/help/axbasic/keyword/pokeint' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeint' \
	  'share/help/axbasic/keyword/pokeminus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeminus' \
	  'share/help/axbasic/keyword/pokemultiply' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokemultiply' \
	  'share/help/axbasic/keyword/pokeplus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeplus' \
	  'share/help/axbasic/keyword/pokepop' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokepop' \
	  'share/help/axbasic/keyword/pokepush' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokepush' \
	  'share/help/axbasic/keyword/pokereplace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokereplace' \
	  'share/help/axbasic/keyword/pokeset' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeset' \
	  'share/help/axbasic/keyword/pokeshift' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeshift' \
	  'share/help/axbasic/keyword/poketrue' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/poketrue' \
	  'share/help/axbasic/keyword/pokeundef' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeundef' \
	  'share/help/axbasic/keyword/pokeunshift' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pokeunshift' \
	  'share/help/axbasic/keyword/pop' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/pop' \
	  'share/help/axbasic/keyword/print' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/print' \
	  'share/help/axbasic/keyword/profile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/profile' \
	  'share/help/axbasic/keyword/push' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/push' \
	  'share/help/axbasic/keyword/randomize' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/randomize' \
	  'share/help/axbasic/keyword/read' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/read' \
	  'share/help/axbasic/keyword/redim' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/redim' \
	  'share/help/axbasic/keyword/relay' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/relay' \
	  'share/help/axbasic/keyword/rem' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/rem' \
	  'share/help/axbasic/keyword/reset' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/reset' \
	  'share/help/axbasic/keyword/restore' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/restore' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/return' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/return' \
	  'share/help/axbasic/keyword/revpath' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/revpath' \
	  'share/help/axbasic/keyword/select' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/select' \
	  'share/help/axbasic/keyword/send' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/send' \
	  'share/help/axbasic/keyword/setalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/setalias' \
	  'share/help/axbasic/keyword/setgauge' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/setgauge' \
	  'share/help/axbasic/keyword/sethook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sethook' \
	  'share/help/axbasic/keyword/setmacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/setmacro' \
	  'share/help/axbasic/keyword/setstatus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/setstatus' \
	  'share/help/axbasic/keyword/settimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/settimer' \
	  'share/help/axbasic/keyword/settrig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/settrig' \
	  'share/help/axbasic/keyword/shift' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/shift' \
	  'share/help/axbasic/keyword/skipiface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/skipiface' \
	  'share/help/axbasic/keyword/sleep' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sleep' \
	  'share/help/axbasic/keyword/sort' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sort' \
	  'share/help/axbasic/keyword/sortcase' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sortcase' \
	  'share/help/axbasic/keyword/sortcaser' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sortcaser' \
	  'share/help/axbasic/keyword/sortr' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sortr' \
	  'share/help/axbasic/keyword/speak' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/speak' \
	  'share/help/axbasic/keyword/speed' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/speed' \
	  'share/help/axbasic/keyword/stop' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/stop' \
	  'share/help/axbasic/keyword/sub' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/sub' \
	  'share/help/axbasic/keyword/titlewin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/titlewin' \
	  'share/help/axbasic/keyword/unflashwin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/unflashwin' \
	  'share/help/axbasic/keyword/unshift' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/unshift' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/until' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/until' \
	  'share/help/axbasic/keyword/waitactive' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitactive' \
	  'share/help/axbasic/keyword/waitalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitalias' \
	  'share/help/axbasic/keyword/waitalive' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitalive' \
	  'share/help/axbasic/keyword/waitarrive' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitarrive' \
	  'share/help/axbasic/keyword/waitdead' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitdead' \
	  'share/help/axbasic/keyword/waitep' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitep' \
	  'share/help/axbasic/keyword/waitgp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitgp' \
	  'share/help/axbasic/keyword/waithook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waithook' \
	  'share/help/axbasic/keyword/waithp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waithp' \
	  'share/help/axbasic/keyword/waitmacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitmacro' \
	  'share/help/axbasic/keyword/waitmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitmp' \
	  'share/help/axbasic/keyword/waitnextxp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitnextxp' \
	  'share/help/axbasic/keyword/waitnotactive' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitnotactive' \
	  'share/help/axbasic/keyword/waitpassout' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitpassout' \
	  'share/help/axbasic/keyword/waitscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitscript' \
	  'share/help/axbasic/keyword/waitsleep' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitsleep' \
	  'share/help/axbasic/keyword/waitsp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitsp' \
	  'share/help/axbasic/keyword/waittask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waittask' \
	  'share/help/axbasic/keyword/waittimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waittimer' \
	  'share/help/axbasic/keyword/waittotalxp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waittotalxp' \
	  'share/help/axbasic/keyword/waittrig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waittrig' \
	  'share/help/axbasic/keyword/waitxp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/waitxp' \
	  'share/help/axbasic/keyword/warning' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/warning' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/axbasic/keyword/while' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/while' \
	  'share/help/axbasic/keyword/write' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/write' \
	  'share/help/axbasic/keyword/writewin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/axbasic/keyword/writewin' \
	  'share/help/cmd/aardwolf' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/aardwolf' \
	  'share/help/cmd/abortselfdestruct' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/abortselfdestruct' \
	  'share/help/cmd/about' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/about' \
	  'share/help/cmd/activategrid' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/activategrid' \
	  'share/help/cmd/activateinventory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/activateinventory' \
	  'share/help/cmd/activatestatustask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/activatestatustask' \
	  'share/help/cmd/addalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addalias' \
	  'share/help/cmd/addchannelpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addchannelpattern' \
	  'share/help/cmd/addchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addchar' \
	  'share/help/cmd/addcolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addcolourscheme' \
	  'share/help/cmd/addconfig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addconfig' \
	  'share/help/cmd/addcontact' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addcontact' \
	  'share/help/cmd/addcustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addcustomprofile' \
	  'share/help/cmd/addcustomtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addcustomtask' \
	  'share/help/cmd/adddictionary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/adddictionary' \
	  'share/help/cmd/adddirectory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/adddirectory' \
	  'share/help/cmd/addexit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addexit' \
	  'share/help/cmd/addexitpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addexitpattern' \
	  'share/help/cmd/addguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addguild' \
	  'share/help/cmd/addhashproperty' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addhashproperty' \
	  'share/help/cmd/addhook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addhook' \
	  'share/help/cmd/addinitialplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addinitialplugin' \
	  'share/help/cmd/addinitialscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addinitialscript' \
	  'share/help/cmd/addinitialtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addinitialtask' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/addinitialworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addinitialworkspace' \
	  'share/help/cmd/addlabelstyle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addlabelstyle' \
	  'share/help/cmd/addlistproperty' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addlistproperty' \
	  'share/help/cmd/addmacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addmacro' \
	  'share/help/cmd/addminionstring' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addminionstring' \
	  'share/help/cmd/addmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addmission' \
	  'share/help/cmd/addmodelobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addmodelobject' \
	  'share/help/cmd/addmodifierchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addmodifierchar' \
	  'share/help/cmd/addplayercharacter' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addplayercharacter' \
	  'share/help/cmd/addquest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addquest' \
	  'share/help/cmd/addrace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addrace' \
	  'share/help/cmd/addregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addregion' \
	  'share/help/cmd/addregionscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addregionscheme' \
	  'share/help/cmd/addrelative' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addrelative' \
	  'share/help/cmd/addroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addroom' \
	  'share/help/cmd/addroute' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addroute' \
	  'share/help/cmd/addscalarproperty' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addscalarproperty' \
	  'share/help/cmd/addsecondary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addsecondary' \
	  'share/help/cmd/addsmiley' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addsmiley' \
	  'share/help/cmd/addsoundeffect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addsoundeffect' \
	  'share/help/cmd/addspeedwalk' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addspeedwalk' \
	  'share/help/cmd/addstatuscommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addstatuscommand' \
	  'share/help/cmd/addtasklabel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addtasklabel' \
	  'share/help/cmd/addtaskpackage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addtaskpackage' \
	  'share/help/cmd/addteleport' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addteleport' \
	  'share/help/cmd/addtemplate' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addtemplate' \
	  'share/help/cmd/addtimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addtimer' \
	  'share/help/cmd/addtrigger' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addtrigger' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/addusercommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addusercommand' \
	  'share/help/cmd/addwinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addwinmap' \
	  'share/help/cmd/addwinzone' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addwinzone' \
	  'share/help/cmd/addword' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addword' \
	  'share/help/cmd/addworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addworld' \
	  'share/help/cmd/addzonemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addzonemap' \
	  'share/help/cmd/addzonemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/addzonemodel' \
	  'share/help/cmd/advance' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/advance' \
	  'share/help/cmd/alert' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/alert' \
	  'share/help/cmd/allocateexit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/allocateexit' \
	  'share/help/cmd/alternativeexit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/alternativeexit' \
	  'share/help/cmd/applycolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/applycolourscheme' \
	  'share/help/cmd/applywindowstorage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/applywindowstorage' \
	  'share/help/cmd/asciibell' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/asciibell' \
	  'share/help/cmd/atcp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/atcp' \
	  'share/help/cmd/autobackup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/autobackup' \
	  'share/help/cmd/autosave' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/autosave' \
	  'share/help/cmd/awayfromkeys' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/awayfromkeys' \
	  'share/help/cmd/axbasichelp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/axbasichelp' \
	  'share/help/cmd/backupdata' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/backupdata' \
	  'share/help/cmd/banishwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/banishwindow' \
	  'share/help/cmd/beep' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/beep' \
	  'share/help/cmd/break' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/break' \
	  'share/help/cmd/bypass' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/bypass' \
	  'share/help/cmd/chat' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chat' \
	  'share/help/cmd/chatall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatall' \
	  'share/help/cmd/chatcall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatcall' \
	  'share/help/cmd/chatcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatcommand' \
	  'share/help/cmd/chatdnd' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatdnd' \
	  'share/help/cmd/chatescape' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatescape' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/chatgroup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatgroup' \
	  'share/help/cmd/chathangup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chathangup' \
	  'share/help/cmd/chatignore' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatignore' \
	  'share/help/cmd/chatinfo' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatinfo' \
	  'share/help/cmd/chatlisten' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatlisten' \
	  'share/help/cmd/chatmcall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatmcall' \
	  'share/help/cmd/chatpeek' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatpeek' \
	  'share/help/cmd/chatping' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatping' \
	  'share/help/cmd/chatrequest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatrequest' \
	  'share/help/cmd/chatsendfile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsendfile' \
	  'share/help/cmd/chatset' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatset' \
	  'share/help/cmd/chatsetemail' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsetemail' \
	  'share/help/cmd/chatsetgroup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsetgroup' \
	  'share/help/cmd/chatseticon' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatseticon' \
	  'share/help/cmd/chatsetname' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsetname' \
	  'share/help/cmd/chatsetsmiley' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsetsmiley' \
	  'share/help/cmd/chatsnoop' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsnoop' \
	  'share/help/cmd/chatstopfile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatstopfile' \
	  'share/help/cmd/chatsubmit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatsubmit' \
	  'share/help/cmd/chatzcall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/chatzcall' \
	  'share/help/cmd/checkscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/checkscript' \
	  'share/help/cmd/circuit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/circuit' \
	  'share/help/cmd/clearhistory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clearhistory' \
	  'share/help/cmd/cleartextview' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/cleartextview' \
	  'share/help/cmd/clearwindowstorage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clearwindowstorage' \
	  'share/help/cmd/clientcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clientcommand' \
	  'share/help/cmd/clonechar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonechar' \
	  'share/help/cmd/cloneconfig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/cloneconfig' \
	  'share/help/cmd/clonecustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonecustomprofile' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/clonedictionary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonedictionary' \
	  'share/help/cmd/cloneguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/cloneguild' \
	  'share/help/cmd/clonemission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonemission' \
	  'share/help/cmd/clonequest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonequest' \
	  'share/help/cmd/clonerace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonerace' \
	  'share/help/cmd/clonetemplate' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonetemplate' \
	  'share/help/cmd/clonewinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonewinmap' \
	  'share/help/cmd/cloneworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/cloneworld' \
	  'share/help/cmd/clonezonemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/clonezonemap' \
	  'share/help/cmd/closeaboutwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/closeaboutwindow' \
	  'share/help/cmd/closeautomapper' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/closeautomapper' \
	  'share/help/cmd/closefreewindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/closefreewindow' \
	  'share/help/cmd/closeobjectviewer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/closeobjectviewer' \
	  'share/help/cmd/closetaskwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/closetaskwindow' \
	  'share/help/cmd/closewindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/closewindow' \
	  'share/help/cmd/collectcontentslines' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/collectcontentslines' \
	  'share/help/cmd/collectunknownwords' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/collectunknownwords' \
	  'share/help/cmd/commandbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/commandbuffer' \
	  'share/help/cmd/commandseparator' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/commandseparator' \
	  'share/help/cmd/comment' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/comment' \
	  'share/help/cmd/compass' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/compass' \
	  'share/help/cmd/compressmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/compressmodel' \
	  'share/help/cmd/configureterminal' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/configureterminal' \
	  'share/help/cmd/connect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/connect' \
	  'share/help/cmd/converttext' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/converttext' \
	  'share/help/cmd/copyrecording' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/copyrecording' \
	  'share/help/cmd/crawl' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/crawl' \
	  'share/help/cmd/debugconnection' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/debugconnection' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/debugtoggle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/debugtoggle' \
	  'share/help/cmd/deletealias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletealias' \
	  'share/help/cmd/deletecage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletecage' \
	  'share/help/cmd/deletechannelpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletechannelpattern' \
	  'share/help/cmd/deletechar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletechar' \
	  'share/help/cmd/deletecolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletecolourscheme' \
	  'share/help/cmd/deleteconfig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteconfig' \
	  'share/help/cmd/deletecontact' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletecontact' \
	  'share/help/cmd/deletecustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletecustomprofile' \
	  'share/help/cmd/deletecustomtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletecustomtask' \
	  'share/help/cmd/deletedictionary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletedictionary' \
	  'share/help/cmd/deletedirectory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletedirectory' \
	  'share/help/cmd/deleteexit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteexit' \
	  'share/help/cmd/deleteexitpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteexitpattern' \
	  'share/help/cmd/deleteguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteguild' \
	  'share/help/cmd/deletehook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletehook' \
	  'share/help/cmd/deleteinitialplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteinitialplugin' \
	  'share/help/cmd/deleteinitialscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteinitialscript' \
	  'share/help/cmd/deleteinitialtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteinitialtask' \
	  'share/help/cmd/deleteinitialworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteinitialworkspace' \
	  'share/help/cmd/deletelabelstyle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletelabelstyle' \
	  'share/help/cmd/deletemacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletemacro' \
	  'share/help/cmd/deleteminionstring' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteminionstring' \
	  'share/help/cmd/deletemission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletemission' \
	  'share/help/cmd/deletemodelobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletemodelobject' \
	  'share/help/cmd/deletemodifierchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletemodifierchar' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/deleteplayercharacter' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteplayercharacter' \
	  'share/help/cmd/deleteproperty' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteproperty' \
	  'share/help/cmd/deletequest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletequest' \
	  'share/help/cmd/deleterace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleterace' \
	  'share/help/cmd/deleterecording' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleterecording' \
	  'share/help/cmd/deleteregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteregion' \
	  'share/help/cmd/deleteregionscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteregionscheme' \
	  'share/help/cmd/deleterelative' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleterelative' \
	  'share/help/cmd/deleteroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteroom' \
	  'share/help/cmd/deleteroute' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteroute' \
	  'share/help/cmd/deletesecondary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletesecondary' \
	  'share/help/cmd/deletesmiley' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletesmiley' \
	  'share/help/cmd/deletesoundeffect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletesoundeffect' \
	  'share/help/cmd/deletespeedwalk' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletespeedwalk' \
	  'share/help/cmd/deletestatuscommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletestatuscommand' \
	  'share/help/cmd/deletetasklabel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletetasklabel' \
	  'share/help/cmd/deletetaskpackage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletetaskpackage' \
	  'share/help/cmd/deleteteleport' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteteleport' \
	  'share/help/cmd/deletetemplate' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletetemplate' \
	  'share/help/cmd/deletetemporaryregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletetemporaryregion' \
	  'share/help/cmd/deletetimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletetimer' \
	  'share/help/cmd/deletetrigger' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletetrigger' \
	  'share/help/cmd/deleteusercommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteusercommand' \
	  'share/help/cmd/deletewinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletewinmap' \
	  'share/help/cmd/deletewinzone' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletewinzone' \
	  'share/help/cmd/deleteword' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteword' \
	  'share/help/cmd/deleteworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deleteworld' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/deletezonemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletezonemap' \
	  'share/help/cmd/deletezonemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/deletezonemodel' \
	  'share/help/cmd/disableactiveinterface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disableactiveinterface' \
	  'share/help/cmd/disableplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disableplugin' \
	  'share/help/cmd/disablesaveload' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disablesaveload' \
	  'share/help/cmd/disablesaveworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disablesaveworld' \
	  'share/help/cmd/disactivategrid' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disactivategrid' \
	  'share/help/cmd/disactivateinventory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disactivateinventory' \
	  'share/help/cmd/disactivatestatustask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/disactivatestatustask' \
	  'share/help/cmd/displaybuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/displaybuffer' \
	  'share/help/cmd/drive' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/drive' \
	  'share/help/cmd/dropall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dropall' \
	  'share/help/cmd/dumpascii' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpascii' \
	  'share/help/cmd/dumpcommandbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpcommandbuffer' \
	  'share/help/cmd/dumpdisplaybuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpdisplaybuffer' \
	  'share/help/cmd/dumpexitmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpexitmodel' \
	  'share/help/cmd/dumpinstructionbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpinstructionbuffer' \
	  'share/help/cmd/dumpmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpmodel' \
	  'share/help/cmd/dumpwindowstorage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/dumpwindowstorage' \
	  'share/help/cmd/echo' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/echo' \
	  'share/help/cmd/editactiveinterface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editactiveinterface' \
	  'share/help/cmd/editcage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcage' \
	  'share/help/cmd/editcagemask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcagemask' \
	  'share/help/cmd/editchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editchar' \
	  'share/help/cmd/editclient' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editclient' \
	  'share/help/cmd/editcolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcolourscheme' \
	  'share/help/cmd/editcommandbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcommandbuffer' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/editconfig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editconfig' \
	  'share/help/cmd/editcontact' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcontact' \
	  'share/help/cmd/editcustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcustomprofile' \
	  'share/help/cmd/editcustomtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editcustomtask' \
	  'share/help/cmd/editdictionary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editdictionary' \
	  'share/help/cmd/editdisplaybuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editdisplaybuffer' \
	  'share/help/cmd/editexit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editexit' \
	  'share/help/cmd/editfreewindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editfreewindow' \
	  'share/help/cmd/editgrid' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editgrid' \
	  'share/help/cmd/editguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editguild' \
	  'share/help/cmd/editinitialtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editinitialtask' \
	  'share/help/cmd/editinstructionbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editinstructionbuffer' \
	  'share/help/cmd/editinterfacemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editinterfacemodel' \
	  'share/help/cmd/editlabelstyle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editlabelstyle' \
	  'share/help/cmd/editmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editmission' \
	  'share/help/cmd/editmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editmodel' \
	  'share/help/cmd/editmodelobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editmodelobject' \
	  'share/help/cmd/editpainter' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editpainter' \
	  'share/help/cmd/editquest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editquest' \
	  'share/help/cmd/editquick' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editquick' \
	  'share/help/cmd/editrace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editrace' \
	  'share/help/cmd/editregionmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editregionmap' \
	  'share/help/cmd/editregionscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editregionscheme' \
	  'share/help/cmd/editroomcomponent' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editroomcomponent' \
	  'share/help/cmd/editroute' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editroute' \
	  'share/help/cmd/editscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editscript' \
	  'share/help/cmd/editsession' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editsession' \
	  'share/help/cmd/edittask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/edittask' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/edittemplate' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/edittemplate' \
	  'share/help/cmd/edittoolbar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/edittoolbar' \
	  'share/help/cmd/editwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editwindow' \
	  'share/help/cmd/editwindowstrip' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editwindowstrip' \
	  'share/help/cmd/editwindowtable' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editwindowtable' \
	  'share/help/cmd/editwinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editwinmap' \
	  'share/help/cmd/editwinzone' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editwinzone' \
	  'share/help/cmd/editworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editworkspace' \
	  'share/help/cmd/editworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editworld' \
	  'share/help/cmd/editzonemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editzonemap' \
	  'share/help/cmd/editzonemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/editzonemodel' \
	  'share/help/cmd/emergencysave' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emergencysave' \
	  'share/help/cmd/emote' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emote' \
	  'share/help/cmd/emoteall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emoteall' \
	  'share/help/cmd/emotegroup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emotegroup' \
	  'share/help/cmd/emptychannelswindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emptychannelswindow' \
	  'share/help/cmd/emptycontentslines' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emptycontentslines' \
	  'share/help/cmd/emptydivertwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emptydivertwindow' \
	  'share/help/cmd/emptyregion' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emptyregion' \
	  'share/help/cmd/emptyunknownwords' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emptyunknownwords' \
	  'share/help/cmd/emptywatchwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/emptywatchwindow' \
	  'share/help/cmd/enableactiveinterface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/enableactiveinterface' \
	  'share/help/cmd/enableplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/enableplugin' \
	  'share/help/cmd/exit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/exit' \
	  'share/help/cmd/exitall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/exitall' \
	  'share/help/cmd/exportdata' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/exportdata' \
	  'share/help/cmd/exportfiles' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/exportfiles' \
	  'share/help/cmd/findreset' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/findreset' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/findtext' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/findtext' \
	  'share/help/cmd/finishquest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/finishquest' \
	  'share/help/cmd/first' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/first' \
	  'share/help/cmd/fixwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/fixwindow' \
	  'share/help/cmd/flashwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/flashwindow' \
	  'share/help/cmd/forcelookup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/forcelookup' \
	  'share/help/cmd/freekeys' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/freekeys' \
	  'share/help/cmd/freezetask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/freezetask' \
	  'share/help/cmd/getip' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/getip' \
	  'share/help/cmd/gmcp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/gmcp' \
	  'share/help/cmd/go' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/go' \
	  'share/help/cmd/grabwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/grabwindow' \
	  'share/help/cmd/haltmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/haltmission' \
	  'share/help/cmd/haltreplay' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/haltreplay' \
	  'share/help/cmd/halttask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/halttask' \
	  'share/help/cmd/help' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/help' \
	  'share/help/cmd/helptest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/helptest' \
	  'share/help/cmd/hijackkeys' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/hijackkeys' \
	  'share/help/cmd/hint' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/hint' \
	  'share/help/cmd/ignoreroomcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/ignoreroomcommand' \
	  'share/help/cmd/iinteract' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/iinteract' \
	  'share/help/cmd/importdata' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/importdata' \
	  'share/help/cmd/importfiles' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/importfiles' \
	  'share/help/cmd/importplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/importplugin' \
	  'share/help/cmd/inputzmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/inputzmp' \
	  'share/help/cmd/insertfailedexit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/insertfailedexit' \
	  'share/help/cmd/insertlook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/insertlook' \
	  'share/help/cmd/insertrecording' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/insertrecording' \
	  'share/help/cmd/instructionbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/instructionbuffer' \
	  'share/help/cmd/interact' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/interact' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/interactall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/interactall' \
	  'share/help/cmd/interactmall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/interactmall' \
	  'share/help/cmd/intervalrepeat' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/intervalrepeat' \
	  'share/help/cmd/kill' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/kill' \
	  'share/help/cmd/killall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/killall' \
	  'share/help/cmd/killmall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/killmall' \
	  'share/help/cmd/killtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/killtask' \
	  'share/help/cmd/kkill' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/kkill' \
	  'share/help/cmd/last' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/last' \
	  'share/help/cmd/layerdown' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/layerdown' \
	  'share/help/cmd/layerup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/layerup' \
	  'share/help/cmd/listactiveinterface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listactiveinterface' \
	  'share/help/cmd/listadvance' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listadvance' \
	  'share/help/cmd/listadvancehistory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listadvancehistory' \
	  'share/help/cmd/listalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listalias' \
	  'share/help/cmd/listattribute' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listattribute' \
	  'share/help/cmd/listautosecondary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listautosecondary' \
	  'share/help/cmd/listautoworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listautoworld' \
	  'share/help/cmd/listbasicworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listbasicworld' \
	  'share/help/cmd/listcage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcage' \
	  'share/help/cmd/listchannelpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listchannelpattern' \
	  'share/help/cmd/listchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listchar' \
	  'share/help/cmd/listcolour' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcolour' \
	  'share/help/cmd/listcolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcolourscheme' \
	  'share/help/cmd/listconfig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listconfig' \
	  'share/help/cmd/listcontact' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcontact' \
	  'share/help/cmd/listcontentslines' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcontentslines' \
	  'share/help/cmd/listcustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcustomprofile' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/listcustomtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listcustomtask' \
	  'share/help/cmd/listdatadirectory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listdatadirectory' \
	  'share/help/cmd/listdictionary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listdictionary' \
	  'share/help/cmd/listdirection' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listdirection' \
	  'share/help/cmd/listdirectory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listdirectory' \
	  'share/help/cmd/listexitmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listexitmodel' \
	  'share/help/cmd/listexitpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listexitpattern' \
	  'share/help/cmd/listfavouriteworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listfavouriteworld' \
	  'share/help/cmd/listfreewindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listfreewindow' \
	  'share/help/cmd/listgrid' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listgrid' \
	  'share/help/cmd/listguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listguild' \
	  'share/help/cmd/listguildskills' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listguildskills' \
	  'share/help/cmd/listhook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listhook' \
	  'share/help/cmd/listinitialplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listinitialplugin' \
	  'share/help/cmd/listinitialscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listinitialscript' \
	  'share/help/cmd/listinitialtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listinitialtask' \
	  'share/help/cmd/listinitialworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listinitialworkspace' \
	  'share/help/cmd/listinterfacemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listinterfacemodel' \
	  'share/help/cmd/listkeycode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listkeycode' \
	  'share/help/cmd/listkeycodealternative' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listkeycodealternative' \
	  'share/help/cmd/listlabelstyle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listlabelstyle' \
	  'share/help/cmd/listlookup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listlookup' \
	  'share/help/cmd/listmacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listmacro' \
	  'share/help/cmd/listminionstring' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listminionstring' \
	  'share/help/cmd/listmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listmission' \
	  'share/help/cmd/listmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listmodel' \
	  'share/help/cmd/listmodifierchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listmodifierchar' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/listmonitorobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listmonitorobject' \
	  'share/help/cmd/listorphan' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listorphan' \
	  'share/help/cmd/listpanel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listpanel' \
	  'share/help/cmd/listplayercharacter' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listplayercharacter' \
	  'share/help/cmd/listplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listplugin' \
	  'share/help/cmd/listprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listprofile' \
	  'share/help/cmd/listprofilepriority' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listprofilepriority' \
	  'share/help/cmd/listproperty' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listproperty' \
	  'share/help/cmd/listprotectobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listprotectobject' \
	  'share/help/cmd/listquest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listquest' \
	  'share/help/cmd/listrace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listrace' \
	  'share/help/cmd/listrecording' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listrecording' \
	  'share/help/cmd/listregionscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listregionscheme' \
	  'share/help/cmd/listreserved' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listreserved' \
	  'share/help/cmd/listrestoreworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listrestoreworld' \
	  'share/help/cmd/listroomcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listroomcommand' \
	  'share/help/cmd/listroomcomponent' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listroomcomponent' \
	  'share/help/cmd/listroute' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listroute' \
	  'share/help/cmd/listsession' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listsession' \
	  'share/help/cmd/listsmiley' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listsmiley' \
	  'share/help/cmd/listsoundeffect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listsoundeffect' \
	  'share/help/cmd/listsourcecode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listsourcecode' \
	  'share/help/cmd/listspeedwalk' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listspeedwalk' \
	  'share/help/cmd/liststatuscommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/liststatuscommand' \
	  'share/help/cmd/listsystemcolour' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listsystemcolour' \
	  'share/help/cmd/listtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtask' \
	  'share/help/cmd/listtasklabel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtasklabel' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/listtaskpackage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtaskpackage' \
	  'share/help/cmd/listteleport' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listteleport' \
	  'share/help/cmd/listtemplate' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtemplate' \
	  'share/help/cmd/listtextview' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtextview' \
	  'share/help/cmd/listtimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtimer' \
	  'share/help/cmd/listtoolbar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtoolbar' \
	  'share/help/cmd/listtrigger' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listtrigger' \
	  'share/help/cmd/listunknownwords' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listunknownwords' \
	  'share/help/cmd/listusercommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listusercommand' \
	  'share/help/cmd/listwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listwindow' \
	  'share/help/cmd/listwindowcontrols' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listwindowcontrols' \
	  'share/help/cmd/listwindowstrip' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listwindowstrip' \
	  'share/help/cmd/listwindowtable' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listwindowtable' \
	  'share/help/cmd/listwinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listwinmap' \
	  'share/help/cmd/listwinzone' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listwinzone' \
	  'share/help/cmd/listword' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listword' \
	  'share/help/cmd/listworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listworkspace' \
	  'share/help/cmd/listworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listworld' \
	  'share/help/cmd/listzonemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listzonemap' \
	  'share/help/cmd/listzonemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/listzonemodel' \
	  'share/help/cmd/load' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/load' \
	  'share/help/cmd/loadbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/loadbuffer' \
	  'share/help/cmd/loadplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/loadplugin' \
	  'share/help/cmd/locateroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/locateroom' \
	  'share/help/cmd/locatorwizard' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/locatorwizard' \
	  'share/help/cmd/log' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/log' \
	  'share/help/cmd/login' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/login' \
	  'share/help/cmd/maxsession' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/maxsession' \
	  'share/help/cmd/mcp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/mcp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/mergemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/mergemodel' \
	  'share/help/cmd/mission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/mission' \
	  'share/help/cmd/mnes' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/mnes' \
	  'share/help/cmd/modelreport' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modelreport' \
	  'share/help/cmd/modifyalias' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyalias' \
	  'share/help/cmd/modifycolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifycolourscheme' \
	  'share/help/cmd/modifyconfig' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyconfig' \
	  'share/help/cmd/modifyhook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyhook' \
	  'share/help/cmd/modifyinitialworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyinitialworkspace' \
	  'share/help/cmd/modifymacro' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifymacro' \
	  'share/help/cmd/modifyprimary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyprimary' \
	  'share/help/cmd/modifyquest' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyquest' \
	  'share/help/cmd/modifysecondary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifysecondary' \
	  'share/help/cmd/modifytimer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifytimer' \
	  'share/help/cmd/modifytrigger' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifytrigger' \
	  'share/help/cmd/modifywinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifywinmap' \
	  'share/help/cmd/modifywinzone' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifywinzone' \
	  'share/help/cmd/modifyzonemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/modifyzonemodel' \
	  'share/help/cmd/monitorobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/monitorobject' \
	  'share/help/cmd/moveactiveinterface' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/moveactiveinterface' \
	  'share/help/cmd/movedirection' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/movedirection' \
	  'share/help/cmd/movewindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/movewindow' \
	  'share/help/cmd/msdp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/msdp' \
	  'share/help/cmd/msp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/msp' \
	  'share/help/cmd/mssp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/mssp' \
	  'share/help/cmd/multi' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/multi' \
	  'share/help/cmd/mxp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/mxp' \
	  'share/help/cmd/noticeroomcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/noticeroomcommand' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/nudgemission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/nudgemission' \
	  'share/help/cmd/openaboutwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/openaboutwindow' \
	  'share/help/cmd/openautomapper' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/openautomapper' \
	  'share/help/cmd/openobjectviewer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/openobjectviewer' \
	  'share/help/cmd/opentaskwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/opentaskwindow' \
	  'share/help/cmd/panic' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/panic' \
	  'share/help/cmd/pauserecording' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/pauserecording' \
	  'share/help/cmd/pausetask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/pausetask' \
	  'share/help/cmd/peek' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/peek' \
	  'share/help/cmd/peekhelp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/peekhelp' \
	  'share/help/cmd/perl' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/perl' \
	  'share/help/cmd/permalert' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/permalert' \
	  'share/help/cmd/permcompass' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/permcompass' \
	  'share/help/cmd/permread' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/permread' \
	  'share/help/cmd/permswitch' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/permswitch' \
	  'share/help/cmd/playsoundeffect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/playsoundeffect' \
	  'share/help/cmd/poke' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/poke' \
	  'share/help/cmd/presentmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/presentmission' \
	  'share/help/cmd/prompt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/prompt' \
	  'share/help/cmd/protectobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/protectobject' \
	  'share/help/cmd/qquit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/qquit' \
	  'share/help/cmd/quick' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quick' \
	  'share/help/cmd/quickaddword' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quickaddword' \
	  'share/help/cmd/quickhelp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quickhelp' \
	  'share/help/cmd/quickinput' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quickinput' \
	  'share/help/cmd/quicklabeldelete' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quicklabeldelete' \
	  'share/help/cmd/quicksoundeffect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quicksoundeffect' \
	  'share/help/cmd/quit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quit' \
	  'share/help/cmd/quitall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/quitall' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/read' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/read' \
	  'share/help/cmd/reconnect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/reconnect' \
	  'share/help/cmd/record' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/record' \
	  'share/help/cmd/redirectmode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/redirectmode' \
	  'share/help/cmd/relaydirection' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/relaydirection' \
	  'share/help/cmd/removeworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/removeworkspace' \
	  'share/help/cmd/renamelabelstyle' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/renamelabelstyle' \
	  'share/help/cmd/renameregionscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/renameregionscheme' \
	  'share/help/cmd/repeat' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/repeat' \
	  'share/help/cmd/repeatcomment' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/repeatcomment' \
	  'share/help/cmd/repeatmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/repeatmission' \
	  'share/help/cmd/replaybuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/replaybuffer' \
	  'share/help/cmd/resetapplication' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetapplication' \
	  'share/help/cmd/resetcounter' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetcounter' \
	  'share/help/cmd/resetgrid' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetgrid' \
	  'share/help/cmd/resetguildskills' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetguildskills' \
	  'share/help/cmd/resetlightlist' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetlightlist' \
	  'share/help/cmd/resetlocatortask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetlocatortask' \
	  'share/help/cmd/resetlookup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetlookup' \
	  'share/help/cmd/resetroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetroom' \
	  'share/help/cmd/resetsmiley' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetsmiley' \
	  'share/help/cmd/resetsoundeffect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetsoundeffect' \
	  'share/help/cmd/resettask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resettask' \
	  'share/help/cmd/resettasklabel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resettasklabel' \
	  'share/help/cmd/resettaskpackage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resettaskpackage' \
	  'share/help/cmd/resetusercommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetusercommand' \
	  'share/help/cmd/resetwinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetwinmap' \
	  'share/help/cmd/resetzonemap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resetzonemap' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/restart' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/restart' \
	  'share/help/cmd/restoredata' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/restoredata' \
	  'share/help/cmd/restorewindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/restorewindow' \
	  'share/help/cmd/restoreworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/restoreworld' \
	  'share/help/cmd/resume' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resume' \
	  'share/help/cmd/resumetask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/resumetask' \
	  'share/help/cmd/retainfilecopy' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/retainfilecopy' \
	  'share/help/cmd/road' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/road' \
	  'share/help/cmd/roomcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/roomcommand' \
	  'share/help/cmd/runscript' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/runscript' \
	  'share/help/cmd/runscripttask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/runscripttask' \
	  'share/help/cmd/save' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/save' \
	  'share/help/cmd/savebuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/savebuffer' \
	  'share/help/cmd/scrolllock' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/scrolllock' \
	  'share/help/cmd/searchhelp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/searchhelp' \
	  'share/help/cmd/sellall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/sellall' \
	  'share/help/cmd/sendatcp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/sendatcp' \
	  'share/help/cmd/sendgmcp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/sendgmcp' \
	  'share/help/cmd/sendzmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/sendzmp' \
	  'share/help/cmd/setapplication' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setapplication' \
	  'share/help/cmd/setassistedmoves' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setassistedmoves' \
	  'share/help/cmd/setautocomplete' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setautocomplete' \
	  'share/help/cmd/setautosecondary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setautosecondary' \
	  'share/help/cmd/setautoworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setautoworld' \
	  'share/help/cmd/setcagemask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcagemask' \
	  'share/help/cmd/setchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setchar' \
	  'share/help/cmd/setcharset' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcharset' \
	  'share/help/cmd/setcolour' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcolour' \
	  'share/help/cmd/setcommandbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcommandbuffer' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/setcommifymode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcommifymode' \
	  'share/help/cmd/setcountdown' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcountdown' \
	  'share/help/cmd/setcountup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcountup' \
	  'share/help/cmd/setcustommonth' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcustommonth' \
	  'share/help/cmd/setcustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcustomprofile' \
	  'share/help/cmd/setcustomweek' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setcustomweek' \
	  'share/help/cmd/setdatadirectory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setdatadirectory' \
	  'share/help/cmd/setdefaultwinmap' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setdefaultwinmap' \
	  'share/help/cmd/setdictionary' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setdictionary' \
	  'share/help/cmd/setdisplaybuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setdisplaybuffer' \
	  'share/help/cmd/setfacing' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setfacing' \
	  'share/help/cmd/setfavouriteworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setfavouriteworld' \
	  'share/help/cmd/setgrid' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setgrid' \
	  'share/help/cmd/setguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setguild' \
	  'share/help/cmd/setinstructionbuffer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setinstructionbuffer' \
	  'share/help/cmd/setlanguage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setlanguage' \
	  'share/help/cmd/setlayer' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setlayer' \
	  'share/help/cmd/setlife' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setlife' \
	  'share/help/cmd/setlightlist' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setlightlist' \
	  'share/help/cmd/setlightstatus' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setlightstatus' \
	  'share/help/cmd/setlookup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setlookup' \
	  'share/help/cmd/setmodelparent' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setmodelparent' \
	  'share/help/cmd/setmudprotocol' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setmudprotocol' \
	  'share/help/cmd/setofflineroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setofflineroom' \
	  'share/help/cmd/setpanel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setpanel' \
	  'share/help/cmd/setprofilepriority' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setprofilepriority' \
	  'share/help/cmd/setpromptdelay' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setpromptdelay' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/setprotectedmoves' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setprotectedmoves' \
	  'share/help/cmd/setrace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setrace' \
	  'share/help/cmd/setredirectmode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setredirectmode' \
	  'share/help/cmd/setreminder' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setreminder' \
	  'share/help/cmd/setroom' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setroom' \
	  'share/help/cmd/setrunlist' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setrunlist' \
	  'share/help/cmd/setsession' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setsession' \
	  'share/help/cmd/setstatusevent' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setstatusevent' \
	  'share/help/cmd/setsystemcolour' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setsystemcolour' \
	  'share/help/cmd/setsystemmode' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setsystemmode' \
	  'share/help/cmd/settelnetoption' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/settelnetoption' \
	  'share/help/cmd/settermtype' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/settermtype' \
	  'share/help/cmd/settextview' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/settextview' \
	  'share/help/cmd/setwimpy' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setwimpy' \
	  'share/help/cmd/setwindowcontrols' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setwindowcontrols' \
	  'share/help/cmd/setwindowsize' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setwindowsize' \
	  'share/help/cmd/setworkspacedirection' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setworkspacedirection' \
	  'share/help/cmd/setworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setworld' \
	  'share/help/cmd/setxterm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/setxterm' \
	  'share/help/cmd/showfile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/showfile' \
	  'share/help/cmd/showhistory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/showhistory' \
	  'share/help/cmd/showstatusgauge' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/showstatusgauge' \
	  'share/help/cmd/shutup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/shutup' \
	  'share/help/cmd/simulatecommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/simulatecommand' \
	  'share/help/cmd/simulatehook' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/simulatehook' \
	  'share/help/cmd/simulateprompt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/simulateprompt' \
	  'share/help/cmd/simulateworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/simulateworld' \
	  'share/help/cmd/skip' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/skip' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/skipadvance' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/skipadvance' \
	  'share/help/cmd/slowwalk' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/slowwalk' \
	  'share/help/cmd/sound' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/sound' \
	  'share/help/cmd/speak' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/speak' \
	  'share/help/cmd/speech' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/speech' \
	  'share/help/cmd/speedwalk' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/speedwalk' \
	  'share/help/cmd/speedwalkcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/speedwalkcommand' \
	  'share/help/cmd/split' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/split' \
	  'share/help/cmd/splitmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/splitmodel' \
	  'share/help/cmd/splitscreen' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/splitscreen' \
	  'share/help/cmd/ssh' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/ssh' \
	  'share/help/cmd/ssl' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/ssl' \
	  'share/help/cmd/startcustomtask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/startcustomtask' \
	  'share/help/cmd/startmission' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/startmission' \
	  'share/help/cmd/starttask' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/starttask' \
	  'share/help/cmd/stopclient' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/stopclient' \
	  'share/help/cmd/stopcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/stopcommand' \
	  'share/help/cmd/stopsession' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/stopsession' \
	  'share/help/cmd/swapwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/swapwindow' \
	  'share/help/cmd/switch' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/switch' \
	  'share/help/cmd/switchlanguage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/switchlanguage' \
	  'share/help/cmd/switchsession' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/switchsession' \
	  'share/help/cmd/taskhelp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/taskhelp' \
	  'share/help/cmd/teleport' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/teleport' \
	  'share/help/cmd/telnet' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/telnet' \
	  'share/help/cmd/test' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/test' \
	  'share/help/cmd/testcolour' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testcolour' \
	  'share/help/cmd/testfile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testfile' \
	  'share/help/cmd/testmodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testmodel' \
	  'share/help/cmd/testpanel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testpanel' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/testpattern' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testpattern' \
	  'share/help/cmd/testplugin' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testplugin' \
	  'share/help/cmd/testwindowcontrols' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testwindowcontrols' \
	  'share/help/cmd/testxterm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/testxterm' \
	  'share/help/cmd/toggleautomapper' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/toggleautomapper' \
	  'share/help/cmd/togglehistory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglehistory' \
	  'share/help/cmd/toggleinstruction' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/toggleinstruction' \
	  'share/help/cmd/toggleirreversible' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/toggleirreversible' \
	  'share/help/cmd/togglelabel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglelabel' \
	  'share/help/cmd/togglemainwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglemainwindow' \
	  'share/help/cmd/togglepalette' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglepalette' \
	  'share/help/cmd/togglepopup' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglepopup' \
	  'share/help/cmd/toggleshare' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/toggleshare' \
	  'share/help/cmd/toggleshortlink' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/toggleshortlink' \
	  'share/help/cmd/togglesigil' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglesigil' \
	  'share/help/cmd/togglewindowkey' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglewindowkey' \
	  'share/help/cmd/togglewindowstorage' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/togglewindowstorage' \
	  'share/help/cmd/unflashwindow' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unflashwindow' \
	  'share/help/cmd/unmonitorobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unmonitorobject' \
	  'share/help/cmd/unprotectobject' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unprotectobject' \
	  'share/help/cmd/unsetchar' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unsetchar' \
	  'share/help/cmd/unsetcustomprofile' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unsetcustomprofile' \
	  'share/help/cmd/unsetguild' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unsetguild' \
	  'share/help/cmd/unsetrace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unsetrace' \
	  'share/help/cmd/unskip' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/unskip' \
	  'share/help/cmd/updatecolourscheme' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/updatecolourscheme' \
	  'share/help/cmd/updatemodel' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/updatemodel' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/cmd/updateworld' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/updateworld' \
	  'share/help/cmd/useall' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/useall' \
	  'share/help/cmd/useworkspace' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/useworkspace' \
	  'share/help/cmd/worldcommand' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/worldcommand' \
	  'share/help/cmd/worldcompass' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/worldcompass' \
	  'share/help/cmd/xconnect' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/xconnect' \
	  'share/help/cmd/xxit' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/xxit' \
	  'share/help/cmd/zmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/cmd/zmp' \
	  'share/help/misc/peekpoke' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/misc/peekpoke' \
	  'share/help/misc/quickhelp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/misc/quickhelp' \
	  'share/help/task/advance' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/advance' \
	  'share/help/task/attack' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/attack' \
	  'share/help/task/channels' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/channels' \
	  'share/help/task/chat' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/chat' \
	  'share/help/task/compass' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/compass' \
	  'share/help/task/condition' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/condition' \
	  'share/help/task/connections' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/connections' \
	  'share/help/task/countdown' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/countdown' \
	  'share/help/task/divert' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/divert' \
	  'share/help/task/frame' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/frame' \
	  'share/help/task/inventory' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/inventory' \
	  'share/help/task/launch' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/launch' \
	  'share/help/task/locator' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/locator' \
	  'share/help/task/mapcheck' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/mapcheck' \
	  'share/help/task/notepad' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/notepad' \
	  'share/help/task/rawtext' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/rawtext' \
	  'share/help/task/rawtoken' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/rawtoken' \
	  'share/help/task/script' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/script' \
	  'share/help/task/status' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/status' \
	  'share/help/task/system' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/system' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/help/task/tasklist' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/tasklist' \
	  'share/help/task/watch' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/help/task/watch' \
	  'share/icons/COPYING' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/COPYING' \
	  'share/icons/button/application.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/application.png' \
	  'share/icons/button/application_tile_vertical.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/application_tile_vertical.png' \
	  'share/icons/button/broom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/broom.png' \
	  'share/icons/button/console.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/console.png' \
	  'share/icons/button/console_debug.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/console_debug.png' \
	  'share/icons/button/console_error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/console_error.png' \
	  'share/icons/button/console_system.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/console_system.png' \
	  'share/icons/button/lock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/lock.png' \
	  'share/icons/button/lock_open.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/lock_open.png' \
	  'share/icons/button/prohibition_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/prohibition_button.png' \
	  'share/icons/button/search.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/search.png' \
	  'share/icons/button/switch_windows.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/switch_windows.png' \
	  'share/icons/button/textfield_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/textfield_add.png' \
	  'share/icons/button/toggle_expand.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/toggle_expand.png' \
	  'share/icons/button/wall.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/button/wall.png' \
	  'share/icons/chat/3d_glasses.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/3d_glasses.bmp' \
	  'share/icons/chat/COPYING' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/COPYING' \
	  'share/icons/chat/acoustic_guitar.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/acoustic_guitar.bmp' \
	  'share/icons/chat/administrator.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/administrator.bmp' \
	  'share/icons/chat/anchor.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/anchor.bmp' \
	  'share/icons/chat/angel.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/angel.bmp' \
	  'share/icons/chat/autos.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/autos.bmp' \
	  'share/icons/chat/ax.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/ax.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/backpack.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/backpack.bmp' \
	  'share/icons/chat/ballon.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/ballon.bmp' \
	  'share/icons/chat/bomb.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/bomb.bmp' \
	  'share/icons/chat/boomerang.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/boomerang.bmp' \
	  'share/icons/chat/bow.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/bow.bmp' \
	  'share/icons/chat/bug.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/bug.bmp' \
	  'share/icons/chat/burro.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/burro.bmp' \
	  'share/icons/chat/cactus.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cactus.bmp' \
	  'share/icons/chat/cake.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cake.bmp' \
	  'share/icons/chat/cards.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cards.bmp' \
	  'share/icons/chat/cat.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cat.bmp' \
	  'share/icons/chat/caterpillar.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/caterpillar.bmp' \
	  'share/icons/chat/caution_radiation.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/caution_radiation.bmp' \
	  'share/icons/chat/chameleon.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/chameleon.bmp' \
	  'share/icons/chat/chartplotter.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/chartplotter.bmp' \
	  'share/icons/chat/checkerboard.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/checkerboard.bmp' \
	  'share/icons/chat/cheese.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cheese.bmp' \
	  'share/icons/chat/chefs_hat.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/chefs_hat.bmp' \
	  'share/icons/chat/chess_horse.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/chess_horse.bmp' \
	  'share/icons/chat/chess_tower.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/chess_tower.bmp' \
	  'share/icons/chat/church.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/church.bmp' \
	  'share/icons/chat/circus.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/circus.bmp' \
	  'share/icons/chat/cocacola.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cocacola.bmp' \
	  'share/icons/chat/cold.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cold.bmp' \
	  'share/icons/chat/cricket.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cricket.bmp' \
	  'share/icons/chat/crown_bronze.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/crown_bronze.bmp' \
	  'share/icons/chat/crown_gold.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/crown_gold.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/crown_silver.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/crown_silver.bmp' \
	  'share/icons/chat/cup.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/cup.bmp' \
	  'share/icons/chat/dog.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/dog.bmp' \
	  'share/icons/chat/donut.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/donut.bmp' \
	  'share/icons/chat/door.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/door.bmp' \
	  'share/icons/chat/door_in.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/door_in.bmp' \
	  'share/icons/chat/door_open.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/door_open.bmp' \
	  'share/icons/chat/door_out.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/door_out.bmp' \
	  'share/icons/chat/dynamite.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/dynamite.bmp' \
	  'share/icons/chat/egyptian_pyramid.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/egyptian_pyramid.bmp' \
	  'share/icons/chat/electric_guitar.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/electric_guitar.bmp' \
	  'share/icons/chat/emotion_adore.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_adore.bmp' \
	  'share/icons/chat/emotion_after_boom.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_after_boom.bmp' \
	  'share/icons/chat/emotion_ah.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_ah.bmp' \
	  'share/icons/chat/emotion_alien.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_alien.bmp' \
	  'share/icons/chat/emotion_amazing.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_amazing.bmp' \
	  'share/icons/chat/emotion_angel.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_angel.bmp' \
	  'share/icons/chat/emotion_anger.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_anger.bmp' \
	  'share/icons/chat/emotion_angry.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_angry.bmp' \
	  'share/icons/chat/emotion_baby.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_baby.bmp' \
	  'share/icons/chat/emotion_bad_egg.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_bad_egg.bmp' \
	  'share/icons/chat/emotion_bad_smelly.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_bad_smelly.bmp' \
	  'share/icons/chat/emotion_baffle.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_baffle.bmp' \
	  'share/icons/chat/emotion_batman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_batman.bmp' \
	  'share/icons/chat/emotion_beat_brick.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_beat_brick.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/emotion_beaten.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_beaten.bmp' \
	  'share/icons/chat/emotion_bigsmile.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_bigsmile.bmp' \
	  'share/icons/chat/emotion_bloody.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_bloody.bmp' \
	  'share/icons/chat/emotion_bubblegum.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_bubblegum.bmp' \
	  'share/icons/chat/emotion_bye_bye.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_bye_bye.bmp' \
	  'share/icons/chat/emotion_clown.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_clown.bmp' \
	  'share/icons/chat/emotion_cold.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_cold.bmp' \
	  'share/icons/chat/emotion_confident.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_confident.bmp' \
	  'share/icons/chat/emotion_confuse.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_confuse.bmp' \
	  'share/icons/chat/emotion_cool.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_cool.bmp' \
	  'share/icons/chat/emotion_crazy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_crazy.bmp' \
	  'share/icons/chat/emotion_crazy_rabbit.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_crazy_rabbit.bmp' \
	  'share/icons/chat/emotion_cry.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_cry.bmp' \
	  'share/icons/chat/emotion_cyclops.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_cyclops.bmp' \
	  'share/icons/chat/emotion_darth_wader.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_darth_wader.bmp' \
	  'share/icons/chat/emotion_david_blaine.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_david_blaine.bmp' \
	  'share/icons/chat/emotion_dead.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_dead.bmp' \
	  'share/icons/chat/emotion_devil.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_devil.bmp' \
	  'share/icons/chat/emotion_diver.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_diver.bmp' \
	  'share/icons/chat/emotion_doubt.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_doubt.bmp' \
	  'share/icons/chat/emotion_dribble.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_dribble.bmp' \
	  'share/icons/chat/emotion_evilgrin.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_evilgrin.bmp' \
	  'share/icons/chat/emotion_evolution.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_evolution.bmp' \
	  'share/icons/chat/emotion_exciting.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_exciting.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/emotion_eyes_droped.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_eyes_droped.bmp' \
	  'share/icons/chat/emotion_face_monkey.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_face_monkey.bmp' \
	  'share/icons/chat/emotion_face_panda.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_face_panda.bmp' \
	  'share/icons/chat/emotion_fan.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_fan.bmp' \
	  'share/icons/chat/emotion_flower_dead.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_flower_dead.bmp' \
	  'share/icons/chat/emotion_franken.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_franken.bmp' \
	  'share/icons/chat/emotion_gear.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_gear.bmp' \
	  'share/icons/chat/emotion_ghost.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_ghost.bmp' \
	  'share/icons/chat/emotion_girl.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_girl.bmp' \
	  'share/icons/chat/emotion_go.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_go.bmp' \
	  'share/icons/chat/emotion_greedy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_greedy.bmp' \
	  'share/icons/chat/emotion_grin.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_grin.bmp' \
	  'share/icons/chat/emotion_haha.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_haha.bmp' \
	  'share/icons/chat/emotion_hand_flower.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_hand_flower.bmp' \
	  'share/icons/chat/emotion_happy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_happy.bmp' \
	  'share/icons/chat/emotion_hitler.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_hitler.bmp' \
	  'share/icons/chat/emotion_horror.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_horror.bmp' \
	  'share/icons/chat/emotion_hungry.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_hungry.bmp' \
	  'share/icons/chat/emotion_hypnotized.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_hypnotized.bmp' \
	  'share/icons/chat/emotion_japan.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_japan.bmp' \
	  'share/icons/chat/emotion_jason.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_jason.bmp' \
	  'share/icons/chat/emotion_kiss.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_kiss.bmp' \
	  'share/icons/chat/emotion_kissed.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_kissed.bmp' \
	  'share/icons/chat/emotion_love.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_love.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/emotion_mad.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_mad.bmp' \
	  'share/icons/chat/emotion_matrix.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_matrix.bmp' \
	  'share/icons/chat/emotion_medic.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_medic.bmp' \
	  'share/icons/chat/emotion_misdoubt.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_misdoubt.bmp' \
	  'share/icons/chat/emotion_money.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_money.bmp' \
	  'share/icons/chat/emotion_mummy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_mummy.bmp' \
	  'share/icons/chat/emotion_nerd.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_nerd.bmp' \
	  'share/icons/chat/emotion_ninja.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_ninja.bmp' \
	  'share/icons/chat/emotion_nosebleed.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_nosebleed.bmp' \
	  'share/icons/chat/emotion_pirate.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_pirate.bmp' \
	  'share/icons/chat/emotion_pumpkin.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_pumpkin.bmp' \
	  'share/icons/chat/emotion_question.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_question.bmp' \
	  'share/icons/chat/emotion_rap.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_rap.bmp' \
	  'share/icons/chat/emotion_red.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_red.bmp' \
	  'share/icons/chat/emotion_sad.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_sad.bmp' \
	  'share/icons/chat/emotion_shame.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_shame.bmp' \
	  'share/icons/chat/emotion_shocked.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_shocked.bmp' \
	  'share/icons/chat/emotion_sick.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_sick.bmp' \
	  'share/icons/chat/emotion_silent.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_silent.bmp' \
	  'share/icons/chat/emotion_skull.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_skull.bmp' \
	  'share/icons/chat/emotion_sleep.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_sleep.bmp' \
	  'share/icons/chat/emotion_smile.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_smile.bmp' \
	  'share/icons/chat/emotion_spiderman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_spiderman.bmp' \
	  'share/icons/chat/emotion_spy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_spy.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/emotion_star.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_star.bmp' \
	  'share/icons/chat/emotion_stupid.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_stupid.bmp' \
	  'share/icons/chat/emotion_suprised.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_suprised.bmp' \
	  'share/icons/chat/emotion_sure.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_sure.bmp' \
	  'share/icons/chat/emotion_surrender.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_surrender.bmp' \
	  'share/icons/chat/emotion_sweat.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_sweat.bmp' \
	  'share/icons/chat/emotion_terminator.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_terminator.bmp' \
	  'share/icons/chat/emotion_tire.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_tire.bmp' \
	  'share/icons/chat/emotion_tongue.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_tongue.bmp' \
	  'share/icons/chat/emotion_too_sad.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_too_sad.bmp' \
	  'share/icons/chat/emotion_unhappy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_unhappy.bmp' \
	  'share/icons/chat/emotion_unshaven.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_unshaven.bmp' \
	  'share/icons/chat/emotion_vampire.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_vampire.bmp' \
	  'share/icons/chat/emotion_waaaht.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_waaaht.bmp' \
	  'share/icons/chat/emotion_waii.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_waii.bmp' \
	  'share/icons/chat/emotion_what.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_what.bmp' \
	  'share/icons/chat/emotion_whist.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_whist.bmp' \
	  'share/icons/chat/emotion_wink.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_wink.bmp' \
	  'share/icons/chat/emotion_zedz.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/emotion_zedz.bmp' \
	  'share/icons/chat/fatcow.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/fatcow.bmp' \
	  'share/icons/chat/find.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/find.bmp' \
	  'share/icons/chat/flag_1.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/flag_1.bmp' \
	  'share/icons/chat/flag_2.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/flag_2.bmp' \
	  'share/icons/chat/flamingo.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/flamingo.bmp' \
	  'share/icons/chat/flower.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/flower.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/game_monitor.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/game_monitor.bmp' \
	  'share/icons/chat/globe_place.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/globe_place.bmp' \
	  'share/icons/chat/grass.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/grass.bmp' \
	  'share/icons/chat/green.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/green.bmp' \
	  'share/icons/chat/handbag.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/handbag.bmp' \
	  'share/icons/chat/hat.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/hat.bmp' \
	  'share/icons/chat/headphone.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/headphone.bmp' \
	  'share/icons/chat/headphone_mic.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/headphone_mic.bmp' \
	  'share/icons/chat/health.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/health.bmp' \
	  'share/icons/chat/heart.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/heart.bmp' \
	  'share/icons/chat/holly.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/holly.bmp' \
	  'share/icons/chat/horoscopes.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/horoscopes.bmp' \
	  'share/icons/chat/house_two.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/house_two.bmp' \
	  'share/icons/chat/hummingbird.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/hummingbird.bmp' \
	  'share/icons/chat/ice_cube.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/ice_cube.bmp' \
	  'share/icons/chat/icecream.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/icecream.bmp' \
	  'share/icons/chat/jason_mask.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/jason_mask.bmp' \
	  'share/icons/chat/joystick.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/joystick.bmp' \
	  'share/icons/chat/kids.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/kids.bmp' \
	  'share/icons/chat/ladybird.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/ladybird.bmp' \
	  'share/icons/chat/lighthouse.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/lighthouse.bmp' \
	  'share/icons/chat/lightning.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/lightning.bmp' \
	  'share/icons/chat/magic_wand_2.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/magic_wand_2.bmp' \
	  'share/icons/chat/money_bag.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/money_bag.bmp' \
	  'share/icons/chat/moneybox.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/moneybox.bmp' \
	  'share/icons/chat/moon.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/moon.bmp' \
	  'share/icons/chat/mosque.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/mosque.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/parrot.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/parrot.bmp' \
	  'share/icons/chat/peacock.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/peacock.bmp' \
	  'share/icons/chat/peak_cap.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/peak_cap.bmp' \
	  'share/icons/chat/pearl.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/pearl.bmp' \
	  'share/icons/chat/phone_vintage.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/phone_vintage.bmp' \
	  'share/icons/chat/piano.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/piano.bmp' \
	  'share/icons/chat/pirate_flag.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/pirate_flag.bmp' \
	  'share/icons/chat/pizza.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/pizza.bmp' \
	  'share/icons/chat/rabbit.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/rabbit.bmp' \
	  'share/icons/chat/rainbow_cloud.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/rainbow_cloud.bmp' \
	  'share/icons/chat/ring.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/ring.bmp' \
	  'share/icons/chat/robo_to.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/robo_to.bmp' \
	  'share/icons/chat/scull.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/scull.bmp' \
	  'share/icons/chat/shuriken.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/shuriken.bmp' \
	  'share/icons/chat/snail.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/snail.bmp' \
	  'share/icons/chat/snowman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/snowman.bmp' \
	  'share/icons/chat/sport.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport.bmp' \
	  'share/icons/chat/sport_8ball.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_8ball.bmp' \
	  'share/icons/chat/sport_basketball.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_basketball.bmp' \
	  'share/icons/chat/sport_football.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_football.bmp' \
	  'share/icons/chat/sport_golf.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_golf.bmp' \
	  'share/icons/chat/sport_raquet.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_raquet.bmp' \
	  'share/icons/chat/sport_shuttlecock.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_shuttlecock.bmp' \
	  'share/icons/chat/sport_soccer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_soccer.bmp' \
	  'share/icons/chat/sport_tennis.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sport_tennis.bmp' \
	  'share/icons/chat/sword.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/sword.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/teapot.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/teapot.bmp' \
	  'share/icons/chat/teddy_bear.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/teddy_bear.bmp' \
	  'share/icons/chat/toucan.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/toucan.bmp' \
	  'share/icons/chat/tower.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/tower.bmp' \
	  'share/icons/chat/trojan_horse.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/trojan_horse.bmp' \
	  'share/icons/chat/user_alien.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_alien.bmp' \
	  'share/icons/chat/user_angel.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_angel.bmp' \
	  'share/icons/chat/user_angel_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_angel_black.bmp' \
	  'share/icons/chat/user_angel_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_angel_female.bmp' \
	  'share/icons/chat/user_angel_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_angel_female_black.bmp' \
	  'share/icons/chat/user_astronaut.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_astronaut.bmp' \
	  'share/icons/chat/user_ballplayer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_ballplayer.bmp' \
	  'share/icons/chat/user_ballplayer_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_ballplayer_black.bmp' \
	  'share/icons/chat/user_banker.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_banker.bmp' \
	  'share/icons/chat/user_bart.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_bart.bmp' \
	  'share/icons/chat/user_batman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_batman.bmp' \
	  'share/icons/chat/user_beach_lifeguard.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_beach_lifeguard.bmp' \
	  'share/icons/chat/user_beach_lifeguard_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_beach_lifeguard_female.bmp' \
	  'share/icons/chat/user_bender.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_bender.bmp' \
	  'share/icons/chat/user_bishop.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_bishop.bmp' \
	  'share/icons/chat/user_blondy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_blondy.bmp' \
	  'share/icons/chat/user_boxer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_boxer.bmp' \
	  'share/icons/chat/user_boxer_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_boxer_black.bmp' \
	  'share/icons/chat/user_buddhist.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_buddhist.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/user_c3po.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_c3po.bmp' \
	  'share/icons/chat/user_catwomen.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_catwomen.bmp' \
	  'share/icons/chat/user_chief.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_chief.bmp' \
	  'share/icons/chat/user_chief_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_chief_black.bmp' \
	  'share/icons/chat/user_chief_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_chief_female.bmp' \
	  'share/icons/chat/user_chief_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_chief_female_black.bmp' \
	  'share/icons/chat/user_clown.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_clown.bmp' \
	  'share/icons/chat/user_comment.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_comment.bmp' \
	  'share/icons/chat/user_cook.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_cook.bmp' \
	  'share/icons/chat/user_cook_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_cook_black.bmp' \
	  'share/icons/chat/user_cook_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_cook_female.bmp' \
	  'share/icons/chat/user_cook_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_cook_female_black.bmp' \
	  'share/icons/chat/user_cowboy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_cowboy.bmp' \
	  'share/icons/chat/user_cowboy_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_cowboy_female.bmp' \
	  'share/icons/chat/user_crabs.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_crabs.bmp' \
	  'share/icons/chat/user_darth_vader.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_darth_vader.bmp' \
	  'share/icons/chat/user_death.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_death.bmp' \
	  'share/icons/chat/user_delete.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_delete.bmp' \
	  'share/icons/chat/user_detective.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_detective.bmp' \
	  'share/icons/chat/user_detective_gray.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_detective_gray.bmp' \
	  'share/icons/chat/user_devil.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_devil.bmp' \
	  'share/icons/chat/user_diver.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_diver.bmp' \
	  'share/icons/chat/user_dracula.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_dracula.bmp' \
	  'share/icons/chat/user_edit.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_edit.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/user_egyptian.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_egyptian.bmp' \
	  'share/icons/chat/user_egyptian_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_egyptian_female.bmp' \
	  'share/icons/chat/user_emo.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_emo.bmp' \
	  'share/icons/chat/user_eskimo.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_eskimo.bmp' \
	  'share/icons/chat/user_eskimo_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_eskimo_female.bmp' \
	  'share/icons/chat/user_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_female.bmp' \
	  'share/icons/chat/user_firefighter.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_firefighter.bmp' \
	  'share/icons/chat/user_firefighter_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_firefighter_black.bmp' \
	  'share/icons/chat/user_freddy.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_freddy.bmp' \
	  'share/icons/chat/user_geisha.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_geisha.bmp' \
	  'share/icons/chat/user_gladiator.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_gladiator.bmp' \
	  'share/icons/chat/user_go.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_go.bmp' \
	  'share/icons/chat/user_gomer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_gomer.bmp' \
	  'share/icons/chat/user_goth.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_goth.bmp' \
	  'share/icons/chat/user_gray.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_gray.bmp' \
	  'share/icons/chat/user_green.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_green.bmp' \
	  'share/icons/chat/user_halk.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_halk.bmp' \
	  'share/icons/chat/user_hendrix.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_hendrix.bmp' \
	  'share/icons/chat/user_imprisoned.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_imprisoned.bmp' \
	  'share/icons/chat/user_imprisoned_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_imprisoned_black.bmp' \
	  'share/icons/chat/user_imprisoned_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_imprisoned_female.bmp' \
	  'share/icons/chat/user_imprisoned_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_imprisoned_female_black.bmp' \
	  'share/icons/chat/user_indian.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_indian.bmp' \
	  'share/icons/chat/user_indian_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_indian_female.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/user_ironman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_ironman.bmp' \
	  'share/icons/chat/user_jason.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_jason.bmp' \
	  'share/icons/chat/user_jawa.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_jawa.bmp' \
	  'share/icons/chat/user_jester.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_jester.bmp' \
	  'share/icons/chat/user_jew.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_jew.bmp' \
	  'share/icons/chat/user_judge.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_judge.bmp' \
	  'share/icons/chat/user_judge_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_judge_black.bmp' \
	  'share/icons/chat/user_king.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_king.bmp' \
	  'share/icons/chat/user_king_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_king_black.bmp' \
	  'share/icons/chat/user_knight.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_knight.bmp' \
	  'share/icons/chat/user_leprechaun.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_leprechaun.bmp' \
	  'share/icons/chat/user_lisa.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_lisa.bmp' \
	  'share/icons/chat/user_maid.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_maid.bmp' \
	  'share/icons/chat/user_medical.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_medical.bmp' \
	  'share/icons/chat/user_medical_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_medical_black.bmp' \
	  'share/icons/chat/user_medical_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_medical_female.bmp' \
	  'share/icons/chat/user_medical_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_medical_female_black.bmp' \
	  'share/icons/chat/user_mexican.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_mexican.bmp' \
	  'share/icons/chat/user_muslim.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_muslim.bmp' \
	  'share/icons/chat/user_muslim_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_muslim_female.bmp' \
	  'share/icons/chat/user_ninja.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_ninja.bmp' \
	  'share/icons/chat/user_nude.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_nude.bmp' \
	  'share/icons/chat/user_nude_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_nude_black.bmp' \
	  'share/icons/chat/user_nude_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_nude_female.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/user_nude_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_nude_female_black.bmp' \
	  'share/icons/chat/user_nun.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_nun.bmp' \
	  'share/icons/chat/user_nun_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_nun_black.bmp' \
	  'share/icons/chat/user_officer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_officer.bmp' \
	  'share/icons/chat/user_officer_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_officer_black.bmp' \
	  'share/icons/chat/user_oldman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_oldman.bmp' \
	  'share/icons/chat/user_oldman_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_oldman_black.bmp' \
	  'share/icons/chat/user_oldwoman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_oldwoman.bmp' \
	  'share/icons/chat/user_oldwoman_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_oldwoman_black.bmp' \
	  'share/icons/chat/user_orange.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_orange.bmp' \
	  'share/icons/chat/user_patrick.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_patrick.bmp' \
	  'share/icons/chat/user_pilot.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_pilot.bmp' \
	  'share/icons/chat/user_pilot_civil.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_pilot_civil.bmp' \
	  'share/icons/chat/user_pirate.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_pirate.bmp' \
	  'share/icons/chat/user_plankton.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_plankton.bmp' \
	  'share/icons/chat/user_police_england.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_police_england.bmp' \
	  'share/icons/chat/user_police_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_police_female.bmp' \
	  'share/icons/chat/user_police_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_police_female_black.bmp' \
	  'share/icons/chat/user_policeman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_policeman.bmp' \
	  'share/icons/chat/user_policeman_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_policeman_black.bmp' \
	  'share/icons/chat/user_priest.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_priest.bmp' \
	  'share/icons/chat/user_priest_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_priest_black.bmp' \
	  'share/icons/chat/user_pumpkin.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_pumpkin.bmp' \
	  'share/icons/chat/user_queen.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_queen.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/user_queen_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_queen_black.bmp' \
	  'share/icons/chat/user_r2d2.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_r2d2.bmp' \
	  'share/icons/chat/user_racer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_racer.bmp' \
	  'share/icons/chat/user_rambo.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_rambo.bmp' \
	  'share/icons/chat/user_red.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_red.bmp' \
	  'share/icons/chat/user_redskin.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_redskin.bmp' \
	  'share/icons/chat/user_robocop.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_robocop.bmp' \
	  'share/icons/chat/user_sailor.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_sailor.bmp' \
	  'share/icons/chat/user_sailor_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_sailor_black.bmp' \
	  'share/icons/chat/user_samurai.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_samurai.bmp' \
	  'share/icons/chat/user_scream.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_scream.bmp' \
	  'share/icons/chat/user_silhouette.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_silhouette.bmp' \
	  'share/icons/chat/user_soldier.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_soldier.bmp' \
	  'share/icons/chat/user_spiderman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_spiderman.bmp' \
	  'share/icons/chat/user_sponge_bob.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_sponge_bob.bmp' \
	  'share/icons/chat/user_squidward.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_squidward.bmp' \
	  'share/icons/chat/user_stewardess.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_stewardess.bmp' \
	  'share/icons/chat/user_stewardess_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_stewardess_black.bmp' \
	  'share/icons/chat/user_striper.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_striper.bmp' \
	  'share/icons/chat/user_striper_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_striper_black.bmp' \
	  'share/icons/chat/user_student.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_student.bmp' \
	  'share/icons/chat/user_student_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_student_black.bmp' \
	  'share/icons/chat/user_student_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_student_female.bmp' \
	  'share/icons/chat/user_student_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_student_female_black.bmp' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/chat/user_suit.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_suit.bmp' \
	  'share/icons/chat/user_superman.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_superman.bmp' \
	  'share/icons/chat/user_swimmer.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_swimmer.bmp' \
	  'share/icons/chat/user_swimmer_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_swimmer_black.bmp' \
	  'share/icons/chat/user_swimmer_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_swimmer_female.bmp' \
	  'share/icons/chat/user_trooper.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_trooper.bmp' \
	  'share/icons/chat/user_trooper_captain.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_trooper_captain.bmp' \
	  'share/icons/chat/user_vietnamese.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_vietnamese.bmp' \
	  'share/icons/chat/user_vietnamese_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_vietnamese_female.bmp' \
	  'share/icons/chat/user_viking.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_viking.bmp' \
	  'share/icons/chat/user_viking_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_viking_female.bmp' \
	  'share/icons/chat/user_waiter.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_waiter.bmp' \
	  'share/icons/chat/user_waiter_female.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_waiter_female.bmp' \
	  'share/icons/chat/user_waiter_female_black.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_waiter_female_black.bmp' \
	  'share/icons/chat/user_wicket.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_wicket.bmp' \
	  'share/icons/chat/user_yoda.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_yoda.bmp' \
	  'share/icons/chat/user_zorro.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/user_zorro.bmp' \
	  'share/icons/chat/wizard.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/chat/wizard.bmp' \
	  'share/icons/connect/icon_apply.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_apply.png' \
	  'share/icons/connect/icon_apply_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_apply_large.png' \
	  'share/icons/connect/icon_clear.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_clear.png' \
	  'share/icons/connect/icon_clear_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_clear_large.png' \
	  'share/icons/connect/icon_config.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_config.png' \
	  'share/icons/connect/icon_config_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_config_large.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/connect/icon_console.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_console.png' \
	  'share/icons/connect/icon_console_alert.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_console_alert.png' \
	  'share/icons/connect/icon_console_alert_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_console_alert_large.png' \
	  'share/icons/connect/icon_console_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_console_large.png' \
	  'share/icons/connect/icon_other.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_other.png' \
	  'share/icons/connect/icon_other_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_other_large.png' \
	  'share/icons/connect/icon_search.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_search.png' \
	  'share/icons/connect/icon_search_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_search_large.png' \
	  'share/icons/connect/icon_sort_a.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_sort_a.png' \
	  'share/icons/connect/icon_sort_a_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_sort_a_large.png' \
	  'share/icons/connect/icon_sort_random.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_sort_random.png' \
	  'share/icons/connect/icon_sort_random_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_sort_random_large.png' \
	  'share/icons/connect/icon_sort_z.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_sort_z.png' \
	  'share/icons/connect/icon_sort_z_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/connect/icon_sort_z_large.png' \
	  'share/icons/custom/3d_glasses.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/3d_glasses.png' \
	  'share/icons/custom/abacus.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/abacus.png' \
	  'share/icons/custom/accept_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/accept_button.png' \
	  'share/icons/custom/accept_document.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/accept_document.png' \
	  'share/icons/custom/account_functions.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/account_functions.png' \
	  'share/icons/custom/account_menu.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/account_menu.png' \
	  'share/icons/custom/acorn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/acorn.png' \
	  'share/icons/custom/acoustic_guitar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/acoustic_guitar.png' \
	  'share/icons/custom/action.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/action.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/action_log.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/action_log.png' \
	  'share/icons/custom/add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/add.png' \
	  'share/icons/custom/add_on.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/add_on.png' \
	  'share/icons/custom/administrator.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/administrator.png' \
	  'share/icons/custom/alarm_bell.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/alarm_bell.png' \
	  'share/icons/custom/anchor.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/anchor.png' \
	  'share/icons/custom/apple.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/apple.png' \
	  'share/icons/custom/apple_half.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/apple_half.png' \
	  'share/icons/custom/application.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application.png' \
	  'share/icons/custom/application_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_add.png' \
	  'share/icons/custom/application_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_delete.png' \
	  'share/icons/custom/application_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_edit.png' \
	  'share/icons/custom/application_get.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_get.png' \
	  'share/icons/custom/application_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_go.png' \
	  'share/icons/custom/application_home.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_home.png' \
	  'share/icons/custom/application_key.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_key.png' \
	  'share/icons/custom/application_lightning.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_lightning.png' \
	  'share/icons/custom/application_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_link.png' \
	  'share/icons/custom/application_put.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/application_put.png' \
	  'share/icons/custom/areachart.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/areachart.png' \
	  'share/icons/custom/arrow_branch.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_branch.png' \
	  'share/icons/custom/arrow_divide.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_divide.png' \
	  'share/icons/custom/arrow_down.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_down.png' \
	  'share/icons/custom/arrow_in.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_in.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/arrow_inout.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_inout.png' \
	  'share/icons/custom/arrow_join.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_join.png' \
	  'share/icons/custom/arrow_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_left.png' \
	  'share/icons/custom/arrow_merge.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_merge.png' \
	  'share/icons/custom/arrow_out.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_out.png' \
	  'share/icons/custom/arrow_redo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_redo.png' \
	  'share/icons/custom/arrow_refresh.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_refresh.png' \
	  'share/icons/custom/arrow_refresh_small.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_refresh_small.png' \
	  'share/icons/custom/arrow_repeat.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_repeat.png' \
	  'share/icons/custom/arrow_repeat_once.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_repeat_once.png' \
	  'share/icons/custom/arrow_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_right.png' \
	  'share/icons/custom/arrow_rotate_anticlockwise.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_rotate_anticlockwise.png' \
	  'share/icons/custom/arrow_rotate_clockwise.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_rotate_clockwise.png' \
	  'share/icons/custom/arrow_switch.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_switch.png' \
	  'share/icons/custom/arrow_turn_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_turn_left.png' \
	  'share/icons/custom/arrow_turn_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_turn_right.png' \
	  'share/icons/custom/arrow_undo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_undo.png' \
	  'share/icons/custom/arrow_up.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/arrow_up.png' \
	  'share/icons/custom/artwork.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/artwork.png' \
	  'share/icons/custom/asterisk_orange.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/asterisk_orange.png' \
	  'share/icons/custom/asterisk_yellow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/asterisk_yellow.png' \
	  'share/icons/custom/at_sign.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/at_sign.png' \
	  'share/icons/custom/atm.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/atm.png' \
	  'share/icons/custom/attach.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/attach.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/attribution.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/attribution.png' \
	  'share/icons/custom/auction_hammer_gavel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/auction_hammer_gavel.png' \
	  'share/icons/custom/autoarchieve_settings.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/autoarchieve_settings.png' \
	  'share/icons/custom/autos.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/autos.png' \
	  'share/icons/custom/awstats.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/awstats.png' \
	  'share/icons/custom/ax.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ax.png' \
	  'share/icons/custom/baby_bottle.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/baby_bottle.png' \
	  'share/icons/custom/backpack.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/backpack.png' \
	  'share/icons/custom/baggage_cart.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/baggage_cart.png' \
	  'share/icons/custom/baggage_cart_box.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/baggage_cart_box.png' \
	  'share/icons/custom/balance.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/balance.png' \
	  'share/icons/custom/balance_unbalance.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/balance_unbalance.png' \
	  'share/icons/custom/ballon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ballon.png' \
	  'share/icons/custom/baloon_blue.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/baloon_blue.png' \
	  'share/icons/custom/bandaid.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bandaid.png' \
	  'share/icons/custom/bandwith.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bandwith.png' \
	  'share/icons/custom/barcode.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/barcode.png' \
	  'share/icons/custom/barcode_2d.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/barcode_2d.png' \
	  'share/icons/custom/bed.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bed.png' \
	  'share/icons/custom/beer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/beer.png' \
	  'share/icons/custom/bell.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bell.png' \
	  'share/icons/custom/billboard_empty.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/billboard_empty.png' \
	  'share/icons/custom/billboard_picture.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/billboard_picture.png' \
	  'share/icons/custom/billiard_marker.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/billiard_marker.png' \
	  'share/icons/custom/bin.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bin.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/bin_closed.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bin_closed.png' \
	  'share/icons/custom/bin_empty.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bin_empty.png' \
	  'share/icons/custom/bin_recycle.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bin_recycle.png' \
	  'share/icons/custom/blackboard_drawing.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/blackboard_drawing.png' \
	  'share/icons/custom/blackboard_empty.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/blackboard_empty.png' \
	  'share/icons/custom/blackboard_steps.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/blackboard_steps.png' \
	  'share/icons/custom/blackboard_sum.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/blackboard_sum.png' \
	  'share/icons/custom/blueprint.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/blueprint.png' \
	  'share/icons/custom/blueprints.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/blueprints.png' \
	  'share/icons/custom/board_game.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/board_game.png' \
	  'share/icons/custom/bomb.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bomb.png' \
	  'share/icons/custom/book.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book.png' \
	  'share/icons/custom/book_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_add.png' \
	  'share/icons/custom/book_addresses.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_addresses.png' \
	  'share/icons/custom/book_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_delete.png' \
	  'share/icons/custom/book_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_edit.png' \
	  'share/icons/custom/book_error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_error.png' \
	  'share/icons/custom/book_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_go.png' \
	  'share/icons/custom/book_keeping.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_keeping.png' \
	  'share/icons/custom/book_key.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_key.png' \
	  'share/icons/custom/book_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_link.png' \
	  'share/icons/custom/book_next.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_next.png' \
	  'share/icons/custom/book_picture.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_picture.png' \
	  'share/icons/custom/book_previous.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/book_previous.png' \
	  'share/icons/custom/bookmark.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bookmark.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/bookshelf.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bookshelf.png' \
	  'share/icons/custom/boomerang.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/boomerang.png' \
	  'share/icons/custom/box.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/box.png' \
	  'share/icons/custom/box_closed.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/box_closed.png' \
	  'share/icons/custom/box_front_open.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/box_front_open.png' \
	  'share/icons/custom/box_open.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/box_open.png' \
	  'share/icons/custom/brain_trainer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/brain_trainer.png' \
	  'share/icons/custom/broom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/broom.png' \
	  'share/icons/custom/bug.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bug.png' \
	  'share/icons/custom/building.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/building.png' \
	  'share/icons/custom/bulb.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bulb.png' \
	  'share/icons/custom/burro.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/burro.png' \
	  'share/icons/custom/bus.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/bus.png' \
	  'share/icons/custom/butterfly.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/butterfly.png' \
	  'share/icons/custom/cactus.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cactus.png' \
	  'share/icons/custom/cake.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cake.png' \
	  'share/icons/custom/calculator.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/calculator.png' \
	  'share/icons/custom/calendar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/calendar.png' \
	  'share/icons/custom/camera.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/camera.png' \
	  'share/icons/custom/camera_black.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/camera_black.png' \
	  'share/icons/custom/cancel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cancel.png' \
	  'share/icons/custom/candle_2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/candle_2.png' \
	  'share/icons/custom/candy_cane.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/candy_cane.png' \
	  'share/icons/custom/cap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cap.png' \
	  'share/icons/custom/car_taxi.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/car_taxi.png' \
	  'share/icons/custom/card_gift.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/card_gift.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/card_money.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/card_money.png' \
	  'share/icons/custom/cargo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cargo.png' \
	  'share/icons/custom/cart.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cart.png' \
	  'share/icons/custom/cash_stack.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cash_stack.png' \
	  'share/icons/custom/cash_terminal.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cash_terminal.png' \
	  'share/icons/custom/cat.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cat.png' \
	  'share/icons/custom/catalog_pages.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/catalog_pages.png' \
	  'share/icons/custom/categories.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/categories.png' \
	  'share/icons/custom/category.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/category.png' \
	  'share/icons/custom/category_group.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/category_group.png' \
	  'share/icons/custom/category_group_select.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/category_group_select.png' \
	  'share/icons/custom/category_item.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/category_item.png' \
	  'share/icons/custom/category_item_select.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/category_item_select.png' \
	  'share/icons/custom/caterpillar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/caterpillar.png' \
	  'share/icons/custom/caution_biohazard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/caution_biohazard.png' \
	  'share/icons/custom/caution_board.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/caution_board.png' \
	  'share/icons/custom/caution_high_voltage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/caution_high_voltage.png' \
	  'share/icons/custom/caution_radiation.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/caution_radiation.png' \
	  'share/icons/custom/cctv_camera.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cctv_camera.png' \
	  'share/icons/custom/cd.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cd.png' \
	  'share/icons/custom/cd_case.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cd_case.png' \
	  'share/icons/custom/chair.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chair.png' \
	  'share/icons/custom/chameleon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chameleon.png' \
	  'share/icons/custom/chart_bar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chart_bar.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/chart_curve.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chart_curve.png' \
	  'share/icons/custom/chart_pie_plane.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chart_pie_plane.png' \
	  'share/icons/custom/chart_stock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chart_stock.png' \
	  'share/icons/custom/chartplotter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chartplotter.png' \
	  'share/icons/custom/check_box.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/check_box.png' \
	  'share/icons/custom/check_box_mix.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/check_box_mix.png' \
	  'share/icons/custom/check_box_uncheck.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/check_box_uncheck.png' \
	  'share/icons/custom/checkerboard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/checkerboard.png' \
	  'share/icons/custom/cheese.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cheese.png' \
	  'share/icons/custom/chefs_hat.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chefs_hat.png' \
	  'share/icons/custom/chess_bishop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_bishop.png' \
	  'share/icons/custom/chess_bishop_white.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_bishop_white.png' \
	  'share/icons/custom/chess_horse.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_horse.png' \
	  'share/icons/custom/chess_horse_white.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_horse_white.png' \
	  'share/icons/custom/chess_king.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_king.png' \
	  'share/icons/custom/chess_king_white.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_king_white.png' \
	  'share/icons/custom/chess_pawn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_pawn.png' \
	  'share/icons/custom/chess_pawn_white.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_pawn_white.png' \
	  'share/icons/custom/chess_queen.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_queen.png' \
	  'share/icons/custom/chess_queen_white.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_queen_white.png' \
	  'share/icons/custom/chess_tower.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_tower.png' \
	  'share/icons/custom/chess_tower_white.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chess_tower_white.png' \
	  'share/icons/custom/chiken_leg.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chiken_leg.png' \
	  'share/icons/custom/children_cap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/children_cap.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/chocolate.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chocolate.png' \
	  'share/icons/custom/chocolate_milk.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/chocolate_milk.png' \
	  'share/icons/custom/christmas_tree.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/christmas_tree.png' \
	  'share/icons/custom/church.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/church.png' \
	  'share/icons/custom/cigarette.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cigarette.png' \
	  'share/icons/custom/cinema_ticket.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cinema_ticket.png' \
	  'share/icons/custom/circus.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/circus.png' \
	  'share/icons/custom/clear_formatting.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clear_formatting.png' \
	  'share/icons/custom/clock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clock.png' \
	  'share/icons/custom/clock_15.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clock_15.png' \
	  'share/icons/custom/clock_45.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clock_45.png' \
	  'share/icons/custom/clock_moon_phase.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clock_moon_phase.png' \
	  'share/icons/custom/clock_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clock_red.png' \
	  'share/icons/custom/clown_fish.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/clown_fish.png' \
	  'share/icons/custom/cocacola.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cocacola.png' \
	  'share/icons/custom/cog.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cog.png' \
	  'share/icons/custom/cog_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cog_add.png' \
	  'share/icons/custom/cog_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cog_delete.png' \
	  'share/icons/custom/cog_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cog_edit.png' \
	  'share/icons/custom/cog_error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cog_error.png' \
	  'share/icons/custom/cog_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cog_go.png' \
	  'share/icons/custom/coin_single_cooper.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coin_single_cooper.png' \
	  'share/icons/custom/coin_single_gold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coin_single_gold.png' \
	  'share/icons/custom/coin_single_silver.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coin_single_silver.png' \
	  'share/icons/custom/coin_stack_gold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coin_stack_gold.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/coins.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coins.png' \
	  'share/icons/custom/coins_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coins_add.png' \
	  'share/icons/custom/coins_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coins_delete.png' \
	  'share/icons/custom/coins_in_hand.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/coins_in_hand.png' \
	  'share/icons/custom/cold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cold.png' \
	  'share/icons/custom/color_wheel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/color_wheel.png' \
	  'share/icons/custom/comment.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comment.png' \
	  'share/icons/custom/comment_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comment_add.png' \
	  'share/icons/custom/comment_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comment_delete.png' \
	  'share/icons/custom/comment_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comment_edit.png' \
	  'share/icons/custom/comments.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comments.png' \
	  'share/icons/custom/comments_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comments_add.png' \
	  'share/icons/custom/comments_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/comments_delete.png' \
	  'share/icons/custom/compass.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/compass.png' \
	  'share/icons/custom/computer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/computer.png' \
	  'share/icons/custom/construction.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/construction.png' \
	  'share/icons/custom/control_pause_record.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/control_pause_record.png' \
	  'share/icons/custom/controller.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/controller.png' \
	  'share/icons/custom/cooler.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cooler.png' \
	  'share/icons/custom/counter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/counter.png' \
	  'share/icons/custom/cricket.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cricket.png' \
	  'share/icons/custom/cross.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cross.png' \
	  'share/icons/custom/cross_shield.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cross_shield.png' \
	  'share/icons/custom/crown_bronze.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/crown_bronze.png' \
	  'share/icons/custom/crown_gold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/crown_gold.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/crown_silver.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/crown_silver.png' \
	  'share/icons/custom/cruise_ship.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cruise_ship.png' \
	  'share/icons/custom/cup.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cup.png' \
	  'share/icons/custom/cup_bronze.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cup_bronze.png' \
	  'share/icons/custom/cup_gold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cup_gold.png' \
	  'share/icons/custom/cup_silver.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cup_silver.png' \
	  'share/icons/custom/curriculum_vitae.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/curriculum_vitae.png' \
	  'share/icons/custom/cursor.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cursor.png' \
	  'share/icons/custom/cursor_lifebuoy.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cursor_lifebuoy.png' \
	  'share/icons/custom/curtain.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/curtain.png' \
	  'share/icons/custom/cushion.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cushion.png' \
	  'share/icons/custom/cut.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cut.png' \
	  'share/icons/custom/cut_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cut_red.png' \
	  'share/icons/custom/cutleries.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cutleries.png' \
	  'share/icons/custom/cutlery.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cutlery.png' \
	  'share/icons/custom/cutter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/cutter.png' \
	  'share/icons/custom/dashboard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/dashboard.png' \
	  'share/icons/custom/date.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/date.png' \
	  'share/icons/custom/delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/delete.png' \
	  'share/icons/custom/delicious.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/delicious.png' \
	  'share/icons/custom/derivatives.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/derivatives.png' \
	  'share/icons/custom/diamond.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/diamond.png' \
	  'share/icons/custom/dice.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/dice.png' \
	  'share/icons/custom/disk_multiple.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/disk_multiple.png' \
	  'share/icons/custom/diskette.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/diskette.png' \
	  'share/icons/custom/dog.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/dog.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/donut.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/donut.png' \
	  'share/icons/custom/door.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/door.png' \
	  'share/icons/custom/door_in.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/door_in.png' \
	  'share/icons/custom/door_open.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/door_open.png' \
	  'share/icons/custom/door_out.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/door_out.png' \
	  'share/icons/custom/download.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/download.png' \
	  'share/icons/custom/draw_calligraphic.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/draw_calligraphic.png' \
	  'share/icons/custom/draw_clone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/draw_clone.png' \
	  'share/icons/custom/draw_convolve.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/draw_convolve.png' \
	  'share/icons/custom/draw_dodge_burn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/draw_dodge_burn.png' \
	  'share/icons/custom/draw_ink.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/draw_ink.png' \
	  'share/icons/custom/drive_disk.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/drive_disk.png' \
	  'share/icons/custom/drop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/drop.png' \
	  'share/icons/custom/drum.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/drum.png' \
	  'share/icons/custom/dynamite.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/dynamite.png' \
	  'share/icons/custom/ear_listen.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ear_listen.png' \
	  'share/icons/custom/earth_night.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/earth_night.png' \
	  'share/icons/custom/egyptian_pyramid.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/egyptian_pyramid.png' \
	  'share/icons/custom/electric_guitar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/electric_guitar.png' \
	  'share/icons/custom/electric_socket_120.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/electric_socket_120.png' \
	  'share/icons/custom/email.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/email.png' \
	  'share/icons/custom/email_authentication.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/email_authentication.png' \
	  'share/icons/custom/entity.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/entity.png' \
	  'share/icons/custom/envelopes.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/envelopes.png' \
	  'share/icons/custom/error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/error.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/events.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/events.png' \
	  'share/icons/custom/exclamation.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/exclamation.png' \
	  'share/icons/custom/eye.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/eye.png' \
	  'share/icons/custom/eye_close.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/eye_close.png' \
	  'share/icons/custom/eye_half.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/eye_half.png' \
	  'share/icons/custom/eye_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/eye_red.png' \
	  'share/icons/custom/find.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/find.png' \
	  'share/icons/custom/fingerprint.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/fingerprint.png' \
	  'share/icons/custom/fire.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/fire.png' \
	  'share/icons/custom/fire_extinguisher.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/fire_extinguisher.png' \
	  'share/icons/custom/flag_great_britain.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/flag_great_britain.png' \
	  'share/icons/custom/flamingo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/flamingo.png' \
	  'share/icons/custom/flashlight.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/flashlight.png' \
	  'share/icons/custom/flashlight_shine.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/flashlight_shine.png' \
	  'share/icons/custom/flask_empty.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/flask_empty.png' \
	  'share/icons/custom/flower.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/flower.png' \
	  'share/icons/custom/folder.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/folder.png' \
	  'share/icons/custom/folder_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/folder_add.png' \
	  'share/icons/custom/folder_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/folder_delete.png' \
	  'share/icons/custom/frontpage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/frontpage.png' \
	  'share/icons/custom/fruit_grape.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/fruit_grape.png' \
	  'share/icons/custom/fruit_lime.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/fruit_lime.png' \
	  'share/icons/custom/function.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/function.png' \
	  'share/icons/custom/game_monitor.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/game_monitor.png' \
	  'share/icons/custom/gear_in.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/gear_in.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/georectify.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/georectify.png' \
	  'share/icons/custom/getting_started_wizard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/getting_started_wizard.png' \
	  'share/icons/custom/glass_narrow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/glass_narrow.png' \
	  'share/icons/custom/glass_of_wine_full.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/glass_of_wine_full.png' \
	  'share/icons/custom/globe_africa.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/globe_africa.png' \
	  'share/icons/custom/globe_australia.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/globe_australia.png' \
	  'share/icons/custom/globe_model.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/globe_model.png' \
	  'share/icons/custom/globe_network.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/globe_network.png' \
	  'share/icons/custom/globe_place.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/globe_place.png' \
	  'share/icons/custom/google_map.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/google_map.png' \
	  'share/icons/custom/google_webmaster_tools.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/google_webmaster_tools.png' \
	  'share/icons/custom/grass.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/grass.png' \
	  'share/icons/custom/green.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/green.png' \
	  'share/icons/custom/green_wormhole.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/green_wormhole.png' \
	  'share/icons/custom/green_yellow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/green_yellow.png' \
	  'share/icons/custom/grenade.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/grenade.png' \
	  'share/icons/custom/grid.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/grid.png' \
	  'share/icons/custom/gun.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/gun.png' \
	  'share/icons/custom/half_moon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/half_moon.png' \
	  'share/icons/custom/hamburger.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hamburger.png' \
	  'share/icons/custom/hammer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hammer.png' \
	  'share/icons/custom/hand.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand.png' \
	  'share/icons/custom/hand_fuck.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand_fuck.png' \
	  'share/icons/custom/hand_ily.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand_ily.png' \
	  'share/icons/custom/hand_point_090.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand_point_090.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/hand_point_180.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand_point_180.png' \
	  'share/icons/custom/hand_point_270.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand_point_270.png' \
	  'share/icons/custom/hand_property.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hand_property.png' \
	  'share/icons/custom/handbag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/handbag.png' \
	  'share/icons/custom/hard_hat_military.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hard_hat_military.png' \
	  'share/icons/custom/hat.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hat.png' \
	  'share/icons/custom/hbox.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hbox.png' \
	  'share/icons/custom/headphone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/headphone.png' \
	  'share/icons/custom/headphone_mic.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/headphone_mic.png' \
	  'share/icons/custom/heart.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/heart.png' \
	  'share/icons/custom/heart_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/heart_add.png' \
	  'share/icons/custom/heart_break.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/heart_break.png' \
	  'share/icons/custom/heart_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/heart_delete.png' \
	  'share/icons/custom/heart_half.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/heart_half.png' \
	  'share/icons/custom/helicopter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/helicopter.png' \
	  'share/icons/custom/helmet.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/helmet.png' \
	  'share/icons/custom/helmet_mine.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/helmet_mine.png' \
	  'share/icons/custom/help.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/help.png' \
	  'share/icons/custom/holly.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/holly.png' \
	  'share/icons/custom/horoscopes.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/horoscopes.png' \
	  'share/icons/custom/hot.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hot.png' \
	  'share/icons/custom/hourglass.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hourglass.png' \
	  'share/icons/custom/hourglass_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hourglass_add.png' \
	  'share/icons/custom/hourglass_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hourglass_delete.png' \
	  'share/icons/custom/hourglass_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hourglass_go.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/hourglass_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hourglass_link.png' \
	  'share/icons/custom/house.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/house.png' \
	  'share/icons/custom/house_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/house_go.png' \
	  'share/icons/custom/house_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/house_link.png' \
	  'share/icons/custom/house_one.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/house_one.png' \
	  'share/icons/custom/house_two.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/house_two.png' \
	  'share/icons/custom/hummingbird.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/hummingbird.png' \
	  'share/icons/custom/information.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/information.png' \
	  'share/icons/custom/jacket.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/jacket.png' \
	  'share/icons/custom/jason_mask.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/jason_mask.png' \
	  'share/icons/custom/jeans.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/jeans.png' \
	  'share/icons/custom/joystick.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/joystick.png' \
	  'share/icons/custom/key.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/key.png' \
	  'share/icons/custom/keyboard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/keyboard.png' \
	  'share/icons/custom/kids.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/kids.png' \
	  'share/icons/custom/knot.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/knot.png' \
	  'share/icons/custom/ladybird.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ladybird.png' \
	  'share/icons/custom/landmarks.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/landmarks.png' \
	  'share/icons/custom/laptop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/laptop.png' \
	  'share/icons/custom/lcd_tv_image.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lcd_tv_image.png' \
	  'share/icons/custom/lightning.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lightning.png' \
	  'share/icons/custom/lock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock.png' \
	  'share/icons/custom/lock_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock_add.png' \
	  'share/icons/custom/lock_break.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock_break.png' \
	  'share/icons/custom/lock_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock_delete.png' \
	  'share/icons/custom/lock_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock_edit.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/lock_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock_go.png' \
	  'share/icons/custom/lock_open.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lock_open.png' \
	  'share/icons/custom/lollipop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lollipop.png' \
	  'share/icons/custom/lorry.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/lorry.png' \
	  'share/icons/custom/luggage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/luggage.png' \
	  'share/icons/custom/magnet.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/magnet.png' \
	  'share/icons/custom/mail_box.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mail_box.png' \
	  'share/icons/custom/map.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map.png' \
	  'share/icons/custom/map_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map_add.png' \
	  'share/icons/custom/map_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map_delete.png' \
	  'share/icons/custom/map_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map_edit.png' \
	  'share/icons/custom/map_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map_go.png' \
	  'share/icons/custom/map_magnify.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map_magnify.png' \
	  'share/icons/custom/map_torn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/map_torn.png' \
	  'share/icons/custom/mask.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mask.png' \
	  'share/icons/custom/measure.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/measure.png' \
	  'share/icons/custom/medal_award_bronze.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/medal_award_bronze.png' \
	  'share/icons/custom/medal_award_gold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/medal_award_gold.png' \
	  'share/icons/custom/medal_award_silver.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/medal_award_silver.png' \
	  'share/icons/custom/metronome.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/metronome.png' \
	  'share/icons/custom/microphone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/microphone.png' \
	  'share/icons/custom/microscope.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/microscope.png' \
	  'share/icons/custom/microwave.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/microwave.png' \
	  'share/icons/custom/milestone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/milestone.png' \
	  'share/icons/custom/mixer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mixer.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/money_bag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/money_bag.png' \
	  'share/icons/custom/moneybox.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/moneybox.png' \
	  'share/icons/custom/moon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/moon.png' \
	  'share/icons/custom/mosque.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mosque.png' \
	  'share/icons/custom/mouse.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mouse.png' \
	  'share/icons/custom/mouse_pc.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mouse_pc.png' \
	  'share/icons/custom/mouse_select_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mouse_select_left.png' \
	  'share/icons/custom/mouse_select_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mouse_select_right.png' \
	  'share/icons/custom/mouse_select_scroll.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mouse_select_scroll.png' \
	  'share/icons/custom/multitool.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/multitool.png' \
	  'share/icons/custom/mushroom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mushroom.png' \
	  'share/icons/custom/music.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/music.png' \
	  'share/icons/custom/mustache.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/mustache.png' \
	  'share/icons/custom/nameboard_open.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/nameboard_open.png' \
	  'share/icons/custom/new.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/new.png' \
	  'share/icons/custom/oil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/oil.png' \
	  'share/icons/custom/oil_barrel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/oil_barrel.png' \
	  'share/icons/custom/omelet.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/omelet.png' \
	  'share/icons/custom/page_white_magnify.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/page_white_magnify.png' \
	  'share/icons/custom/page_white_text.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/page_white_text.png' \
	  'share/icons/custom/paintbrush.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/paintbrush.png' \
	  'share/icons/custom/palette.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/palette.png' \
	  'share/icons/custom/paper_airplane.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/paper_airplane.png' \
	  'share/icons/custom/paper_lantern_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/paper_lantern_red.png' \
	  'share/icons/custom/paragraph_spacing.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/paragraph_spacing.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/parrot.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/parrot.png' \
	  'share/icons/custom/party_hat.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/party_hat.png' \
	  'share/icons/custom/peacock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/peacock.png' \
	  'share/icons/custom/pencil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pencil.png' \
	  'share/icons/custom/pencil_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pencil_add.png' \
	  'share/icons/custom/pencil_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pencil_delete.png' \
	  'share/icons/custom/phone_handset.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/phone_handset.png' \
	  'share/icons/custom/phone_vintage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/phone_vintage.png' \
	  'share/icons/custom/photo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/photo.png' \
	  'share/icons/custom/photo_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/photo_add.png' \
	  'share/icons/custom/photo_album.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/photo_album.png' \
	  'share/icons/custom/photo_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/photo_delete.png' \
	  'share/icons/custom/photo_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/photo_link.png' \
	  'share/icons/custom/photos.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/photos.png' \
	  'share/icons/custom/pi_math.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pi_math.png' \
	  'share/icons/custom/piano.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/piano.png' \
	  'share/icons/custom/picture.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture.png' \
	  'share/icons/custom/picture_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_add.png' \
	  'share/icons/custom/picture_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_delete.png' \
	  'share/icons/custom/picture_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_edit.png' \
	  'share/icons/custom/picture_empty.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_empty.png' \
	  'share/icons/custom/picture_error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_error.png' \
	  'share/icons/custom/picture_frame.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_frame.png' \
	  'share/icons/custom/picture_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_go.png' \
	  'share/icons/custom/picture_insert.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_insert.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/picture_insert_from_web.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_insert_from_web.png' \
	  'share/icons/custom/picture_key.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_key.png' \
	  'share/icons/custom/picture_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_link.png' \
	  'share/icons/custom/picture_position.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_position.png' \
	  'share/icons/custom/picture_save.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_save.png' \
	  'share/icons/custom/picture_sunset.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/picture_sunset.png' \
	  'share/icons/custom/pictures.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pictures.png' \
	  'share/icons/custom/piece_of_cake.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/piece_of_cake.png' \
	  'share/icons/custom/pill.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pill.png' \
	  'share/icons/custom/pint.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pint.png' \
	  'share/icons/custom/pirate_flag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pirate_flag.png' \
	  'share/icons/custom/pizza.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/pizza.png' \
	  'share/icons/custom/places.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/places.png' \
	  'share/icons/custom/plane.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/plane.png' \
	  'share/icons/custom/playing_cards.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/playing_cards.png' \
	  'share/icons/custom/poker.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/poker.png' \
	  'share/icons/custom/poo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/poo.png' \
	  'share/icons/custom/popcorn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/popcorn.png' \
	  'share/icons/custom/postage_stamp.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/postage_stamp.png' \
	  'share/icons/custom/power_supply.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/power_supply.png' \
	  'share/icons/custom/printer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/printer.png' \
	  'share/icons/custom/purse.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/purse.png' \
	  'share/icons/custom/question.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/question.png' \
	  'share/icons/custom/rabbit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rabbit.png' \
	  'share/icons/custom/radio_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/radio_button.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/radio_modern.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/radio_modern.png' \
	  'share/icons/custom/radio_oldschool.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/radio_oldschool.png' \
	  'share/icons/custom/radiolocator.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/radiolocator.png' \
	  'share/icons/custom/rain.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rain.png' \
	  'share/icons/custom/rainbow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rainbow.png' \
	  'share/icons/custom/rainbow_cloud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rainbow_cloud.png' \
	  'share/icons/custom/redo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/redo.png' \
	  'share/icons/custom/refresh_all.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/refresh_all.png' \
	  'share/icons/custom/report.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/report.png' \
	  'share/icons/custom/report_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/report_add.png' \
	  'share/icons/custom/report_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/report_delete.png' \
	  'share/icons/custom/report_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/report_edit.png' \
	  'share/icons/custom/restaurant_menu.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/restaurant_menu.png' \
	  'share/icons/custom/resultset_first.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/resultset_first.png' \
	  'share/icons/custom/resultset_last.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/resultset_last.png' \
	  'share/icons/custom/resultset_next.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/resultset_next.png' \
	  'share/icons/custom/resultset_previous.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/resultset_previous.png' \
	  'share/icons/custom/ribbon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ribbon.png' \
	  'share/icons/custom/ring.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ring.png' \
	  'share/icons/custom/rip.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rip.png' \
	  'share/icons/custom/road_sign.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/road_sign.png' \
	  'share/icons/custom/road_sign_hard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/road_sign_hard.png' \
	  'share/icons/custom/roadworks.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/roadworks.png' \
	  'share/icons/custom/robo_to.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/robo_to.png' \
	  'share/icons/custom/robot.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/robot.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/rocket.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rocket.png' \
	  'share/icons/custom/rosette.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rosette.png' \
	  'share/icons/custom/routing_around.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_around.png' \
	  'share/icons/custom/routing_forward.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_forward.png' \
	  'share/icons/custom/routing_go_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_go_left.png' \
	  'share/icons/custom/routing_go_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_go_right.png' \
	  'share/icons/custom/routing_go_straight_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_go_straight_left.png' \
	  'share/icons/custom/routing_go_straight_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_go_straight_right.png' \
	  'share/icons/custom/routing_intersection_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_intersection_right.png' \
	  'share/icons/custom/routing_turn_arround_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_arround_left.png' \
	  'share/icons/custom/routing_turn_arround_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_arround_right.png' \
	  'share/icons/custom/routing_turn_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_left.png' \
	  'share/icons/custom/routing_turn_left_90.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_left_90.png' \
	  'share/icons/custom/routing_turn_left_crossroads.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_left_crossroads.png' \
	  'share/icons/custom/routing_turn_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_right.png' \
	  'share/icons/custom/routing_turn_right_90.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_right_90.png' \
	  'share/icons/custom/routing_turn_u.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turn_u.png' \
	  'share/icons/custom/routing_turnaround_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turnaround_left.png' \
	  'share/icons/custom/routing_turnaround_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turnaround_right.png' \
	  'share/icons/custom/routing_turning_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turning_left.png' \
	  'share/icons/custom/routing_turning_right.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/routing_turning_right.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/rubber_duck.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/rubber_duck.png' \
	  'share/icons/custom/ruby.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ruby.png' \
	  'share/icons/custom/ruler.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/ruler.png' \
	  'share/icons/custom/run_macros.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/run_macros.png' \
	  'share/icons/custom/safe.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/safe.png' \
	  'share/icons/custom/santa.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/santa.png' \
	  'share/icons/custom/satellite.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/satellite.png' \
	  'share/icons/custom/satellite_dish.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/satellite_dish.png' \
	  'share/icons/custom/save_as.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/save_as.png' \
	  'share/icons/custom/save_data.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/save_data.png' \
	  'share/icons/custom/save_new.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/save_new.png' \
	  'share/icons/custom/scull.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/scull.png' \
	  'share/icons/custom/security.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/security.png' \
	  'share/icons/custom/separator.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/separator.png' \
	  'share/icons/custom/shoe.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/shoe.png' \
	  'share/icons/custom/shop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/shop.png' \
	  'share/icons/custom/shop_closed.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/shop_closed.png' \
	  'share/icons/custom/shopping.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/shopping.png' \
	  'share/icons/custom/showel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/showel.png' \
	  'share/icons/custom/skins.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/skins.png' \
	  'share/icons/custom/small_business.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/small_business.png' \
	  'share/icons/custom/snail.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/snail.png' \
	  'share/icons/custom/snowman.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/snowman.png' \
	  'share/icons/custom/sound.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sound.png' \
	  'share/icons/custom/sound_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sound_add.png' \
	  'share/icons/custom/sound_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sound_delete.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/sound_low.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sound_low.png' \
	  'share/icons/custom/sound_mute.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sound_mute.png' \
	  'share/icons/custom/sound_none.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sound_none.png' \
	  'share/icons/custom/spider_web.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/spider_web.png' \
	  'share/icons/custom/splitter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/splitter.png' \
	  'share/icons/custom/splitter_horizontal.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/splitter_horizontal.png' \
	  'share/icons/custom/sport.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport.png' \
	  'share/icons/custom/sport_8ball.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_8ball.png' \
	  'share/icons/custom/sport_basketball.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_basketball.png' \
	  'share/icons/custom/sport_football.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_football.png' \
	  'share/icons/custom/sport_golf.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_golf.png' \
	  'share/icons/custom/sport_raquet.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_raquet.png' \
	  'share/icons/custom/sport_shuttlecock.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_shuttlecock.png' \
	  'share/icons/custom/sport_soccer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_soccer.png' \
	  'share/icons/custom/sport_tennis.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sport_tennis.png' \
	  'share/icons/custom/star.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/star.png' \
	  'share/icons/custom/steak_fish.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/steak_fish.png' \
	  'share/icons/custom/steering_wheel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/steering_wheel.png' \
	  'share/icons/custom/steering_wheel_common.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/steering_wheel_common.png' \
	  'share/icons/custom/steering_wheel_racing.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/steering_wheel_racing.png' \
	  'share/icons/custom/stethoscope.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/stethoscope.png' \
	  'share/icons/custom/stickman.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/stickman.png' \
	  'share/icons/custom/stop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/stop.png' \
	  'share/icons/custom/stopwatch_finish.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/stopwatch_finish.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/stopwatch_pause.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/stopwatch_pause.png' \
	  'share/icons/custom/stopwatch_start.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/stopwatch_start.png' \
	  'share/icons/custom/sword.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/sword.png' \
	  'share/icons/custom/tea_cup.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tea_cup.png' \
	  'share/icons/custom/teddy_bear.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/teddy_bear.png' \
	  'share/icons/custom/telephone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/telephone.png' \
	  'share/icons/custom/telephone_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/telephone_add.png' \
	  'share/icons/custom/telephone_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/telephone_delete.png' \
	  'share/icons/custom/telephone_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/telephone_edit.png' \
	  'share/icons/custom/telephone_error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/telephone_error.png' \
	  'share/icons/custom/terminal_seats_blue.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/terminal_seats_blue.png' \
	  'share/icons/custom/terminal_seats_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/terminal_seats_red.png' \
	  'share/icons/custom/text.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/text.png' \
	  'share/icons/custom/theater.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/theater.png' \
	  'share/icons/custom/things_beauty.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/things_beauty.png' \
	  'share/icons/custom/thumb_down.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/thumb_down.png' \
	  'share/icons/custom/thumb_up.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/thumb_up.png' \
	  'share/icons/custom/tick.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick.png' \
	  'share/icons/custom/tick_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_button.png' \
	  'share/icons/custom/tick_circle_frame.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_circle_frame.png' \
	  'share/icons/custom/tick_light_blue.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_light_blue.png' \
	  'share/icons/custom/tick_octagon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_octagon.png' \
	  'share/icons/custom/tick_octagon_frame.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_octagon_frame.png' \
	  'share/icons/custom/tick_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_red.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/tick_shield.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tick_shield.png' \
	  'share/icons/custom/tie.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tie.png' \
	  'share/icons/custom/tire.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tire.png' \
	  'share/icons/custom/to_do_list.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/to_do_list.png' \
	  'share/icons/custom/to_do_list_checked_1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/to_do_list_checked_1.png' \
	  'share/icons/custom/to_do_list_checked_all.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/to_do_list_checked_all.png' \
	  'share/icons/custom/toggle.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/toggle.png' \
	  'share/icons/custom/toggle_expand.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/toggle_expand.png' \
	  'share/icons/custom/toilet.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/toilet.png' \
	  'share/icons/custom/toilet_pan.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/toilet_pan.png' \
	  'share/icons/custom/token_anchors.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/token_anchors.png' \
	  'share/icons/custom/tower.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tower.png' \
	  'share/icons/custom/traffic_lights.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/traffic_lights.png' \
	  'share/icons/custom/traffic_lights_green.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/traffic_lights_green.png' \
	  'share/icons/custom/traffic_lights_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/traffic_lights_red.png' \
	  'share/icons/custom/traffic_lights_yellow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/traffic_lights_yellow.png' \
	  'share/icons/custom/train.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/train.png' \
	  'share/icons/custom/train_metro.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/train_metro.png' \
	  'share/icons/custom/tux.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/tux.png' \
	  'share/icons/custom/umbrella.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/umbrella.png' \
	  'share/icons/custom/user.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user.png' \
	  'share/icons/custom/user_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_add.png' \
	  'share/icons/custom/user_angel.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_angel.png' \
	  'share/icons/custom/user_angel_female.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_angel_female.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/user_clown.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_clown.png' \
	  'share/icons/custom/user_cowboy.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_cowboy.png' \
	  'share/icons/custom/user_cowboy_female.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_cowboy_female.png' \
	  'share/icons/custom/user_death.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_death.png' \
	  'share/icons/custom/user_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_delete.png' \
	  'share/icons/custom/user_detective.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_detective.png' \
	  'share/icons/custom/user_diver.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_diver.png' \
	  'share/icons/custom/user_dracula.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_dracula.png' \
	  'share/icons/custom/user_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_go.png' \
	  'share/icons/custom/user_imprisoned.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_imprisoned.png' \
	  'share/icons/custom/user_imprisoned_female.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_imprisoned_female.png' \
	  'share/icons/custom/user_king.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_king.png' \
	  'share/icons/custom/user_knight.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_knight.png' \
	  'share/icons/custom/user_medical_female.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_medical_female.png' \
	  'share/icons/custom/user_ninja.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_ninja.png' \
	  'share/icons/custom/user_officer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_officer.png' \
	  'share/icons/custom/user_oldman.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_oldman.png' \
	  'share/icons/custom/user_oldwoman.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_oldwoman.png' \
	  'share/icons/custom/user_pirate.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_pirate.png' \
	  'share/icons/custom/user_queen.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_queen.png' \
	  'share/icons/custom/user_rambo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_rambo.png' \
	  'share/icons/custom/user_samurai.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_samurai.png' \
	  'share/icons/custom/user_silhouette.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_silhouette.png' \
	  'share/icons/custom/user_soldier.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_soldier.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/user_swimmer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_swimmer.png' \
	  'share/icons/custom/user_swimmer_female.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_swimmer_female.png' \
	  'share/icons/custom/user_viking.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_viking.png' \
	  'share/icons/custom/user_viking_female.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_viking_female.png' \
	  'share/icons/custom/user_wicket.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/user_wicket.png' \
	  'share/icons/custom/users_3.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/users_3.png' \
	  'share/icons/custom/users_4.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/users_4.png' \
	  'share/icons/custom/users_5.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/users_5.png' \
	  'share/icons/custom/users_men_women.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/users_men_women.png' \
	  'share/icons/custom/vase.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/vase.png' \
	  'share/icons/custom/vcard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/vcard.png' \
	  'share/icons/custom/video.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/video.png' \
	  'share/icons/custom/virus_protection.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/virus_protection.png' \
	  'share/icons/custom/wand.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/wand.png' \
	  'share/icons/custom/watch_window.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/watch_window.png' \
	  'share/icons/custom/watermark_table.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/watermark_table.png' \
	  'share/icons/custom/weather_cloudy.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_cloudy.png' \
	  'share/icons/custom/weather_lightning.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_lightning.png' \
	  'share/icons/custom/weather_moon_cloudy.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_moon_cloudy.png' \
	  'share/icons/custom/weather_moon_fog.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_moon_fog.png' \
	  'share/icons/custom/weather_moon_half.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_moon_half.png' \
	  'share/icons/custom/weather_rain.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_rain.png' \
	  'share/icons/custom/weather_rain_little.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_rain_little.png' \
	  'share/icons/custom/weather_snow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_snow.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/weather_snow_little.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_snow_little.png' \
	  'share/icons/custom/weather_sun.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_sun.png' \
	  'share/icons/custom/weather_sun_fog.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/weather_sun_fog.png' \
	  'share/icons/custom/whistle.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/whistle.png' \
	  'share/icons/custom/widgets.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/widgets.png' \
	  'share/icons/custom/windy.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/windy.png' \
	  'share/icons/custom/wine_pairings.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/wine_pairings.png' \
	  'share/icons/custom/wizard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/wizard.png' \
	  'share/icons/custom/wizard_women.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/wizard_women.png' \
	  'share/icons/custom/world.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/world.png' \
	  'share/icons/custom/world_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/world_add.png' \
	  'share/icons/custom/world_delete.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/world_delete.png' \
	  'share/icons/custom/world_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/world_edit.png' \
	  'share/icons/custom/world_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/world_go.png' \
	  'share/icons/custom/world_link.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/world_link.png' \
	  'share/icons/custom/wrench.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/wrench.png' \
	  'share/icons/custom/wrench_orange.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/wrench_orange.png' \
	  'share/icons/custom/www_page.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/www_page.png' \
	  'share/icons/custom/x_ray.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/x_ray.png' \
	  'share/icons/custom/yacht.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/yacht.png' \
	  'share/icons/custom/yellow_submarine.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/yellow_submarine.png' \
	  'share/icons/custom/yin_yang.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/yin_yang.png' \
	  'share/icons/custom/zodiac.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac.png' \
	  'share/icons/custom/zodiac_aries.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_aries.png' \
	  'share/icons/custom/zodiac_cancer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_cancer.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/zodiac_capricorn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_capricorn.png' \
	  'share/icons/custom/zodiac_gemini.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_gemini.png' \
	  'share/icons/custom/zodiac_leo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_leo.png' \
	  'share/icons/custom/zodiac_libra.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_libra.png' \
	  'share/icons/custom/zodiac_pisces.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_pisces.png' \
	  'share/icons/custom/zodiac_sagittarius.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_sagittarius.png' \
	  'share/icons/custom/zodiac_scorpio.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_scorpio.png' \
	  'share/icons/custom/zodiac_taurus.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_taurus.png' \
	  'share/icons/custom/zodiac_virgo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zodiac_virgo.png' \
	  'share/icons/custom/zone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zone.png' \
	  'share/icons/custom/zone_money.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zone_money.png' \
	  'share/icons/custom/zone_resize.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zone_resize.png' \
	  'share/icons/custom/zone_resize_actual.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zone_resize_actual.png' \
	  'share/icons/custom/zone_select.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zone_select.png' \
	  'share/icons/custom/zoom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom.png' \
	  'share/icons/custom/zoom_actual.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_actual.png' \
	  'share/icons/custom/zoom_actual_equal.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_actual_equal.png' \
	  'share/icons/custom/zoom_extend.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_extend.png' \
	  'share/icons/custom/zoom_fit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_fit.png' \
	  'share/icons/custom/zoom_in.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_in.png' \
	  'share/icons/custom/zoom_last.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_last.png' \
	  'share/icons/custom/zoom_layer.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_layer.png' \
	  'share/icons/custom/zoom_out.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_out.png' \
	  'share/icons/custom/zoom_refresh.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_refresh.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/custom/zoom_selection.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/custom/zoom_selection.png' \
	  'share/icons/main/application_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/application_edit.png' \
	  'share/icons/main/book_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/book_edit.png' \
	  'share/icons/main/camera_black.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/camera_black.png' \
	  'share/icons/main/candy_cane.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/candy_cane.png' \
	  'share/icons/main/clock_red.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/clock_red.png' \
	  'share/icons/main/cold.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/cold.png' \
	  'share/icons/main/compass.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/compass.png' \
	  'share/icons/main/control_pause_record.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/control_pause_record.png' \
	  'share/icons/main/drive_disk.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/drive_disk.png' \
	  'share/icons/main/drop.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/drop.png' \
	  'share/icons/main/ear_listen.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/ear_listen.png' \
	  'share/icons/main/gear_in.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/gear_in.png' \
	  'share/icons/main/gun.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/gun.png' \
	  'share/icons/main/hand_point_090.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/hand_point_090.png' \
	  'share/icons/main/hand_point_270.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/hand_point_270.png' \
	  'share/icons/main/help.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/help.png' \
	  'share/icons/main/keyboard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/keyboard.png' \
	  'share/icons/main/phone_vintage.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/phone_vintage.png' \
	  'share/icons/main/prohibition_button.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/prohibition_button.png' \
	  'share/icons/main/quit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/quit.png' \
	  'share/icons/main/roadworks.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/roadworks.png' \
	  'share/icons/main/routing_go_straight_left.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/routing_go_straight_left.png' \
	  'share/icons/main/save_data.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/save_data.png' \
	  'share/icons/main/separator.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/separator.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/main/user_detective.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/user_detective.png' \
	  'share/icons/main/user_go.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/user_go.png' \
	  'share/icons/main/user_soldier.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/user_soldier.png' \
	  'share/icons/main/video.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/video.png' \
	  'share/icons/main/watermark_table.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/watermark_table.png' \
	  'share/icons/main/wizard.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/wizard.png' \
	  'share/icons/main/world_edit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/main/world_edit.png' \
	  'share/icons/map/icon_EMPTY.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_EMPTY.png' \
	  'share/icons/map/icon_EMPTY_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_EMPTY_large.png' \
	  'share/icons/map/icon_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add.png' \
	  'share/icons/map/icon_add_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_large.png' \
	  'share/icons/map/icon_add_quick_flag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_quick_flag.png' \
	  'share/icons/map/icon_add_quick_flag_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_quick_flag_large.png' \
	  'share/icons/map/icon_add_room_flag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_room_flag.png' \
	  'share/icons/map/icon_add_room_flag_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_room_flag_large.png' \
	  'share/icons/map/icon_add_word.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_word.png' \
	  'share/icons/map/icon_add_word_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_add_word_large.png' \
	  'share/icons/map/icon_all_filters.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_all_filters.png' \
	  'share/icons/map/icon_all_filters_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_all_filters_large.png' \
	  'share/icons/map/icon_attacks.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_attacks.png' \
	  'share/icons/map/icon_attacks_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_attacks_large.png' \
	  'share/icons/map/icon_auto_redraw.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_auto_redraw.png' \
	  'share/icons/map/icon_auto_redraw_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_auto_redraw_large.png' \
	  'share/icons/map/icon_bg_add.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_add.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_bg_add_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_add_large.png' \
	  'share/icons/map/icon_bg_blank.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_blank.png' \
	  'share/icons/map/icon_bg_blank_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_blank_large.png' \
	  'share/icons/map/icon_bg_colour.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_colour.png' \
	  'share/icons/map/icon_bg_colour_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_colour_large.png' \
	  'share/icons/map/icon_bg_default.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_default.png' \
	  'share/icons/map/icon_bg_default_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_default_large.png' \
	  'share/icons/map/icon_bg_remove.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_remove.png' \
	  'share/icons/map/icon_bg_remove_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_remove_large.png' \
	  'share/icons/map/icon_bg_shape.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_shape.png' \
	  'share/icons/map/icon_bg_shape_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_bg_shape_large.png' \
	  'share/icons/map/icon_breakable_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_breakable_exit.png' \
	  'share/icons/map/icon_breakable_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_breakable_exit_large.png' \
	  'share/icons/map/icon_buildings.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_buildings.png' \
	  'share/icons/map/icon_buildings_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_buildings_large.png' \
	  'share/icons/map/icon_centre_current.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_current.png' \
	  'share/icons/map/icon_centre_current_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_current_large.png' \
	  'share/icons/map/icon_centre_last.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_last.png' \
	  'share/icons/map/icon_centre_last_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_last_large.png' \
	  'share/icons/map/icon_centre_middle.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_middle.png' \
	  'share/icons/map/icon_centre_middle_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_middle_large.png' \
	  'share/icons/map/icon_centre_selected.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_selected.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_centre_selected_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_centre_selected_large.png' \
	  'share/icons/map/icon_colour_all_level.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_colour_all_level.png' \
	  'share/icons/map/icon_colour_all_level_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_colour_all_level_large.png' \
	  'share/icons/map/icon_commercial.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_commercial.png' \
	  'share/icons/map/icon_commercial_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_commercial_large.png' \
	  'share/icons/map/icon_connect_click.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_connect_click.png' \
	  'share/icons/map/icon_connect_click_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_connect_click_large.png' \
	  'share/icons/map/icon_custom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_custom.png' \
	  'share/icons/map/icon_custom_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_custom_large.png' \
	  'share/icons/map/icon_dec_visits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_dec_visits.png' \
	  'share/icons/map/icon_dec_visits_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_dec_visits_large.png' \
	  'share/icons/map/icon_drag_mode.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_drag_mode.png' \
	  'share/icons/map/icon_drag_mode_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_drag_mode_large.png' \
	  'share/icons/map/icon_draw_checked.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_checked.png' \
	  'share/icons/map/icon_draw_checked_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_checked_large.png' \
	  'share/icons/map/icon_draw_code.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_code.png' \
	  'share/icons/map/icon_draw_code_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_code_large.png' \
	  'share/icons/map/icon_draw_compare.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_compare.png' \
	  'share/icons/map/icon_draw_compare_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_compare_large.png' \
	  'share/icons/map/icon_draw_complex.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_complex.png' \
	  'share/icons/map/icon_draw_complex_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_complex_large.png' \
	  'share/icons/map/icon_draw_contents.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_contents.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_draw_contents_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_contents_large.png' \
	  'share/icons/map/icon_draw_descrips.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_descrips.png' \
	  'share/icons/map/icon_draw_descrips_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_descrips_large.png' \
	  'share/icons/map/icon_draw_exclusive.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_exclusive.png' \
	  'share/icons/map/icon_draw_exclusive_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_exclusive_large.png' \
	  'share/icons/map/icon_draw_flags.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_flags.png' \
	  'share/icons/map/icon_draw_flags_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_flags_large.png' \
	  'share/icons/map/icon_draw_hidden.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_hidden.png' \
	  'share/icons/map/icon_draw_hidden_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_hidden_large.png' \
	  'share/icons/map/icon_draw_none.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_none.png' \
	  'share/icons/map/icon_draw_none_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_none_large.png' \
	  'share/icons/map/icon_draw_ornaments.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_ornaments.png' \
	  'share/icons/map/icon_draw_ornaments_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_ornaments_large.png' \
	  'share/icons/map/icon_draw_patterns.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_patterns.png' \
	  'share/icons/map/icon_draw_patterns_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_patterns_large.png' \
	  'share/icons/map/icon_draw_shadow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_shadow.png' \
	  'share/icons/map/icon_draw_shadow_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_shadow_large.png' \
	  'share/icons/map/icon_draw_simple.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_simple.png' \
	  'share/icons/map/icon_draw_simple_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_simple_large.png' \
	  'share/icons/map/icon_draw_super.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_super.png' \
	  'share/icons/map/icon_draw_super_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_super_large.png' \
	  'share/icons/map/icon_draw_temp.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_temp.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_draw_temp_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_temp_large.png' \
	  'share/icons/map/icon_draw_visits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_visits.png' \
	  'share/icons/map/icon_draw_visits_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_visits_large.png' \
	  'share/icons/map/icon_draw_vnum.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_vnum.png' \
	  'share/icons/map/icon_draw_vnum_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_vnum_large.png' \
	  'share/icons/map/icon_draw_words.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_words.png' \
	  'share/icons/map/icon_draw_words_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_draw_words_large.png' \
	  'share/icons/map/icon_edit_dict.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_edit_dict.png' \
	  'share/icons/map/icon_edit_dict_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_edit_dict_large.png' \
	  'share/icons/map/icon_edit_model.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_edit_model.png' \
	  'share/icons/map/icon_edit_model_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_edit_model_large.png' \
	  'share/icons/map/icon_edit_painter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_edit_painter.png' \
	  'share/icons/map/icon_edit_painter_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_edit_painter_large.png' \
	  'share/icons/map/icon_enable_painter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_enable_painter.png' \
	  'share/icons/map/icon_enable_painter_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_enable_painter_large.png' \
	  'share/icons/map/icon_fail_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_fail_exit.png' \
	  'share/icons/map/icon_fail_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_fail_exit_large.png' \
	  'share/icons/map/icon_follow.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_follow.png' \
	  'share/icons/map/icon_follow_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_follow_large.png' \
	  'share/icons/map/icon_graffiti_mode.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_graffiti_mode.png' \
	  'share/icons/map/icon_graffiti_mode_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_graffiti_mode_large.png' \
	  'share/icons/map/icon_guilds.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_guilds.png' \
	  'share/icons/map/icon_guilds_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_guilds_large.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_horizontal_lengths.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_horizontal_lengths.png' \
	  'share/icons/map/icon_horizontal_lengths_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_horizontal_lengths_large.png' \
	  'share/icons/map/icon_impassable_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_impassable_exit.png' \
	  'share/icons/map/icon_impassable_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_impassable_exit_large.png' \
	  'share/icons/map/icon_inc_visits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_inc_visits.png' \
	  'share/icons/map/icon_inc_visits_current.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_inc_visits_current.png' \
	  'share/icons/map/icon_inc_visits_current_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_inc_visits_current_large.png' \
	  'share/icons/map/icon_inc_visits_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_inc_visits_large.png' \
	  'share/icons/map/icon_light.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_light.png' \
	  'share/icons/map/icon_light_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_light_large.png' \
	  'share/icons/map/icon_lockable_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_lockable_exit.png' \
	  'share/icons/map/icon_lockable_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_lockable_exit_large.png' \
	  'share/icons/map/icon_markers.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_markers.png' \
	  'share/icons/map/icon_markers_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_markers_large.png' \
	  'share/icons/map/icon_move_click.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_move_click.png' \
	  'share/icons/map/icon_move_click_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_move_click_large.png' \
	  'share/icons/map/icon_move_down.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_move_down.png' \
	  'share/icons/map/icon_move_down_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_move_down_large.png' \
	  'share/icons/map/icon_move_up.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_move_up.png' \
	  'share/icons/map/icon_move_up_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_move_up_large.png' \
	  'share/icons/map/icon_mystery_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_mystery_exit.png' \
	  'share/icons/map/icon_mystery_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_mystery_exit_large.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_navigation.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_navigation.png' \
	  'share/icons/map/icon_navigation_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_navigation_large.png' \
	  'share/icons/map/icon_no_counts.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_no_counts.png' \
	  'share/icons/map/icon_no_counts_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_no_counts_large.png' \
	  'share/icons/map/icon_no_ornament.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_no_ornament.png' \
	  'share/icons/map/icon_no_ornament_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_no_ornament_large.png' \
	  'share/icons/map/icon_objects.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_objects.png' \
	  'share/icons/map/icon_objects_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_objects_large.png' \
	  'share/icons/map/icon_obscured_exits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_obscured_exits.png' \
	  'share/icons/map/icon_obscured_exits_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_obscured_exits_large.png' \
	  'share/icons/map/icon_obscured_radius.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_obscured_radius.png' \
	  'share/icons/map/icon_obscured_radius_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_obscured_radius_large.png' \
	  'share/icons/map/icon_openable_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_openable_exit.png' \
	  'share/icons/map/icon_openable_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_openable_exit_large.png' \
	  'share/icons/map/icon_paint_all.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_all.png' \
	  'share/icons/map/icon_paint_all_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_all_large.png' \
	  'share/icons/map/icon_paint_border.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_border.png' \
	  'share/icons/map/icon_paint_border_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_border_large.png' \
	  'share/icons/map/icon_paint_new.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_new.png' \
	  'share/icons/map/icon_paint_new_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_new_large.png' \
	  'share/icons/map/icon_paint_normal.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_normal.png' \
	  'share/icons/map/icon_paint_normal_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_normal_large.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_paint_wild.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_wild.png' \
	  'share/icons/map/icon_paint_wild_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_paint_wild_large.png' \
	  'share/icons/map/icon_pickable_exit.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_pickable_exit.png' \
	  'share/icons/map/icon_pickable_exit_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_pickable_exit_large.png' \
	  'share/icons/map/icon_quests.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_quests.png' \
	  'share/icons/map/icon_quests_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_quests_large.png' \
	  'share/icons/map/icon_quick_multi.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_quick_multi.png' \
	  'share/icons/map/icon_quick_multi_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_quick_multi_large.png' \
	  'share/icons/map/icon_quick_single.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_quick_single.png' \
	  'share/icons/map/icon_quick_single_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_quick_single_large.png' \
	  'share/icons/map/icon_remove.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_remove.png' \
	  'share/icons/map/icon_remove_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_remove_large.png' \
	  'share/icons/map/icon_remove_quick_flag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_remove_quick_flag.png' \
	  'share/icons/map/icon_remove_quick_flag_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_remove_quick_flag_large.png' \
	  'share/icons/map/icon_remove_room_flag.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_remove_room_flag.png' \
	  'share/icons/map/icon_remove_room_flag_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_remove_room_flag_large.png' \
	  'share/icons/map/icon_reset_locator.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_reset_locator.png' \
	  'share/icons/map/icon_reset_locator_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_reset_locator_large.png' \
	  'share/icons/map/icon_reset_visits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_reset_visits.png' \
	  'share/icons/map/icon_reset_visits_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_reset_visits_large.png' \
	  'share/icons/map/icon_search_model.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_search_model.png' \
	  'share/icons/map/icon_search_model_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_search_model_large.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_set.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_set.png' \
	  'share/icons/map/icon_set_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_set_large.png' \
	  'share/icons/map/icon_set_visits.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_set_visits.png' \
	  'share/icons/map/icon_set_visits_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_set_visits_large.png' \
	  'share/icons/map/icon_spare_filter.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_spare_filter.png' \
	  'share/icons/map/icon_spare_filter_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_spare_filter_large.png' \
	  'share/icons/map/icon_structures.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_structures.png' \
	  'share/icons/map/icon_structures_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_structures_large.png' \
	  'share/icons/map/icon_switch.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_switch.png' \
	  'share/icons/map/icon_switch_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_switch_large.png' \
	  'share/icons/map/icon_take_screenshot.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_take_screenshot.png' \
	  'share/icons/map/icon_take_screenshot_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_take_screenshot_large.png' \
	  'share/icons/map/icon_terrain.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_terrain.png' \
	  'share/icons/map/icon_terrain_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_terrain_large.png' \
	  'share/icons/map/icon_toggle_graffiti.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_toggle_graffiti.png' \
	  'share/icons/map/icon_toggle_graffiti_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_toggle_graffiti_large.png' \
	  'share/icons/map/icon_track_always.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_always.png' \
	  'share/icons/map/icon_track_always_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_always_large.png' \
	  'share/icons/map/icon_track_centre.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_centre.png' \
	  'share/icons/map/icon_track_centre_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_centre_large.png' \
	  'share/icons/map/icon_track_edge.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_edge.png' \
	  'share/icons/map/icon_track_edge_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_edge_large.png' \
	  'share/icons/map/icon_track_room.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_room.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/map/icon_track_room_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_room_large.png' \
	  'share/icons/map/icon_track_visible.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_visible.png' \
	  'share/icons/map/icon_track_visible_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_track_visible_large.png' \
	  'share/icons/map/icon_update.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_update.png' \
	  'share/icons/map/icon_update_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_update_large.png' \
	  'share/icons/map/icon_use_region.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_use_region.png' \
	  'share/icons/map/icon_use_region_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_use_region_large.png' \
	  'share/icons/map/icon_vertical_lengths.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_vertical_lengths.png' \
	  'share/icons/map/icon_vertical_lengths_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_vertical_lengths_large.png' \
	  'share/icons/map/icon_wait.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_wait.png' \
	  'share/icons/map/icon_wait_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/map/icon_wait_large.png' \
	  'share/icons/replace/dialogue_replace_error.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/replace/dialogue_replace_error.png' \
	  'share/icons/replace/dialogue_replace_info.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/replace/dialogue_replace_info.png' \
	  'share/icons/replace/dialogue_replace_question.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/replace/dialogue_replace_question.png' \
	  'share/icons/replace/dialogue_replace_warning.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/replace/dialogue_replace_warning.png' \
	  'share/icons/search/application_tile_vertical.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/search/application_tile_vertical.png' \
	  'share/icons/search/arrow_down.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/search/arrow_down.png' \
	  'share/icons/search/arrow_up.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/search/arrow_up.png' \
	  'share/icons/search/broom.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/search/broom.png' \
	  'share/icons/search/capitalization.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/search/capitalization.png' \
	  'share/icons/search/token_shortland_character.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/search/token_shortland_character.png' \
	  'share/icons/setup/attack_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/attack_task.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/setup/basic_zonemap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/basic_zonemap.png' \
	  'share/icons/setup/bypass_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/bypass_sigil.png' \
	  'share/icons/setup/client_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/client_sigil.png' \
	  'share/icons/setup/compass_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/compass_task.png' \
	  'share/icons/setup/divert_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/divert_task.png' \
	  'share/icons/setup/echo_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/echo_sigil.png' \
	  'share/icons/setup/extended_zonemap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/extended_zonemap.png' \
	  'share/icons/setup/forced_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/forced_sigil.png' \
	  'share/icons/setup/help.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/help.png' \
	  'share/icons/setup/horizontal_zonemap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/horizontal_zonemap.png' \
	  'share/icons/setup/inventory_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/inventory_task.png' \
	  'share/icons/setup/launch_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/launch_task.png' \
	  'share/icons/setup/locator_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/locator_task.png' \
	  'share/icons/setup/multi_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/multi_sigil.png' \
	  'share/icons/setup/no_zonemap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/no_zonemap.png' \
	  'share/icons/setup/notepad_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/notepad_task.png' \
	  'share/icons/setup/perl_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/perl_sigil.png' \
	  'share/icons/setup/script_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/script_sigil.png' \
	  'share/icons/setup/shared.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/shared.png' \
	  'share/icons/setup/single.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/single.png' \
	  'share/icons/setup/speedwalk_sigil.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/speedwalk_sigil.png' \
	  'share/icons/setup/status_task.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/status_task.png' \
	  'share/icons/setup/vertical_zonemap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/vertical_zonemap.png' \
	  'share/icons/setup/widescreen_zonemap.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/setup/widescreen_zonemap.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/smileys/emotion_angel.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_angel.bmp' \
	  'share/icons/smileys/emotion_devil.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_devil.bmp' \
	  'share/icons/smileys/emotion_evilgrin.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_evilgrin.bmp' \
	  'share/icons/smileys/emotion_haha.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_haha.bmp' \
	  'share/icons/smileys/emotion_horror.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_horror.bmp' \
	  'share/icons/smileys/emotion_kiss.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_kiss.bmp' \
	  'share/icons/smileys/emotion_love.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_love.bmp' \
	  'share/icons/smileys/emotion_mad.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_mad.bmp' \
	  'share/icons/smileys/emotion_misdoubt.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_misdoubt.bmp' \
	  'share/icons/smileys/emotion_red.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_red.bmp' \
	  'share/icons/smileys/emotion_sad.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_sad.bmp' \
	  'share/icons/smileys/emotion_shocked.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_shocked.bmp' \
	  'share/icons/smileys/emotion_smile.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_smile.bmp' \
	  'share/icons/smileys/emotion_tongue.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_tongue.bmp' \
	  'share/icons/smileys/emotion_too_sad.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_too_sad.bmp' \
	  'share/icons/smileys/emotion_what.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_what.bmp' \
	  'share/icons/smileys/emotion_wink.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/smileys/emotion_wink.bmp' \
	  'share/icons/system/adult.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/adult.png' \
	  'share/icons/system/adult_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/adult_large.png' \
	  'share/icons/system/client_logo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/client_logo.png' \
	  'share/icons/system/client_logo_18.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/client_logo_18.png' \
	  'share/icons/system/client_logo_xmas.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/client_logo_xmas.png' \
	  'share/icons/system/client_logo_xmas_18.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/client_logo_xmas_18.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/system/default_chat.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/default_chat.bmp' \
	  'share/icons/system/default_contact.bmp' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/default_contact.bmp' \
	  'share/icons/system/dialogue_icon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/dialogue_icon.png' \
	  'share/icons/system/dialogue_icon_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/dialogue_icon_large.png' \
	  'share/icons/system/dialogue_icon_medium.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/dialogue_icon_medium.png' \
	  'share/icons/system/dialogue_icon_xmas.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/dialogue_icon_xmas.png' \
	  'share/icons/system/dialogue_icon_xmas_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/dialogue_icon_xmas_large.png' \
	  'share/icons/system/dialogue_icon_xmas_medium.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/dialogue_icon_xmas_medium.png' \
	  'share/icons/system/irreversible.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/irreversible.png' \
	  'share/icons/system/mapper.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/mapper.png' \
	  'share/icons/system/mapper_large.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/mapper_large.png' \
	  'share/icons/system/mapper_medium.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/system/mapper_medium.png' \
	  'share/icons/win/icon_custom_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_custom_win_128.png' \
	  'share/icons/win/icon_custom_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_custom_win_16.png' \
	  'share/icons/win/icon_custom_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_custom_win_32.png' \
	  'share/icons/win/icon_custom_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_custom_win_48.png' \
	  'share/icons/win/icon_custom_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_custom_win_64.png' \
	  'share/icons/win/icon_dialogue_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_dialogue_win_128.png' \
	  'share/icons/win/icon_dialogue_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_dialogue_win_16.png' \
	  'share/icons/win/icon_dialogue_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_dialogue_win_32.png' \
	  'share/icons/win/icon_dialogue_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_dialogue_win_48.png' \
	  'share/icons/win/icon_dialogue_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_dialogue_win_64.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/win/icon_edit_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_edit_win_128.png' \
	  'share/icons/win/icon_edit_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_edit_win_16.png' \
	  'share/icons/win/icon_edit_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_edit_win_32.png' \
	  'share/icons/win/icon_edit_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_edit_win_48.png' \
	  'share/icons/win/icon_edit_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_edit_win_64.png' \
	  'share/icons/win/icon_external_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_external_win_128.png' \
	  'share/icons/win/icon_external_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_external_win_16.png' \
	  'share/icons/win/icon_external_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_external_win_32.png' \
	  'share/icons/win/icon_external_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_external_win_48.png' \
	  'share/icons/win/icon_external_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_external_win_64.png' \
	  'share/icons/win/icon_fixed_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_fixed_win_128.png' \
	  'share/icons/win/icon_fixed_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_fixed_win_16.png' \
	  'share/icons/win/icon_fixed_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_fixed_win_32.png' \
	  'share/icons/win/icon_fixed_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_fixed_win_48.png' \
	  'share/icons/win/icon_fixed_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_fixed_win_64.png' \
	  'share/icons/win/icon_main_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_main_win_128.png' \
	  'share/icons/win/icon_main_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_main_win_16.png' \
	  'share/icons/win/icon_main_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_main_win_32.png' \
	  'share/icons/win/icon_main_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_main_win_48.png' \
	  'share/icons/win/icon_main_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_main_win_64.png' \
	  'share/icons/win/icon_map_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_map_win_128.png' \
	  'share/icons/win/icon_map_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_map_win_16.png' \
	  'share/icons/win/icon_map_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_map_win_32.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/win/icon_map_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_map_win_48.png' \
	  'share/icons/win/icon_map_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_map_win_64.png' \
	  'share/icons/win/icon_other_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_other_win_128.png' \
	  'share/icons/win/icon_other_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_other_win_16.png' \
	  'share/icons/win/icon_other_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_other_win_32.png' \
	  'share/icons/win/icon_other_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_other_win_48.png' \
	  'share/icons/win/icon_other_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_other_win_64.png' \
	  'share/icons/win/icon_pref_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_pref_win_128.png' \
	  'share/icons/win/icon_pref_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_pref_win_16.png' \
	  'share/icons/win/icon_pref_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_pref_win_32.png' \
	  'share/icons/win/icon_pref_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_pref_win_48.png' \
	  'share/icons/win/icon_pref_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_pref_win_64.png' \
	  'share/icons/win/icon_protocol_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_protocol_win_128.png' \
	  'share/icons/win/icon_protocol_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_protocol_win_16.png' \
	  'share/icons/win/icon_protocol_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_protocol_win_32.png' \
	  'share/icons/win/icon_protocol_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_protocol_win_48.png' \
	  'share/icons/win/icon_protocol_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_protocol_win_64.png' \
	  'share/icons/win/icon_viewer_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_viewer_win_128.png' \
	  'share/icons/win/icon_viewer_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_viewer_win_16.png' \
	  'share/icons/win/icon_viewer_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_viewer_win_32.png' \
	  'share/icons/win/icon_viewer_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_viewer_win_48.png' \
	  'share/icons/win/icon_viewer_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_viewer_win_64.png' \
	  'share/icons/win/icon_wiz_win_128.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_wiz_win_128.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/icons/win/icon_wiz_win_16.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_wiz_win_16.png' \
	  'share/icons/win/icon_wiz_win_32.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_wiz_win_32.png' \
	  'share/icons/win/icon_wiz_win_48.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_wiz_win_48.png' \
	  'share/icons/win/icon_wiz_win_64.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/icons/win/icon_wiz_win_64.png' \
	  'share/images/COPYING' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/images/COPYING' \
	  'share/images/viewerbg.jpg' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/images/viewerbg.jpg' \
	  'share/items/mudlist/mudlist.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/mudlist/mudlist.txt' \
	  'share/items/phrasebooks/_template.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/_template.txt' \
	  'share/items/phrasebooks/dutch.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/dutch.txt' \
	  'share/items/phrasebooks/english.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/english.txt' \
	  'share/items/phrasebooks/estonian.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/estonian.txt' \
	  'share/items/phrasebooks/french.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/french.txt' \
	  'share/items/phrasebooks/german.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/german.txt' \
	  'share/items/phrasebooks/italian.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/italian.txt' \
	  'share/items/phrasebooks/polish.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/polish.txt' \
	  'share/items/phrasebooks/portuguese.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/portuguese.txt' \
	  'share/items/phrasebooks/russian.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/russian.txt' \
	  'share/items/phrasebooks/spanish.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/spanish.txt' \
	  'share/items/phrasebooks/swedish.txt' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/phrasebooks/swedish.txt' \
	  'share/items/readme/README' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/readme/README' \
	  'share/items/scripts/hello.bas' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/scripts/hello.bas' \
	  'share/items/scripts/test.bas' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/scripts/test.bas' \
	  'share/items/scripts/wumpus.bas' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/scripts/wumpus.bas' \
	  'share/items/sounds/COPYING' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/COPYING' \
	  'share/items/sounds/afk.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/afk.mp3' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/sounds/ahem.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/ahem.mp3' \
	  'share/items/sounds/alarm.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/alarm.mp3' \
	  'share/items/sounds/alert.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/alert.mp3' \
	  'share/items/sounds/attack.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/attack.mp3' \
	  'share/items/sounds/baby.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/baby.mp3' \
	  'share/items/sounds/balloon.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/balloon.mp3' \
	  'share/items/sounds/barking.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/barking.mp3' \
	  'share/items/sounds/bear.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/bear.mp3' \
	  'share/items/sounds/beep.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/beep.mp3' \
	  'share/items/sounds/belch.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/belch.mp3' \
	  'share/items/sounds/bell.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/bell.mp3' \
	  'share/items/sounds/bottles.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/bottles.mp3' \
	  'share/items/sounds/boxing.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/boxing.mp3' \
	  'share/items/sounds/broom.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/broom.mp3' \
	  'share/items/sounds/bullet.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/bullet.mp3' \
	  'share/items/sounds/call.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/call.mp3' \
	  'share/items/sounds/cheer.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/cheer.mp3' \
	  'share/items/sounds/chime.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/chime.mp3' \
	  'share/items/sounds/chipmunk.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/chipmunk.mp3' \
	  'share/items/sounds/clap.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/clap.mp3' \
	  'share/items/sounds/coins.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/coins.mp3' \
	  'share/items/sounds/computer.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/computer.mp3' \
	  'share/items/sounds/cops.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/cops.mp3' \
	  'share/items/sounds/cow.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/cow.mp3' \
	  'share/items/sounds/crash.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/crash.mp3' \
	  'share/items/sounds/cuckoo.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/cuckoo.mp3' \
	  'share/items/sounds/death.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/death.mp3' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/sounds/deposit.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/deposit.mp3' \
	  'share/items/sounds/dixie.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/dixie.mp3' \
	  'share/items/sounds/dragon.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/dragon.mp3' \
	  'share/items/sounds/drum.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/drum.mp3' \
	  'share/items/sounds/ecg.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/ecg.mp3' \
	  'share/items/sounds/elephant.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/elephant.mp3' \
	  'share/items/sounds/error.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/error.mp3' \
	  'share/items/sounds/explode.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/explode.mp3' \
	  'share/items/sounds/fireworks.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/fireworks.mp3' \
	  'share/items/sounds/flyby.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/flyby.mp3' \
	  'share/items/sounds/footsteps.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/footsteps.mp3' \
	  'share/items/sounds/frogs.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/frogs.mp3' \
	  'share/items/sounds/gorilla.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/gorilla.mp3' \
	  'share/items/sounds/greeting.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/greeting.mp3' \
	  'share/items/sounds/gun.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/gun.mp3' \
	  'share/items/sounds/hammer.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/hammer.mp3' \
	  'share/items/sounds/hawk.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/hawk.mp3' \
	  'share/items/sounds/heartbeat.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/heartbeat.mp3' \
	  'share/items/sounds/hiccup.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/hiccup.mp3' \
	  'share/items/sounds/honk.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/honk.mp3' \
	  'share/items/sounds/jet.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/jet.mp3' \
	  'share/items/sounds/kick.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/kick.mp3' \
	  'share/items/sounds/kid.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/kid.mp3' \
	  'share/items/sounds/kill.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/kill.mp3' \
	  'share/items/sounds/kookaburra.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/kookaburra.mp3' \
	  'share/items/sounds/landing.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/landing.mp3' \
	  'share/items/sounds/laser.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/laser.mp3' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/sounds/laugh.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/laugh.mp3' \
	  'share/items/sounds/lion.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/lion.mp3' \
	  'share/items/sounds/lost.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/lost.mp3' \
	  'share/items/sounds/march.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/march.mp3' \
	  'share/items/sounds/morse.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/morse.mp3' \
	  'share/items/sounds/mosquito.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/mosquito.mp3' \
	  'share/items/sounds/murder.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/murder.mp3' \
	  'share/items/sounds/notify.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/notify.mp3' \
	  'share/items/sounds/oink.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/oink.mp3' \
	  'share/items/sounds/party.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/party.mp3' \
	  'share/items/sounds/phone1.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/phone1.mp3' \
	  'share/items/sounds/phone2.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/phone2.mp3' \
	  'share/items/sounds/phone3.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/phone3.mp3' \
	  'share/items/sounds/phone4.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/phone4.mp3' \
	  'share/items/sounds/phone5.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/phone5.mp3' \
	  'share/items/sounds/piano.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/piano.mp3' \
	  'share/items/sounds/plop.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/plop.mp3' \
	  'share/items/sounds/pour.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/pour.mp3' \
	  'share/items/sounds/punch.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/punch.mp3' \
	  'share/items/sounds/raygun.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/raygun.mp3' \
	  'share/items/sounds/ready.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/ready.mp3' \
	  'share/items/sounds/ring.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/ring.mp3' \
	  'share/items/sounds/rooster.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/rooster.mp3' \
	  'share/items/sounds/sander.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/sander.mp3' \
	  'share/items/sounds/saw.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/saw.mp3' \
	  'share/items/sounds/sharpen.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/sharpen.mp3' \
	  'share/items/sounds/short.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/short.mp3' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/sounds/slap.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/slap.mp3' \
	  'share/items/sounds/sleigh.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/sleigh.mp3' \
	  'share/items/sounds/snooker.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/snooker.mp3' \
	  'share/items/sounds/snoring.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/snoring.mp3' \
	  'share/items/sounds/squish.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/squish.mp3' \
	  'share/items/sounds/suspense.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/suspense.mp3' \
	  'share/items/sounds/takeoff.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/takeoff.mp3' \
	  'share/items/sounds/thunder.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/thunder.mp3' \
	  'share/items/sounds/torch.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/torch.mp3' \
	  'share/items/sounds/train.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/train.mp3' \
	  'share/items/sounds/twist.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/twist.mp3' \
	  'share/items/sounds/typewriter.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/typewriter.mp3' \
	  'share/items/sounds/unscrew.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/unscrew.mp3' \
	  'share/items/sounds/vibrate.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/vibrate.mp3' \
	  'share/items/sounds/warble.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/warble.mp3' \
	  'share/items/sounds/whip.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/whip.mp3' \
	  'share/items/sounds/whistle.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/whistle.mp3' \
	  'share/items/sounds/withdraw.mp3' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/sounds/withdraw.mp3' \
	  'share/items/worlds/aardwolf/aardwolf.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aardwolf/aardwolf.amx' \
	  'share/items/worlds/aardwolf/aardwolf.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aardwolf/aardwolf.png' \
	  'share/items/worlds/aardwolf/aardwolf.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aardwolf/aardwolf.tgz' \
	  'share/items/worlds/achaea/achaea.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/achaea/achaea.amx' \
	  'share/items/worlds/achaea/achaea.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/achaea/achaea.png' \
	  'share/items/worlds/achaea/achaea.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/achaea/achaea.tgz' \
	  'share/items/worlds/advun/advun.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/advun/advun.amx' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/advun/advun.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/advun/advun.png' \
	  'share/items/worlds/advun/advun.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/advun/advun.tgz' \
	  'share/items/worlds/aetolia/aetolia.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aetolia/aetolia.amx' \
	  'share/items/worlds/aetolia/aetolia.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aetolia/aetolia.png' \
	  'share/items/worlds/aetolia/aetolia.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aetolia/aetolia.tgz' \
	  'share/items/worlds/alteraeon/alteraeon.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/alteraeon/alteraeon.amx' \
	  'share/items/worlds/alteraeon/alteraeon.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/alteraeon/alteraeon.png' \
	  'share/items/worlds/alteraeon/alteraeon.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/alteraeon/alteraeon.tgz' \
	  'share/items/worlds/anguish/anguish.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/anguish/anguish.amx' \
	  'share/items/worlds/anguish/anguish.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/anguish/anguish.png' \
	  'share/items/worlds/anguish/anguish.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/anguish/anguish.tgz' \
	  'share/items/worlds/aochaos/aochaos.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aochaos/aochaos.amx' \
	  'share/items/worlds/aochaos/aochaos.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aochaos/aochaos.png' \
	  'share/items/worlds/aochaos/aochaos.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/aochaos/aochaos.tgz' \
	  'share/items/worlds/archipelago/archipelago.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/archipelago/archipelago.amx' \
	  'share/items/worlds/archipelago/archipelago.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/archipelago/archipelago.png' \
	  'share/items/worlds/archipelago/archipelago.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/archipelago/archipelago.tgz' \
	  'share/items/worlds/arctic/arctic.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/arctic/arctic.amx' \
	  'share/items/worlds/arctic/arctic.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/arctic/arctic.png' \
	  'share/items/worlds/arctic/arctic.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/arctic/arctic.tgz' \
	  'share/items/worlds/ateraan/ateraan.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ateraan/ateraan.amx' \
	  'share/items/worlds/ateraan/ateraan.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ateraan/ateraan.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/ateraan/ateraan.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ateraan/ateraan.tgz' \
	  'share/items/worlds/avalonmud/avalonmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avalonmud/avalonmud.amx' \
	  'share/items/worlds/avalonmud/avalonmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avalonmud/avalonmud.png' \
	  'share/items/worlds/avalonmud/avalonmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avalonmud/avalonmud.tgz' \
	  'share/items/worlds/avalonrpg/avalonrpg.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avalonrpg/avalonrpg.amx' \
	  'share/items/worlds/avalonrpg/avalonrpg.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avalonrpg/avalonrpg.png' \
	  'share/items/worlds/avalonrpg/avalonrpg.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avalonrpg/avalonrpg.tgz' \
	  'share/items/worlds/avatarmud/avatarmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avatarmud/avatarmud.amx' \
	  'share/items/worlds/avatarmud/avatarmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avatarmud/avatarmud.png' \
	  'share/items/worlds/avatarmud/avatarmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/avatarmud/avatarmud.tgz' \
	  'share/items/worlds/batmud/batmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/batmud/batmud.amx' \
	  'share/items/worlds/batmud/batmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/batmud/batmud.png' \
	  'share/items/worlds/batmud/batmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/batmud/batmud.tgz' \
	  'share/items/worlds/bedlam/bedlam.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/bedlam/bedlam.amx' \
	  'share/items/worlds/bedlam/bedlam.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/bedlam/bedlam.png' \
	  'share/items/worlds/bedlam/bedlam.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/bedlam/bedlam.tgz' \
	  'share/items/worlds/burningmud/burningmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/burningmud/burningmud.amx' \
	  'share/items/worlds/burningmud/burningmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/burningmud/burningmud.png' \
	  'share/items/worlds/burningmud/burningmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/burningmud/burningmud.tgz' \
	  'share/items/worlds/bylins/bylins.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/bylins/bylins.amx' \
	  'share/items/worlds/bylins/bylins.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/bylins/bylins.png' \
	  'share/items/worlds/bylins/bylins.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/bylins/bylins.tgz' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/carrion/carrion.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/carrion/carrion.amx' \
	  'share/items/worlds/carrion/carrion.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/carrion/carrion.png' \
	  'share/items/worlds/carrion/carrion.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/carrion/carrion.tgz' \
	  'share/items/worlds/clessidra/clessidra.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/clessidra/clessidra.amx' \
	  'share/items/worlds/clessidra/clessidra.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/clessidra/clessidra.png' \
	  'share/items/worlds/clessidra/clessidra.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/clessidra/clessidra.tgz' \
	  'share/items/worlds/clok/clok.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/clok/clok.amx' \
	  'share/items/worlds/clok/clok.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/clok/clok.png' \
	  'share/items/worlds/clok/clok.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/clok/clok.tgz' \
	  'share/items/worlds/coffeemud/coffeemud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/coffeemud/coffeemud.amx' \
	  'share/items/worlds/coffeemud/coffeemud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/coffeemud/coffeemud.png' \
	  'share/items/worlds/coffeemud/coffeemud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/coffeemud/coffeemud.tgz' \
	  'share/items/worlds/cryosphere/cryosphere.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/cryosphere/cryosphere.amx' \
	  'share/items/worlds/cryosphere/cryosphere.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/cryosphere/cryosphere.png' \
	  'share/items/worlds/cryosphere/cryosphere.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/cryosphere/cryosphere.tgz' \
	  'share/items/worlds/cyberassault/cyberassault.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/cyberassault/cyberassault.amx' \
	  'share/items/worlds/cyberassault/cyberassault.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/cyberassault/cyberassault.png' \
	  'share/items/worlds/cyberassault/cyberassault.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/cyberassault/cyberassault.tgz' \
	  'share/items/worlds/darkrealms/darkrealms.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/darkrealms/darkrealms.amx' \
	  'share/items/worlds/darkrealms/darkrealms.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/darkrealms/darkrealms.png' \
	  'share/items/worlds/darkrealms/darkrealms.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/darkrealms/darkrealms.tgz' \
	  'share/items/worlds/dartmud/dartmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dartmud/dartmud.amx' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/dartmud/dartmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dartmud/dartmud.png' \
	  'share/items/worlds/dartmud/dartmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dartmud/dartmud.tgz' \
	  'share/items/worlds/dawn/dawn.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dawn/dawn.amx' \
	  'share/items/worlds/dawn/dawn.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dawn/dawn.png' \
	  'share/items/worlds/dawn/dawn.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dawn/dawn.tgz' \
	  'share/items/worlds/discworld/discworld.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/discworld/discworld.amx' \
	  'share/items/worlds/discworld/discworld.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/discworld/discworld.png' \
	  'share/items/worlds/discworld/discworld.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/discworld/discworld.tgz' \
	  'share/items/worlds/dragonstone/dragonstone.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dragonstone/dragonstone.amx' \
	  'share/items/worlds/dragonstone/dragonstone.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dragonstone/dragonstone.png' \
	  'share/items/worlds/dragonstone/dragonstone.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dragonstone/dragonstone.tgz' \
	  'share/items/worlds/dsdev/dsdev.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dsdev/dsdev.amx' \
	  'share/items/worlds/dsdev/dsdev.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dsdev/dsdev.png' \
	  'share/items/worlds/dsdev/dsdev.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dsdev/dsdev.tgz' \
	  'share/items/worlds/dslands/dslands.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dslands/dslands.amx' \
	  'share/items/worlds/dslands/dslands.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dslands/dslands.png' \
	  'share/items/worlds/dslands/dslands.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dslands/dslands.tgz' \
	  'share/items/worlds/dslocal/dslocal.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dslocal/dslocal.amx' \
	  'share/items/worlds/dslocal/dslocal.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dslocal/dslocal.png' \
	  'share/items/worlds/dslocal/dslocal.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dslocal/dslocal.tgz' \
	  'share/items/worlds/dsprime/dsprime.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dsprime/dsprime.amx' \
	  'share/items/worlds/dsprime/dsprime.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dsprime/dsprime.png' \
	  'share/items/worlds/dsprime/dsprime.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dsprime/dsprime.tgz' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/dswords/dswords.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dswords/dswords.amx' \
	  'share/items/worlds/dswords/dswords.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dswords/dswords.png' \
	  'share/items/worlds/dswords/dswords.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dswords/dswords.tgz' \
	  'share/items/worlds/dunemud/dunemud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dunemud/dunemud.amx' \
	  'share/items/worlds/dunemud/dunemud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dunemud/dunemud.png' \
	  'share/items/worlds/dunemud/dunemud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/dunemud/dunemud.tgz' \
	  'share/items/worlds/duris/duris.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/duris/duris.amx' \
	  'share/items/worlds/duris/duris.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/duris/duris.png' \
	  'share/items/worlds/duris/duris.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/duris/duris.tgz' \
	  'share/items/worlds/edmud/edmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/edmud/edmud.amx' \
	  'share/items/worlds/edmud/edmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/edmud/edmud.png' \
	  'share/items/worlds/edmud/edmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/edmud/edmud.tgz' \
	  'share/items/worlds/elephantmud/elephantmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/elephantmud/elephantmud.amx' \
	  'share/items/worlds/elephantmud/elephantmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/elephantmud/elephantmud.png' \
	  'share/items/worlds/elephantmud/elephantmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/elephantmud/elephantmud.tgz' \
	  'share/items/worlds/elysium/elysium.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/elysium/elysium.amx' \
	  'share/items/worlds/elysium/elysium.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/elysium/elysium.png' \
	  'share/items/worlds/elysium/elysium.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/elysium/elysium.tgz' \
	  'share/items/worlds/empire/empire.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/empire/empire.amx' \
	  'share/items/worlds/empire/empire.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/empire/empire.png' \
	  'share/items/worlds/empire/empire.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/empire/empire.tgz' \
	  'share/items/worlds/eotl/eotl.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/eotl/eotl.amx' \
	  'share/items/worlds/eotl/eotl.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/eotl/eotl.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/eotl/eotl.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/eotl/eotl.tgz' \
	  'share/items/worlds/fkingdoms/fkingdoms.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/fkingdoms/fkingdoms.amx' \
	  'share/items/worlds/fkingdoms/fkingdoms.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/fkingdoms/fkingdoms.png' \
	  'share/items/worlds/fkingdoms/fkingdoms.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/fkingdoms/fkingdoms.tgz' \
	  'share/items/worlds/forestsedge/forestsedge.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/forestsedge/forestsedge.amx' \
	  'share/items/worlds/forestsedge/forestsedge.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/forestsedge/forestsedge.png' \
	  'share/items/worlds/forestsedge/forestsedge.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/forestsedge/forestsedge.tgz' \
	  'share/items/worlds/fourdims/fourdims.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/fourdims/fourdims.amx' \
	  'share/items/worlds/fourdims/fourdims.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/fourdims/fourdims.png' \
	  'share/items/worlds/fourdims/fourdims.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/fourdims/fourdims.tgz' \
	  'share/items/worlds/genesis/genesis.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/genesis/genesis.amx' \
	  'share/items/worlds/genesis/genesis.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/genesis/genesis.png' \
	  'share/items/worlds/genesis/genesis.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/genesis/genesis.tgz' \
	  'share/items/worlds/greatermud/greatermud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/greatermud/greatermud.amx' \
	  'share/items/worlds/greatermud/greatermud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/greatermud/greatermud.png' \
	  'share/items/worlds/greatermud/greatermud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/greatermud/greatermud.tgz' \
	  'share/items/worlds/gwapoc/gwapoc.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/gwapoc/gwapoc.amx' \
	  'share/items/worlds/gwapoc/gwapoc.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/gwapoc/gwapoc.png' \
	  'share/items/worlds/gwapoc/gwapoc.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/gwapoc/gwapoc.tgz' \
	  'share/items/worlds/hellmoo/hellmoo.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/hellmoo/hellmoo.amx' \
	  'share/items/worlds/hellmoo/hellmoo.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/hellmoo/hellmoo.png' \
	  'share/items/worlds/hellmoo/hellmoo.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/hellmoo/hellmoo.tgz' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/hexonyx/hexonyx.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/hexonyx/hexonyx.amx' \
	  'share/items/worlds/hexonyx/hexonyx.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/hexonyx/hexonyx.png' \
	  'share/items/worlds/hexonyx/hexonyx.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/hexonyx/hexonyx.tgz' \
	  'share/items/worlds/holyquest/holyquest.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/holyquest/holyquest.amx' \
	  'share/items/worlds/holyquest/holyquest.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/holyquest/holyquest.png' \
	  'share/items/worlds/holyquest/holyquest.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/holyquest/holyquest.tgz' \
	  'share/items/worlds/iberia/iberia.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/iberia/iberia.amx' \
	  'share/items/worlds/iberia/iberia.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/iberia/iberia.png' \
	  'share/items/worlds/iberia/iberia.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/iberia/iberia.tgz' \
	  'share/items/worlds/icesus/icesus.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/icesus/icesus.amx' \
	  'share/items/worlds/icesus/icesus.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/icesus/icesus.png' \
	  'share/items/worlds/icesus/icesus.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/icesus/icesus.tgz' \
	  'share/items/worlds/ifmud/ifmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ifmud/ifmud.amx' \
	  'share/items/worlds/ifmud/ifmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ifmud/ifmud.png' \
	  'share/items/worlds/ifmud/ifmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ifmud/ifmud.tgz' \
	  'share/items/worlds/imperian/imperian.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/imperian/imperian.amx' \
	  'share/items/worlds/imperian/imperian.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/imperian/imperian.png' \
	  'share/items/worlds/imperian/imperian.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/imperian/imperian.tgz' \
	  'share/items/worlds/islands/islands.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/islands/islands.amx' \
	  'share/items/worlds/islands/islands.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/islands/islands.png' \
	  'share/items/worlds/islands/islands.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/islands/islands.tgz' \
	  'share/items/worlds/kallisti/kallisti.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/kallisti/kallisti.amx' \
	  'share/items/worlds/kallisti/kallisti.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/kallisti/kallisti.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/kallisti/kallisti.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/kallisti/kallisti.tgz' \
	  'share/items/worlds/lambda/lambda.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lambda/lambda.amx' \
	  'share/items/worlds/lambda/lambda.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lambda/lambda.png' \
	  'share/items/worlds/lambda/lambda.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lambda/lambda.tgz' \
	  'share/items/worlds/legendmud/legendmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/legendmud/legendmud.amx' \
	  'share/items/worlds/legendmud/legendmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/legendmud/legendmud.png' \
	  'share/items/worlds/legendmud/legendmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/legendmud/legendmud.tgz' \
	  'share/items/worlds/lostsouls/lostsouls.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lostsouls/lostsouls.amx' \
	  'share/items/worlds/lostsouls/lostsouls.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lostsouls/lostsouls.png' \
	  'share/items/worlds/lostsouls/lostsouls.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lostsouls/lostsouls.tgz' \
	  'share/items/worlds/lowlands/lowlands.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lowlands/lowlands.amx' \
	  'share/items/worlds/lowlands/lowlands.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lowlands/lowlands.png' \
	  'share/items/worlds/lowlands/lowlands.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lowlands/lowlands.tgz' \
	  'share/items/worlds/luminari/luminari.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/luminari/luminari.amx' \
	  'share/items/worlds/luminari/luminari.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/luminari/luminari.png' \
	  'share/items/worlds/luminari/luminari.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/luminari/luminari.tgz' \
	  'share/items/worlds/lusternia/lusternia.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lusternia/lusternia.amx' \
	  'share/items/worlds/lusternia/lusternia.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lusternia/lusternia.png' \
	  'share/items/worlds/lusternia/lusternia.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/lusternia/lusternia.tgz' \
	  'share/items/worlds/magica/magica.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/magica/magica.amx' \
	  'share/items/worlds/magica/magica.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/magica/magica.png' \
	  'share/items/worlds/magica/magica.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/magica/magica.tgz' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/medievia/medievia.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/medievia/medievia.amx' \
	  'share/items/worlds/medievia/medievia.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/medievia/medievia.png' \
	  'share/items/worlds/medievia/medievia.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/medievia/medievia.tgz' \
	  'share/items/worlds/merentha/merentha.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/merentha/merentha.amx' \
	  'share/items/worlds/merentha/merentha.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/merentha/merentha.png' \
	  'share/items/worlds/merentha/merentha.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/merentha/merentha.tgz' \
	  'share/items/worlds/midnightsun/midnightsun.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/midnightsun/midnightsun.amx' \
	  'share/items/worlds/midnightsun/midnightsun.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/midnightsun/midnightsun.png' \
	  'share/items/worlds/midnightsun/midnightsun.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/midnightsun/midnightsun.tgz' \
	  'share/items/worlds/miriani/miriani.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/miriani/miriani.amx' \
	  'share/items/worlds/miriani/miriani.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/miriani/miriani.png' \
	  'share/items/worlds/miriani/miriani.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/miriani/miriani.tgz' \
	  'share/items/worlds/morgengrauen/morgengrauen.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/morgengrauen/morgengrauen.amx' \
	  'share/items/worlds/morgengrauen/morgengrauen.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/morgengrauen/morgengrauen.png' \
	  'share/items/worlds/morgengrauen/morgengrauen.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/morgengrauen/morgengrauen.tgz' \
	  'share/items/worlds/mud1/mud1.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mud1/mud1.amx' \
	  'share/items/worlds/mud1/mud1.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mud1/mud1.png' \
	  'share/items/worlds/mud1/mud1.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mud1/mud1.tgz' \
	  'share/items/worlds/mud2/mud2.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mud2/mud2.amx' \
	  'share/items/worlds/mud2/mud2.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mud2/mud2.png' \
	  'share/items/worlds/mud2/mud2.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mud2/mud2.tgz' \
	  'share/items/worlds/mudii/mudii.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mudii/mudii.amx' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/mudii/mudii.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mudii/mudii.png' \
	  'share/items/worlds/mudii/mudii.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mudii/mudii.tgz' \
	  'share/items/worlds/mume/mume.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mume/mume.amx' \
	  'share/items/worlds/mume/mume.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mume/mume.png' \
	  'share/items/worlds/mume/mume.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/mume/mume.tgz' \
	  'share/items/worlds/nannymud/nannymud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nannymud/nannymud.amx' \
	  'share/items/worlds/nannymud/nannymud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nannymud/nannymud.png' \
	  'share/items/worlds/nannymud/nannymud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nannymud/nannymud.tgz' \
	  'share/items/worlds/nanvaent/nanvaent.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nanvaent/nanvaent.amx' \
	  'share/items/worlds/nanvaent/nanvaent.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nanvaent/nanvaent.png' \
	  'share/items/worlds/nanvaent/nanvaent.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nanvaent/nanvaent.tgz' \
	  'share/items/worlds/nodeka/nodeka.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nodeka/nodeka.amx' \
	  'share/items/worlds/nodeka/nodeka.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nodeka/nodeka.png' \
	  'share/items/worlds/nodeka/nodeka.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nodeka/nodeka.tgz' \
	  'share/items/worlds/nuclearwar/nuclearwar.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nuclearwar/nuclearwar.amx' \
	  'share/items/worlds/nuclearwar/nuclearwar.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nuclearwar/nuclearwar.png' \
	  'share/items/worlds/nuclearwar/nuclearwar.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/nuclearwar/nuclearwar.tgz' \
	  'share/items/worlds/penultimate/penultimate.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/penultimate/penultimate.amx' \
	  'share/items/worlds/penultimate/penultimate.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/penultimate/penultimate.png' \
	  'share/items/worlds/penultimate/penultimate.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/penultimate/penultimate.tgz' \
	  'share/items/worlds/pict/pict.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/pict/pict.amx' \
	  'share/items/worlds/pict/pict.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/pict/pict.png' \
	  'share/items/worlds/pict/pict.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/pict/pict.tgz' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/ravenmud/ravenmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ravenmud/ravenmud.amx' \
	  'share/items/worlds/ravenmud/ravenmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ravenmud/ravenmud.png' \
	  'share/items/worlds/ravenmud/ravenmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/ravenmud/ravenmud.tgz' \
	  'share/items/worlds/realmsmud/realmsmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/realmsmud/realmsmud.amx' \
	  'share/items/worlds/realmsmud/realmsmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/realmsmud/realmsmud.png' \
	  'share/items/worlds/realmsmud/realmsmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/realmsmud/realmsmud.tgz' \
	  'share/items/worlds/reinos/reinos.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/reinos/reinos.amx' \
	  'share/items/worlds/reinos/reinos.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/reinos/reinos.png' \
	  'share/items/worlds/reinos/reinos.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/reinos/reinos.tgz' \
	  'share/items/worlds/retromud/retromud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/retromud/retromud.amx' \
	  'share/items/worlds/retromud/retromud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/retromud/retromud.png' \
	  'share/items/worlds/retromud/retromud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/retromud/retromud.tgz' \
	  'share/items/worlds/rodespair/rodespair.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rodespair/rodespair.amx' \
	  'share/items/worlds/rodespair/rodespair.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rodespair/rodespair.png' \
	  'share/items/worlds/rodespair/rodespair.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rodespair/rodespair.tgz' \
	  'share/items/worlds/roninmud/roninmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/roninmud/roninmud.amx' \
	  'share/items/worlds/roninmud/roninmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/roninmud/roninmud.png' \
	  'share/items/worlds/roninmud/roninmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/roninmud/roninmud.tgz' \
	  'share/items/worlds/rowonder/rowonder.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rowonder/rowonder.amx' \
	  'share/items/worlds/rowonder/rowonder.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rowonder/rowonder.png' \
	  'share/items/worlds/rowonder/rowonder.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rowonder/rowonder.tgz' \
	  'share/items/worlds/rupert/rupert.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rupert/rupert.amx' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/rupert/rupert.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rupert/rupert.png' \
	  'share/items/worlds/rupert/rupert.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/rupert/rupert.tgz' \
	  'share/items/worlds/slothmud/slothmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/slothmud/slothmud.amx' \
	  'share/items/worlds/slothmud/slothmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/slothmud/slothmud.png' \
	  'share/items/worlds/slothmud/slothmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/slothmud/slothmud.tgz' \
	  'share/items/worlds/stickmud/stickmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/stickmud/stickmud.amx' \
	  'share/items/worlds/stickmud/stickmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/stickmud/stickmud.png' \
	  'share/items/worlds/stickmud/stickmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/stickmud/stickmud.tgz' \
	  'share/items/worlds/stonia/stonia.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/stonia/stonia.amx' \
	  'share/items/worlds/stonia/stonia.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/stonia/stonia.png' \
	  'share/items/worlds/stonia/stonia.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/stonia/stonia.tgz' \
	  'share/items/worlds/swmud/swmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/swmud/swmud.amx' \
	  'share/items/worlds/swmud/swmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/swmud/swmud.png' \
	  'share/items/worlds/swmud/swmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/swmud/swmud.tgz' \
	  'share/items/worlds/tempora/tempora.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tempora/tempora.amx' \
	  'share/items/worlds/tempora/tempora.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tempora/tempora.png' \
	  'share/items/worlds/tempora/tempora.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tempora/tempora.tgz' \
	  'share/items/worlds/theland/theland.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/theland/theland.amx' \
	  'share/items/worlds/theland/theland.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/theland/theland.png' \
	  'share/items/worlds/theland/theland.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/theland/theland.tgz' \
	  'share/items/worlds/threekingdoms/threekingdoms.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/threekingdoms/threekingdoms.amx' \
	  'share/items/worlds/threekingdoms/threekingdoms.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/threekingdoms/threekingdoms.png' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/threekingdoms/threekingdoms.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/threekingdoms/threekingdoms.tgz' \
	  'share/items/worlds/threescapes/threescapes.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/threescapes/threescapes.amx' \
	  'share/items/worlds/threescapes/threescapes.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/threescapes/threescapes.png' \
	  'share/items/worlds/threescapes/threescapes.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/threescapes/threescapes.tgz' \
	  'share/items/worlds/tilegacy/tilegacy.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tilegacy/tilegacy.amx' \
	  'share/items/worlds/tilegacy/tilegacy.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tilegacy/tilegacy.png' \
	  'share/items/worlds/tilegacy/tilegacy.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tilegacy/tilegacy.tgz' \
	  'share/items/worlds/torilmud/torilmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/torilmud/torilmud.amx' \
	  'share/items/worlds/torilmud/torilmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/torilmud/torilmud.png' \
	  'share/items/worlds/torilmud/torilmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/torilmud/torilmud.tgz' \
	  'share/items/worlds/tsunami/tsunami.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tsunami/tsunami.amx' \
	  'share/items/worlds/tsunami/tsunami.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tsunami/tsunami.png' \
	  'share/items/worlds/tsunami/tsunami.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/tsunami/tsunami.tgz' \
	  'share/items/worlds/twotowers/twotowers.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/twotowers/twotowers.amx' \
	  'share/items/worlds/twotowers/twotowers.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/twotowers/twotowers.png' \
	  'share/items/worlds/twotowers/twotowers.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/twotowers/twotowers.tgz' \
	  'share/items/worlds/uossmud/uossmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/uossmud/uossmud.amx' \
	  'share/items/worlds/uossmud/uossmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/uossmud/uossmud.png' \
	  'share/items/worlds/uossmud/uossmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/uossmud/uossmud.tgz' \
	  'share/items/worlds/valhalla/valhalla.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/valhalla/valhalla.amx' \
	  'share/items/worlds/valhalla/valhalla.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/valhalla/valhalla.png' \
	  'share/items/worlds/valhalla/valhalla.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/valhalla/valhalla.tgz' 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)'\'')' -- \
	  'share/items/worlds/vikingmud/vikingmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/vikingmud/vikingmud.amx' \
	  'share/items/worlds/vikingmud/vikingmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/vikingmud/vikingmud.png' \
	  'share/items/worlds/vikingmud/vikingmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/vikingmud/vikingmud.tgz' \
	  'share/items/worlds/waterdeep/waterdeep.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/waterdeep/waterdeep.amx' \
	  'share/items/worlds/waterdeep/waterdeep.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/waterdeep/waterdeep.png' \
	  'share/items/worlds/waterdeep/waterdeep.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/waterdeep/waterdeep.tgz' \
	  'share/items/worlds/wotmud/wotmud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/wotmud/wotmud.amx' \
	  'share/items/worlds/wotmud/wotmud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/wotmud/wotmud.png' \
	  'share/items/worlds/wotmud/wotmud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/wotmud/wotmud.tgz' \
	  'share/items/worlds/zombiemud/zombiemud.amx' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/zombiemud/zombiemud.amx' \
	  'share/items/worlds/zombiemud/zombiemud.png' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/zombiemud/zombiemud.png' \
	  'share/items/worlds/zombiemud/zombiemud.tgz' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/items/worlds/zombiemud/zombiemud.tgz' \
	  'share/plugins/_convertlpc_cmds.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/_convertlpc_cmds.pm' \
	  'share/plugins/_mcptest_objs.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/_mcptest_objs.pm' \
	  'share/plugins/_wilderness_cmds.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/_wilderness_cmds.pm' \
	  'share/plugins/convertlpc.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/convertlpc.pm' \
	  'share/plugins/help/cmd/convertlpc' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/help/cmd/convertlpc' \
	  'share/plugins/help/cmd/wildempire' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/help/cmd/wildempire' \
	  'share/plugins/help/task/README' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/help/task/README' \
	  'share/plugins/mcptest.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/mcptest.pm' \
	  'share/plugins/mxpfilter.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/mxpfilter.pm' \
	  'share/plugins/wilderness.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/wilderness.pm' \
	  'share/plugins/zmptest.pm' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/plugins/zmptest.pm' \
	  'share/standalone/mapextract.pl' '$(INST_LIB)/auto/share/dist/$(DISTNAME)/standalone/mapextract.pl' 


# End.
