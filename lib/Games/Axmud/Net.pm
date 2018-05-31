# Copyright (C) 2011-2018 A S Lewis
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU
# Lesser Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser Public License along with this program.  If not,
# see <http://www.gnu.org/licenses/>.
#
# Our own version of Net::Telnet (v3.04) by Jay Rogers; with a few modifications
#
# List of changes (besides cosmetic ones):
#   - Removed user documentation
#   - 'use warnings' and 'use diagnostics' added
#   - Fixed apparent problem in ->_optimal_blksize, which caused a warning
#   - Fixed apparent problem in ->_negotiate_recv_disable and ->_negotiate_recv_enable, which causes
#       errors when the $$state argument was 'undef'
#   - Removed 'require 5.002', since Axmud requires 5.008 anyway
#   - Removed 'require FileHandle' for the same reason
#   - Implemented MCCP (Mud Client Compression Protocol, http://tintin.sourceforge.net/mccp/)
#       - Added 'use Compress::Zlib'
#       - Added new IVs to ->new() : ->axmud_mccp_mode, ->axmud_zlib_obj and ->axmud_session
#       - Modified _>_fillbuf to decompress text when MCCP enabled
#       - Added new function ->_disable_mccp, called by ->_fillbuf
#       - Added new function ->axmud_session, called by ->new
#   - In ->new, commented out automatic handling of TELOPT_ECHO and TELOPT_SGA, which are now
#       handled by Axmud itself
#   - Added some new constants to @EXPORT_OK and %Axmud_Telopts describing various MUD protocols,
#       and modified ->_log_option to use them
#   - Modified ->localfamily, ->_parse_family and ->_parse_localfamily to cope with the error seen
#       on Debian/Ubuntu:
#           'WARNING: Argument "2.020_03" isn't numeric in numeric ge (>=)'

