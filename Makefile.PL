require 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

delete_share '.';
install_share 'share';

my %prereqHash = (
    'Archive::Extract'      => '0',
    'Archive::Tar'          => '0',
    'Compress::Zlib'        => '0',
    'Encode'                => '0',
    'Fcntl'                 => '0',
    'File::Basename'        => '0',
    'File::Copy'            => '0',
    'File::Copy::Recursive' => '0',
    'File::Fetch'           => '0',
    'File::Find'            => '0',
    'File::HomeDir'         => '0',
    'File::Path'            => '0',
    'File::ShareDir'        => '0',
    'File::ShareDir::Install'
                            => '0',
    'Glib'                  => '0',
    'Gnome2::Canvas'        => '0',
    'Gnome2::Wnck'          => '0',
    'Gtk2'                  => '0',
    'IO::Socket::INET'      => '0',
    'IO::Socket::INET6'     => '0',
    'IO::Socket::SSL'       => '0',
    'IPC::Run'              => '0',
    'JSON'                  => '0',
    'Math::Trig'            => '0',
    'Module::Load'          => '0',
    'Net::OpenSSH'          => '0',
    'POSIX'                 => '0',
    'Regexp::IPv6'          => '0',
    'Safe'                  => '0',
    'Scalar::Util'          => '0',
    'Socket'                => '0',
    'Symbol'                => '0',
    'Storable'              => '0',
    'Time::HiRes'           => '0',
);

if ($^O eq 'MSWin32') {

    # Wnck doesn't exist on MS Windows systems
    delete $prereqHash{'Gnome2::Wnck'};
}

WriteMakefile(
    NAME                    => 'Games::Axmud',
    AUTHOR                  => 'A S Lewis <aslewis@cpan.org>',
    VERSION_FROM            => 'scripts/axmud.pl',
    LICENSE                 => 'gpl_3',
    MIN_PERL_VERSION        => 5.008,
    CONFIGURE_REQUIRES      => {
        "ExtUtils::MakeMaker"
                            => '6.52',
        "File::ShareDir::Install"
                            => 0,
    },
    PREREQ_PM               => { %prereqHash },
    INSTALLDIRS             => 'site',
    EXE_FILES               => [
        'scripts/axmud.pl',
        'scripts/baxmud.pl',
    ],
    META_MERGE              => {
        'meta-spec'         => { version => 2 },
        resources           => {
             repository     => {
                 type       => 'git',
                 url        => 'https://github.com/axcore/axmud.git',
                 web        => 'https://github.com/axcore/axmud',
             },
             bugtracker     => {web => 'https://github.com/axcore/axmud/issues'},
             homepage       => 'https://axmud.sourceforge.io/',
         },
    },
);

package MY;
use File::ShareDir::Install 'postamble';