{ package Games::Axmud::Net::Telnet;

    use strict;
    use warnings;
    use diagnostics;

    ## Module export.
    use vars qw(@EXPORT_OK);
    @EXPORT_OK = qw(
        TELNET_IAC TELNET_DONT TELNET_DO TELNET_WONT TELNET_WILL
        TELNET_SB TELNET_GA TELNET_EL TELNET_EC TELNET_AYT TELNET_AO
        TELNET_IP TELNET_BREAK TELNET_DM TELNET_NOP TELNET_SE
        TELNET_EOR TELNET_ABORT TELNET_SUSP TELNET_EOF TELNET_SYNCH
        TELOPT_BINARY TELOPT_ECHO TELOPT_RCP TELOPT_SGA TELOPT_NAMS
        TELOPT_STATUS TELOPT_TM TELOPT_RCTE TELOPT_NAOL TELOPT_NAOP
        TELOPT_NAOCRD TELOPT_NAOHTS TELOPT_NAOHTD TELOPT_NAOFFD
        TELOPT_NAOVTS TELOPT_NAOVTD TELOPT_NAOLFD TELOPT_XASCII
        TELOPT_LOGOUT TELOPT_BM TELOPT_DET TELOPT_SUPDUP
        TELOPT_SUPDUPOUTPUT TELOPT_SNDLOC TELOPT_TTYPE TELOPT_EOR
        TELOPT_TUID TELOPT_OUTMRK TELOPT_TTYLOC TELOPT_3270REGIME
        TELOPT_X3PAD TELOPT_NAWS TELOPT_TSPEED TELOPT_LFLOW
        TELOPT_LINEMODE TELOPT_XDISPLOC TELOPT_OLD_ENVIRON
        TELOPT_AUTHENTICATION TELOPT_ENCRYPT TELOPT_NEW_ENVIRON
        TELOPT_TN3270E TELOPT_CHARSET TELOPT_COMPORT TELOPT_KERMIT
        TELOPT_EXOPL

        TELOPT_MSDP TELOPT_MSSP TELOPT_MCCP1 TELOPT_MCCP2 TELOPT_MSP
        TELOPT_MXP TELOPT_ZMP TELOPT_AARDWOLF TELOPT_ATCP TELOPT_GMCP
    );

    ## Module import.
    use Exporter ();
    use Compress::Zlib;
    use Socket qw(AF_INET SOCK_STREAM inet_aton sockaddr_in);
    use Symbol qw(qualify);

    ## Base classes.
    use vars qw(@ISA);
    @ISA = qw(Exporter);
    if (&_io_socket_include) {  # successfully required module IO::Socket
        push @ISA, "IO::Socket::INET";
    }
    my $AF_INET6 = &_import_af_inet6();
    my $AF_UNSPEC = &_import_af_unspec() || 0;
    my $AI_ADDRCONFIG = &_import_ai_addrconfig() || 0;
    my $EAI_BADFLAGS = &_import_eai_badflags() || -1;
    my $EINTR = &_import_eintr();

    ## Global variables.
    use vars qw($VERSION @Telopts %Axmud_Telopts);
    $VERSION = "3.04";
    @Telopts = ("BINARY", "ECHO", "RCP", "SUPPRESS GO AHEAD", "NAMS", "STATUS",
            "TIMING MARK", "RCTE", "NAOL", "NAOP", "NAOCRD", "NAOHTS",
            "NAOHTD", "NAOFFD", "NAOVTS", "NAOVTD", "NAOLFD", "EXTEND ASCII",
            "LOGOUT", "BYTE MACRO", "DATA ENTRY TERMINAL", "SUPDUP",
            "SUPDUP OUTPUT", "SEND LOCATION", "TERMINAL TYPE", "END OF RECORD",
            "TACACS UID", "OUTPUT MARKING", "TTYLOC", "3270 REGIME", "X.3 PAD",
            "NAWS", "TSPEED", "LFLOW", "LINEMODE", "XDISPLOC", "OLD-ENVIRON",
            "AUTHENTICATION", "ENCRYPT", "NEW-ENVIRON", "TN3270E", "XAUTH",
            "CHARSET", "RSP", "COMPORT", "SUPPRESS LOCAL ECHO", "START TLS",
            "KERMIT");

    %Axmud_Telopts = (
        69  => 'MSDP',
        70  => 'MSSP',
        85  => 'MCCP1',
        86  => 'MCCP2',
        90  => 'MSP',
        91  => 'MXP',
        93  => 'ZMP',
        102 => 'AARDWOLF',
        200 => 'ATCP',
        201 => 'GMCP',
    );

    ########################### Public Methods ###########################


    sub new {
        my ($class) = @_;
        my (
        $dump_log,
        $errmode,
        $family,
        $fh_open,
        $host,
        $input_log,
        $localfamily,
        $option_log,
        $output_log,
        $port,
        $prompt,
        $axmud_session,
        $self,
        %args,
        );
        local $_;

        ## Create a new object with defaults.
        $self = $class->SUPER::new;
        *$self->{net_telnet} = {
        bin_mode         => 0,
        blksize          => &_optimal_blksize(),
        buf              => "",
        cmd_prompt       => '/[\$%#>] $/',
        cmd_rm_mode      => "auto",
        dumplog          => '',
        eofile           => 1,
        errormode        => "die",
        errormsg         => "",
        fdmask           => '',
        host             => "localhost",
        inputlog         => '',
        last_line        => "",
        last_prompt      => "",
        local_family     => "ipv4",
        local_host       => "",
        maxbufsize       => 1_048_576,
        num_wrote        => 0,
        ofs              => "",
        opened           => '',
        opt_cback        => '',
        opt_log          => '',
        opts             => {},
        ors              => "\n",
        outputlog        => '',
        peer_family      => "ipv4",
        pending_errormsg => "",
        port             => 23,
        pushback_buf     => "",
        rs               => "\n",
        select_supported => 1,
        sock_family      => 0,
        subopt_cback     => '',
        telnet_mode      => 1,
        time_out         => 10,
        timedout         => '',
        unsent_opts      => "",
        # New variables for Axmud
        axmud_session    => '',
        axmud_mccp_mode  => 0,
        axmud_zlib_obj   => '',
        # End of new variables
        };

        # TELOPT_ECHO and TELOPT_SGA are now handled directly by Axmud
#        ## Indicate that we'll accept an offer from remote side for it to echo
#        ## and suppress go aheads.
#        &_opt_accept($self,
#             { option    => &TELOPT_ECHO,
#               is_remote => 1,
#               is_enable => 1 },
#             { option    => &TELOPT_SGA,
#               is_remote => 1,
#               is_enable => 1 },
#             );

        ## Parse the args.
        if (@_ == 2) {  # one positional arg given
        $host = $_[1];
        }
        elsif (@_ > 2) {  # named args given
        ## Get the named args.
        (undef, %args) = @_;

        ## Parse all other named args.
        foreach (keys %args) {
            if (/^-?binmode$/i) {
            $self->binmode($args{$_});
            }
            elsif (/^-?cmd_remove_mode$/i) {
            $self->cmd_remove_mode($args{$_});
            }
            elsif (/^-?dump_log$/i) {
            $dump_log = $args{$_};
            }
            elsif (/^-?errmode$/i) {
            $errmode = $args{$_};
            }
            elsif (/^-?family$/i) {
            $family = $args{$_};
            }
            elsif (/^-?fhopen$/i) {
            $fh_open = $args{$_};
            }
            elsif (/^-?host$/i) {
            $host = $args{$_};
            }
            elsif (/^-?input_log$/i) {
            $input_log = $args{$_};
            }
            elsif (/^-?input_record_separator$/i or /^-?rs$/i) {
            $self->input_record_separator($args{$_});
            }
            elsif (/^-?localfamily$/i) {
            $localfamily = $args{$_};
            }
            elsif (/^-?localhost$/i) {
            $self->localhost($args{$_});
            }
            elsif (/^-?max_buffer_length$/i) {
            $self->max_buffer_length($args{$_});
            }
            elsif (/^-?option_log$/i) {
            $option_log = $args{$_};
            }
            elsif (/^-?output_field_separator$/i or /^-?ofs$/i) {
            $self->output_field_separator($args{$_});
            }
            elsif (/^-?output_log$/i) {
            $output_log = $args{$_};
            }
            elsif (/^-?output_record_separator$/i or /^-?ors$/i) {
            $self->output_record_separator($args{$_});
            }
            elsif (/^-?port$/i) {
            $port = $args{$_};
            }
            elsif (/^-?prompt$/i) {
            $prompt = $args{$_};
            }
            elsif (/^-?telnetmode$/i) {
            $self->telnetmode($args{$_});
            }
            elsif (/^-?timeout$/i) {
            $self->timeout($args{$_});
            }
            # New args for Axmud
            elsif (/^-?axmud_session$/i) {
            $axmud_session = $args{$_};
            }
            # End of new args
            else {
            &_croak($self, "bad named parameter \"$_\" given " .
                "to " . ref($self) . "::new()");
            }
        }
        }

        if (defined $errmode) {  # user wants to set errmode
        $self->errmode($errmode);
        }

        if (defined $host) {  # user wants to set host
        $self->host($host);
        }

        if (defined $port) {  # user wants to set port
        $self->port($port)
            or return;
        }

        if (defined $family) {  # user wants to set family
        $self->family($family)
            or return;
        }

        if (defined $localfamily) {  # user wants to set localfamily
        $self->localfamily($localfamily)
            or return;
        }

        if (defined $prompt) {  # user wants to set prompt
        $self->prompt($prompt)
            or return;
        }

        if (defined $dump_log) {  # user wants to set dump_log
        $self->dump_log($dump_log)
            or return;
        }

        if (defined $input_log) {  # user wants to set input_log
        $self->input_log($input_log)
            or return;
        }

        if (defined $option_log) {  # user wants to set option_log
        $self->option_log($option_log)
            or return;
        }

        if (defined $output_log) {  # user wants to set output_log
        $self->output_log($output_log)
            or return;
        }

        if (defined $fh_open) {  # user wants us to attach to existing filehandle
        $self->fhopen($fh_open)
            or return;
        }
        elsif (defined $host) {  # user wants us to open a connection to host
        $self->open
            or return;
        }

        # New args for Axmud
        if (defined $axmud_session) {  # user wants to set axmud_session
        $self->axmud_session($axmud_session)
            or return;
        }
        # End of new args

        $self;
    } # end sub new


    sub DESTROY {
    } # end sub DESTROY


    sub axmud_session {
        my ($self, $session) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{axmud_session};

        if (@_ >= 2) {
        unless (defined $session) {
            $session = "";
        }

        $s->{axmud_session} = $session;
        }

        1;
    } # end sub axmud_session


    sub binmode {
        my ($self, $mode) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{bin_mode};

        if (@_ >= 2) {
        unless (defined $mode) {
            $mode = 0;
        }

        $s->{bin_mode} = $mode;
        }

        $prev;
    } # end sub binmode


    sub break {
        my ($self) = @_;
        my $s = *$self->{net_telnet};
        my $break_cmd = "\xff\xf3";

        $s->{timedout} = '';

        &_put($self, \$break_cmd, "break");
    } # end sub break


    sub buffer {
        my ($self) = @_;
        my $s = *$self->{net_telnet};

        \$s->{buf};
    } # end sub buffer


    sub buffer_empty {
        my ($self) = @_;
        my (
        $buffer,
        );

        $buffer = $self->buffer;
        $$buffer = "";
    } # end sub buffer_empty


    sub close {
        my ($self) = @_;
        my $s = *$self->{net_telnet};

        $s->{eofile} = 1;
        $s->{opened} = '';
        $s->{sock_family} = 0;
        close $self
        if defined fileno($self);

        1;
    } # end sub close


    sub cmd {
        my ($self, @args) = @_;
        my (
        $arg_errmode,
        $cmd_remove_mode,
        $firstpos,
        $last_prompt,
        $lastpos,
        $lines,
        $ors,
        $output,
        $output_ref,
        $prompt,
        $remove_echo,
        $rs,
        $rs_len,
        $s,
        $telopt_echo,
        $timeout,
        %args,
        );
        my $cmd = "";
        local $_;

        ## Init.
        $self->timed_out('');
        $self->last_prompt("");
        $s = *$self->{net_telnet};
        $output = [];
        $cmd_remove_mode = $self->cmd_remove_mode;
        $ors = $self->output_record_separator;
        $prompt = $self->prompt;
        $rs = $self->input_record_separator;
        $timeout = $self->timeout;

        ## Override errmode first, if specified.
        $arg_errmode = &_extract_arg_errmode($self, \@args);
        local $s->{errormode} = $arg_errmode
        if $arg_errmode;

        ## Parse args.
        if (@args == 1) {  # one positional arg given
        $cmd = $args[0];
        }
        elsif (@args >= 2) {  # named args given
        ## Get the named args.
        %args = @args;

        ## Parse the named args.
        foreach (keys %args) {
            if (/^-?cmd_remove/i) {
            $cmd_remove_mode = &_parse_cmd_remove_mode($self, $args{$_});
            }
            elsif (/^-?input_record_separator$/i or /^-?rs$/i) {
            $rs = &_parse_input_record_separator($self, $args{$_});
            }
            elsif (/^-?output$/i) {
            $output_ref = $args{$_};
            if (defined($output_ref) and ref($output_ref) eq "ARRAY") {
                $output = $output_ref;
            }
            }
            elsif (/^-?output_record_separator$/i or /^-?ors$/i) {
            $ors = $args{$_};
            }
            elsif (/^-?prompt$/i) {
            $prompt = &_parse_prompt($self, $args{$_})
                or return;
            }
            elsif (/^-?string$/i) {
            $cmd = $args{$_};
            }
            elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
            }
            else {
            &_croak($self, "bad named parameter \"$_\" given " .
                "to " . ref($self) . "::cmd()");
            }
        }
        }

        ## Override some user settings.
        local $s->{time_out} = &_endtime($timeout);
        $self->errmsg("");

        ## Send command and wait for the prompt.
        {
        local $s->{errormode} = "return";

        $self->put($cmd . $ors)
            and ($lines, $last_prompt) = $self->waitfor($prompt);
        }

        ## Check for failure.
        return $self->error("command timed-out") if $self->timed_out;
        return $self->error($self->errmsg) if $self->errmsg ne "";

        ## Save the most recently matched prompt.
        $self->last_prompt($last_prompt);

        ## Split lines into an array, keeping record separator at end of line.
        $firstpos = 0;
        $rs_len = length $rs;
        while (($lastpos = index($lines, $rs, $firstpos)) > -1) {
        push(@$output,
             substr($lines, $firstpos, $lastpos - $firstpos + $rs_len));
        $firstpos = $lastpos + $rs_len;
        }

        if ($firstpos < length $lines) {
        push @$output, substr($lines, $firstpos);
        }

        ## Determine if we should remove the first line of output based
        ## on the assumption that it's an echoed back command.
        if ($cmd_remove_mode eq "auto") {
        ## See if remote side told us they'd echo.
        $telopt_echo = $self->option_state(&TELOPT_ECHO);
        $remove_echo = $telopt_echo->{remote_enabled};
        }
        else {  # user explicitly told us how many lines to remove.
        $remove_echo = $cmd_remove_mode;
        }

        ## Get rid of possible echo back command.
        while ($remove_echo--) {
        shift @$output;
        }

        ## Ensure at least a null string when there's no command output - so
        ## "true" is returned in a list context.
        unless (@$output) {
        @$output = ("");
        }

        ## Return command output via named arg, if requested.
        if (defined $output_ref) {
        if (ref($output_ref) eq "SCALAR") {
            $$output_ref = join "", @$output;
        }
        elsif (ref($output_ref) eq "HASH") {
            %$output_ref = @$output;
        }
        }

        wantarray ? @$output : 1;
    } # end sub cmd


    sub cmd_remove_mode {
        my ($self, $mode) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{cmd_rm_mode};

        if (@_ >= 2) {
        $s->{cmd_rm_mode} = &_parse_cmd_remove_mode($self, $mode);
        }

        $prev;
    } # end sub cmd_remove_mode


    sub dump_log {
        my ($self, $name) = @_;
        my (
        $fh,
        $s,
        );

        $s = *$self->{net_telnet};
        $fh = $s->{dumplog};

        if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        }
        elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
            or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        else {
            return $self->error("bad Dump_log argument ",
                    "\"$name\": not filename or open fh");
        }

        $s->{dumplog} = $fh;
        }

        $fh;
    } # end sub dump_log


    sub eof {
        my ($self) = @_;

        *$self->{net_telnet}{eofile};
    } # end sub eof


    sub errmode {
        my ($self, $mode) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{errormode};

        if (@_ >= 2) {
        $s->{errormode} = &_parse_errmode($self, $mode);
        }

        $prev;
    } # end sub errmode


    sub errmsg {
        my ($self, @errmsgs) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{errormsg};

        if (@_ >= 2) {
        $s->{errormsg} = join "", @errmsgs;
        }

        $prev;
    } # end sub errmsg


    sub error {
        my ($self, @errmsg) = @_;
        my (
        $errmsg,
        $func,
        $mode,
        $s,
        @args,
        );
        local $_;

        $s = *$self->{net_telnet};

        if (@_ >= 2) {
        ## Put error message in the object.
        $errmsg = join "", @errmsg;
        $s->{errormsg} = $errmsg;

        ## Do the error action as described by error mode.
        $mode = $s->{errormode};
        if (ref($mode) eq "CODE") {
            &$mode($errmsg);
            return;
        }
        elsif (ref($mode) eq "ARRAY") {
            ($func, @args) = @$mode;
            &$func(@args);
            return;
        }
        elsif ($mode =~ /^return$/i) {
            return;
        }
        else {  # die
            if ($errmsg =~ /\n$/) {
            die $errmsg;
            }
            else {
            ## Die and append caller's line number to message.
            &_croak($self, $errmsg);
            }
        }
        }
        else {
        return $s->{errormsg} ne "";
        }
    } # end sub error


    sub family {
        my ($self, $family) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{peer_family};

        if (@_ >= 2) {
        $family = &_parse_family($self, $family)
            or return;

        $s->{peer_family} = $family;
        }

        $prev;
    } # end sub family


    sub fhopen {
        my ($self, $fh) = @_;
        my (
        $globref,
        $s,
        );

        ## Convert given filehandle to a typeglob reference, if necessary.
        $globref = &_qualify_fh($self, $fh);

        ## Ensure filehandle is already open.
        return $self->error("fhopen filehandle isn't already open")
        unless defined($globref) and defined(fileno $globref);

        ## Ensure we're closed.
        $self->close;

        ## Save our private data.
        $s = *$self->{net_telnet};

        ## Switch ourself with the given filehandle.
        *$self = *$globref;

        ## Restore our private data.
        *$self->{net_telnet} = $s;

        ## Re-initialize ourself.
        select((select($self), $|=1)[$[]);  # don't buffer writes
        $s = *$self->{net_telnet};
        $s->{blksize} = &_optimal_blksize((stat $self)[11]);
        $s->{buf} = "";
        $s->{eofile} = '';
        $s->{errormsg} = "";
        vec($s->{fdmask}='', fileno($self), 1) = 1;
        $s->{host} = "";
        $s->{last_line} = "";
        $s->{last_prompt} = "";
        $s->{num_wrote} = 0;
        $s->{opened} = 1;
        $s->{pending_errormsg} = "";
        $s->{port} = '';
        $s->{pushback_buf} = "";
        $s->{select_supported} = $^O ne "MSWin32" || -S $self;
        $s->{timedout} = '';
        $s->{unsent_opts} = "";
        &_reset_options($s->{opts});

        1;
    } # end sub fhopen


    sub get {
        my ($self, %args) = @_;
        my (
        $binmode,
        $endtime,
        $errmode,
        $line,
        $s,
        $telnetmode,
        $timeout,
        );
        local $_;

        ## Init.
        $s = *$self->{net_telnet};
        $timeout = $s->{time_out};
        $s->{timedout} = '';
        return if $s->{eofile};

        ## Parse the named args.
        foreach (keys %args) {
        if (/^-?binmode$/i) {
            $binmode = $args{$_};
            unless (defined $binmode) {
            $binmode = 0;
            }
        }
        elsif (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $args{$_});
        }
        elsif (/^-?telnetmode$/i) {
            $telnetmode = $args{$_};
            unless (defined $telnetmode) {
            $telnetmode = 0;
            }
        }
        elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
        }
        else {
            &_croak($self, "bad named parameter \"$_\" given " .
                "to " . ref($self) . "::get()");
        }
        }

        ## If any args given, override corresponding instance data.
        local $s->{errormode} = $errmode
        if defined $errmode;
        local $s->{bin_mode} = $binmode
        if defined $binmode;
        local $s->{telnet_mode} = $telnetmode
        if defined $telnetmode;

        ## Set wall time when we time out.
        $endtime = &_endtime($timeout);

        ## Try to send any waiting option negotiation.
        if (length $s->{unsent_opts}) {
        &_flush_opts($self);
        }

        ## Try to read just the waiting data using return error mode.
        {
        local $s->{errormode} = "return";
        $s->{errormsg} = "";
        &_fillbuf($self, $s, 0);
        }

        ## We're done if we timed-out and timeout value is set to "poll".
        return $self->error($s->{errormsg})
        if ($s->{timedout} and defined($timeout) and $timeout == 0
            and !length $s->{buf});

        ## We're done if we hit an error other than timing out.
        if ($s->{errormsg} and !$s->{timedout}) {
        if (!length $s->{buf}) {
            return $self->error($s->{errormsg});
        }
        else {  # error encountered but there's some data in buffer
            $s->{pending_errormsg} = $s->{errormsg};
        }
        }

        ## Clear time-out error from first read.
        $s->{timedout} = '';
        $s->{errormsg} = "";

        ## If buffer is still empty, try to read according to user's timeout.
        if (!length $s->{buf}) {
        &_fillbuf($self, $s, $endtime)
            or do {
            return if $s->{timedout};

            ## We've reached end-of-file.
            $self->close;
            return;
            };
        }

        ## Extract chars from buffer.
        $line = $s->{buf};
        $s->{buf} = "";

        $line;
    } # end sub get


    sub getline {
        my ($self, %args) = @_;
        my (
        $binmode,
        $endtime,
        $errmode,
        $len,
        $line,
        $offset,
        $pos,
        $rs,
        $s,
        $telnetmode,
        $timeout,
        );
        local $_;

        ## Init.
        $s = *$self->{net_telnet};
        $s->{timedout} = '';
        return if $s->{eofile};
        $rs = $s->{"rs"};
        $timeout = $s->{time_out};

        ## Parse the named args.
        foreach (keys %args) {
        if (/^-?binmode$/i) {
            $binmode = $args{$_};
            unless (defined $binmode) {
            $binmode = 0;
            }
        }
        elsif (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $args{$_});
        }
        elsif (/^-?input_record_separator$/i or /^-?rs$/i) {
            $rs = &_parse_input_record_separator($self, $args{$_});
        }
        elsif (/^-?telnetmode$/i) {
            $telnetmode = $args{$_};
            unless (defined $telnetmode) {
            $telnetmode = 0;
            }
        }
        elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
        }
        else {
            &_croak($self, "bad named parameter \"$_\" given " .
                "to " . ref($self) . "::getline()");
        }
        }

        ## If any args given, override corresponding instance data.
        local $s->{bin_mode} = $binmode
        if defined $binmode;
        local $s->{errormode} = $errmode
        if defined $errmode;
        local $s->{telnet_mode} = $telnetmode
        if defined $telnetmode;

        ## Set wall time when we time out.
        $endtime = &_endtime($timeout);

        ## Try to send any waiting option negotiation.
        if (length $s->{unsent_opts}) {
        &_flush_opts($self);
        }

        ## Keep reading into buffer until end-of-line is read.
        $offset = 0;
        while (($pos = index($s->{buf}, $rs, $offset)) == -1) {
        $offset = length $s->{buf};
        &_fillbuf($self, $s, $endtime)
            or do {
            return if $s->{timedout};

            ## We've reached end-of-file.
            $self->close;
            if (length $s->{buf}) {
                return $s->{buf};
            }
            else {
                return;
            }
            };
        }

        ## Extract line from buffer.
        $len = $pos + length $rs;
        $line = substr($s->{buf}, 0, $len);
        substr($s->{buf}, 0, $len) = "";

        $line;
    } # end sub getline


    sub getlines {
        my ($self, %args) = @_;
        my (
        $binmode,
        $errmode,
        $line,
        $rs,
        $s,
        $telnetmode,
        $timeout,
        );
        my $all = 1;
        my @lines = ();
        local $_;

        ## Init.
        $s = *$self->{net_telnet};
        $s->{timedout} = '';
        return if $s->{eofile};
        $timeout = $s->{time_out};

        ## Parse the named args.
        foreach (keys %args) {
        if (/^-?all$/i) {
            $all = $args{$_};
            unless (defined $all) {
            $all = '';
            }
        }
        elsif (/^-?binmode$/i) {
            $binmode = $args{$_};
            unless (defined $binmode) {
            $binmode = 0;
            }
        }
        elsif (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $args{$_});
        }
        elsif (/^-?input_record_separator$/i or /^-?rs$/i) {
            $rs = &_parse_input_record_separator($self, $args{$_});
        }
        elsif (/^-?telnetmode$/i) {
            $telnetmode = $args{$_};
            unless (defined $telnetmode) {
            $telnetmode = 0;
            }
        }
        elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
        }
        else {
            &_croak($self, "bad named parameter \"$_\" given " .
                "to " . ref($self) . "::getlines()");
        }
        }

        ## If any args given, override corresponding instance data.
        local $s->{bin_mode} = $binmode
        if defined $binmode;
        local $s->{errormode} = $errmode
        if defined $errmode;
        local $s->{"rs"} = $rs
        if defined $rs;
        local $s->{telnet_mode} = $telnetmode
        if defined $telnetmode;
        local $s->{time_out} = &_endtime($timeout);

        ## User requested only the currently available lines.
        if (! $all) {
        return &_next_getlines($self, $s);
        }

        ## Read lines until eof or error.
        while (1) {
        $line = $self->getline
            or last;
        push @lines, $line;
        }

        ## Check for error.
        return if ! $self->eof;

        @lines;
    } # end sub getlines


    sub host {
        my ($self, $host) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{host};

        if (@_ >= 2) {
        unless (defined $host) {
            $host = "";
        }

        $s->{host} = $host;
        }

        $prev;
    } # end sub host


    sub input_log {
        my ($self, $name) = @_;
        my (
        $fh,
        $s,
        );

        $s = *$self->{net_telnet};
        $fh = $s->{inputlog};

        if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        }
        elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
            or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        else {
            return $self->error("bad Input_log argument ",
                    "\"$name\": not filename or open fh");
        }

        $s->{inputlog} = $fh;
        }

        $fh;
    } # end sub input_log


    sub input_record_separator {
        my ($self, $rs) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{"rs"};

        if (@_ >= 2) {
        $s->{"rs"} = &_parse_input_record_separator($self, $rs);
        }

        $prev;
    } # end sub input_record_separator


    sub last_prompt {
        my ($self, $string) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{last_prompt};

        if (@_ >= 2) {
        unless (defined $string) {
            $string = "";
        }

        $s->{last_prompt} = $string;
        }

        $prev;
    } # end sub last_prompt


    sub lastline {
        my ($self, $line) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{last_line};

        if (@_ >= 2) {
        unless (defined $line) {
            $line = "";
        }

        $s->{last_line} = $line;
        }

        $prev;
    } # end sub lastline


    sub localfamily {
        my ($self, $family) = @_;
        my (
        $prev,
        $s,
        $socket_version,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{local_family};
        $socket_version = $Socket::VERSION;     # replace '2.020_03' with '2.020'
        $socket_version =~ s/\_.*$//;

        if (@_ >= 2) {
        unless (defined $family) {
            $family = "";
        }

        if ($family =~ /^\s*ipv4\s*$/i) {  # family arg is "ipv4"
            $s->{local_family} = "ipv4";
        }
        elsif ($family =~ /^\s*any\s*$/i) {  # family arg is "any"
            if ($socket_version >= 1.94 and defined $AF_INET6) {  # has IPv6
            $s->{local_family} = "any";
            }
            else {  # IPv6 not supported on this machine
            $s->{local_family} = "ipv4";
            }
        }
        elsif ($family =~ /^\s*ipv6\s*$/i) {  # family arg is "ipv6"
            return $self->error("Localfamily arg ipv6 not supported when " .
                    "Socket.pm version < 1.94")
            unless $socket_version >= 1.94;
            return $self->error("Localfamily arg ipv6 not supported by " .
                    "this OS: AF_INET6 not in Socket.pm")
            unless defined $AF_INET6;

            $s->{local_family} = "ipv6";
        }
        else {
            return $self->error("bad Localfamily argument \"$family\": " .
                    "must be \"ipv4\", \"ipv6\", or \"any\"");
        }
        }

        $prev;
    } # end sub localfamily


    sub localhost {
        my ($self, $localhost) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{local_host};

        if (@_ >= 2) {
        unless (defined $localhost) {
            $localhost = "";
        }

        $s->{local_host} = $localhost;
        }

        $prev;
    } # end sub localhost


    sub login {
        my ($self, @args) = @_;
        my (
        $arg_errmode,
        $error,
        $is_passwd_arg,
        $is_username_arg,
        $lastline,
        $match,
        $ors,
        $passwd,
        $prematch,
        $prompt,
        $s,
        $timeout,
        $username,
        %args,
        );
        local $_;

        ## Init.
        $self->timed_out('');
        $self->last_prompt("");
        $s = *$self->{net_telnet};
        $timeout = $self->timeout;
        $ors = $self->output_record_separator;
        $prompt = $self->prompt;

        ## Parse positional args.
        if (@args == 2) {  # just username and passwd given
        $username = $args[0];
        $passwd = $args[1];

        $is_username_arg = 1;
        $is_passwd_arg = 1;
        }

        ## Override errmode first, if specified.
        $arg_errmode = &_extract_arg_errmode($self, \@args);
        local $s->{errormode} = $arg_errmode
        if $arg_errmode;

        ## Parse named args.
        if (@args > 2) {
        ## Get the named args.
        %args = @args;

        ## Parse the named args.
        foreach (keys %args) {
            if (/^-?name$/i) {
            $username = $args{$_};
            unless (defined $username) {
                $username = "";
            }

            $is_username_arg = 1;
            }
            elsif (/^-?pass/i) {
            $passwd = $args{$_};
            unless (defined $passwd) {
                $passwd = "";
            }

            $is_passwd_arg = 1;
            }
            elsif (/^-?prompt$/i) {
            $prompt = &_parse_prompt($self, $args{$_})
                or return;
            }
            elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
            }
            else {
            &_croak($self, "bad named parameter \"$_\" given ",
                "to " . ref($self) . "::login()");
            }
        }
        }

        ## Ensure both username and password argument given.
        &_croak($self,"Name argument not given to " . ref($self) . "::login()")
        unless $is_username_arg;
        &_croak($self,"Password argument not given to " . ref($self) . "::login()")
        unless $is_passwd_arg;

        ## Set timeout for this invocation.
        local $s->{time_out} = &_endtime($timeout);

        ## Create a subroutine to generate an error.
        $error
        = sub {
            my ($errmsg) = @_;

            if ($self->timed_out) {
            return $self->error($errmsg);
            }
            elsif ($self->eof) {
            ($lastline = $self->lastline) =~ s/\n+//;
            return $self->error($errmsg, ": ", $lastline);
            }
            else {
            return $self->error($self->errmsg);
            }
        };


        return $self->error("login failed: filehandle isn't open")
        if $self->eof;

        ## Wait for login prompt.
        $self->waitfor(Match => '/login[: ]*$/i',
               Match => '/username[: ]*$/i',
               Errmode => "return")
        or do {
            return &$error("eof read waiting for login prompt")
            if $self->eof;
            return &$error("timed-out waiting for login prompt");
        };

        ## Delay sending response because of bug in Linux login program.
        &_sleep(0.01);

        ## Send login name.
        $self->put(String => $username . $ors,
               Errmode => "return")
        or return &$error("login disconnected");

        ## Wait for password prompt.
        $self->waitfor(Match => '/password[: ]*$/i',
               Errmode => "return")
        or do {
            return &$error("eof read waiting for password prompt")
            if $self->eof;
            return &$error("timed-out waiting for password prompt");
        };

        ## Delay sending response because of bug in Linux login program.
        &_sleep(0.01);

        ## Send password.
        $self->put(String => $passwd . $ors,
               Errmode => "return")
        or return &$error("login disconnected");

        ## Wait for command prompt or another login prompt.
        ($prematch, $match) = $self->waitfor(Match => '/login[: ]*$/i',
                         Match => '/username[: ]*$/i',
                         Match => $prompt,
                         Errmode => "return")
        or do {
            return &$error("eof read waiting for command prompt")
            if $self->eof;
            return &$error("timed-out waiting for command prompt");
        };

        ## It's a bad login if we got another login prompt.
        return $self->error("login failed: bad name or password")
        if $match =~ /login[: ]*$/i or $match =~ /username[: ]*$/i;

        ## Save the most recently matched command prompt.
        $self->last_prompt($match);

        1;
    } # end sub login


    sub max_buffer_length {
        my ($self, $maxbufsize) = @_;
        my (
        $prev,
        $s,
        );
        my $minbufsize = 512;

        $s = *$self->{net_telnet};
        $prev = $s->{maxbufsize};

        if (@_ >= 2) {
        ## Ensure a positive integer value.
        unless (defined $maxbufsize
            and $maxbufsize =~ /^\d+$/
            and $maxbufsize)
        {
            &_carp($self, "ignoring bad Max_buffer_length " .
               "argument \"$maxbufsize\": it's not a positive integer");
            $maxbufsize = $prev;
        }

        ## Adjust up values that are too small.
        if ($maxbufsize < $minbufsize) {
            $maxbufsize = $minbufsize;
        }

        $s->{maxbufsize} = $maxbufsize;
        }

        $prev;
    } # end sub max_buffer_length


    ## Make ofs() synonymous with output_field_separator().
    sub ofs { &output_field_separator; }


    sub open {
        my ($self, @args) = @_;
        my (
        $af,
        $arg_errmode,
        $err,
        $errno,
        $family,
        $flags_hint,
        $host,
        $ip_addr,
        $lfamily,
        $localhost,
        $port,
        $s,
        $timeout,
        %args,
        @ai,
        );
        local $@;
        local $_;
        my $local_addr = '';
        my $remote_addr = '';
        my %af = (
        ipv4 => AF_INET,
        ipv6 => defined($AF_INET6) ? $AF_INET6 : undef,
        any => $AF_UNSPEC,
        );

        ## Init.
        $s = *$self->{net_telnet};
        $s->{timedout} = '';
        $s->{sock_family} = 0;
        $port = $self->port;
        $family = $self->family;
        $localhost = $self->localhost;
        $lfamily = $self->localfamily;
        $timeout = $self->timeout;

        ## Override errmode first, if specified.
        $arg_errmode = &_extract_arg_errmode($self, \@args);
        local $s->{errormode} = $arg_errmode
        if $arg_errmode;

        if (@args == 1) {  # one positional arg given
        $self->host($args[0]);
        }
        elsif (@args >= 2) {  # named args given
        ## Get the named args.
        %args = @args;

        ## Parse the named args.
        foreach (keys %args) {
            if (/^-?family$/i) {
            $family = &_parse_family($self, $args{$_});
            }
            elsif (/^-?host$/i) {
            $self->host($args{$_});
            }
            elsif (/^-?localfamily$/i) {
            $lfamily = &_parse_localfamily($self, $args{$_});
            }
            elsif (/^-?localhost$/i) {
            $args{$_} = "" unless defined $args{$_};
            $localhost = $args{$_};
            }
            elsif (/^-?port$/i) {
            $port = &_parse_port($self, $args{$_});
            }
            elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
            }
            else {
            &_croak($self, "bad named parameter \"$_\" given ",
                "to " . ref($self) . "::open()");
            }
        }
        }

        ## Get hostname/ip address.
        $host = $self->host;

        ## Ensure we're already closed.
        $self->close;

        ## Connect with or without a timeout.
        if (defined($timeout) and &_have_alarm) {  # use a timeout
        ## Convert possible absolute timeout to relative timeout.
        if ($timeout >= $^T) {  # it's an absolute time
            $timeout = $timeout - time;
        }

        ## Ensure a valid timeout value for alarm.
        if ($timeout < 1) {
            $timeout = 1;
        }
        $timeout = int($timeout + 0.5);

        ## Connect to server, timing out if it takes too long.
        eval {
            ## Turn on timer.
            local $SIG{"__DIE__"} = "DEFAULT";
            local $SIG{ALRM} = sub { die "timed-out\n" };
            alarm $timeout;

            if ($family eq "ipv4") {
            ## Lookup server's IP address.
            $ip_addr = inet_aton $host
                or die "unknown remote host: $host\n";
            $af = AF_INET;
            $remote_addr = sockaddr_in($port, $ip_addr);
            }
            else {  # family is "ipv6" or "any"
            ## Lookup server's IP address.
            $flags_hint = $family eq "any" ? $AI_ADDRCONFIG : 0;
            ($err, @ai) = Socket::getaddrinfo($host, $port,
                              { socktype => SOCK_STREAM,
                                "family" => $af{$family},
                                "flags" => $flags_hint });
            if ($err == $EAI_BADFLAGS) {
                ## Try again with no flags.
                ($err, @ai) = Socket::getaddrinfo($host, $port,
                                  {socktype => SOCK_STREAM,
                                   "family"=> $af{$family},
                                   "flags" => 0 });
            }
            die "unknown remote host: $host: $err\n"
                if $err or !@ai;
            $af = $ai[0]{"family"};
            $remote_addr = $ai[0]{addr};
            }

            ## Create a socket and attach the filehandle to it.
            socket $self, $af, SOCK_STREAM, 0
            or die "problem creating socket: $!\n";

            ## Bind to a local network interface.
            if (length $localhost) {
            if ($lfamily eq "ipv4") {
                ## Lookup server's IP address.
                $ip_addr = inet_aton $localhost
                or die "unknown local host: $localhost\n";
                $local_addr = sockaddr_in(0, $ip_addr);
            }
            else {  # local family is "ipv6" or "any"
                ## Lookup local IP address.
                ($err, @ai) = Socket::getaddrinfo($localhost, 0,
                                  {socktype => SOCK_STREAM,
                                   "family"=>$af{$lfamily},
                                   "flags" => 0 });
                die "unknown local host: $localhost: $err\n"
                if $err or !@ai;
                $local_addr = $ai[0]{addr};
            }

            bind $self, $local_addr
                or die "problem binding to \"$localhost\": $!\n";
            }

            ## Open connection to server.
            connect $self, $remote_addr
            or die "problem connecting to \"$host\", port $port: $!\n";
        };
        alarm 0;

        ## Check for error.
        if ($@ =~ /^timed-out$/) {  # time out failure
            $s->{timedout} = 1;
            $self->close;
            if (!$remote_addr) {
            return $self->error("unknown remote host: $host: ",
                        "name lookup timed-out");
            }
            elsif (length($localhost) and !$local_addr) {
            return $self->error("unknown local host: $localhost: ",
                        "name lookup timed-out");
            }
            else {
            return $self->error("problem connecting to \"$host\", ",
                        "port $port: connect timed-out");
            }
        }
        elsif ($@) {  # hostname lookup or connect failure
            $self->close;
            chomp $@;
            return $self->error($@);
        }
        }
        else {  # don't use a timeout
        $timeout = undef;

        if ($family eq "ipv4") {
            ## Lookup server's IP address.
            $ip_addr = inet_aton $host
            or return $self->error("unknown remote host: $host");
            $af = AF_INET;
            $remote_addr = sockaddr_in($port, $ip_addr);
        }
        else {  # family is "ipv6" or "any"
            ## Lookup server's IP address.
            $flags_hint = $family eq "any" ? $AI_ADDRCONFIG : 0;
            ($err, @ai) = Socket::getaddrinfo($host, $port,
                              { socktype => SOCK_STREAM,
                            "family" => $af{$family},
                            "flags" => $flags_hint });
            if ($err == $EAI_BADFLAGS) {
            ## Try again with no flags.
            ($err, @ai) = Socket::getaddrinfo($host, $port,
                              { socktype => SOCK_STREAM,
                                "family"=> $af{$family},
                                "flags" => 0 });
            }
            return $self->error("unknown remote host: $host")
            if $err or !@ai;
            $af = $ai[0]{"family"};
            $remote_addr = $ai[0]{addr};
        }

        ## Create a socket and attach the filehandle to it.
        socket $self, $af, SOCK_STREAM, 0
            or return $self->error("problem creating socket: $!");

        ## Bind to a local network interface.
        if (length $localhost) {
            if ($lfamily eq "ipv4") {
            ## Lookup server's IP address.
            $ip_addr = inet_aton $localhost
                or return $self->error("unknown local host: $localhost");
            $local_addr = sockaddr_in(0, $ip_addr);
            }
            else {  # local family is "ipv6" or "any"
            ## Lookup local IP address.
            ($err, @ai) = Socket::getaddrinfo($localhost, 0,
                              { socktype => SOCK_STREAM,
                                "family"=>$af{$lfamily},
                                "flags" => 0 });
            return $self->error("unknown local host: $localhost: $err")
                if $err or !@ai;
            $local_addr = $ai[0]{addr};
            }

            bind $self, $local_addr
            or return $self->error("problem binding ",
                           "to \"$localhost\": $!");
        }

        ## Open connection to server.
        connect $self, $remote_addr
            or do {
            $errno = "$!";
            $self->close;
            return $self->error("problem connecting to \"$host\", ",
                        "port $port: $errno");
            };
        }

        select((select($self), $|=1)[$[]);  # don't buffer writes
        $s->{blksize} = &_optimal_blksize((stat $self)[11]);
        $s->{buf} = "";
        $s->{eofile} = '';
        $s->{errormsg} = "";
        vec($s->{fdmask}='', fileno($self), 1) = 1;
        $s->{last_line} = "";
        $s->{sock_family} = $af;
        $s->{num_wrote} = 0;
        $s->{opened} = 1;
        $s->{pending_errormsg} = "";
        $s->{pushback_buf} = "";
        $s->{select_supported} = 1;
        $s->{timedout} = '';
        $s->{unsent_opts} = "";
        &_reset_options($s->{opts});

        1;
    } # end sub open


    sub option_accept {
        my ($self, @args) = @_;
        my (
        $arg,
        $option,
        $s,
        @opt_args,
        );
        local $_;

        ## Init.
        $s = *$self->{net_telnet};

        ## Parse the named args.
        while (($_, $arg) = splice @args, 0, 2) {
        ## Verify and save arguments.
        if (/^-?do$/i) {
            ## Make sure a callback is defined.
            return $self->error("usage: an option callback must already ",
                    "be defined when enabling with $_")
            unless $s->{opt_cback};

            $option = &_verify_telopt_arg($self, $arg, $_);
            return unless defined $option;
            push @opt_args, { option    => $option,
                      is_remote => '',
                      is_enable => 1,
                  };
        }
        elsif (/^-?dont$/i) {
            $option = &_verify_telopt_arg($self, $arg, $_);
            return unless defined $option;
            push @opt_args, { option    => $option,
                      is_remote => '',
                      is_enable => '',
                  };
        }
        elsif (/^-?will$/i) {
            ## Make sure a callback is defined.
            return $self->error("usage: an option callback must already ",
                    "be defined when enabling with $_")
            unless $s->{opt_cback};

            $option = &_verify_telopt_arg($self, $arg, $_);
            return unless defined $option;
            push @opt_args, { option    => $option,
                      is_remote => 1,
                      is_enable => 1,
                  };
        }
        elsif (/^-?wont$/i) {
            $option = &_verify_telopt_arg($self, $arg, $_);
            return unless defined $option;
            push @opt_args, { option    => $option,
                      is_remote => 1,
                      is_enable => '',
                  };
        }
        else {
            return $self->error('usage: $obj->option_accept(' .
                    '[Do => $telopt,] ',
                    '[Dont => $telopt,] ',
                    '[Will => $telopt,] ',
                    '[Wont => $telopt,]');
        }
        }

        ## Set "receive ok" for options specified.
        &_opt_accept($self, @opt_args);
    } # end sub option_accept


    sub option_callback {
        my ($self, $callback) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{opt_cback};

        if (@_ >= 2) {
        unless (defined $callback and ref($callback) eq "CODE") {
            &_carp($self, "ignoring Option_callback argument because it's " .
               "not a code ref");
            $callback = $prev;
        }

        $s->{opt_cback} = $callback;
        }

        $prev;
    } # end sub option_callback


    sub option_log {
        my ($self, $name) = @_;
        my (
        $fh,
        $s,
        );

        $s = *$self->{net_telnet};
        $fh = $s->{opt_log};

        if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        }
        elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
            or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        else {
            return $self->error("bad Option_log argument ",
                    "\"$name\": not filename or open fh");
        }

        $s->{opt_log} = $fh;
        }

        $fh;
    } # end sub option_log


    sub option_state {
        my ($self, $option) = @_;
        my (
        $opt_state,
        $s,
        %opt_state,
        );

        ## Ensure telnet option is non-negative integer.
        $option = &_verify_telopt_arg($self, $option);
        return unless defined $option;

        ## Init.
        $s = *$self->{net_telnet};
        unless (defined $s->{opts}{$option}) {
        &_set_default_option($s, $option);
        }

        ## Return hashref to a copy of the values.
        $opt_state = $s->{opts}{$option};
        %opt_state = %$opt_state;
        \%opt_state;
    } # end sub option_state


    ## Make ors() synonymous with output_record_separator().
    sub ors { &output_record_separator; }


    sub output_field_separator {
        my ($self, $ofs) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{"ofs"};

        if (@_ >= 2) {
        unless (defined $ofs) {
            $ofs = "";
        }

        $s->{"ofs"} = $ofs;
        }

        $prev;
    } # end sub output_field_separator


    sub output_log {
        my ($self, $name) = @_;
        my (
        $fh,
        $s,
        );

        $s = *$self->{net_telnet};
        $fh = $s->{outputlog};

        if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        }
        elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
            or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        }
        else {
            return $self->error("bad Output_log argument ",
                    "\"$name\": not filename or open fh");
        }

        $s->{outputlog} = $fh;
        }

        $fh;
    } # end sub output_log


    sub output_record_separator {
        my ($self, $ors) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{"ors"};

        if (@_ >= 2) {
        unless (defined $ors) {
            $ors = "";
        }

        $s->{"ors"} = $ors;
        }

        $prev;
    } # end sub output_record_separator


    sub peerhost {
        my ($self) = @_;
        my (
        $host,
        $sockaddr,
        );
        local $^W = '';  # avoid closed socket warning from getpeername()

        ## Get packed sockaddr struct of remote side and then unpack it.
        $sockaddr = getpeername $self
        or return "";
        (undef, $host) = $self->_unpack_sockaddr($sockaddr);

        $host;
    } # end sub peerhost


    sub peerport {
        my ($self) = @_;
        my (
        $port,
        $sockaddr,
        );
        local $^W = '';  # avoid closed socket warning from getpeername()

        ## Get packed sockaddr struct of remote side and then unpack it.
        $sockaddr = getpeername $self
        or return "";
        ($port) = $self->_unpack_sockaddr($sockaddr);

        $port;
    } # end sub peerport


    sub port {
        my ($self, $port) = @_;
        my (
        $prev,
        $s,
        $service,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{port};

        if (@_ >= 2) {
        $port = &_parse_port($self, $port)
            or return;

        $s->{port} = $port;
        }

        $prev;
    } # end sub port


    sub print {
        my ($self) = shift;
        my (
        $buf,
        $fh,
        $s,
        );

        $s = *$self->{net_telnet};
        $s->{timedout} = '';
        return $self->error("write error: filehandle isn't open")
        unless $s->{opened};

        ## Add field and record separators.
        $buf = join($s->{"ofs"}, @_) . $s->{"ors"};

        ## Log the output if requested.
        if ($s->{outputlog}) {
        &_log_print($s->{outputlog}, $buf);
        }

        ## Convert native newlines to CR LF.
        if (!$s->{bin_mode}) {
        $buf =~ s(\n)(\015\012)g;
        }

        ## Escape TELNET IAC and also CR not followed by LF.
        if ($s->{telnet_mode}) {
        $buf =~ s(\377)(\377\377)g;
        &_escape_cr(\$buf);
        }

        &_put($self, \$buf, "print");
    } # end sub print


    sub print_length {
        my ($self) = @_;

        *$self->{net_telnet}{num_wrote};
    } # end sub print_length


    sub prompt {
        my ($self, $prompt) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{cmd_prompt};

        ## Parse args.
        if (@_ == 2) {
        $prompt = &_parse_prompt($self, $prompt)
            or return;

        $s->{cmd_prompt} = $prompt;
        }

        $prev;
    } # end sub prompt


    sub put {
        my ($self) = @_;
        my (
        $binmode,
        $buf,
        $errmode,
        $is_timeout_arg,
        $s,
        $telnetmode,
        $timeout,
        %args,
        );
        local $_;

        ## Init.
        $s = *$self->{net_telnet};
        $s->{timedout} = '';

        ## Parse args.
        if (@_ == 2) {  # one positional arg given
        $buf = $_[1];
        }
        elsif (@_ > 2) {  # named args given
        ## Get the named args.
        (undef, %args) = @_;

        ## Parse the named args.
        foreach (keys %args) {
            if (/^-?binmode$/i) {
            $binmode = $args{$_};
            unless (defined $binmode) {
                $binmode = 0;
            }
            }
            elsif (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $args{$_});
            }
            elsif (/^-?string$/i) {
            $buf = $args{$_};
            }
            elsif (/^-?telnetmode$/i) {
            $telnetmode = $args{$_};
            unless (defined $telnetmode) {
                $telnetmode = 0;
            }
            }
            elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $args{$_});
            $is_timeout_arg = 1;
            }
            else {
            &_croak($self, "bad named parameter \"$_\" given ",
                "to " . ref($self) . "::put()");
            }
        }
        }

        ## If any args given, override corresponding instance data.
        local $s->{bin_mode} = $binmode
        if defined $binmode;
        local $s->{errormode} = $errmode
        if defined $errmode;
        local $s->{telnet_mode} = $telnetmode
        if defined $telnetmode;
        local $s->{time_out} = $timeout
        if defined $is_timeout_arg;

        ## Check for errors.
        return $self->error("write error: filehandle isn't open")
        unless $s->{opened};

        ## Log the output if requested.
        if ($s->{outputlog}) {
        &_log_print($s->{outputlog}, $buf);
        }

        ## Convert native newlines to CR LF.
        if (!$s->{bin_mode}) {
        $buf =~ s(\n)(\015\012)g;
        }

        ## Escape TELNET IAC and also CR not followed by LF.
        if ($s->{telnet_mode}) {
        $buf =~ s(\377)(\377\377)g;
        &_escape_cr(\$buf);
        }

        &_put($self, \$buf, "put");
    } # end sub put


    ## Make rs() synonymous input_record_separator().
    sub rs { &input_record_separator; }


    sub sockfamily {
        my ($self) = @_;
        my $s = *$self->{net_telnet};
        my $sockfamily = "";

        if ($s->{sock_family} == AF_INET) {
        $sockfamily = "ipv4";
        }
        elsif (defined($AF_INET6) and $s->{sock_family} == $AF_INET6) {
        $sockfamily = "ipv6";
        }

        $sockfamily;
    } # end sub sockfamily


    sub sockhost {
        my ($self) = @_;
        my (
        $host,
        $sockaddr,
        );
        local $^W = '';  # avoid closed socket warning from getsockname()

        ## Get packed sockaddr struct of local side and then unpack it.
        $sockaddr = getsockname $self
        or return "";
        (undef, $host) = $self->_unpack_sockaddr($sockaddr);

        $host;
    } # end sub sockhost


    sub sockport {
        my ($self) = @_;
        my (
        $port,
        $sockaddr,
        );
        local $^W = '';  # avoid closed socket warning from getsockname()

        ## Get packed sockaddr struct of local side and then unpack it.
        $sockaddr = getsockname $self
        or return "";
        ($port) = $self->_unpack_sockaddr($sockaddr);

        $port;
    } # end sub sockport


    sub suboption_callback {
        my ($self, $callback) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{subopt_cback};

        if (@_ >= 2) {
        unless (defined $callback and ref($callback) eq "CODE") {
            &_carp($self,"ignoring Suboption_callback argument because it's " .
               "not a code ref");
            $callback = $prev;
        }

        $s->{subopt_cback} = $callback;
        }

        $prev;
    } # end sub suboption_callback


    sub telnetmode {
        my ($self, $mode) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{telnet_mode};

        if (@_ >= 2) {
        unless (defined $mode) {
            $mode = 0;
        }

        $s->{telnet_mode} = $mode;
        }

        $prev;
    } # end sub telnetmode


    sub timed_out {
        my ($self, $value) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{timedout};

        if (@_ >= 2) {
        unless (defined $value) {
            $value = "";
        }

        $s->{timedout} = $value;
        }

        $prev;
    } # end sub timed_out


    sub timeout {
        my ($self, $timeout) = @_;
        my (
        $prev,
        $s,
        );

        $s = *$self->{net_telnet};
        $prev = $s->{time_out};

        if (@_ >= 2) {
        $s->{time_out} = &_parse_timeout($self, $timeout);
        }

        $prev;
    } # end sub timeout


    sub waitfor {
        my ($self, @args) = @_;
        my (
        $arg,
        $binmode,
        $endtime,
        $errmode,
        $len,
        $match,
        $match_op,
        $pos,
        $prematch,
        $s,
        $search,
        $search_cond,
        $telnetmode,
        $timeout,
        @match_cond,
        @match_ops,
        @search_cond,
        @string_cond,
        @warns,
        );
        local $@;
        local $_;

        ## Init.
        $s = *$self->{net_telnet};
        $s->{timedout} = '';
        return if $s->{eofile};
        return unless @args;
        $timeout = $s->{time_out};

        ## Code template used to build string match conditional.
        ## Values between array elements must be supplied later.
        @string_cond =
        ('if (($pos = index $s->{buf}, ', ') > -1) {
            $len = ', ';
            $prematch = substr $s->{buf}, 0, $pos;
            $match = substr $s->{buf}, $pos, $len;
            substr($s->{buf}, 0, $pos + $len) = "";
            last;
        }');

        ## Code template used to build pattern match conditional.
        ## Values between array elements must be supplied later.
        @match_cond =
        ('if ($s->{buf} =~ ', ') {
            $prematch = $`;
            $match = $&;
            substr($s->{buf}, 0, length($`) + length($&)) = "";
            last;
        }');

        ## Parse args.
        if (@_ == 2) {  # one positional arg given
        $arg = $_[1];

        ## Fill in the blanks in the code template.
        push @match_ops, $arg;
        push @search_cond, join("", $match_cond[0], $arg, $match_cond[1]);
        }
        elsif (@_ > 2) {  # named args given
        ## Parse the named args.
        while (($_, $arg) = splice @args, 0, 2) {
            if (/^-?binmode$/i) {
            $binmode = $arg;
            unless (defined $binmode) {
                $binmode = 0;
            }
            }
            elsif (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $arg);
            }
            elsif (/^-?match$/i) {
            ## Fill in the blanks in the code template.
            push @match_ops, $arg;
            push @search_cond, join("",
                        $match_cond[0], $arg, $match_cond[1]);
            }
            elsif (/^-?string$/i) {
            ## Fill in the blanks in the code template.
            $arg =~ s/'/\\'/g;  # quote ticks
            push @search_cond, join("",
                        $string_cond[0], "'$arg'",
                        $string_cond[1], length($arg),
                        $string_cond[2]);
            }
            elsif (/^-?telnetmode$/i) {
            $telnetmode = $arg;
            unless (defined $telnetmode) {
                $telnetmode = 0;
            }
            }
            elsif (/^-?timeout$/i) {
            $timeout = &_parse_timeout($self, $arg);
            }
            else {
            &_croak($self, "bad named parameter \"$_\" given " .
                "to " . ref($self) . "::waitfor()");
            }
        }
        }

        ## If any args given, override corresponding instance data.
        local $s->{errormode} = $errmode
        if defined $errmode;
        local $s->{bin_mode} = $binmode
        if defined $binmode;
        local $s->{telnet_mode} = $telnetmode
        if defined $telnetmode;

        ## Check for bad match operator argument.
        foreach $match_op (@match_ops) {
        return $self->error("missing opening delimiter of match operator ",
                    "in argument \"$match_op\" given to ",
                    ref($self) . "::waitfor()")
            unless $match_op =~ m(^\s*/) or $match_op =~ m(^\s*m\s*\W);
        }

        ## Construct conditional to check for requested string and pattern matches.
        ## Turn subsequent "if"s into "elsif".
        $search_cond = join "\n\tels", @search_cond;

        ## Construct loop to fill buffer until string/pattern, timeout, or eof.
        $search = join "", "
        while (1) {\n\t",
        $search_cond, '
        &_fillbuf($self, $s, $endtime)
            or do {
            last if $s->{timedout};
            $self->close;
            last;
            };
        }';

        ## Set wall time when we timeout.
        $endtime = &_endtime($timeout);

        ## Run the loop.
        {
        local $^W = 1;
        local $SIG{"__WARN__"} = sub { push @warns, @_ };
        local $s->{errormode} = "return";
        $s->{errormsg} = "";
        eval $search;
        }

        ## Check for failure.
        return $self->error("pattern match timed-out") if $s->{timedout};
        return $self->error($s->{errormsg}) if $s->{errormsg} ne "";
        return $self->error("pattern match read eof") if $s->{eofile};

        ## Check for Perl syntax errors or warnings.
        if ($@ or @warns) {
        foreach $match_op (@match_ops) {
            &_match_check($self, $match_op)
            or return;
        }
        return $self->error($@) if $@;
        return $self->error(@warns) if @warns;
        }

        wantarray ? ($prematch, $match) : 1;
    } # end sub waitfor


    ######################## Private Subroutines #########################


    sub _append_lineno {
        my ($obj, @msgs) = @_;
        my (
        $file,
        $line,
        $pkg,
        );

        ## Find the caller that's not in object's class or one of its base classes.
        ($pkg, $file , $line) = &_user_caller($obj);
        join("", @msgs, " at ", $file, " line ", $line, "\n");
    } # end sub _append_lineno


    sub _carp {
        my ($self) = @_;
        my $s = *$self->{net_telnet};

        $s->{errormsg} = &_append_lineno(@_);
        warn $s->{errormsg}, "\n";
    } # end sub _carp


    sub _croak {
        my ($self) = @_;
        my $s = *$self->{net_telnet};

        $s->{errormsg} = &_append_lineno(@_);
        die $s->{errormsg}, "\n";
    } # end sub _croak


    sub _endtime {
        my ($interval) = @_;

        ## Compute wall time when timeout occurs.
        if (defined $interval) {
        if ($interval >= $^T) {  # it's already an absolute time
            return $interval;
        }
        elsif ($interval > 0) {  # it's relative to the current time
            return int($interval + time + 0.5);
        }
        else {  # it's a one time poll
            return 0;
        }
        }
        else {  # there's no timeout
        return undef;
        }
    } # end sub _endtime


    sub _errno_include {
        local $@;
        local $SIG{"__DIE__"} = "DEFAULT";

        eval "require Errno";
    } # end sub errno_include


    sub _escape_cr {
        my ($string) = @_;
        my (
        $nextchar,
        );
        my $pos = 0;

        ## Convert all CR (not followed by LF) to CR NULL.
        while (($pos = index($$string, "\015", $pos)) > -1) {
        $nextchar = substr $$string, $pos + 1, 1;

        substr($$string, $pos, 1) = "\015\000"
            unless $nextchar eq "\012";

        $pos++;
        }

        1;
    } # end sub _escape_cr


    sub _extract_arg_errmode {
        my ($self, $args) = @_;
        my (
        %args,
        );
        local $_;
        my $errmode = '';

        ## Check for named parameters.
        return '' unless @$args >= 2;

        ## Rebuild args without errmode parameter.
        %args = @$args;
        @$args = ();

        ## Extract errmode arg.
        foreach (keys %args) {
        if (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $args{$_});
        }
        else {
            push @$args, $_, $args{$_};
        }
        }

        $errmode;
    } # end sub _extract_arg_errmode


    sub _fillbuf {
        my ($self, $s, $endtime) = @_;
        my (
        $msg,
        $nfound,
        $nread,
        $pushback_len,
        $read_pos,
        $ready,
        $timed_out,
        $timeout,
        $unparsed_pos,
        );

        ## If error from last read not yet reported then do it now.
        if ($s->{pending_errormsg}) {
        $msg = $s->{pending_errormsg};
        $s->{pending_errormsg} = "";
        return $self->error($msg);
        }

        return unless $s->{opened};

        while (1) {
        ## Maximum buffer size exceeded?
        return $self->error("maximum input buffer length exceeded: ",
                    $s->{maxbufsize}, " bytes")
            unless length($s->{buf}) <= $s->{maxbufsize};

        ## Determine how long to wait for input ready.
        ($timed_out, $timeout) = &_timeout_interval($endtime);
        if ($timed_out) {
            $s->{timedout} = 1;
            return $self->error("read timed-out");
        }

        ## Wait for input ready.
        $nfound = select $ready=$s->{fdmask}, "", "", $timeout;

        ## Handle any errors while waiting.
        if ((!defined $nfound or $nfound <= 0) and $s->{select_supported}) {
            if (defined $nfound and $nfound == 0) {  # timed-out
            $s->{timedout} = 1;
            return $self->error("read timed-out");
            }
            else {  # error waiting for input ready
            if (defined $EINTR) {
                next if $! == $EINTR;  # restart select()
            }
            else {
                next if $! =~ /^interrupted/i;  # restart select()
            }

            $s->{opened} = '';
            return $self->error("read error: $!");
            }
        }

        ## Append to buffer any partially processed telnet or CR sequence.
        $pushback_len = length $s->{pushback_buf};
        if ($pushback_len) {
            $s->{buf} .= $s->{pushback_buf};
            $s->{pushback_buf} = "";
        }

        ## Read the waiting data.
        $read_pos = length $s->{buf};
        $unparsed_pos = $read_pos - $pushback_len;
        $nread = sysread $self, $s->{buf}, $s->{blksize}, $read_pos;

        # Modified section to handle MCCP2 and MCCP1 ##############################################
        if ($nread && ($s->{opts}{86}{remote_enabled} || $s->{opts}{85}{remote_enabled})) {

            my ($buff, $zlibObj, $status, $posn, $previousBuff, $output, $spare, $sparePosn);

            $buff = $s->{buf};

            if (! $s->{axmud_mccp_mode}) {

                ($zlibObj, $status) = Compress::Zlib::inflateInit();
                if (! defined $zlibObj) {

                    $self->error("failed to initiate zlib compression stream");
                    &_disable_mccp($self, 1);
                    $s->{axmud_session}->set_mccpMode('compress_error');

                } else {

                    $s->{axmud_zlib_obj} = $zlibObj;
                    $s->{axmud_mccp_mode} = 1;
                    $s->{axmud_session}->set_mccpMode('client_agree');
                }
            }

            if ($s->{axmud_mccp_mode} == 1) {

                # Wait for IAC SB MCCP IAC SE (MCCP2), or IAC SB 85 WILL SE (MCCP1)
                $posn = index($buff, chr(255) . chr(250) . chr(85) . chr(251) . chr(240));
                if ($posn == -1) {

                    $posn = index($buff, chr(255) . chr(250) . chr(86) . chr(255) . chr(240));
                }

                if ($posn > -1) {

                    # IAC SB MCCP IAC SE (or IAC SB 85 WILL SE) received
                    $s->{axmud_mccp_mode} = 2;
                    # For MCCP1, the IAC SB 85 WILL SE is broken, and won't cause
                    #   Games::Axmud::Session->subOptCallback to be called in the normal way, so
                    #   here we have to call it artificially, pretending that a IAC SB 85 IAC SE
                    #   sequence was received
                    if ($s->{opts}{85}{remote_enabled}) {

                        $s->{axmud_session}->subOptCallback($self, 85, '');
                    }
                }
            }

            if ($s->{axmud_mccp_mode} >= 2 && $pushback_len) {

                # If any partially processed telnet or CR sequence was appended to the buffer,
                #   don't inflate that portion
                $previousBuff = substr($buff, 0, $pushback_len);
                $buff = substr($buff, $pushback_len);
            }

            if ($buff && $s->{axmud_mccp_mode} >= 2) {

                if ($s->{axmud_mccp_mode} == 2) {

                    # First inflation attempt. In case the packet contains IAC SB MCCP IAC SE (or
                    #   IAC SB 85 WILL SE) followed immediately by the zlib stream, we must only
                    #   inflate the zlib stream itself
                    $sparePosn = index($buff, chr(255) . chr(250) . chr(85) . chr(251) . chr(240));
                    if ($sparePosn == -1) {

                        $sparePosn
                            = index($buff, chr(255) . chr(250) . chr(86) . chr(255) . chr(240));
                    }

                    if ($sparePosn > -1) {

                        $spare = substr($buff, 0, ($sparePosn + 5));
                        $buff = substr($buff, ($sparePosn + 5));
                        ($output, $status) = $s->{axmud_zlib_obj}->inflate($buff);
                        $output = $spare . $output;

                    } else {

                        ($output, $status) = $s->{axmud_zlib_obj}->inflate($buff);
                    }

                } else {

                    # Subsequent inflation attempts
                    ($output, $status) = $s->{axmud_zlib_obj}->inflate($buff);
                }

                if ($status == Z_STREAM_END) {

                    # End of zlib compression stream. Don't inflate anything after this point
                    &_disable_mccp($self, 0);
                    $s->{axmud_session}->set_mccpMode('compress_stop');

                    # Re-attach anything that appeared after the end of the data stream
                    if (defined $previousBuff) {
                        $s->{buf} = $previousBuff . $output . $buff;
                    } else {
                        $s->{buf} = $output . $buff;
                    }

                    $nread = length ($output . $buff);

                } elsif ($status != Z_OK) {

                    $self->error("zlib compression failed, disabling MCCP");
                    &_disable_mccp($self, 1);
                    $s->{axmud_session}->set_mccpMode('compress_error');

                } else {

                    if ($s->{axmud_mccp_mode} == 2) {

                        # First successful inflation
                        $s->{axmud_mccp_mode} = 3;
                    }

                    # Inflation successful
                    if (defined $previousBuff) {
                        $s->{buf} = $previousBuff . $output;
                    } else {
                        $s->{buf} = $output;
                    }

                    $nread = length ($output);
                }
            }
        }

        # #########################################################################################

        ## Handle any read errors.
        if (!defined $nread) {  # read failed
            if (defined $EINTR) {
            next if $! == $EINTR;  # restart sysread()
            }
            else {
            next if $! =~ /^interrupted/i;  # restart sysread()
            }

            $s->{opened} = '';
            return $self->error("read error: $!");
        }

        ## Handle eof.
        if ($nread == 0) {  # eof read
            $s->{opened} = '';
            return;
        }

        ## Display network traffic if requested.
        if ($s->{dumplog}) {
            &_log_dump('<', $s->{dumplog}, \$s->{buf}, $read_pos);
        }

        ## Process any telnet commands in the data stream.
        if ($s->{telnet_mode} and index($s->{buf},"\377",$unparsed_pos) > -1) {
            &_interpret_tcmd($self, $s, $unparsed_pos);
        }

        ## Process any carriage-return sequences in the data stream.
        &_interpret_cr($s, $unparsed_pos);

        ## Read again if all chars read were consumed as telnet cmds.
        next if $unparsed_pos >= length $s->{buf};

        ## Log the input if requested.
        if ($s->{inputlog}) {
            &_log_print($s->{inputlog}, substr($s->{buf}, $unparsed_pos));
        }

        ## Save the last line read.
        &_save_lastline($s);

        ## We've successfully read some data into the buffer.
        last;
        } # end while(1)

        1;
    } # end sub _fillbuf


    sub _disable_mccp {
        my ($self, $flag) = @_;
        my $s = *$self->{net_telnet};

        if ($flag) {

            # Must send IAC DONT MCCP
            my $telCmd;

            if ($s->{opts}{86}{remote_enabled}) {
                $telCmd = pack("C*", &TELNET_IAC, &TELNET_DONT, 86);
            } else {
                $telCmd = pack("C*", &TELNET_IAC, &TELNET_DONT, 85);
            }

            $self->put(
                String => $telCmd,
                Telnetmode => 0,
            );
        }

        $s->{axmud_mccp_mode} = 0;
        $s->{axmud_zlib_obj} = '';
        $s->{opts}{85}{remote_enabled} = '';
        $s->{opts}{85}{remote_state} = 'no';
        $s->{opts}{85}{local_enabled} = '';
        $s->{opts}{85}{local_state} = 'no';
        $s->{opts}{86}{remote_enabled} = '';
        $s->{opts}{86}{remote_state} = 'no';
        $s->{opts}{86}{local_enabled} = '';
        $s->{opts}{86}{local_state} = 'no';

        1;
    } # end sub _disable_mccp


    sub _flush_opts {
        my ($self) = @_;
        my (
        $option_chars,
        );
        my $s = *$self->{net_telnet};

        ## Get option and clear the output buf.
        $option_chars = $s->{unsent_opts};
        $s->{unsent_opts} = "";

        ## Try to send options without waiting.
        {
        local $s->{errormode} = "return";
        local $s->{time_out} = 0;
        &_put($self, \$option_chars, "telnet option negotiation")
            or do {
            ## Save chars not printed for later.
            substr($option_chars, 0, $self->print_length) = "";
            $s->{unsent_opts} .= $option_chars;
            };
        }

        1;
    } # end sub _flush_opts


    sub _fname_to_handle {
        my ($self, $filename) = @_;
        my (
        $fh,
        );
        no strict "refs";

        $fh = &_new_handle();
        CORE::open $fh, "> $filename"
        or return $self->error("problem creating $filename: $!");

        $fh;
    } # end sub _fname_to_handle


    sub _have_alarm {
        local $@;

        eval {
        local $SIG{"__DIE__"} = "DEFAULT";
        local $SIG{ALRM} = sub { die };
        alarm 0;
        };

        ! $@;
    } # end sub _have_alarm


    sub _import_af_inet6 {
        local $@;

        eval {
        local $SIG{"__DIE__"} = "DEFAULT";

        Socket::AF_INET6();
        };
    } # end sub _import_af_inet6


    sub _import_af_unspec {
        local $@;

        eval {
        local $SIG{"__DIE__"} = "DEFAULT";

        Socket::AF_UNSPEC();
        };
    } # end sub _import_af_unspec


    sub _import_ai_addrconfig {
        local $@;

        eval {
        local $SIG{"__DIE__"} = "DEFAULT";

        Socket::AI_ADDRCONFIG();
        };
    } # end sub _import_ai_addrconfig


    sub _import_eai_badflags {
        local $@;

        eval {
        local $SIG{"__DIE__"} = "DEFAULT";

        Socket::EAI_BADFLAGS();
        };
    } # end sub _import_eai_badflags


    sub _import_eintr {
        local $@;
        local $SIG{"__DIE__"} = "DEFAULT";

        eval "require Errno; Errno::EINTR();";
    } # end sub _import_eintr


    sub _interpret_cr {
        my ($s, $pos) = @_;
        my (
        $nextchar,
        );

        while (($pos = index($s->{buf}, "\015", $pos)) > -1) {
        $nextchar = substr($s->{buf}, $pos + 1, 1);
        if ($nextchar eq "\0") {
            ## Convert CR NULL to CR when in telnet mode.
            if ($s->{telnet_mode}) {
            substr($s->{buf}, $pos + 1, 1) = "";
            }
        }
        elsif ($nextchar eq "\012") {
            ## Convert CR LF to newline when not in binary mode.
            if (!$s->{bin_mode}) {
            substr($s->{buf}, $pos, 2) = "\n";
            }
        }
        elsif (!length($nextchar) and ($s->{telnet_mode} or !$s->{bin_mode})) {
            ## Save CR in alt buffer for possible CR LF or CR NULL conversion.
            $s->{pushback_buf} .= "\015";
            chop $s->{buf};
        }

        $pos++;
        }

        1;
    } # end sub _interpret_cr


    sub _interpret_tcmd {
        my ($self, $s, $offset) = @_;
        my (
        $callback,
        $endpos,
        $nextchar,
        $option,
        $parameters,
        $pos,
        $subcmd,
        );
        local $_;

        ## Parse telnet commands in the data stream.
        $pos = $offset;
        while (($pos = index $s->{buf}, "\377", $pos) > -1) {  # unprocessed IAC
        $nextchar = substr $s->{buf}, $pos + 1, 1;

        ## Save command if it's only partially read.
        if (!length $nextchar) {
            $s->{pushback_buf} .= "\377";
            chop $s->{buf};
            last;
        }

        if ($nextchar eq "\377") {  # IAC is escaping "\377" char
            ## Remove escape char from data stream.
            substr($s->{buf}, $pos, 1) = "";
            $pos++;
        }
        elsif ($nextchar eq "\375" or $nextchar eq "\373" or
               $nextchar eq "\374" or $nextchar eq "\376") {  # opt negotiation
            $option = substr $s->{buf}, $pos + 2, 1;

            ## Save command if it's only partially read.
            if (!length $option) {
            $s->{pushback_buf} .= "\377" . $nextchar;
            chop $s->{buf};
            chop $s->{buf};
            last;
            }

            ## Remove command from data stream.
            substr($s->{buf}, $pos, 3) = "";

            ## Handle option negotiation.
            &_negotiate_recv($self, $s, $nextchar, ord($option), $pos);
        }
        elsif ($nextchar eq "\372") {  # start of subnegotiation parameters
            ## Save command if it's only partially read.
            $endpos = index $s->{buf}, "\360", $pos;
            if ($endpos == -1) {
            $s->{pushback_buf} .= substr $s->{buf}, $pos;
            substr($s->{buf}, $pos) = "";
            last;
            }

            ## Remove subnegotiation cmd from buffer.
            $subcmd = substr($s->{buf}, $pos, $endpos - $pos + 1);
            substr($s->{buf}, $pos, $endpos - $pos + 1) = "";

            ## Invoke subnegotiation callback.
            if ($s->{subopt_cback} and length($subcmd) >= 5) {
            $option = unpack "C", substr($subcmd, 2, 1);
            if (length($subcmd) >= 6) {
                $parameters = substr $subcmd, 3, length($subcmd) - 5;
            }
            else {
                $parameters = "";
            }

            $callback = $s->{subopt_cback};
            &$callback($self, $option, $parameters);
            }
        }
        else {  # various two char telnet commands
            ## Ignore and remove command from data stream.
            substr($s->{buf}, $pos, 2) = "";
        }
        }

        ## Try to send any waiting option negotiation.
        if (length $s->{unsent_opts}) {
        &_flush_opts($self);
        }

        1;
    } # end sub _interpret_tcmd


    sub _io_socket_include {
        local $@;
        local $SIG{"__DIE__"} = "DEFAULT";

        eval "require IO::Socket";
    } # end sub io_socket_include


    sub _is_open_fh {
        my ($fh) = @_;
        my $is_open = '';
        local $@;

        eval {
        local $SIG{"__DIE__"} = "DEFAULT";
        $is_open = defined(fileno $fh);
        };

        $is_open;
    } # end sub _is_open_fh


    sub _log_dump {
        my ($direction, $fh, $data, $offset, $len) = @_;
        my (
        $addr,
        $hexvals,
        $line,
        );

        $addr = 0;
        $len = length($$data) - $offset
        if !defined $len;
        return 1 if $len <= 0;

        ## Print data in dump format.
        while ($len > 0) {
        ## Convert up to the next 16 chars to hex, padding w/ spaces.
        if ($len >= 16) {
            $line = substr $$data, $offset, 16;
        }
        else {
            $line = substr $$data, $offset, $len;
        }
        $hexvals = unpack("H*", $line);
        $hexvals .= ' ' x (32 - length $hexvals);

        ## Place in 16 columns, each containing two hex digits.
        $hexvals = sprintf("%s %s %s %s  " x 4,
                   unpack("a2" x 16, $hexvals));

        ## For the ASCII column, change unprintable chars to a period.
        $line =~ s/[\000-\037,\177-\237]/./g;

        ## Print the line in dump format.
        &_log_print($fh, sprintf("%s 0x%5.5lx: %s%s\n",
                     $direction, $addr, $hexvals, $line));

        $addr += 16;
        $offset += 16;
        $len -= 16;
        }

        &_log_print($fh, "\n");

        1;
    } # end sub _log_dump


    sub _log_option {
        my ($fh, $direction, $request, $option) = @_;
        my (
        $name,
        );

        if ($option >= 0 and $option <= $#Telopts) {
        $name = $Telopts[$option];
        } elsif (exists $Axmud_Telopts{$option}) {
        $name = $Axmud_Telopts{$option};
        } else {
        $name = $option;
        }

        &_log_print($fh, "$direction $request $name\n");
    } # end sub _log_option


    sub _log_print {
        my ($fh, $buf) = @_;
        local $\ = '';

        if (ref($fh) eq "GLOB") {  # fh is GLOB ref
        print $fh $buf;
        }
        else {  # fh isn't GLOB ref
        $fh->print($buf);
        }
    } # end sub _log_print


    sub _match_check {
        my ($self, $code) = @_;
        my $error;
        my @warns = ();
        local $@;

        ## Use eval to check for syntax errors or warnings.
        {
        local $SIG{"__DIE__"} = "DEFAULT";
        local $SIG{"__WARN__"} = sub { push @warns, @_ };
        local $^W = 1;
        local $_ = '';
        eval "\$_ =~ $code;";
        }
        if ($@) {
        ## Remove useless lines numbers from message.
        ($error = $@) =~ s/ at \(eval \d+\) line \d+.?//;
        chomp $error;
        return $self->error("bad match operator: $error");
        }
        elsif (@warns) {
        ## Remove useless lines numbers from message.
        ($error = shift @warns) =~ s/ at \(eval \d+\) line \d+.?//;
        $error =~ s/ while "strict subs" in use//;
        chomp $error;
        return $self->error("bad match operator: $error");
        }

        1;
    } # end sub _match_check


    sub _negotiate_callback {
        my ($self, $opt, $is_remote, $is_enabled, $was_enabled, $opt_bufpos) = @_;
        my (
        $callback,
        $s,
        );
        local $_;

        ## Keep track of remote echo.
        if ($is_remote and $opt == &TELOPT_ECHO) {  # received WILL or WONT ECHO
        $s = *$self->{net_telnet};

        if ($is_enabled and !$was_enabled) {  # received WILL ECHO
            $s->{remote_echo} = 1;
        }
        elsif (!$is_enabled and $was_enabled) {  # received WONT ECHO
            $s->{remote_echo} = '';
        }
        }

        ## Invoke callback, if there is one.
        $callback = $self->option_callback;
        if ($callback) {
        &$callback($self, $opt, $is_remote,
               $is_enabled, $was_enabled, $opt_bufpos);
        }

        1;
    } # end sub _negotiate_callback


    sub _negotiate_recv {
        my ($self, $s, $opt_request, $opt, $opt_bufpos) = @_;

        ## Ensure data structure exists for this option.
        unless (defined $s->{opts}{$opt}) {
        &_set_default_option($s, $opt);
        }

        ## Process the option.
        if ($opt_request eq "\376") {  # DONT
        &_negotiate_recv_disable($self, $s, $opt, "dont", $opt_bufpos,
                     $s->{opts}{$opt}{local_enable_ok},
                     \$s->{opts}{$opt}{local_enabled},
                     \$s->{opts}{$opt}{local_state});
        }
        elsif ($opt_request eq "\375") {  # DO
        &_negotiate_recv_enable($self, $s, $opt, "do", $opt_bufpos,
                    $s->{opts}{$opt}{local_enable_ok},
                    \$s->{opts}{$opt}{local_enabled},
                    \$s->{opts}{$opt}{local_state});
        }
        elsif ($opt_request eq "\374") {  # WONT
        &_negotiate_recv_disable($self, $s, $opt, "wont", $opt_bufpos,
                     $s->{opts}{$opt}{remote_enable_ok},
                     \$s->{opts}{$opt}{remote_enabled},
                     \$s->{opts}{$opt}{remote_state});
        }
        elsif ($opt_request eq "\373") {  # WILL
        &_negotiate_recv_enable($self, $s, $opt, "will", $opt_bufpos,
                    $s->{opts}{$opt}{remote_enable_ok},
                    \$s->{opts}{$opt}{remote_enabled},
                    \$s->{opts}{$opt}{remote_state});
        }
        else {  # internal error
        die;
        }

        1;
    } # end sub _negotiate_recv


    sub _negotiate_recv_disable {
        my ($self, $s, $opt, $opt_request,
        $opt_bufpos, $enable_ok, $is_enabled, $state) = @_;
        my (
        $ack,
        $disable_cmd,
        $enable_cmd,
        $is_remote,
        $nak,
        $was_enabled,
        );

        # Axmud v1.0.696 - $$state is sometimes 'undef', for some reason, and this causes an error
        if (! defined $$state) {

            $$state = '';
        }

        ## What do we use to request enable/disable or respond with ack/nak.
        if ($opt_request eq "wont") {
        $enable_cmd  = "\377\375" . pack("C", $opt);  # do command
        $disable_cmd = "\377\376" . pack("C", $opt);  # dont command
        $is_remote = 1;
        $ack = "DO";
        $nak = "DONT";

        &_log_option($s->{opt_log}, "RCVD", "WONT", $opt)
            if $s->{opt_log};
        }
        elsif ($opt_request eq "dont") {
        $enable_cmd  = "\377\373" . pack("C", $opt);  # will command
        $disable_cmd = "\377\374" . pack("C", $opt);  # wont command
        $is_remote = '';
        $ack = "WILL";
        $nak = "WONT";

        &_log_option($s->{opt_log}, "RCVD", "DONT", $opt)
            if $s->{opt_log};
        }
        else {  # internal error
        die;
        }

        ## Respond to WONT or DONT based on the current negotiation state.
        if ($$state eq "no") {  # state is already disabled
        }
        elsif ($$state eq "yes") {  # they're initiating disable
        $$is_enabled = '';
        $$state = "no";

        ## Send positive acknowledgment.
        $s->{unsent_opts} .= $disable_cmd;
        &_log_option($s->{opt_log}, "SENT", $nak, $opt)
            if $s->{opt_log};

        ## Invoke callbacks.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantno") {  # they sent positive ack
        $$is_enabled = '';
        $$state = "no";

        ## Invoke callback.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantno opposite") {  # pos ack but we changed our mind
        ## Indicate disabled but now we want to enable.
        $$is_enabled = '';
        $$state = "wantyes";

        ## Send queued request.
        $s->{unsent_opts} .= $enable_cmd;
        &_log_option($s->{opt_log}, "SENT", $ack, $opt)
            if $s->{opt_log};

        ## Invoke callback.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantyes") {  # they sent negative ack
        $$is_enabled = '';
        $$state = "no";

        ## Invoke callback.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantyes opposite") {  # nak but we changed our mind
        $$is_enabled = '';
        $$state = "no";

        ## Invoke callback.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
    } # end sub _negotiate_recv_disable


    sub _negotiate_recv_enable {
        my ($self, $s, $opt, $opt_request,
        $opt_bufpos, $enable_ok, $is_enabled, $state) = @_;
        my (
        $ack,
        $disable_cmd,
        $enable_cmd,
        $is_remote,
        $nak,
        $was_enabled,
        );

        # Axmud v1.0.696 - $$state is sometimes 'undef', for some reason, and this causes an error
        if (! defined $$state) {

            $$state = '';
        }

        ## What we use to send enable/disable request or send ack/nak response.
        if ($opt_request eq "will") {
        $enable_cmd  = "\377\375" . pack("C", $opt);  # do command
        $disable_cmd = "\377\376" . pack("C", $opt);  # dont command
        $is_remote = 1;
        $ack = "DO";
        $nak = "DONT";

        &_log_option($s->{opt_log}, "RCVD", "WILL", $opt)
            if $s->{opt_log};
        }
        elsif ($opt_request eq "do") {
        $enable_cmd  = "\377\373" . pack("C", $opt);  # will command
        $disable_cmd = "\377\374" . pack("C", $opt);  # wont command
        $is_remote = '';
        $ack = "WILL";
        $nak = "WONT";

        &_log_option($s->{opt_log}, "RCVD", "DO", $opt)
            if $s->{opt_log};
        }
        else {  # internal error
        die;
        }

        ## Save current enabled state.
        $was_enabled = $$is_enabled;

        ## Respond to WILL or DO based on the current negotiation state.
        if ($$state eq "no") {  # they're initiating enable
        if ($enable_ok) {  # we agree they/us should enable
            $$is_enabled = 1;
            $$state = "yes";

            ## Send positive acknowledgment.
            $s->{unsent_opts} .= $enable_cmd;
            &_log_option($s->{opt_log}, "SENT", $ack, $opt)
            if $s->{opt_log};

            ## Invoke callbacks.
            &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        else {  # we disagree they/us should enable
            ## Send negative acknowledgment.
            $s->{unsent_opts} .= $disable_cmd;
            &_log_option($s->{opt_log}, "SENT", $nak, $opt)
            if $s->{opt_log};
        }
        }
        elsif ($$state eq "yes") {  # state is already enabled
        }
        elsif ($$state eq "wantno") {  # error: our disable req answered by enable
        $$is_enabled = '';
        $$state = "no";

        ## Invoke callbacks.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantno opposite") { # err: disable req answerd by enable
        $$is_enabled = 1;
        $$state = "yes";

        ## Invoke callbacks.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantyes") {  # they sent pos ack
        $$is_enabled = 1;
        $$state = "yes";

        ## Invoke callback.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }
        elsif ($$state eq "wantyes opposite") {  # pos ack but we changed our mind
        ## Indicate enabled but now we want to disable.
        $$is_enabled = 1;
        $$state = "wantno";

        ## Inform other side we changed our mind.
        $s->{unsent_opts} .= $disable_cmd;
        &_log_option($s->{opt_log}, "SENT", $nak, $opt)
            if $s->{opt_log};

        ## Invoke callback.
        &_negotiate_callback($self, $opt, $is_remote,
                     $$is_enabled, $was_enabled, $opt_bufpos);
        }

        1;
    } # end sub _negotiate_recv_enable


    sub _new_handle {
        if ($INC{"IO/Handle.pm"}) {
        return IO::Handle->new;
        }
        else {
        require FileHandle;
        return FileHandle->new;
        }
    } # end sub _new_handle


    sub _next_getlines {
        my ($self, $s) = @_;
        my (
        $len,
        $line,
        $pos,
        @lines,
        );

        ## Fill buffer and get first line.
        $line = $self->getline
        or return;
        push @lines, $line;

        ## Extract subsequent lines from buffer.
        while (($pos = index($s->{buf}, $s->{"rs"})) != -1) {
        $len = $pos + length $s->{"rs"};
        push @lines, substr($s->{buf}, 0, $len);
        substr($s->{buf}, 0, $len) = "";
        }

        @lines;
    } # end sub _next_getlines


    sub _opt_accept {
        my ($self, @args) = @_;
        my (
        $arg,
        $option,
        $s,
        );

        ## Init.
        $s = *$self->{net_telnet};

        foreach $arg (@args) {
        ## Ensure data structure defined for this option.
        $option = $arg->{option};
        if (!defined $s->{opts}{$option}) {
            &_set_default_option($s, $option);
        }

        ## Save whether we'll accept or reject this option.
        if ($arg->{is_remote}) {
            $s->{opts}{$option}{remote_enable_ok} = $arg->{is_enable};
        }
        else {
            $s->{opts}{$option}{local_enable_ok} = $arg->{is_enable};
        }
        }

        1;
    } # end sub _opt_accept

    sub _optimal_blksize {
        my ($blksize) = @_;

        ## Use default when block size is invalid.
        if (!defined $blksize or $blksize eq "" or $blksize < 512 or $blksize > 1_048_576) {
        $blksize = 4096;
        }

        $blksize;
    } # end sub _optimal_blksize


    sub _parse_cmd_remove_mode {
        my ($self, $mode) = @_;

        if (!defined $mode) {
        $mode = 0;
        }
        elsif ($mode =~ /^\s*auto\s*$/i) {
        $mode = "auto";
        }
        elsif ($mode !~ /^\d+$/) {
        &_carp($self, "ignoring bad Cmd_remove_mode " .
               "argument \"$mode\": it's not \"auto\" or a " .
               "non-negative integer");
        $mode = *$self->{net_telnet}{cmd_rm_mode};
        }

        $mode;
    } # end sub _parse_cmd_remove_mode


    sub _parse_errmode {
        my ($self, $errmode) = @_;

        ## Set the error mode.
        if (!defined $errmode) {
        &_carp($self, "ignoring undefined Errmode argument");
        $errmode = *$self->{net_telnet}{errormode};
        }
        elsif ($errmode =~ /^\s*return\s*$/i) {
        $errmode = "return";
        }
        elsif ($errmode =~ /^\s*die\s*$/i) {
        $errmode = "die";
        }
        elsif (ref($errmode) eq "CODE") {
        }
        elsif (ref($errmode) eq "ARRAY") {
        unless (ref($errmode->[0]) eq "CODE") {
            &_carp($self, "ignoring bad Errmode argument: " .
               "first list item isn't a code ref");
            $errmode = *$self->{net_telnet}{errormode};
        }
        }
        else {
        &_carp($self, "ignoring bad Errmode argument \"$errmode\"");
        $errmode = *$self->{net_telnet}{errormode};
        }

        $errmode;
    } # end sub _parse_errmode


    sub _parse_family {
        my ($self, $family) = @_;
        my (
        $parsed_family,
        $socket_version,
        );

        $socket_version = $Socket::VERSION;     # replace '2.020_03' with '2.020'
        $socket_version =~ s/\_.*$//;

        unless (defined $family) {
        $family = "";
        }

        if ($family =~ /^\s*ipv4\s*$/i) {  # family arg is "ipv4"
        $parsed_family = "ipv4";
        }
        elsif ($family =~ /^\s*any\s*$/i) {  # family arg is "any"
        if ($socket_version >= 1.94 and defined $AF_INET6) {  # has IPv6
            $parsed_family = "any";
        }
        else {  # IPv6 not supported on this machine
            $parsed_family = "ipv4";
        }
        }
        elsif ($family =~ /^\s*ipv6\s*$/i) {  # family arg is "ipv6"
        return $self->error("Family arg ipv6 not supported when " .
                    "Socket.pm version < 1.94")
            unless $socket_version >= 1.94;
        return $self->error("Family arg ipv6 not supported by " .
                    "this OS: AF_INET6 not in Socket.pm")
            unless defined $AF_INET6;

        $parsed_family = "ipv6";
        }
        else {
        return $self->error("bad Family argument \"$family\": " .
                    "must be \"ipv4\", \"ipv6\", or \"any\"");
        }

        $parsed_family;
    } # end sub _parse_family


    sub _parse_input_record_separator {
        my ($self, $rs) = @_;

        unless (defined $rs and length $rs) {
        &_carp($self, "ignoring null Input_record_separator argument");
        $rs = *$self->{net_telnet}{"rs"};
        }

        $rs;
    } # end sub _parse_input_record_separator


    sub _parse_localfamily {
        my ($self, $family) = @_;
        my (
        $socket_version,
        );

        $socket_version = $Socket::VERSION;     # replace '2.020_03' with '2.020'
        $socket_version =~ s/\_.*$//;

        unless (defined $family) {
        $family = "";
        }

        if ($family =~ /^\s*ipv4\s*$/i) {  # family arg is "ipv4"
        $family = "ipv4";
        }
        elsif ($family =~ /^\s*any\s*$/i) {  # family arg is "any"
        if ($socket_version >= 1.94 and defined $AF_INET6) {  # has IPv6
            $family = "any";
        }
        else {  # IPv6 not supported on this machine
            $family = "ipv4";
        }
        }
        elsif ($family =~ /^\s*ipv6\s*$/i) {  # family arg is "ipv6"
        return $self->error("Localfamily arg ipv6 not supported when " .
                    "Socket.pm version < 1.94")
            unless $socket_version >= 1.94;
        return $self->error("Localfamily arg ipv6 not supported by " .
                    "this OS: AF_INET6 not in Socket.pm")
            unless defined $AF_INET6;

        $family = "ipv6";
        }
        else {
        return $self->error("bad Localfamily argument \"$family\": " .
                    "must be \"ipv4\", \"ipv6\", or \"any\"");
        }

        $family;
    } # end sub _parse_localfamily


    sub _parse_port {
        my ($self, $port) = @_;
        my (
        $service,
        );

        unless (defined $port) {
        $port = "";
        }

        return $self->error("bad Port argument \"$port\"")
        unless $port;

        if ($port !~ /^\d+$/) {  # port isn't all digits
        $service = $port;
        $port = getservbyname($service, "tcp");

        return $self->error("bad Port argument \"$service\": " .
                    "it's an unknown TCP service")
            unless $port;
        }

        $port;
    } # end sub _parse_port


    sub _parse_prompt {
        my ($self, $prompt) = @_;

        unless (defined $prompt) {
        $prompt = "";
        }

        return $self->error("bad Prompt argument \"$prompt\": " .
                "missing opening delimiter of match operator")
        unless $prompt =~ m(^\s*/) or $prompt =~ m(^\s*m\s*\W);

        $prompt;
    } # end sub _parse_prompt


    sub _parse_timeout {
        my ($self, $timeout) = @_;
        local $@;

        ## Ensure valid timeout.
        if (defined $timeout) {
        ## Test for non-numeric or negative values.
        eval {
            local $SIG{"__DIE__"} = "DEFAULT";
            local $SIG{"__WARN__"} = sub { die "non-numeric\n" };
            local $^W = 1;
            $timeout *= 1;
        };
        if ($@) {  # timeout arg is non-numeric
            &_carp($self,
               "ignoring non-numeric Timeout argument \"$timeout\"");
            $timeout = *$self->{net_telnet}{time_out};
        }
        elsif ($timeout < 0) {  # timeout arg is negative
            &_carp($self, "ignoring negative Timeout argument \"$timeout\"");
            $timeout = *$self->{net_telnet}{time_out};
        }
        }

        $timeout;
    } # end sub _parse_timeout


    sub _put {
        my ($self, $buf, $subname) = @_;
        my (
        $endtime,
        $len,
        $nfound,
        $nwrote,
        $offset,
        $ready,
        $s,
        $timed_out,
        $timeout,
        $zero_wrote_count,
        );

        ## Init.
        $s = *$self->{net_telnet};
        $s->{num_wrote} = 0;
        $zero_wrote_count = 0;
        $offset = 0;
        $len = length $$buf;
        $endtime = &_endtime($s->{time_out});

        return $self->error("write error: filehandle isn't open")
        unless $s->{opened};

        ## Try to send any waiting option negotiation.
        if (length $s->{unsent_opts}) {
        &_flush_opts($self);
        }

        ## Write until all data blocks written.
        while ($len) {
        ## Determine how long to wait for output ready.
        ($timed_out, $timeout) = &_timeout_interval($endtime);
        if ($timed_out) {
            $s->{timedout} = 1;
            return $self->error("$subname timed-out");
        }

        ## Wait for output ready.
        $nfound = select "", $ready=$s->{fdmask}, "", $timeout;

        ## Handle any errors while waiting.
        if ((!defined $nfound or $nfound <= 0) and $s->{select_supported}) {
            if (defined $nfound and $nfound == 0) {  # timed-out
            $s->{timedout} = 1;
            return $self->error("$subname timed-out");
            }
            else {  # error waiting for output ready
            if (defined $EINTR) {
                next if $! == $EINTR;  # restart select()
            }
            else {
                next if $! =~ /^interrupted/i;  # restart select()
            }

            $s->{opened} = '';
            return $self->error("write error: $!");
            }
        }

        ## Write the data.
        $nwrote = syswrite $self, $$buf, $s->{blksize}, $offset;

        ## Handle any write errors.
        if (!defined $nwrote) {  # write failed
            if (defined $EINTR) {
            next if $! == $EINTR;  # restart syswrite()
            }
            else {
            next if $! =~ /^interrupted/i;  # restart syswrite()
            }

            $s->{opened} = '';
            return $self->error("write error: $!");
        }
        elsif ($nwrote == 0) {  # zero chars written
            ## Try ten more times to write the data.
            if ($zero_wrote_count++ <= 10) {
            &_sleep(0.01);
            next;
            }

            $s->{opened} = '';
            return $self->error("write error: zero length write: $!");
        }

        ## Display network traffic if requested.
        if ($s->{dumplog}) {
            &_log_dump('>', $s->{dumplog}, $buf, $offset, $nwrote);
        }

        ## Increment.
        $s->{num_wrote} += $nwrote;
        $offset += $nwrote;
        $len -= $nwrote;
        }

        1;
    } # end sub _put


    sub _qualify_fh {
        my ($obj, $name) = @_;
        my (
        $user_class,
        );
        local $@;
        local $_;

        ## Get user's package name.
        ($user_class) = &_user_caller($obj);

        ## Ensure name is qualified with a package name.
        $name = qualify($name, $user_class);

        ## If it's not already, make it a typeglob ref.
        if (!ref $name) {
        no strict;
        local $SIG{"__DIE__"} = "DEFAULT";
        local $^W = '';

        $name =~ s/^\*+//;
        $name = eval "\\*$name";
        return unless ref $name;
        }

        $name;
    } # end sub _qualify_fh


    sub _reset_options {
        my ($opts) = @_;
        my (
        $opt,
        );

        foreach $opt (keys %$opts) {
        $opts->{$opt}{remote_enabled} = '';
        $opts->{$opt}{remote_state} = "no";
        $opts->{$opt}{local_enabled} = '';
        $opts->{$opt}{local_state} = "no";
        }

        1;
    } # end sub _reset_options


    sub _save_lastline {
        my ($s) = @_;
        my (
        $firstpos,
        $lastpos,
        $len_w_sep,
        $len_wo_sep,
        $offset,
        );
        my $rs = "\n";

        if (($lastpos = rindex $s->{buf}, $rs) > -1) {  # eol found
        while (1) {
            ## Find beginning of line.
            $firstpos = rindex $s->{buf}, $rs, $lastpos - 1;
            if ($firstpos == -1) {
            $offset = 0;
            }
            else {
            $offset = $firstpos + length $rs;
            }

            ## Determine length of line with and without separator.
            $len_wo_sep = $lastpos - $offset;
            $len_w_sep = $len_wo_sep + length $rs;

            ## Save line if it's not blank.
            if (substr($s->{buf}, $offset, $len_wo_sep)
            !~ /^\s*$/)
            {
            $s->{last_line} = substr($s->{buf},
                         $offset,
                         $len_w_sep);
            last;
            }

            last if $firstpos == -1;

            $lastpos = $firstpos;
        }
        }

        1;
    } # end sub _save_lastline


    sub _set_default_option {
        my ($s, $option) = @_;

        $s->{opts}{$option} = {
        remote_enabled   => '',
        remote_state     => "no",
        remote_enable_ok => '',
        local_enabled    => '',
        local_state      => "no",
        local_enable_ok  => '',
        };
    } # end sub _set_default_option


    sub _sleep {
        my ($secs) = @_;
        my $bitmask = "";
        local *SOCK;

        socket SOCK, AF_INET, SOCK_STREAM, 0;
        vec($bitmask, fileno(SOCK), 1) = 1;
        select $bitmask, "", "", $secs;
        CORE::close SOCK;

        1;
    } # end sub _sleep


    sub _timeout_interval {
        my ($endtime) = @_;
        my (
        $timeout,
        );

        ## Return timed-out boolean and timeout interval.
        if (defined $endtime) {
        ## Is it a one-time poll.
        return ('', 0) if $endtime == 0;

        ## Calculate the timeout interval.
        $timeout = $endtime - time;

        ## Did we already timeout.
        return (1, 0) unless $timeout > 0;

        return ('', $timeout);
        }
        else {  # there is no timeout
        return ('', undef);
        }
    } # end sub _timeout_interval


    sub _unpack_sockaddr {
        my ($self, $sockaddr) = @_;
        my (
        $packed_addr,
        $sockfamily,
        );
        my $addr = "";
        my $port = "";

        $sockfamily = $self->sockfamily;

        ## Parse sockaddr struct.
        if ($sockfamily eq "ipv4") {
        ($port, $packed_addr) = sockaddr_in($sockaddr);
        $addr = Socket::inet_ntoa($packed_addr);
        }
        elsif ($sockfamily eq "ipv6") {
        ($port, $packed_addr) = Socket::sockaddr_in6($sockaddr);
        $addr = Socket::inet_ntop($AF_INET6, $packed_addr);
        }

        ($port, $addr);
    } # end sub _unpack_sockaddr


    sub _user_caller {
        my ($obj) = @_;
        my (
        $class,
        $curr_pkg,
        $file,
        $i,
        $line,
        $pkg,
        %isa,
        @isa,
        );
        local $@;
        local $_;

        ## Create a boolean hash to test for isa.  Make sure current
        ## package and the object's class are members.
        $class = ref $obj;
        @isa = eval "\@${class}::ISA";
        push @isa, $class;
        ($curr_pkg) = caller 1;
        push @isa, $curr_pkg;
        %isa = map { $_ => 1 } @isa;

        ## Search back in call frames for a package that's not in isa.
        $i = 1;
        while (($pkg, $file, $line) = caller ++$i) {
        next if $isa{$pkg};

        return ($pkg, $file, $line);
        }

        ## If not found, choose outer most call frame.
        ($pkg, $file, $line) = caller --$i;
        return ($pkg, $file, $line);
    } # end sub _user_caller


    sub _verify_telopt_arg {
        my ($self, $option, $argname) = @_;
        local $@;

        ## If provided, use argument name in error message.
        if (defined $argname) {
        $argname = "for arg $argname";
        }
        else {
        $argname = "";
        }

        ## Ensure telnet option is a non-negative integer.
        eval {
        local $SIG{"__DIE__"} = "DEFAULT";
        local $SIG{"__WARN__"} = sub { die "non-numeric\n" };
        local $^W = 1;
        $option = abs(int $option);
        };
        return $self->error("bad telnet option $argname: non-numeric")
        if $@;

        return $self->error("bad telnet option $argname: option > 255")
        unless $option <= 255;

        $option;
    } # end sub _verify_telopt_arg


    ######################## Exported Constants ##########################


    sub TELNET_IAC ()               {255};  # interpret as command:
    sub TELNET_DONT ()              {254};  # you are not to use option
    sub TELNET_DO ()                {253};  # please, you use option
    sub TELNET_WONT ()              {252};  # I won't use option
    sub TELNET_WILL ()              {251};  # I will use option
    sub TELNET_SB ()                {250};  # interpret as subnegotiation
    sub TELNET_GA ()                {249};  # you may reverse the line
    sub TELNET_EL ()                {248};  # erase the current line
    sub TELNET_EC ()                {247};  # erase the current character
    sub TELNET_AYT ()               {246};  # are you there
    sub TELNET_AO ()                {245};  # abort output--but let prog finish
    sub TELNET_IP ()                {244};  # interrupt process--permanently
    sub TELNET_BREAK ()             {243};  # break
    sub TELNET_DM ()                {242};  # data mark--for connect. cleaning
    sub TELNET_NOP ()               {241};  # nop
    sub TELNET_SE ()                {240};  # end sub negotiation
    sub TELNET_EOR ()               {239};  # end of record (transparent mode)
    sub TELNET_ABORT ()             {238};  # Abort process
    sub TELNET_SUSP ()              {237};  # Suspend process
    sub TELNET_EOF ()               {236};  # End of file
    sub TELNET_SYNCH ()             {242};  # for telfunc calls

    sub TELOPT_BINARY ()            {0};    # Binary Transmission
    sub TELOPT_ECHO ()              {1};    # Echo
    sub TELOPT_RCP ()               {2};    # Reconnection
    sub TELOPT_SGA ()               {3};    # Suppress Go Ahead
    sub TELOPT_NAMS ()              {4};    # Approx Message Size Negotiation
    sub TELOPT_STATUS ()            {5};    # Status
    sub TELOPT_TM ()                {6};    # Timing Mark
    sub TELOPT_RCTE ()              {7};    # Remote Controlled Trans and Echo
    sub TELOPT_NAOL ()              {8};    # Output Line Width
    sub TELOPT_NAOP ()              {9};    # Output Page Size
    sub TELOPT_NAOCRD ()            {10};   # Output Carriage-Return Disposition
    sub TELOPT_NAOHTS ()            {11};   # Output Horizontal Tab Stops
    sub TELOPT_NAOHTD ()            {12};   # Output Horizontal Tab Disposition
    sub TELOPT_NAOFFD ()            {13};   # Output Formfeed Disposition
    sub TELOPT_NAOVTS ()            {14};   # Output Vertical Tabstops
    sub TELOPT_NAOVTD ()            {15};   # Output Vertical Tab Disposition
    sub TELOPT_NAOLFD ()            {16};   # Output Linefeed Disposition
    sub TELOPT_XASCII ()            {17};   # Extended ASCII
    sub TELOPT_LOGOUT ()            {18};   # Logout
    sub TELOPT_BM ()                {19};   # Byte Macro
    sub TELOPT_DET ()               {20};   # Data Entry Terminal
    sub TELOPT_SUPDUP ()            {21};   # SUPDUP
    sub TELOPT_SUPDUPOUTPUT ()      {22};   # SUPDUP Output
    sub TELOPT_SNDLOC ()            {23};   # Send Location
    sub TELOPT_TTYPE ()             {24};   # Terminal Type
    sub TELOPT_EOR ()               {25};   # End of Record
    sub TELOPT_TUID ()              {26};   # TACACS User Identification
    sub TELOPT_OUTMRK ()            {27};   # Output Marking
    sub TELOPT_TTYLOC ()            {28};   # Terminal Location Number
    sub TELOPT_3270REGIME ()        {29};   # Telnet 3270 Regime
    sub TELOPT_X3PAD ()             {30};   # X.3 PAD
    sub TELOPT_NAWS ()              {31};   # Negotiate About Window Size
    sub TELOPT_TSPEED ()            {32};   # Terminal Speed
    sub TELOPT_LFLOW ()             {33};   # Remote Flow Control
    sub TELOPT_LINEMODE ()          {34};   # Linemode
    sub TELOPT_XDISPLOC ()          {35};   # X Display Location
    sub TELOPT_OLD_ENVIRON ()       {36};   # Environment Option
    sub TELOPT_AUTHENTICATION ()    {37};   # Authentication Option
    sub TELOPT_ENCRYPT ()           {38};   # Encryption Option
    sub TELOPT_NEW_ENVIRON ()       {39};   # New Environment Option
    sub TELOPT_TN3270E ()           {40};   # TN3270 Enhancements
    sub TELOPT_CHARSET ()           {42};   # CHARSET Option
    sub TELOPT_COMPORT ()           {44};   # Com Port Control Option
    sub TELOPT_KERMIT ()            {47};   # Kermit Option
    sub TELOPT_EXOPL ()             {255};  # Extended-Options-List

    # Added by Axmud
    sub TELOPT_MSDP ()              {69};   # Mud Server Data Protocol
    sub TELOPT_MSSP ()              {70};   # Mud Server Status Protocol
    sub TELOPT_MCCP1 ()             {85};   # Mud Client Compression Protocol (MCCP1)
    sub TELOPT_MCCP2 ()             {86};   # Mud Client Compression Protocol (MCCP2)
    sub TELOPT_MSP ()               {90};   # Mud Sound Protocol
    sub TELOPT_MXP ()               {91};   # Mud Xtension Protocol
    sub TELOPT_ZMP ()               {93};   # Zenith Mud Protocol
    sub TELOPT_AARDWOLF ()          {102};  # Aardwolf 102 channel
    sub TELOPT_ATCP ()              {200};  # Achaea Telnet Client Protocol
    sub TELOPT_GMCP ()              {201};  # Generic MUD Communication Protocol
}

# Package must return true
1
