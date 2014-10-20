#!/usr/bin/perl -X
#
my $sGlobalVersion = "3.0.001";
my $sGlobalRelease = '2010-11-21';

##############################################################################
#
# HeavyMetal v3.0.000
#
# Teletype control program.
#
# By Bill Buzbee and Javier Albinarrate (LU8AJA)
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# 2010-06-25 v3.0.000 Finished complete rewrite
# 2010-11-20 v3.0.001 Fixes to Serial port handling in Windows XP
##############################################################################


### v3.0 TODO LIST
# Allow the tty to be used as with LF to behave as CRLF
# Check how columns are tracked for the TTY
# Nothing for X10 has been tested
# Solve issue with LoopSuppress not being updated from the interfase
# Autedetect loop suppress upon init o reinit


#-----------------------------------------------------------------------------
# Module imports
#-----------------------------------------------------------------------------

use strict;
use lib "./lib";

use Encode::Unicode; 

my %Modules;

$Modules{'Win32::SerialPort'}  = {'order' => 1,  'loaded' => 0, 'required' => 1, 'os'=>'Win32'};
$Modules{'Win32::API'}         = {'order' => 2,  'loaded' => 0, 'required' => 1, 'os'=>'Win32'};
$Modules{'File::Spec::Win32'}  = {'order' => 3,  'loaded' => 0, 'required' => 1, 'os'=>'Win32'};
$Modules{'Device::SerialPort'} = {'order' => 5,  'loaded' => 0, 'required' => 1, 'os'=>'Linux'}; #This surely will need to be tweaked
$Modules{'LWP::Simple'}        = {'order' => 6,  'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Net::POP3'}          = {'order' => 7,  'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'Net::SMTP'}          = {'order' => 8,  'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'MIME::Base64'}       = {'order' => 9,  'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'IO::Handle'}         = {'order' => 10, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'IO::Socket'}         = {'order' => 11, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'IO::Select'}         = {'order' => 12, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'IO::Socket::Telnet'} = {'order' => 12, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'POSIX'}              = {'order' => 12, 'loaded' => 0, 'required' => 0, 'os'=>'', 'args'=>"('tmpnam')"};
$Modules{'Text::Wrap'}         = {'order' => 13, 'loaded' => 0, 'required' => 0, 'os'=>''};

$Modules{'Tk'}                 = {'order' => 14, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::ROText'}         = {'order' => 15, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::FileSelect'}     = {'order' => 16, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Dialog'}         = {'order' => 17, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Menubutton'}     = {'order' => 18, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Label'}          = {'order' => 19, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Button'}         = {'order' => 20, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Checkbutton'}    = {'order' => 21, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Radiobutton'}    = {'order' => 22, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Entry'}          = {'order' => 23, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Frame'}          = {'order' => 24, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Listbox'}        = {'order' => 25, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Scrollbar'}      = {'order' => 26, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Text'}           = {'order' => 27, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Menu'}           = {'order' => 28, 'loaded' => 0, 'required' => 1, 'os'=>''};
$Modules{'Tk::Icon'}           = {'order' => 29, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'Finance::YahooQuote'}= {'order' => 39, 'loaded' => 0, 'required' => 0, 'os'=>''};

$Modules{'Math::BigInt'}       = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'URI::Escape'}        = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'Data::Dumper'}       = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'HTTP::Request'}      = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'LWP::UserAgent'}     = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>''};
$Modules{'HTML::Entities'}     = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>'', 'args'=>"('decode_entities')"};
$Modules{'Digest::MD5'}        = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>'', 'args'=>"('md5','md5_hex','md5_base64')"};
$Modules{'Digest::SHA1'}       = {'order' => 40, 'loaded' => 0, 'required' => 0, 'os'=>'', 'args'=>"('sha1','sha1_hex','sha1_base64')"};
$Modules{'MSN'}                = {'order' => 42, 'loaded' => 0, 'required' => 0, 'os'=>''};

#-----------------------------------------------------------------------------
# Perl2exe directives
#-----------------------------------------------------------------------------

#perl2exe_exclude "Convert/EBCDIC.pm"
#perl2exe_exclude "Mac/InternetConfig.pm"
#perl2exe_exclude "Encode/ConfigLocal.pm"
#perl2exe_exclude "File/BSDGlob.pm"
#perl2exe_exclude "Convert/EBCDIC.pm"
#perl2exe_exclude "I18N/Langinfo.pm"

# - - - perl2exe_include Win32::SerialPort
# - - - perl2exe_include Win32::API
# - - - perl2exe_include File::Spec::Win32
# - - - perl2exe_include Tk
# - - - perl2exe_include Tk::ROText
# - - - perl2exe_include Tk::FileSelect
# - - - perl2exe_include Tk::Dialog
# - - - perl2exe_include LWP::Simple
# - - - perl2exe_include Net::POP3
# - - - perl2exe_include Net::SMTP
# - - - perl2exe_include File::Spec::Win32
# - - - perl2exe_include IO::File
# - - - perl2exe_include POSIX
# - - - perl2exe_include Text::Wrap
# - - - perl2exe_include Tk::Menubutton
# - - - perl2exe_include Tk::Label
# - - - perl2exe_include Tk::Button
# - - - perl2exe_include Tk::Checkbutton
# - - - perl2exe_include Tk::Radiobutton
# - - - perl2exe_include Tk::Entry
# - - - perl2exe_include Tk::Frame
# - - - perl2exe_include Tk::Listbox
# - - - perl2exe_include Tk::Scrollbar
# - - - perl2exe_include Tk::Text
# - - - perl2exe_include Tk::Menu
# - - - perl2exe_include Tk::Icon
# - - - perl2exe_include Finance::YahooQuote
# - - - perl2exe_include Math::BigInt
# - - - perl2exe_include Math::BigInt::Calc
# - - - perl2exe_include Crypt::SSLeay
# - - -  --- perl2exe_include IO::Socket::SSL
# - - - perl2exe_include URI::Escape
# - - - perl2exe_include Data::Dumper
# - - - perl2exe_include HTTP::Request
# - - - perl2exe_include LWP::UserAgent
# - - - perl2exe_include HTML::Entities
# - - - perl2exe_include Digest::MD5
# - - - perl2exe_include Digest::SHA1

# Note: You may need to tweak these paths!
# - - - perl2exe_include "c:/TTY/lib/MSN.pm"
# - - - perl2exe_include "c:/TTY/lib/MSN/Notification.pm"
# - - - perl2exe_include "c:/TTY/lib/MSN/SwitchBoard.pm"
# - - - perl2exe_include "c:/TTY/lib/MSN/Util.pm"
# - - - perl2exe_include "c:/TTY/lib/MSN/P2P.pm"

if (0){
	use Win32::SerialPort;
	use Win32::API;
	use File::Spec::Win32;
	use Tk;
	use Tk::ROText;
	use Tk::FileSelect;
	use Tk::Dialog;
	use LWP::Simple;
	use Net::POP3;
	use Net::SMTP;
	use File::Spec::Win32;
	use IO::File;
	use IO::Socket;
	use IO::Select;
	use IO::Socket::Telnet;
	use POSIX ('tmpnam');
	use Text::Wrap;
	use Tk::Menubutton;
	use Tk::Label;
	use Tk::Button;
	use Tk::Checkbutton;
	use Tk::Radiobutton;
	use Tk::Entry;
	use Tk::Frame;
	use Tk::Listbox;
	use Tk::Scrollbar;
	use Tk::Text;
	use Tk::Menu;
	use Tk::Icon;
	use Finance::YahooQuote;
	use Math::BigInt;
	use Crypt::SSLeay;
	use URI::Escape;
	use Data::Dumper;
	use HTTP::Request;
	use LWP::UserAgent;
	use HTML::Entities ('decode_entities');
	use MSN;
	use Digest::MD5;
	use Digest::SHA1;
}

#-----------------------------------------------------------------------------
# Configuration settings.  Edit these to change defauts.
#-----------------------------------------------------------------------------
my %aConfigs;              # Array for all configs

#- - - - - - - - - - System Configs - - - - - - - - - - - - - - - - - - - -

$aConfigs{SystemName}      = 'HM';
$aConfigs{SystemPrompt}    = $aConfigs{SystemName}.': ';
$aConfigs{SystemPassword}  = 'BAUDOT';
$aConfigs{GuestPassword}   = 'GUEST';
$aConfigs{Debug}           = 0;
$aConfigs{DebugFile}       = '>>debug/debug-$DATETIME.log';
$aConfigs{DebugShowErrors} = 0;
$aConfigs{SerialSetserial} = 1;

#-- Code converstion settings.  Current choices are ASCII, USTTY, ITA2, TTS-M20
$aConfigs{LoopCode} = 'ASCII';

#-- Set Baud rate here
$aConfigs{SerialDivisor} = 0; # Note: Defaults to WPM60 after %aBaudRates is defined (aprox line 780)

#-- Set Word Size here
$aConfigs{SerialWord}    = 8; # must be 5,6,7 or 8

#-- Set stop bits here
$aConfigs{SerialStop}    = 1; # must be 1, 1.5 (for 5-bit word size only) or 2

#-- Set parity here
$aConfigs{SerialParity}  = "none"; # must be "none", "even" or "odd"

#-- Operating entirely from Teletype keyboard?
$aConfigs{RemoteMode} = 0;	# If 1, suppress dialog boxes. Set to 1 if operating
			# from a teletype keyboard and don't want to have
			# to click "OK" on warning and error dialog boxes.

$aConfigs{LoopTest}     = 0; # Skip output to loop?
$aConfigs{LoopSuppress} = 1; # 


#- - - - - - - - - - Control Options - - - - - - - - - - - - - - - - - - - -

$aConfigs{UnshiftOnSpace}= 0;    # Automatically send LTRS if FIGS active on space
$aConfigs{LowercaseLock} = 0;    # Downshift letters when doing LOOP -> HOST translation. As above, but sticks
$aConfigs{EscapeEnabled} = 1;    # Enable "$" & "\" escapes to create special chars and execute commands
$aConfigs{EscapeChar}    = '$';  # Escape character to use
$aConfigs{RunInProtect}  = 60;   # This prevents that the user on tty gets interfered with a message while writting, unless it has been idle for N secs
$aConfigs{BatchMode}     = 0;    # Auto-exit when nothing left to do. If 1, exit when command-line actions complete.

#- - - - - - - - - - Email Configs - - - - - - - - - - - - - - - - - -
#   Edit these to reflect your accounts.  If you don't know your
#   pop & stmp hosts, look in the setting file for your browser or
#   email program.  If your incoming mail host is IMAP rather than
#   pop, put its name for $aConfigs{EmailPOP} anyway.

$aConfigs{EmailPOP}      = "";    # Typically something like pop.myhost.com 
$aConfigs{EmailSMTP}     = "";    # Typically something like mail.myhost.com
$aConfigs{EmailAccount}  = "";                                                       
$aConfigs{EmailPassword} = "";                                                   
$aConfigs{EmailFrom}     = "";                                             

#- - - - - - - - - - Telnet Configs - - - - - - - - - - - - - - - - - - - -
$aConfigs{TelnetEnabled}   = 0;
$aConfigs{TelnetPort}      = 1078;
$aConfigs{TelnetWelcome}   = "Welcome to $aConfigs{SystemName} using HeavyMetal v$sGlobalVersion ($sGlobalRelease) Telnet-TTY chat";
$aConfigs{TelnetNegotiate} = 1;

#- - - - - - - - - - MSN Configs - - - - - - - - - - - - - - - - - - - - -
$aConfigs{MsnEnabled}  = 0;                   
$aConfigs{MsnUsername} = '';
$aConfigs{MsnPassword} = '';
$aConfigs{MsnListen}   = 0;                   
$aConfigs{MsnDebug}    = 0;

#- - - - - - - - - - MISC Configs - - - - - - - - - - - - - - - - - - - - -

#-- Set up your portfolio here.  To get the right ticker symbols, go to Yahoo.com.
$aConfigs{StockPortfolio} = "DJI SPC";

#-- How to build the EOL for the TTY
$aConfigs{TtyExtraLtrs} = 0;
$aConfigs{TtyExtraCr}   = 3;
$aConfigs{TtyExtraLf}   = 1;

#-- Number of columns for TTY & HOST window
$aConfigs{Columns} = 68; 



#-- Weather reports from tgftp.nws.noaa.gov
$aConfigs{WeatherBase} = 'ftp://tgftp.nws.noaa.gov/data/forecasts/city/';

#-- X10 stuff
$aConfigs{X10House}  = 'A';
$aConfigs{X10Device} = '1';
$aConfigs{X10Auto}   = 0;



#-----------------------------------------------------------------------------
# Global vars
#-----------------------------------------------------------------------------

my $nTimeStart       = time();
my $sDebugFile       = ''; # Full filename for debug
my $rDebugHandle;          # File handle for debug output
my $rDebugSocket;          # Allows to copy debug output to a socket
my $sLoginDisallowed = '^(ALL|IN|OUT|MSN|TTY|SYS)$'; # Disallowed Usernames
my $sSessionsHelp    = "Use command ".$aConfigs{EscapeChar}."HELP\r\n";
my $nSessionsCount   = 0;  # Sessions counter
my $NewSessionId     = 0;  # Session id
my @aSessions;             # Array for all sessions
my $nShutDown        = 0;  # At any moment, setting this to a unixtime will shutdown at that moment or later
my $nSleep           = 0;
my $nTimerSleep      = 0;
my $nSleepRepeat     = 0;
my $nCount           = 0;
my $nMax             = 0;
my $sOS              = $^O;
my $bWindows         = ($sOS eq "MSWin32") ? 1 : 0;
my $bWindows98       = 0;



my $config_file = "heavymetal.cfg";        # Config file
my $menu_config = "heavymetal.mnu";        # Custom menu file


#- - - - - - - - - - Code & UART Settings - - - - - - - - - - - - - - - - - -

#-- Optional millisecond delay between character transmission
my $char_delay = 0;

#-- UART settings

if ($bWindows) {
    #$aConfigs{SerialPort} = "COM1:";
    #$aConfigs{SerialPort} = uc($aConfigs{SerialPort});
    # Default: disabled
    $aConfigs{SerialPort} = "";
}
else {
    #$aConfigs{SerialPort} = "/dev/ttyS1";
    $aConfigs{SerialPort} = "";
}

my %aPortAddresses;
#-- Windows only - addresses of serial IO ports
if ($bWindows) {
    %aPortAddresses = (
        'COM1:' => 0x3f8,
        'COM2:' => 0x2f8,
        'COM3:' => 0x3e8,
        'COM4:' => 0x2e8,
        'COM5:' => 0x3f0,
        'COM6:' => 0x2f0,
        'COM7:' => 0x3e0,
        'COM8:' => 0x2e0 );
}
else {
    %aPortAddresses = (
        '/dev/ttyS0' => 0x0,
        '/dev/ttyS1' => 0x0,
        '/dev/ttyS2' => 0x0,
        '/dev/ttyS3' => 0x0,
        '/dev/ttyS4' => 0x0,
        '/dev/ttyS5' => 0x0,
        '/dev/ttyS6' => 0x0,
        '/dev/ttyS7' => 0x0 );
}

$aConfigs{SerialAddress} = $aPortAddresses{ $aConfigs{SerialPort} };

#my $BAUD51  = 2235;	# 60 wpm gear for 6-bit codes w/ 1.5 stop bits
#my $BAUD51  = 2111;	# 60 wpm gear for 6-bit codes w/ 2 stop bits
#my $BAUD51  = 2180;	# 60 wpm gear for 6-bit codes w/ 2 stop bits (slowed)
   		   
my %aBaudRates = (
	'WPM60'     => {'divisor' => 2534, 'label' => '45.5 Baud (60WPM)'              }, # 45.5 baud
	'BAUD51'    => {'divisor' => 2190, 'label' => '51 Baud (60WPM for 6-bit codes)'}, # 60 wpm gear for 6-bit codes w/ 1 stop bits (slowed)
	'WPM66'     => {'divisor' => 2304, 'label' => '50 Baud (66WPM)'                }, # 50 baud
	'BAUD56'    => {'divisor' => 2057, 'label' => '56 Baud (75WPM)'                }, # 75 wpm for 5-bit codes
	'BAUD66'    => {'divisor' => 1697, 'label' => '74 Baud (100WPM)'               }, #
	'WPM100'    => {'divisor' => 1555, 'label' => '66 Baud'                        }, # 74 baud
	'BAUD110'   => {'divisor' => 1047, 'label' => '110 Baud'                       }, #
	'BAUD300'   => {'divisor' =>  384, 'label' => '300 Baud'                       }, #
	'BAUD1200'  => {'divisor' =>   96, 'label' => '1200 Baud'                      }, #
	'BAUD2400'  => {'divisor' =>   48, 'label' => '2400 Baud'                      }, #
	'BAUD4800'  => {'divisor' =>   24, 'label' => '4800 Baud'                      }, #
	'BAUD9600'  => {'divisor' =>   12, 'label' => '9600 Baud'                      }, #
	'BAUD19200' => {'divisor' =>    6, 'label' => '19200 Baud'                     }, #
	'BAUD38400' => {'divisor' =>    2, 'label' => '38400 Baud'                     }, #
);                                                                                 

if ($aConfigs{SerialDivisor} == 0){
	$aConfigs{SerialDivisor} = $aBaudRates{WPM60}->{divisor};
}

#-- Derived variables for status line - don't change.  These will be generated based on $aConfigs{SerialDivisor}
my $nGlobalWPM  = 0;
my $nGlobalBaud = 0;

#- - - - - - - - - - Windowing & Display options - - - - - - - - - - - - - -


my $bCancelSleep  = 0;

my $batchmode_countdown_delay;

$batchmode_countdown_delay = $bWindows ? 10 : 200;

my $batchmode_countdown = $batchmode_countdown_delay;  # Make sure we're done

#-- Half/Full Duplex operation
#!!! global local echo is not supported now
my $local_echo = 1;	# Does output to loop echo in host window?


#-- Update interval
my $polltime = 20;	# How frequently do we check for something to do

my ($ok , $cancel) = ('OK' , 'Cancel');

#-- Font for Menu items [unimplemented]
my $label_font = $bWindows ? "Courier 12 normal" : "-adobe-courier-bold-r-normal--12-120-75-75-m-70-iso8859-1";



#- - - - - - - - - - Debug - - - - - - - - - - - - - - - - - -

my %aDebugLevels = (
	0 => '0 - Disabled',
	1 => '1 - Basic debug',
	2 => '2 - Function calls',
	3 => '3 - Full byte-level dump',
);


#- - - - - - - - - - Test - - - - - - - - - - - - - - - - - - - -

my $qbf_string  = "The quick brown fox jumped over the lazy dogs.\nThe quick brown fox jumped over the lazy dogs.\nThe quick brown fox jumped over the lazy dogs.";

#- - - - - - - - - - Telnet - - - - - - - - - - - - - - - - - - - -

# Global vars
my $sckTelnetListener;   # Listener socket
my %aTelnetSockets;      # Map for sockets->sessions

my $oTelnetReadSet;      # IO Select Set for Socket READ
my $oTelnetWriteSet;     # IO Select Set for Socket WRITE
my $oTelnetExceptionSet; # IO Select Set for Socket EXCEPTION


#- - - - - - - - - - Msn - - - - - - - - - - - - - - - - - - - -

# Global vars
my $MsnConnected   = 0;
my $MsnLastContact = '';
my $oMSN;
my %MsnInboundRoute;
my %MsnContactsRedirected;


#-- X10 stuff
my $x10_motor_state = 0;

#- - - - - - - - - - Misc - - - - - - - - - - - - - - - - - - - -




#-----------------------------------------------------------------------------
# Commands
#-----------------------------------------------------------------------------

my %aEscapeCommands = (
    'LC'        => \&lc_shift_lock,	    # Downshift all chars until LCOFF
    'UC'        => \&lc_shift_unlock,	# Resume normal 
    #'ABORT'     => \&abort_action,	    # Abort current command
    #'DEL'       => \&do_delete,		    # Discard input line
);

my %aActionCommands = (
	'HELP'      => {command => \&do_help,            auth => 2, help => 'Display usage message',        args => 'SETTINGS, COMMANDS, CHARS (optional) -or- command-name (optional)'},
	'PING'      => {command => \&do_ping,            auth => 1, help => 'Ping Pong communication test', args => 'echo-text (optional)'},
	'UPTIME'    => {command => \&do_uptime,          auth => 1, help => 'Show uptime',                  args => 'No args'},
	'TIME'      => {command => \&do_time,            auth => 1, help => 'Show current localtime',       args => 'No args'},
	'JOKE'      => {command => \&do_joke,            auth => 0, help => 'Tell me a joke',               args => 'No args'},
	'LOGOUT'    => {command => \&do_logout,          auth => 2, help => 'Disconnect a session (telnet only)', args => 'No args'},
	'QUIT'      => {command => \&do_logout,          auth => 2, help => 'Alias for logout',             args => 'No args'},
	'EXIT'      => {command => \&do_logout,          auth => 2, help => 'Alias for logout',             args => 'No args'},
	'SHUTDOWN'	=> {command => \&do_shutdown,        auth => 3, help => 'Clean up and exit',            args => 'No args'},
	'LIST'      => {command => \&do_list,            auth => 2, help => 'List existing sessions',       args => 'No args'},
	'LABEL'     => {command => \&do_label,           auth => 3, help => 'Print a punched tape label',   args => 'label-text (optional)'},
	'TELNET'    => {command => \&do_telnet,          auth => 3, help => 'Connect to a telnet server',   args => 'hostname (optional) port (optional)'},
	'EVAL'	    => {command => \&do_eval,            auth => 3, help => 'Execute perl code',            args => 'perl-code'},
	'PROMPT'    => {command => \&do_prompt,          auth => 2, help => 'Change the prompt mode for this session', args => 'On/Off'},
	'DEBUG'     => {command => \&do_debug,           auth => 2, help => 'View/Change debug settings',       args => '0,1,2,3 (optional) -or- SESSION session-id (to copy to session)'},
	'SOURCE'    => {command => \&do_source,          auth => 2, help => 'Change the source of a session',   args => 'source-session (optional) -or- source-session session-id (to set the source of another session)'},
	'DND'       => {command => \&do_dnd,             auth => 2, help => 'Do Not Disturb',                   args => 'On/Off'},
	'TARGET'    => {command => \&do_target,          auth => 2, help => 'Change the target of a session' ,  args => 'target-session (optional) -or- target-session session-id (to set the target of another session)'},
	'CHAT'      => {command => \&do_chat,            auth => 2, help => 'Change the source and target of your session', args => 'session-id -or- ALL'},
	'AUTH'      => {command => \&do_auth,            auth => 3, help => 'Switches a session to authorized', args => 'session-id'},
	'HMPIPE'    => {command => \&do_hmpipe,          auth => 2, help => 'Switches a session to piped mode (No prompt, no echo)', args => 'No args'},
	'USER'      => {command => \&do_user,            auth => 2, help => 'Change your username',             args => 'username'},
	'ABORT'     => {command => \&do_abort,           auth => 2, help => 'Abort current actions',            args => 'No args'},
	'SESSION'   => {command => \&do_session,         auth => 3, help => 'Show/change session parameters',   args => 'session-id (optional) -or- session-id setting value (to change a setting)'},
	'SETVAR'    => {command => \&do_setvar,          auth => 2, help => 'Change a command variable',        args => 'variable value'},
	'CONFIG'    => {command => \&do_config,          auth => 3, help => 'Change a config setting',          args => 'config-name config-value'},
	'CONFIGS'   => {command => \&do_configs,         auth => 3, help => 'Show config settings',             args => 'search-start (optional)'},
	'SAVECONFIG'=> {command => \&do_saveconfig,      auth => 3, help => 'Save config file',                 args => 'No args'},
	'SERIALINIT'=> {command => \&serial_init,        auth => 3, help => 'Initialize the serial port',       args => 'No args'},
	'KICK'      => {command => \&do_kick,            auth => 3, help => 'Kick a telnet session',            args => 'session-id'},
	'HOSTCMD'   => {command => \&do_host_command,    auth => 3, help => 'Execute command on host',          args => 'console-command'},
	'MSG'       => {command => \&do_msg,             auth => 2, help => 'Send a message to a target',       args => 'target message'},
	'SEND'      => {command => \&do_send,            auth => 3, help => 'Send a message to a target without source label',     args => 'target message -or- target command'},
	'SENDFILE'  => {command => \&do_sendfile,        auth => 3, help => 'Send file contents to a target without source label', args => 'target filename'},
	'MSN'       => {command => \&do_msn,             auth => 2, help => 'Interact with MSN (See help)',     args => 'On/Off'},
	'MSNLIST'   => {command => \&do_msnlist,         auth => 2, help => 'Show the MSN contact list',        args => 'No args'},
	'BANNER'    => {command => \&do_banner,          auth => 2, help => 'Generate a banner',                args => 'banner-text'},
	'CHECKMAIL' => {command => \&do_email_fetch,     auth => 3, help => 'Check POP email',                  args => 'No args'},
	'SENDMAIL'  => {command => \&do_email_send,	     auth => 3, help => 'Send email (Interactive command)', args => 'email-to subject (optional)'},
	'EMAIL'     => {command => \&do_email_send,	     auth => 3, help => 'Send email (Interactive command)', args => 'email-to subject (optional)'},
	'QBF'       => {command => \&do_qbf,             auth => 2, help => 'Test QBF',                         args => 'No args'},
	'RYRY'      => {command => \&do_ryry,            auth => 2, help => 'Test RYRY',                        args => 'num-lines (optional)'},
	'R6R6'      => {command => \&do_r6r6,            auth => 2, help => 'Test R6R6',                        args => 'num-lines (optional)'},
	'RRRR'      => {command => \&do_rrrr,            auth => 2, help => 'Test RRRR',                        args => 'num-lines (optional)'},
	'RAW5BIT'   => {command => \&do_raw_5bit,        auth => 2, help => 'Test Raw 5 bits',                  args => 'No args'},
	'RAW6BIT'   => {command => \&do_raw_6bit,        auth => 2, help => 'Test Raw 6 bits',                  args => 'No args'},
	'URL'       => {command => \&do_url,             auth => 2, help => 'Get any FTP/HTTP URL',             args => 'url'},
	'FTP'       => {command => \&do_url,             auth => 2, help => 'Get any FTP/HTTP URL',             args => 'url'},
	'WEATHER'   => {command => \&do_weather,         auth => 2, help => 'Get NOAA weather report',          args => '2-letter-state city'},
	'ART'       => {command => \&do_art,             auth => 2, help => 'Get RTTY ART images',              args => 'path'},
	'QUOTE'     => {command => \&do_quote,           auth => 2, help => 'Get stock quotes',                 args => 'stock-id -or- sotck-id stock-id ...'},
	'QUOTES'    => {command => \&do_quote,           auth => 2, help => 'Get stock quotes',                 args => 'stock-id -or- sotck-id stock-id ...'},
	'FULLQUOTE' => {command => \&do_quote_full,      auth => 2, help => 'Get full stock quotes',            args => 'stock-id -or- sotck-id stock-id ...'},
	'FULLQUOTES'=> {command => \&do_quote_full,      auth => 2, help => 'Get full stock quotes',            args => 'stock-id -or- sotck-id stock-id ...'},
	'PORTFOLIO' => {command => \&do_quote_portfolio, auth => 2, help => 'Get quotes for a given portfolio', args => 'No args'},
	'TOPNEWS'   => {command => \&do_news_topnews,    auth => 2, help => 'AP news summary',                  args => 'No args'},
	'HISTORY'   => {command => \&do_news_history,    auth => 2, help => 'AP Today in History',              args => 'No args'},
	'REPEAT'    => {command => \&do_repeat,          auth => 3, help => 'Endlessly repeat command line',    args => 'No args'},
	'SLEEP'     => {command => \&do_sleep,           auth => 3, help => 'Sleep for n seconds',              args => 'num-seconds'},
);


#-----------------------------------------------------------------------------
# Characters
#-----------------------------------------------------------------------------

# NOTE: If an escape sequence is terminated by a space, that space
# will be considered part of the escape keyword and discarded. 

# TO ASCII
my %aEscapeCharsDecodeASCII = (
	'AT'     => '@',
	'BANG'   => '!',
	'SPLAT'  => '#',
	'PC'     => '%',
	'TILDE'  => '~',
	'CARET'  => '^',
	'STAR'   => '*',
	'AND'    => '&',
	'PLUS'   => '+',
	'EQ'     => '=',
	'LPAREN' => '(',
	'RPAREN' => ')',
	'LT'     => '<',
	'GT'     => '>',
	'SQUOTE' => "'",
	'QMARK'  => '?',
	'SLASH'  => '/',
	'BSLASH' => "\\",
	'BS'     => "\010",
	'BELL'   => "\007",
	'CR'     => "\r",
	'LF'     => "\n",
);
    
# TO ITA2
my %aEscapeCharsDecodeITA = (
	'WRU'    => "\011",
	'BEL'    => "\007",
	'BELL'   => "\007",
	'BCR'    => "\010",
	'BLF'    => "\002",
	'CR'     => "\010",
	'LF'     => "\002",
	'LTRS'   => "\037", # LTRS SHIFT (aka Shift Out in ASCII)
	'FIGS'   => "\033", # FIGS SHIFT (aka Shift In in ASCII)
	'NUL'    => "\000", # NULL (aka All Space)
	'BNUL'   => "\000", # NULL (aka All Space)
	'SP'     => "\004", # Space
	'BSP'    => "\004", # Space

);

my %aEscapeCharsDebugASCII = (
	"\000"	=> 'NUL',  # Null
	"\012"	=> 'LF',   # ASCII LF
	"\015"	=> 'CR',   # ASCII CR
	"\017"	=> 'SI',   # ASCII Shift In     = Figs
	"\016"	=> 'SO',   # ASCII Shift Out    = Ltrs
	"\007"	=> 'BEL',  # ASCII Bell
	"\010"	=> 'BS',   # ASCII BackSpace
);
my %aEscapeCharsDebugITA2 = (
	"\000"	=> 'NUL',  # Null
	"\002"	=> 'BLF',  # ITA2/USTTY LF
	"\004"	=> 'BSP',  # ITA2/USTTY Space
	"\007"	=> 'BEL',  # ITA2/USTTY Bell
	"\010"	=> 'BCR',  # ITA2/USTTY CR
	"\033"	=> 'FIG',  # ITA2/USTTY Figures = SI
	"\037"	=> 'LTR',  # ITA2/USTTY Letters = SO
);


# -- The LTRS ,FIGS and end of line sequences codes are the same for 
# -- all of these supported code types, so we'll just use one set of 
# -- constants.
my $figs  = "\033";
my $ltrs  = "\037";
my $space = "\004";
my $b_cr  = "\010";
my $b_lf  = "\002";
my $b_nul = "\000";

# ASCII Special symbols
my $nul   = chr(0x00);
my $cr    = chr(0x0d);
my $lf    = chr(0x0a); 
my $si    = chr(0x0f);
my $so    = chr(0x0e);
my $bs    = chr(0x08);


my $end_of_line;

set_end_of_line();

sub set_end_of_line {
    $end_of_line = $b_cr . $b_cr x $aConfigs{TtyExtraCr} . $b_lf x $aConfigs{TtyExtraLf} . $ltrs. $ltrs x $aConfigs{TtyExtraLtrs};
}

# Select only one or zero of these
my $xlate_lf = 1;	# Translate ascii CR to CR/LF
my $xlate_cr = 0;	# Translate ascii LF to CR/LF

my $ascii_end_of_line = "\015\012";

my $xmit_shift = $ltrs; # Init w/ ltrs
my $rcv_shift  = $ltrs; # Init w/ ltrs

my $loop_no_match_char = chr(4); # Use this if no code conversion match
my $host_no_match_char = undef;  # Use this if no code conversion match


# Scalar character buffers

my $loop_archive  = ""; 	# Copy of all incoming raw loop data


# Performing the actions...

my @aCommands = ();		# Array of commands to carry out in list form.
			# New commands are pushed onto the commands array
			# and shifted out as they are carried out.

my $sCurrentCommand = '';

# Serial port
my $oSerialPort;

# Windowing variables
my $oTkMainWindow;         # Main window
my $sInputValue      = ''; # Text entered in via keyboard in text box
my $oTkTextarea;           # Displayed text window
my $oTkConfigRemote;
my $dialog_about;
my $oTkStatus;
my $sMainStatus      = '';
my $sPrinthead;	        # current printhead position
my $cursor_ch;	        # char under cursor

my @custom_menu_items;
my $custom_menu_title;

# Field names for full stock quote
my %aStockColumns = (
	 "Symbol" => 0,
	 "Name" => 1,
	 "Last" => 2,
	 "Trade Date" => 3,
	 "Trade Time" => 4,
	 "Change" => 5,
	 "% Change" => 6,
	 "Volume" => 7,
	 "Avg. Daily Volume" => 8,
	 "Bid" => 9,
	 "Ask" => 10,
	 "Prev. Close" => 11,
	 "Open" => 12,
	 "Day's Range" => 13,
	 "52-Week Range" => 14,
	 "EPS" => 15,
	 "P/E Ratio" => 16,
	 "Div. Pay Rate" => 17,
	 "Div/Share" => 18,
	 "Div. Yield" => 19,
	 "Mkt. Cap" => 20,
 	 "Exchange" => 21 );                      

#-----------------------------------------------------------------------------
# Command line options
#-----------------------------------------------------------------------------

my %aConfigDefinitions = (
	BatchMode       => {help => 'Exit when tasks complete'},
	Columns         => {help => 'Number of columns for TTY device'},
	CharDelay       => {help => 'Delay between characters (millisecs)'},
	Debug           => {help => 'Debug level: 0,1,2,3'},
	DebugFile       => {help => 'Debug output to file (must start with > or >>)'},
	DebugShowErrors => {help => 'Display errors are dialogs on host'},
	EmailAccount    => {help => 'Email account for POP and SMTP'},
	EmailFrom       => {help => 'Email from to use for email'},
	EmailPOP        => {help => 'POP server for email'},
	EmailPassword   => {help => 'Email password for POP and SMTP'},
	EmailSMTP       => {help => 'SMTP server for email'},
	EscapeChar      => {help => 'Enable character to use'},
	EscapeEnabled   => {help => 'Enable cmd escapes'},
	GuestPassword   => {help => 'Password for GUEST sessions'},
	LoopCode        => {help => 'Which code set to use'},
	LoopTest        => {help => 'Skip data in-out to loop'},
	LoopSuppress    => {help => 'Suppress the loop-out -> loop-in echo'},
	LowercaseLock   => {help => 'Downshift TTY input'},
	MsnDebug        => {help => 'Enabled debug of MSN protocol'},
	MsnEnabled      => {help => 'Enable MSN account'},
	MsnListen       => {help => 'Broadcast msgs from unauthenticated users'},
	MsnPassword     => {help => 'MSN account password'},
	MsnUsername     => {help => 'MSN account username'},
	PollingTime     => {help => 'Update polling interval'},
	RemoteMode      => {help => 'Control from TTY'},
	RunInProtect    => {help => 'Protect from msgs overriding TTY input (secs)'},
	SerialAddress   => {help => 'Address of serial port',                 command => \&serial_init},
	SerialDivisor   => {help => 'UART divisor of serial port',            command => \&serial_init},
	SerialParity    => {help => 'UART parity setting',                    command => \&serial_init},
	SerialPort      => {help => 'Which serial port to use for TTY',       command => \&serial_init},
	SerialSetserial => {help => 'Use setserial'},
	SerialStop      => {help => 'UART stop bits',                         command => \&serial_init},
	SerialWord      => {help => 'UART word size bits',                    command => \&serial_init},
	StockPortfolio  => {help => 'Stock symbols separated by space'},
	SystemName      => {help => 'System name'},
	SystemPassword  => {help => 'System full auth level password'},
	SystemPrompt    => {help => 'System prompt'},
	TelnetEnabled   => {help => 'Listen for incoming Telnet (TCP)'},
	TelnetPort      => {help => 'TCP port to use for Telnet listening'},
	TelnetWelcome   => {help => 'Telnet Welcome Message'},
	TelnetNegotiate => {help => 'Negotiate Telnet echo'},
	TtyExtraCr      => {help => 'How many extra CR to add on new line',   command => \&set_end_of_line},
	TtyExtraLf      => {help => 'How many extra LF to add on new line',   command => \&set_end_of_line},
	TtyExtraLtrs    => {help => 'How many extra LTRS to add on new line', command => \&set_end_of_line},
	UnshiftOnSpace  => {help => 'Unshift on space'},
	WeatherBase     => {help => 'Weather URL base'},
	X10Auto         => {help => 'X10 automatic motor control'},
	X10Device       => {help => 'X10 device code'},
	X10House        => {help => 'X10 house code'},
);


#------------------------------------------------------------------------
# X10 code snagged from Bill Birthisel's Misterhouse
# http://www.misterhouse.org
#

my $X10_DEBUG = 0;

my %table_hcodes = qw(A 01100 B 01110 C 01000 D 01010 E 10000 F 10010 G 10100 H 10110 
                      I 11100 J 11110 K 11000 L 11010 M 00000 N 00010 O 00100 P 00110);

my %table_dcodes = qw(1J 00000000000 1K 00000100000 2J 00000010000 2K 00000110000
                      3J 00000001000 3K 00000101000 4J 00000011000 4K 00000111000
                      5J 00001000000 5K 00001100000 6J 00001010000 6K 00001110000
                      7J 00001001000 7K 00001101000 8J 00001011000 8K 00001111000
                      9J 10000000000 9K 10000100000 AJ 10000010000 AK 10000110000
                      BJ 10000001000 BK 10000101000 CJ 10000011000 CK 10000111000
                      DJ 10001000000 DK 10001100000 EJ 10001010000 EK 10001110000
                      FJ 10001001000 FK 10001101000 GJ 10001011000 GK 10001111000 
                      L  00010001000 M  00010011000 O  00010010000 N  00010100000 P 00010000000);

my %table_ir_codes = qw(POWER    1000001001111011  MUTE     1000001100100011 
                        CH+      1000001100100111  CH-      1000001101000011
                        VOL+     1000001100001111  VOL-     1000001100010111
                        1        1000001100110011  2        1000001100111111
                        3        1000001100101011  4        1000001001011011
                        5        1000001001101111  6        1000001001100111
                        7        1000001001011111  8        1000001001101011
                        9        1000001001010111  0        1000001001010011
                        MENU     1000001000100111  ENTER    1000001000111111
                        FF       1000001000010011  REW      1000001000001011
                        RECORD   1000001000000111  PAUSE    1000001000011011 
                        PLAY     1000001000011011  STOP     1000001000010111
                        AVSWITCH 1000001001001011  DISPLAY  1000001001000011
                        UP       1000001001001111  DOWN     1000001000110011 
                        LEFT     1000001000110111  RIGHT    1000001000101111
                        SKIPDOWN 1000001000101011  SKIPUP   1000001000001111
                        TITLE    1000001000100011  SUBTITLE 1000001000011111
                        EXIT     1000001001100011  OK       1000001001000111
                        RETURN   1000001000111011
                       );
my %table_device_codes = qw(TV  1000001001110111  VCR 1000001001110011
                            CAB 1000001100001011  CD  1000001100010011
                            SAT 1000001100000111  DVD 1000001100000011
                            );
#------------------ end of MisterHouse vars


#-----------------------------------------------------------------------------
# Code conversion tables
#-----------------------------------------------------------------------------

my %CODES = (
	'ASCII'      => {label => "ASCII",                           upshift=> 0}, 
	'USTTY'      => {label => "USTTY (5-level)",                 upshift=> 1}, 
	'ITA2'       => {label => "ITA2 (5-level)",                  upshift=> 1}, 
	'ITA2-S100A' => {label => "ITA2 (5-level) for SIEMENS 100a", upshift=> 1}, 
	'TTS-M20'    => {label => "TTS (6-level) for Model 20",      upshift=> 0}
);

# USTTY
$CODES{'USTTY'}->{'FROM-LTRS'} = {   # NOTES: \xa = LF \xd = CR \x7 = BELL
    "\001" => 'E', "\002" => "\xa", "\003" => 'A', "\004" => ' ', "\005" => 'S', "\006" => 'I',
    "\007" => 'U', "\010" => "\xd", "\011" => 'D', "\012" => 'R', "\013" => 'J', "\014" => 'N', 
    "\015" => 'F', "\016" => 'C',   "\017" => 'K', "\020" => 'T', "\021" => 'Z', "\022" => 'L', 
    "\023" => 'W', "\024" => 'H',   "\025" => 'Y', "\026" => 'P', "\027" => 'Q', "\030" => 'O', 
    "\031" => 'B', "\032" => 'G',   "\034" => 'M', "\035" => 'X', "\036" => 'V'
};

$CODES{'USTTY'}->{'FROM-FIGS'} = {   # NOTES: \xa = LF \xd = CR \x7 = BELL
    "\001" => "3", "\002" => "\xa", "\003" => "-", "\004" => " ", "\005" => "\x7", "\006" => "8",
    "\007" => "7", "\010" => "\xd", "\011" => '$', "\012" => "4", "\013" => "'",   "\014" => ",",
    "\015" => "!", "\016" => ":",   "\017" => "(", "\020" => "5", "\021" => '"',   "\022" => ")",
    "\023" => "2", "\024" => "#",   "\025" => "6", "\026" => "0", "\027" => "1",   "\030" => "9",
    "\031" => "?", "\032" => "&",   "\034" => ".", "\035" => "/", "\036" => ";"
};

# ITA2
# LTRS is equal to USTTY
$CODES{'ITA2'}->{'FROM-LTRS'} =  $CODES{'USTTY'}->{'FROM-LTRS'};

$CODES{'ITA2'}->{'FROM-FIGS'} = {
    "\001" => '3', "\002" => "\xa", "\003" => '-', "\004" => ' ', "\005" => "'",   "\006" => '8',
    "\007" => '7', "\010" => "\xd", "\011" => '#', "\012" => '4', "\013" => "\x7", "\014" => ',',
    "\015" => '@', "\016" => ':',   "\017" => '(', "\020" => '5', "\021" => '+',   "\022" => ')',
    "\023" => '2', "\024" => '$',   "\025" => '6', "\026" => '0', "\027" => '1',   "\030" => '9',
    "\031" => '?', "\032" => '*',   "\034" => '.', "\035" => '/', "\036" => '='
};

# ITA2-S100A
# LU8AJA: ITA2 Custom mod for supporting my Siemens 100A which has differences in $ @ Ñ (\015 \024)
$CODES{'ITA2-S100A'}->{'FROM-LTRS'} =  $CODES{'ITA2'}->{'FROM-LTRS'};

$CODES{'ITA2-S100A'}->{'FROM-FIGS'} = {
    "\001" => '3', "\002" => "\xa", "\003" => '-', "\004" => ' ', "\005" => "'",   "\006" => '8',
    "\007" => '7', "\010" => "\xd", "\011" => '#', "\012" => '4', "\013" => "\x7", "\014" => ',',
    "\015" => '$', "\016" => ':',   "\017" => '(', "\020" => '5', "\021" => '+',   "\022" => ')',
    "\023" => '2', "\024" => 'Ñ',   "\025" => '6', "\026" => '0', "\027" => '1',   "\030" => '9',
    "\031" => '?', "\032" => '*',   "\034" => '.', "\035" => '/', "\036" => '='
};

# TTS-M20
# Bill Buzbee: 6-bit code used on my Model 20.  This is *not* exactly the same code that is shown in the Model 20 manual 
$CODES{'TTS-M20'}->{'FROM-LTRS'} = {
    "\001" => 'e',   "\002" => "\xa", "\003" => 'a', "\004" => ' ', "\005" => 's', "\006" => 'i',
    "\007" => 'u',   "\010" => "\xd", "\011" => 'd', "\012" => 'r', "\013" => 'j', "\014" => 'n',
    "\015" => 'f',   "\016" => 'c',   "\017" => 'k', "\020" => 't', "\021" => 'z', "\022" => 'l',
    "\023" => 'w',   "\024" => 'h',   "\025" => 'y', "\026" => 'p', "\027" => 'q', "\030" => 'o',
    "\031" => 'b',   "\032" => 'g',   "\034" => 'm', "\035" => 'x', "\036" => 'v', "\041" => '3',
    "\043" => '$',   "\046" => '8',   "\047" => '7', "\050" => "'", "\051" => '-', "\052" => '4',
    "\053" => "\x7", "\054" => ',',   "\060" => '5', "\063" => "2", "\065" => "6", "\066" => "0",
    "\070" => "9",   "\072" => ";",   "\074" => ".", "\075" => "1"
};
# Missing codes: \042 \044 \045 \055 \056 \057 \061 \062 \064 \067 \071 \073 \076

$CODES{'TTS-M20'}->{'FROM-FIGS'} = {
	"\001" => "E",   "\002" => "\xa", "\003" => "A",   "\004" => " ",   "\005" => "S",     "\006" => "I",
    "\007" => "U",   "\010" => "\xd", "\011" => "D",   "\012" => "R",   "\013" => "J",     "\014" => "N",
    "\015" => "F",   "\016" => "C",   "\017" => "K",   "\020" => "T",   "\021" => "Z",     "\022" => "L",
    "\023" => "W",   "\024" => "H",   "\025" => "Y",   "\026" => "P",   "\027" => "Q",     "\030" => "O",
    "\031" => "B",   "\032" => "G",   "\034" => "M",   "\035" => "X",   "\036" => "V",     "\041" => "3/8",
    "\043" => "/",   "\046" => "-",   "\047" => "7/8", "\050" => '"',   "\051" => "\%sp3", "\052" => "1/2",
    "\054" => ",",   "\060" => "5/8", "\063" => "1/4", "\065" => "3/4", "\066" => '?',     "\070" => "&",
    "\072" => ":",   "\074" => ".",   "\075" => "1/8",
};
# Missing codes: \042 \044 \045 \055 \056 \057 \061 \062 \064 \067 \071 \073 \076

# Generate the reverse: ASCII -> BAUDOT
$CODES{'USTTY'}->{'TO-LTRS'}      = {reverse %{$CODES{'USTTY'}->{'FROM-LTRS'}}};
$CODES{'USTTY'}->{'TO-FIGS'}      = {reverse %{$CODES{'USTTY'}->{'FROM-FIGS'}}};

$CODES{'ITA2'}->{'TO-LTRS'}       = {reverse %{$CODES{'ITA2'}->{'FROM-LTRS'}}};
$CODES{'ITA2'}->{'TO-FIGS'}       = {reverse %{$CODES{'ITA2'}->{'FROM-FIGS'}}};

$CODES{'TTS-M20'}->{'TO-LTRS'}    = {reverse %{$CODES{'TTS-M20'}->{'FROM-LTRS'}}};
$CODES{'TTS-M20'}->{'TO-FIGS'}    = {reverse %{$CODES{'TTS-M20'}->{'FROM-FIGS'}}};

$CODES{'ITA2-S100A'}->{'TO-LTRS'} = {reverse %{$CODES{'ITA2-S100A'}->{'FROM-LTRS'}}};
$CODES{'ITA2-S100A'}->{'TO-FIGS'} = {reverse %{$CODES{'ITA2-S100A'}->{'FROM-FIGS'}}};

#-----------------------------------------------------------------------------
# RTTY Art files from RTTY.COM's Royer Art Pavilion
#-----------------------------------------------------------------------------

my %aArtOptions = art_init();
my $sArtCopyOutput = 'TTY';
my $bArtCopyOutput = 0;

# Jokes
my $nCurrentJoke = 0;
my @aJokes = (
	qq{A computer lets you make more mistakes faster than any invention in human history, with the possible exceptions of handguns and tequila.},
	qq{If it weren't for C, we'd all be programming in BASI and OBOL.},
	qq{There are 10 types of people in the world: those who understand binary, and those who don't.},
	qq{In a world without fences and walls, who needs Gates and Windows?},
	qq{Programming today is a race between software engineers striving to build bigger and better idiot-proof programs, and the Universe trying to produce bigger and better idiots. So far, the Universe is winning.},
	qq{Computers make very fast, very accurate mistakes.},
	qq{Never underestimate the bandwidth of a station wagon full of tapes hurling down the highway.},
	qq{An SQL statement walks into a bar and sees two tables. It approaches, and asks "may I join you?"},
	qq{Q: Why is it that programmers always confuse Halloween with Christmas?\n- A: Because 31 OCT = 25 DEC.},
	qq{Man is the best computer we can put aboard a spacecraft... and the only one that can be mass produced with unskilled labor},
	qq{Q: How many programmers does it take to change a light bulb?\n- A: None. It's a hardware problem.},
	qq{Two strings walk into a bar and sit down. The bartender says, "So what'll it be?"\n- The first string says, "I think I'll have a beer quag fulk boorg jdk.CjfdLk jk3s d\$f67howe-U r89nvy..owmc63?Dz x.xvcu"\n- "Please excuse my friend," the second string says. "He isn't null-terminated."},
	qq{"I'm not interrupting you, I'm putting our conversation in full-duplex mode." - Antone Roundy},
	qq{A logician tells a colleague his wife just had a baby.\n - Is it a boy or a girl?\n - Yes.},
	qq{A cop pulls over Werner Heisenberg and says, "Sir, do you know how fast you were going?"\n Heisenberg responds, "NO, but I know EXACTLY where I am."},
);



#-----------------------------------------------------------------------------
# Weather reports from tgftp.nws.noaa.gov
#-----------------------------------------------------------------------------

my %aWeatherCities = weather_init();

#-----------------------------------------------------------------------------
# Main program begins here (Not really, but I like to think of it that way...)
#-----------------------------------------------------------------------------

{
	# Handler for CTRL-C
	$SIG{'INT'} = 'main_exit';

	# Set the defaults for the configs
	foreach my $sKey (keys %aConfigs){
		if (defined $aConfigDefinitions{$sKey}){
			$aConfigDefinitions{$sKey}->{default} = $aConfigs{$sKey};
		}
	}
	
	# Load configs from cfg file
	if (-e "$config_file") {
		load_batch_file($config_file);
	}
	
	# Process Command line options
	process_cmdline();

	
	logDebug("Heavy Metal initializing - ".get_datetime()." - please wait\n");
	
	# Load modules dynamically
	# Find the last one
	foreach my $sKey (keys(%Modules)){ 
		if (exists($Modules{$sKey}->{'order'})){
			if ($Modules{$sKey}->{'order'} > $nMax){
				$nMax = $Modules{$sKey}->{'order'};
			}
		}
	}
	# Load one by one
	for ($nCount = 0; $nCount <= $nMax; $nCount++){
		foreach my $sKey (keys(%Modules)){
			if (exists($Modules{$sKey}->{'order'}) && ($Modules{$sKey}->{'order'} == $nCount)){
				my $bLoad = 1;
				# Check OS to determine if it should be loaded
				if (exists($Modules{$sKey}->{'os'}) && $Modules{$sKey}->{'os'} ne ''){
					$bLoad = ($sOS =~ /$Modules{$sKey}->{'os'}/ix);
				}
				if ($bLoad){
					logDebug (sprintf("Loading Module %25s ", $sKey));
					my $sModule = exists($Modules{$sKey}->{'args'}) ? $sKey : $sKey.' '.$Modules{$sKey}->{'args'};
					eval('use '.$sModule);
					if ($@){
						if (exists($Modules{$sKey}->{'required'}) && $Modules{$sKey}->{'required'}){
							logDebug("FATAL ERROR\n".$@);
							die;
						}
						else{
							logDebug("ERROR\n".$@);
						}
					}
					else{
						logDebug("OK\n");
						$Modules{$sKey}->{'loaded'} = 1;
					}
				}
			}
		}
	}
	
	#----------------------
	

	
	# Deal with windows versions
	if ($bWindows ) {
	
		my $GetVersionEx = new Win32::API("Kernel32","GetVersionEx", ["P"], "N");
		if (!$GetVersionEx){
			logDebug("FATAL ERROR: Cannot get OS version object\n");
		}
		my $os_ver = pack "LLLLLa128",(148,0,0,0,0, "\0"x128);
		my %ver;
		my @ver_param = qw(OSVersionInfoSize MajorVersion MinorVersion BuildNumber PlatformId);
		if(! $GetVersionEx->Call($os_ver)){
			logDebug("FATAL ERROR: Cannot get OS version\n");
			die;
		}
		
		@ver{@ver_param} = unpack "LLLLLa128",$os_ver;
	
	    #print "MajorVersion : $ver{'MajorVersion'}\n";
	    #print "MinorVersion : $ver{'MinorVersion'}\n";
	    #print "BuildNumber  : $ver{'BuildNumber'}\n";
	    #print "PlatformId   : $ver{'PlatformId'}\n";
		
		if ($ver{'PlatformId'} == 2) {
			$bWindows98 = 0;
		}
		elsif ($ver{'PlatformId'} == 1) {
			$bWindows98 = 1;
		}
		else {
			logDebug("FATAL ERROR: Unknown or unsupported Platform\n");
			die;
		}
	}
	else {
		$aConfigs{SerialSetserial} = 1;
	}

	# This determines how HM will split lines when doing AP news summary
	$Text::Wrap::columns = $aConfigs{Columns};

	initialize_buffers();
	
	initialize_loop();
	
	initialize_windows();
	
	redraw_status_window();
	
	serial_init();
	
	if ($aConfigs{TelnetEnabled}){
		telnet_init();
	}

	if ($aConfigs{MsnEnabled}){
		msn_init();
	}

  main_loop();
  
  logDebug("\nHeavy Metal initialization complete, ".get_datetime()."\n");

  MainLoop();

	# Closing everything everything
  serial_close();

	if ($rDebugHandle){
		close($rDebugHandle);
		$rDebugHandle = undef;
	}
	
	exit;

}

#-----------------------------------------------------------------------------
# Subroutine definitions
#-----------------------------------------------------------------------------


sub initialize_buffers{

	my $idSession;
	
	$idSession = $NewSessionId++;

	$aSessions[$idSession] = {       # - SESSION DESCRIPTION -
		'id'          => $idSession, # Session ID
		'type'        => 'HOST',     # Type of session HOST, TTY, TELNET, MSN
		'IN'          => '',         # Input Buffer
		'OUT'         => '',         # Output Buffer
		'status'      => 1,          # Session Active
		'direction'   => 0,          # 0: InBound, 1: OutBound
		'auth'        => 3,          # Session Authenticated
		'user'        => 'HOST',     # User
		'target'      => 'ALL',      # Msg target: ALL, IN, OUT, idSession, user, MSN:email
		'source'      => 'ALL',      # Source filter: ALL, IN, OUT, idSession
		'prompt'      => 1,          # Enable command prompt
		'disconnect'  => 0,          # Order to disconnect
		'address'     => 'local',    # Address (this is relative to the protocol involved)
		'input_type'  => '',         # Type of input: LINE, BLOCK, OUT-EMPTY
		'input_var'   => '',         # Variable name awaiting input
		'input_prompt'=> '',         # Prompt for command inputs
		'echo_input'  => 1,          # Echo my own lines
		'echo_msg'    => 0,          # Echo my own messages
		'clean_line'  => 1,
		'command'     => '',         # Command to be executed (either the command key or a ref to a sub)
		'column'      => 0,          # Current column
		'label_source'=> 1,
	};
	if ($aConfigs{Debug}){ logDebug("\nNew session for HOST: $idSession\n");}
	
	if ($aSessions[$idSession]->{prompt}){
		$aSessions[$idSession]->{OUT} = $aConfigs{SystemPrompt};
	}
	
	$idSession  = $NewSessionId++;

	$aSessions[$idSession] = {
		'type'        => 'TTY', 
		'IN'          => '', 
		'OUT'         => '',
		'RAW_IN'      => '', 
		'RAW_OUT'     => '',
		'id'          => $idSession, 
		'status'      => 1, 
		'direction'   => 0, 
		'auth'        => 3, 
		'user'        => 'TTY', 
		'target'      => 'ALL', 
		'source'      => 'ALL',
		'prompt'      => 0,
		'disconnect'  => 0,
		'address'     => $aConfigs{SerialPort},
		'overstrike_protect' => 1,
		'loop_suppress' => $aConfigs{LoopSuppress},
		'input_type'  => '', 
		'input_var'   => '',
		'input_prompt'=> '',
		'echo_input'  => 0,
		'label_source'=> 1,
		'echo_msg'    => 0, 
		'clean_line'  => 0,
		'raw_mode'    => 0,
		'column'      => 0,      # Keep track of the current column at the TTY
		'rx_last'     => 0,      # Keeps the time of the last receptions from the TTY
		'rx_count'    => 0,
		'runin_count' => 0,
	};
	if ($aConfigs{Debug}){ logDebug("\nNew session for TTY: $idSession\n");}
	
	return 1;
}


sub initialize_windows {

	print "Initialize windows\n";
    $oTkMainWindow = MainWindow->new(-title => "Heavy Metal TTY Program, v$sGlobalVersion");
    if ($Modules{'Tk::Icon'}->{loaded} && -e 'heavymetal.ico'){
    	$oTkMainWindow->setIcon(-file => 'heavymetal.ico');
    }

   	# Frame for menus 
    my $oTkFrameMenu = $oTkMainWindow->Frame->pack(-side => 'top', -fill => 'x');
   
   	# Menu items 
	$oTkFrameMenu->Menubutton(-text=>"File",-tearoff=>0,
		-menuitems => [
			[ 'command' => "Send ASCII file to TTY",  -command => sub { do_sendfile(0, '1'); }],
			[ 'command' => "Send RAW file to TTY",    -command => \&do_send],
			[ 'command' => "Save buffer as ASCII", -command => \&save_file],
			[ 'command' => "Save buffer raw",      -command => \&save_file_raw],
			"-",
			[ 'command' => "Exec host comand",     -command => \&do_host_command],
			"-",
			[ 'command' => "Save Configuration",   -command => \&do_saveconfig],
			"-",
			[ 'command' => "X10 On",               -command => \&do_x10_on],
			[ 'command' => "X10 Off",              -command => \&do_x10_off],
			"-",
			[ 'command' => "Exit",                 -command => sub { $oTkMainWindow->destroy; }]
		])->pack(-side=>'left');
    
    $oTkFrameMenu->Menubutton(-text=>"Edit",-tearoff=>0,
    	-menuitems => [[ 'command' => "Copy"],
    		       [ 'command' => "Paste",
    			 -command => \&paste],
    		       [ 'command' => "Select All",
    			 -command => \&select_all]])->pack(-side=>'left');
    
    my $oTkMenuConfig = $oTkFrameMenu->Menubutton(-text=>"Config",-tearoff=>0)->pack(-side=>'left');

    my $oTkMenuCode = $oTkMenuConfig->cascade(-label => "Code",-tearoff=>0);

	for (sort keys %CODES){
		$oTkMenuCode->radiobutton(
			-label    => $CODES{$_}->{label},
			-command  => \&initialize_loop,
			-value    => $_, 
			-variable => \$aConfigs{LoopCode}
		);
	}
	
	$oTkMenuConfig->separator();
	
  # Add available ports
	my $oTkMenuPort = $oTkMenuConfig->cascade(-label => "Serial port", -tearoff=>0);
	
	# Add disabled
	$oTkMenuPort->radiobutton(
		-label    => "Disabled",
		-value    => "",
		-command  => \&serial_init_with_address,
		-variable => \$aConfigs{SerialPort}
	);
	
	# Add COM ports
	foreach (sort keys %aPortAddresses){ 
		# Check if port can be opened in this system
		my $oTmpSerial   = ($bWindows) ? Win32::SerialPort->new($_ ,1) : Device::SerialPort->new($_);
		my $sStatusLabel = $oTmpSerial ? '(OK)' : '';
		if ($oTmpSerial){
			$oTmpSerial->close();
		}

		$oTkMenuPort->radiobutton(
			-label    => "$_ $sStatusLabel",
			-value    => $_,
			-command  => \&serial_init_with_address,
			-variable => \$aConfigs{SerialPort}
		);
	}
    
	my $oTkMenuAddress = $oTkMenuConfig->cascade(-label => "Port address",-tearoff=>0);
	foreach (sort %aPortAddresses){ 
		if ($_ > 0) {
			$oTkMenuAddress->radiobutton(-label => sprintf("0x%X", $_),
				-value    => "$_",
				-command  => \&serial_init,
				-variable => \$aConfigs{SerialAddress}
			);
		}
    }

    
    my $oTkMenuBaud = $oTkMenuConfig->cascade(-label => "Baud rate",-tearoff=>0);
	foreach (sort {$aBaudRates{$b}->{divisor} <=> $aBaudRates{$a}->{divisor}} keys %aBaudRates){
		$oTkMenuBaud->radiobutton(
			-label    => $aBaudRates{$_}->{label}, 
			-value    => $aBaudRates{$_}->{divisor}, 
			-command  => \&serial_init, 
			-variable => \$aConfigs{SerialDivisor}
		);
    }
       
	my $oTkMenuWord = $oTkMenuConfig->cascade(-label => "Word Size",-tearoff=>0);
	foreach (5, 6, 7, 8) {
		$oTkMenuWord->radiobutton(
			-label    => "$_ Bits", 
			-value    => $_, 
			-command  => \&serial_init, 
			-variable => \$aConfigs{SerialWord}
		);
	}
    
	my $oTkMenuBits = $oTkMenuConfig->cascade(-label => "Stop bits",-tearoff=>0);
	foreach (1, 1.5, 2) {
		$oTkMenuBits->radiobutton(
			-label    => $_, 
			-value    => $_, 
			-command  => \&serial_init, 
			-variable => \$aConfigs{SerialStop}
		);
	}
    
    my $oTkMenuParity = $oTkMenuConfig->cascade(-label => "Parity",-tearoff=>0);
    foreach ('none', 'even', 'odd') {
        $oTkMenuParity->radiobutton(
        	-label    => $_, 
        	-value    => $_, 
        	-command  => \&serial_init, 
        	-variable => \$aConfigs{SerialParity}
        );
    }
    
		$oTkMenuConfig->checkbutton(-label => "Use setserial",           -variable => \$aConfigs{SerialSetserial});
 
    $oTkMenuConfig->separator;

    $oTkMenuConfig->checkbutton(-label => "Supress loop echo",       -variable => \$aConfigs{LoopSuppress});
    $oTkMenuConfig->checkbutton(-label => "Local test (bypass loop)",-variable => \$aConfigs{LoopTest});
    $oTkMenuConfig->checkbutton(-label => "Unshift on space",        -variable => \$aConfigs{UnshiftOnSpace});
    $oTkMenuConfig->checkbutton(-label => "Lowercase lock",          -command => \&redraw_status_window,-variable => \$aConfigs{LowercaseLock});
    $oTkMenuConfig->checkbutton(-label => "Enable '$aConfigs{EscapeChar}' escapes",    -variable => \$aConfigs{EscapeEnabled});
    $oTkMenuConfig->checkbutton(-label => "Remote mode (from TTY)",  -variable => \$aConfigs{RemoteMode});
    $oTkMenuConfig->checkbutton(-label => "X10 Auto Mode",           -variable => \$aConfigs{X10Auto});
    $oTkMenuConfig->checkbutton(-label => "ASCII CR => CR/LF",       -variable => \$xlate_cr);
    $oTkMenuConfig->checkbutton(-label => "ASCII LF => CR/LF",       -variable => \$xlate_lf);



    my $oTkMenuDebug = $oTkMenuConfig->cascade(-label => "Debug", -tearoff => 0);
    foreach (sort keys %aDebugLevels){
    	$oTkMenuDebug->radiobutton(-label => $aDebugLevels{$_}, -value => $_, -variable => \$aConfigs{Debug});
    }

	# INTERNET
	my $oTkMenuInternet = $oTkFrameMenu->Menubutton(-text=>"Internet",-tearoff=>0)->pack(-side=>'left');

	# Internet - Telnet server
    $oTkMenuInternet->checkbutton(-label => "Enable Telnet server", -variable => \$aConfigs{TelnetEnabled}, -command => \&telnet_toggle);
    my $oTkMenuTelnet = $oTkMenuInternet->cascade(-label => "Listen port",-tearoff=>0);
	foreach (23, 1078, 11123, 11124, 11125){
		$oTkMenuTelnet->radiobutton(
			-label => $_, 
			-value => $_, 
			-variable => \$aConfigs{TelnetPort},
			#-command => \&telnet_reset,
		); 
	}

	# Internet - Telnet client
	$oTkMenuInternet->separator();
	$oTkMenuInternet->radiobutton(
		-label    => "Connect to external TCP port", 
		-variable => \$aSessions[0]->{VARS}->{telnet_host},
		-value    => ' ',
		-command  => \&do_telnet
	);
		
	my $oTkMenuHosts = $oTkMenuInternet->cascade(-label => "Telnet connect to", -tearoff=>0);
	my $nCount = 0;
	for my $sKey (sort keys %aConfigs){
		if ($sKey =~ /^TelnetHost\.\d+$/i){
			$nCount++;
			$oTkMenuHosts->radiobutton(
				-label    => $aConfigs{$sKey},
				-variable => \$sInputValue,
				-command  => \&add_text_from_host,
				-value    => "$aConfigs{EscapeChar}TELNET $aConfigs{$sKey}\n"
			);
		}
	}
	if (!$nCount){
		$oTkMenuHosts->command(-label=>'- To add hosts see README -');
	}
	
	# Internet - MSN
	$oTkMenuInternet->separator;
    $oTkMenuInternet->checkbutton(-label => "Enable MSN client", -variable => \$aConfigs{MsnEnabled}, -command => \&msn_toggle);

	# Internet - Email
	$oTkMenuInternet->separator();
	$oTkMenuInternet->command(-label => "Send email",                    -command => \&do_email_send);
	$oTkMenuInternet->radiobutton(-label => "Check email headers",       -command => \&do_email_fetch, -variable => \$aSessions[0]->{VARS}->{'email_action'}, -value => 'HEADERS');
	$oTkMenuInternet->radiobutton(-label => "Read all email",            -command => \&do_email_fetch, -variable => \$aSessions[0]->{VARS}->{'email_action'}, -value => 'ALL');
	$oTkMenuInternet->radiobutton(-label => "Read GreenKeys list email", -command => \&do_email_fetch, -variable => \$aSessions[0]->{VARS}->{'email_action'}, -value => 'GREENKEYS');

	# Internet - HTTP/FTP
	$oTkMenuInternet->separator();
	$oTkMenuInternet->checkbutton(-label => "Fetch file (FTP/HTTP)", -command => \&do_url);
	
	# NEWS
	my $oTkMenuNews = $oTkFrameMenu->Menubutton(-text=>"Newswire",-tearoff=>0)->pack(-side=>'left');
	
	# Newswire - AP newswires
	$oTkMenuNews->command(-label => "AP Top Stories",        -command => \&do_news_topnews);
	$oTkMenuNews->command(-label => "AP Today in History",   -command => \&do_news_history);
	# Newswire - Stock quotes
	$oTkMenuNews->separator();
	$oTkMenuNews->command(-label => "Stock Quote",           -command => \&do_quote);
	$oTkMenuNews->command(-label => "Stock Portfolio",       -command => \&do_quote_portfolio);
	$oTkMenuNews->command(-label => "Full Stock quote",      -command => \&do_quote_full);


	# RTTY ART
	
	# Banner & Label
	my $oTkMenuArt = $oTkFrameMenu->Menubutton(-text=>"RTTY Art",-tearoff=>0,
		-menuitems => [
			[ 'command' => "Create Banner",       -command => \&do_banner],
			[ 'command' => "Create Tape Label",   -command => \&do_label],
		])->pack(-side=>'left');
		
	
	
	# ART
	$oTkMenuArt->separator();
	$oTkMenuArt->checkbutton(
		-label    => 'Copy output to TTY',
		-variable => \$bArtCopyOutput,
		#-command  => \&add_text_from_host,
	);
		
	for my $sArtCategory (keys %aArtOptions){
		$oTkMenuArt->separator();
		$oTkMenuArt->command(-label => $sArtCategory);	
		
		foreach my $sSubLabel (sort(keys %{$aArtOptions{$sArtCategory}})) {
			if (ref(\$aArtOptions{$sArtCategory}->{$sSubLabel}) eq 'SCALAR'){
				my $sValue    = $aArtOptions{$sArtCategory}->{$sSubLabel};
				$oTkMenuArt->radiobutton(
					-label    => $sSubLabel,
					-variable => \$sInputValue,
					-command  => \&add_text_from_host,
					-value    => "$aConfigs{EscapeChar}ART $sValue\n"
				);

			}
			else{
				my $oTkMenuSub = $oTkMenuArt->cascade(-label=>$sSubLabel, -tearoff=>0);				
				foreach my $sKey (sort(keys %{$aArtOptions{$sArtCategory}->{$sSubLabel}})){
					my $sValue    = $aArtOptions{$sArtCategory}->{$sSubLabel}->{$sKey};
					$oTkMenuSub->radiobutton(
						-label    => $sKey,
						-variable => \$sInputValue,
						-command  => \&add_text_from_host,
						-value    => "$aConfigs{EscapeChar}ART $sValue\n"
					);
				}
			}
		}

	}


	# WEATHER
    my $oTkMenuWeather = $oTkFrameMenu->Menubutton(-text=>"Weather",-tearoff=>0)->pack(-side=>'left');
    # Here we might quick favorite cities
    $oTkMenuWeather->command(-label=>'- Favorite Cities -');
	for my $sKey (sort keys %aConfigs){
		if ($sKey =~ /^WeatherFavorite\.\d+$/i){
			$aConfigs{$sKey};

			$oTkMenuWeather->radiobutton(
				-label    => $aConfigs{$sKey},
				-variable => \$sInputValue,
				-command  => \&add_text_from_host,
				-value    => "$aConfigs{EscapeChar}WEATHER $aConfigs{$sKey}\n");
		}
	}

    $oTkMenuWeather->separator();
    $oTkMenuWeather->command(-label=>'- Cities by state -');
    foreach my $sub_label (sort(keys %aWeatherCities)) {
		my $oTkMenuState = $oTkMenuWeather->cascade(-label=>$sub_label,-tearoff=>0);
		foreach my $city (sort(keys %{$aWeatherCities{$sub_label}})) {
			$oTkMenuState->radiobutton(
				-label    => "$city",
				-variable => \$sInputValue,
				-command  => \&add_text_from_host,
				-value    => "$aConfigs{EscapeChar}WEATHER $sub_label $aWeatherCities{$sub_label}->{$city}\n");
        }
    }

	$oTkFrameMenu->Menubutton(-text => "Cancel", -tearoff => 0, -menuitems => [
			[ 'command' => "Cancel action",       -command => \&abort_action],
			[ 'command' => "Cancel I/O & action", -command => \&cancel_printing],
		])->pack(-side=>'left');

	$oTkFrameMenu->Menubutton(-text => "Tests", -tearoff => 0, -menuitems => [
			[ 'command' => "Quick brown fox", -command => \&do_qbf],
			[ 'command' => "RYRY",            -command => \&do_ryry],
			[ 'command' => "RRRR",            -command => \&do_rrrr],
			[ 'command' => "Raw 5-bit codes", -command => \&do_raw_5bit],
			[ 'command' => "Raw 6-bit codes", -command => \&do_raw_6bit],
		])->pack(-side=>'left');

	$oTkFrameMenu->Menubutton(-text => "Info", -tearoff => 0, -menuitems => [
			[ 'command' => "About HeavyMetal", -command => \&do_about],
			[ 'command' => "Usage",            -command => \&do_usage]
		])->pack(-side=>'right');


#    if (-e "$menu_config") {
#        if (open (INPUT, "< $menu_config")) {
#	    while (my $line = (<INPUT>)) {
#	        chomp($line);
#	        $line =~ s/^[\s]*#.*$//;	# Whack comment lines
#	        if (!($line =~ /^ *$/)) {
#		    my @ar = split(/,/,$line);
#		    if ($line =~ "-FTP") {
#			push(@custom_menu_items,
#    		           [ 'command' => "Fetch file (FTP)",
#    			     -command => 
#	                          [\&do_ftp]]);
#		    } elsif ($line =~ "-GENERIC_FTP") {
#			push(@custom_menu_items,
#			   [ 'command' => $ar[1],
#			     -command => [\&do_single_ftp,$ar[1],$ar[2]]]);
#		    } elsif ($line =~ "-MENU_NAME") {
#			$custom_menu_title = $ar[1];
#		    } elsif ($line =~ "-SINGLE_QUOTE") {
#			push(@custom_menu_items,
#			   [ 'command' => "$ar[1] Quote",
#    			     -command => [\&print_single_quote,$ar[1],$ar[2]]]);
#		    } elsif ($line =~ "-STOCK_QUOTE") {
#			push(@custom_menu_items,
#			   [ 'command' => $ar[1],
#    			     -command => \&do_quote]);
#		    } elsif ($line =~ "-PORTFOLIO_QUOTE") {
#			push(@custom_menu_items,
#			   [ 'command' => "$ar[1]",
#    			     -command => [\&print_portfolio,$ar[1],@ar[2..100]]]);
#	  	    } elsif ($line =~ '-SEND_EMAIL') {
#			push(@custom_menu_items,
#			   [ 'command' => "$ar[1]",
#			     -command => [\&do_email]]);
#	  	    } elsif ($line =~ '-FETCH_HEADERS') {
#			push(@custom_menu_items,
#			   [ 'command' => "$ar[1]",
#			     -command => [\&do_fetch_email]]);
#	  	    } elsif ($line =~ '-FETCH_GREENKEYS') {
#			push(@custom_menu_items,
#			   [ 'command' => "$ar[1]",
#			     -command => [\&do_fetch_greenkeys]]);
#	  	    } elsif ($line =~ '-FETCH_ALL') {
#			push(@custom_menu_items,
#			   [ 'command' => "$ar[1]",
#			     -command => [\&do_fetch_all_email]]);
#	            }
#		}
#	    }
#			close(INPUT);
#        }
#		else {
#			local_error("Couldn't open $menu_config");
#		}
#        
#		$oTkFrameMenu->Menubutton(-text=>$custom_menu_title,-tearoff=>0,
#		-menuitems => [@custom_menu_items])->pack(-side=>'left');
#    }

	# Status line     
	$sMainStatus = " - Initialization -";
    $oTkStatus  = $oTkMainWindow->Label(-text=> $sMainStatus, -relief => 'ridge', -height => 2, -justify => 'center', -padx => 0)->pack(-side=>'bottom',-fill=>'x');

 	# Frame for text entry
    my $oTkFrame = $oTkMainWindow->Frame->pack(-side => 'bottom', -fill => 'x');

	# Label, entry box & enter button
	$oTkFrame->Label(-text=> "Enter text here=>")->pack(-side=>'left');
    
    my $oTkInput = $oTkFrame->Entry(-textvariable => \$sInputValue,)->pack(-side=>'left',-anchor => 'w', -fill => 'x', -expand => 1);
	$oTkInput->focus();
	$oTkInput->bind('<Return>' => sub { $sInputValue .= "\n" ; add_text_from_host();});
    
	$oTkFrame->Button(-text => "No <cr>", -command =>\&add_text_from_host)->pack(-side => 'right');

   
	# Text display window	
    $oTkTextarea = $oTkMainWindow->Scrolled('ROText',-setgrid=>'true',-width=>"$aConfigs{Columns}",-height=>'24', -scrollbars=>'se')->pack(-expand=>'yes',-fill=>'both');

	# Init insertion vars
	$sPrinthead = "1.0";
	$cursor_ch = undef;

	# Add pseudo block cursor
	$oTkTextarea->tagConfigure('tagCursor', -background => 'blue', -foreground => 'black');
    
	$oTkTextarea->tagConfigure('tagSent',   -foreground => 'green');
	$oTkTextarea->tagConfigure('tagAction', -foreground => 'red');
	$oTkTextarea->tagRaise('tagAction');

	$oTkTextarea->insert($sPrinthead, " ", 'tagCursor');

}

sub bytes_pending {
    my $BlockingFlags;
    my $InBytes;
    my $LatchErrorFlags;
    my $OutBytes = 0;

    if ($oSerialPort) {
        ($BlockingFlags, $InBytes, $OutBytes, $LatchErrorFlags) = $oSerialPort->{'status'};
    }
    return $OutBytes + length($aSessions[1]->{RAW_IN}) + length($aSessions[1]->{RAW_OUT});
}


#--------------------------------------------------------------------------
# All the action happens here.  Everything else is setting up the
# command arrays to be processed here.
#
# @commands is an array of command_arrays
#     command_arrays contains command_lists ( &funct [, args]* )
#     

sub process_pending_commands {
    my $did_nothing = 1;
    my $bytes_left  = bytes_pending();
    my $reconfig    = 0;
      
    $oTkStatus->configure(-text => "$sMainStatus - Bytes: $bytes_left");

    if ($reconfig) {
		redraw_status_window();
    }

	for (my $i=0;$i < 10;$i++) {
		while ($aSessions[0]->{command} eq '' && $aSessions[0]->{input_type} eq '' && (bytes_pending() == 0 && $sCurrentCommand ne '')){
			$oTkMainWindow->update();
			
			my $idSession = defined $aConfigs{BatchSession} ? $aConfigs{BatchSession} : 0;
			
			if ($aSessions[$idSession]->{echo_input}){
				$aSessions[$idSession]->{OUT} .= $sCurrentCommand . "\n";
				process_host_window();
			}

			process_line(0, $sCurrentCommand);
			
			$sCurrentCommand = '';
			
			$did_nothing = 0;	# Did something
        }

		while ($sCurrentCommand eq '' && (scalar @aCommands != 0)){
			$sCurrentCommand = shift(@aCommands);
			$did_nothing     = 0; # Did something
		}

		if ($did_nothing) {
			last;
		}
	}
    return $did_nothing; # Nothing to do
}

sub display_char { 
    (my $c, my $sTag) = @_;
    
	my $curr_line;
	my $curr_column;
	my $end_line;
	my $end_column;
	
	
	if ($aConfigs{Debug} > 2){ logDebug(' DIS: '. debug_char($c) .' ('.ord($c).')'); }
			
	# Ignore bells
	if ($c eq "\a"){
		return 0;
	}
	
	if ($char_delay) {
		$oTkMainWindow->after($char_delay);
    }

	$oTkTextarea->delete($sPrinthead, "$sPrinthead + 1 char");
	
	if (defined($cursor_ch)) {
		$oTkTextarea->insert("$sPrinthead",$cursor_ch);
		$cursor_ch = undef;
	}
	
	if ($c eq $lf || $c eq $cr || $c eq $bs){
		($curr_line, $curr_column) = split(/\./,$sPrinthead);

		my $tmp_idx = $oTkTextarea->index("$sPrinthead");
		if ($c eq $lf){
			# Line feed
			$curr_line++;
			$tmp_idx = $oTkTextarea->index("$tmp_idx + 1 line");
		}
		elsif ($c eq $cr) {
			# Carriage return
			$curr_column = 0;
		}
		elsif ($c eq $bs) {
			# BackSpace
			$curr_column = $curr_column > 0 ? $curr_column - 1 : 0;
		}

		($end_line, $end_column) = split(/\./,$oTkTextarea->index('end'));
		if ($curr_line == $end_line) {
			$oTkTextarea->insert("$sPrinthead lineend","\n");
		}

		($end_line, $end_column) = split(/\./,$oTkTextarea->index("$tmp_idx lineend"));
		if ($curr_column > $end_column) {
			my $spaces_needed = (($curr_column)-$end_column);
			for ( my $idx = 0;$idx < $spaces_needed; $idx++ ) {
				$oTkTextarea->insert("$tmp_idx lineend"," ");
			}
		}
		
		if ($c eq $lf){
			$sPrinthead = $oTkTextarea->index("$sPrinthead + 1 line");
		}
		elsif($c eq $cr){
			$sPrinthead = $oTkTextarea->index("$sPrinthead linestart");
		}
		elsif($c eq $bs){
			$sPrinthead = $oTkTextarea->index("$sPrinthead - 1 char");
		}
		
	}
	else {
		my $overstrike = $oTkTextarea->get("$sPrinthead","$sPrinthead + 1 char");
		if ($overstrike ne "\n") {
			$oTkTextarea->delete("$sPrinthead","$sPrinthead + 1 char");
		}
		$oTkTextarea->insert("$sPrinthead",$c);
		($curr_line,$curr_column) = split(/\./,$sPrinthead);
		
		# Overstrike simulation
		if ($curr_column < ($aConfigs{Columns} - 1)) {
			$sPrinthead = $oTkTextarea->index("$sPrinthead + 1 char");
		}
	}

	$cursor_ch = $oTkTextarea->get("$sPrinthead","$sPrinthead + 1 char");
	if ($cursor_ch eq "\n") {
		$cursor_ch = undef;
	}
	else {
		$oTkTextarea->delete("$sPrinthead","$sPrinthead + 1 char");
	}
	$oTkTextarea->insert( $sPrinthead , ' ', 'tagCursor' );
}

sub display_line {
	(my $line) = @_;
	my $c;
	foreach $c (split(//,$line)) {
		display_char($c, '');
	}
}


# Main I/O
sub process_pending_io {

    my $res = 1; # Assume nothing to do
    
    # NOTE: With some minor changes (i.e. moving all confs to the session) this would support n TTYs
    
    # SERIAL -> TTY-RAW-IN
    if (!$aConfigs{LoopTest}){
    	$res = process_serial_rawin($res);
    }

	# TTY-RAW-IN -> TTY-IN
	$res = process_rawin_ttyin($res);
	
	# TTY-IN
	$res = process_ttyin($res);

	# WINDOW -> HOST-IN
	$res = process_window_host($res);

	# HOST-OUT -> WINDOW
	$res = process_host_window($res);

	# TTY-OUT -> TTY-RAW-OUT
	$res = process_ttyout_rawout($res);
	
	# TTY-RAW-OUT -> SERIAL
	$res = process_rawout_serial($res);
	
	# TELNET
	if ($aConfigs{TelnetEnabled}){
		telnet_io();
	}
	
	# MSN
	if ($aConfigs{MsnEnabled}){
		msn_io();
	}
	
	return $res;
}



# SERIAL -> TTY RAW-IN
sub process_serial_rawin{
	my ($res)     = @_;
	my $idSession = 1;
	my $c;
	my $n;
	my $sLine;

	if ($oSerialPort){
		if ($sLine = $oSerialPort->input()){
			if ($aConfigs{Debug} > 2){ 
				for ($n = 0; $n < length($sLine); $n++){
					$c = substr($sLine, $n, 1);
					logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'SERIAL','RAW_IN', ord($c), debug_char($c, 1), $aConfigs{LoopCode}));
				}
			}
			
			$aSessions[$idSession]->{RAW_IN} .= $sLine; 
			
			$res = 0;
		}
	}

	return $res;
}


# TTY RAW-IN -> TTY IN
sub process_rawin_ttyin{
	my ($res)     = @_;
	my $idSession = 1;
	my $c;
	my $d;
	my $sEscape = '';
	
	my $thisSession = $aSessions[$idSession];
	
	while (length($thisSession->{RAW_IN}) > 0){
		$c = substr($thisSession->{RAW_IN} , 0 , 1, '');
		
		if ($aConfigs{Debug} > 2){ 
			my $nSup = length($thisSession->{'SUPPRESS'}) ? ord(substr($thisSession->{'SUPPRESS'}, 0, 1)) : '';
			logDebug(sprintf("\n%-8s -> %-8s %03d %3s S:%3s ", 'RAW_IN','TTY-IN', ord($c), debug_char($c, 1), $nSup)); 
		}
		
		if (length($thisSession->{'SUPPRESS'}) > 0 && $c eq substr($thisSession->{'SUPPRESS'}, 0, 1)) {
			if ($aConfigs{Debug} > 2){ logDebug('Supp '); }
			substr($thisSession->{'SUPPRESS'}, 0, 1, '');
		}
		else{
			$thisSession->{rx_last} = time();
			$thisSession->{rx_count}++;
			
			# If we have echo then we add it here
			if ($thisSession->{echo_input}){
				$thisSession->{RAW_OUT} .= $c;
				#if ($thisSession->{'loop_suppress'}){ 
				if ($aConfigs{LoopSuppress}){
					$thisSession->{'SUPPRESS'} .= $c;	
				}
			}

			if ($aConfigs{LoopCode} eq "ASCII" ) {
				$d = $c;
			}
			else {
				# TRANSCODE BAUDOT->ASCII
				if ($c eq $ltrs || $c eq $figs) {
					$rcv_shift = $c;
				}
				elsif ($c eq $space && $aConfigs{UnshiftOnSpace}){
					$rcv_shift = $ltrs;
				}
				if ($rcv_shift eq $ltrs) {
					$d = $CODES{$aConfigs{LoopCode}}->{'FROM-LTRS'}->{$c}
				}
				else {
					$d = $CODES{$aConfigs{LoopCode}}->{'FROM-FIGS'}->{$c}
					#$d = $from_figs_tab->{$c};
				}
				if (!defined($d)) {
					$d = $host_no_match_char;
				}
			}
			if ($thisSession->{'lowercase_lock'}){ 
				$d = lc($d); 
			}
			
			$thisSession->{IN} .= $d; 
			
			# Keep track of the column
			if ($d eq $cr){
				$thisSession->{column} = 0;
			}
			elsif($d ne $lf && $d ne $nul && $d ne $si && $d ne $so){
				$thisSession->{column}++;
			}
		}
	}
	return $res;
}


# Process TTY IN (Session 1)
sub process_ttyin{
	my ($res)     = @_;
	my $idSession = 1;
	my $n;
	my $sLine;
	my $nPos;
	
	my $thisSession = $aSessions[$idSession];
	
	if (length($thisSession->{IN}) > 0 && ($nPos = index($thisSession->{IN}, "\n")) >= 0){
		while ($nPos >= 0){
			$sLine = substr($thisSession->{IN}, 0, $nPos);
			$sLine =~ s/\r+$//;
			
			$thisSession->{IN} = substr($thisSession->{IN}, $nPos+1);
			
			if ($aConfigs{Debug} > 1){ logDebug("\nTTY-IN: $sLine"); }

			# Decode escape sequences TO ASCII
			if ($aConfigs{EscapeEnabled} && index($sLine, $aConfigs{EscapeChar}) >= 0){
				$sLine = escape_to_ascii($idSession, $sLine);
			}
			
			# Process backspaces
			while (($n = index($sLine, $bs)) >= 0){
				substr($sLine, $n - 1, 2, '');
			}
			
			# Detect and execute commands or send message
			process_line($idSession, $sLine);

			# Get the next position for the while loop
			$nPos = index($thisSession->{IN}, "\n");
		}
	}
	return $res;
}

# RAW-OUT -> SERIAL
sub process_rawout_serial{
	my ($res)     = @_;
	my $idSession = 1;
	my $c;
	my $d;
	my $sEscape = '';
	
	my $thisSession = $aSessions[$idSession];

	if (length($thisSession->{RAW_OUT}) == 0){
		if ($thisSession->{input_type} eq 'OUT-EMPTY'){
			# Detect and execute commands once the OUT buffer is empty
			process_line($idSession, '');
		}
	}
	else{
		# If the IN buffer is empty, then send immediately
		# If isn't empty, but it has been idle for 60 secs, then send anyway
		if ($aConfigs{RunInProtect} == 0 || length($thisSession->{IN}) == 0 || (time() - $thisSession->{rx_last}) > $aConfigs{RunInProtect}){
			
			# Runin protect for TTY implies:
			# 1- Prepending a new line
			# 2- Output the OUT buffer, which "should" end with a new line (Note, we should detect this and append a newline if not)
			# 3- Output the IN buffer and end with the correct shift
			# Note: We use a counter to avoid sending a newline with every processed byte
			# !!! I had to remove here a column check, because I realizad that the column count is being done in the wrong place
			if ($aConfigs{RunInProtect} > 0 && length($thisSession->{IN}) > 0 &&  $thisSession->{runin_count} == 0){ #$thisSession->{column} > 0 &&
				#$thisSession->{runin_count} = $thisSession->{rx_count};
				if ($aConfigs{LoopCode} eq "ASCII") {
					$thisSession->{RAW_OUT} = $ascii_end_of_line . $thisSession->{RAW_OUT} . $thisSession->{IN};
				}
				else{
					$thisSession->{RAW_OUT} = $end_of_line . $thisSession->{RAW_OUT} . transcode_to_loop($thisSession->{IN}).$rcv_shift;
				}
				$thisSession->{runin_count} = length($thisSession->{RAW_OUT});
			}
			
			# Loop and output characters
			while (length($thisSession->{RAW_OUT}) > 0){
				$c = substr($thisSession->{RAW_OUT} , 0 , 1, '');
				if ($thisSession->{runin_count} > 0){
					$thisSession->{runin_count}--;
				}
	
				if ($aConfigs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'RAW_OUT','SERIAL', ord($c), debug_char($c, 1))); }
	
	
				if (defined $c){
		
					
		
					# For testing we do absolutely everything just like we would do with a regular setup, and we only 
					# avoid the serial output. At that point instead we simply copy the OUTPUT into the INPUT
					if ($aConfigs{LoopTest}){
						$thisSession->{RAW_IN}.= $c;
						
						# If enabled we add to the SUPRESS buffer
						#if ($thisSession->{loop_suppress}){
						if ($aConfigs{LoopSuppress}){
							$thisSession->{SUPPRESS} .= $c;	
						}

					}
					else{
						# Note: !!! If we don't have a working serial port, we should raise some error... no?
						#       Right now, data will be simply lost
						if ($oSerialPort){
							if ($oSerialPort->write( $c )) {
								
								# If enabled we add to the SUPRESS buffer
								#if ($thisSession->{loop_suppress}){
								if ($aConfigs{LoopSuppress}){
									$thisSession->{SUPPRESS} .= $c;	
								}

								if (!$bWindows) {
									# !!! Is this really needed? And here?
									my $a = 0;
									while (!$oSerialPort->write_drain()){;}
								}
								
								# Note: We process only one character per loop to avoid the program become unresponsive
								# If we would want to proccess more bytes at once, we would add a condition with a counter
								last;
							}
							else{
								logDebug("\nERROR: Cannot write to port, dropping character ".ord($c));
							}
						}
						else{
							logDebug("\nERROR: No open port, dropping character ".ord($c));
						}
					}
				}
				
			}
		}
	}
	return $res;
}


# TTY-OUT -> RAW-OUT (TRANSCODE OUT)
sub process_ttyout_rawout{
	my ($res)     = @_;
	my $idSession = 1;
	my $c;
	my $d;
	my $sEscape = '';
	
	my $thisSession = $aSessions[$idSession];
	
	if (length($thisSession->{OUT}) > 0){
		$res = 0;
		if ($aConfigs{X10Auto} && ($x10_motor_state == 0)) {
			x10_on();
			sleep(2);
			$x10_motor_state = 1;
		}

		# RAWMODE OFF
		if (!$thisSession->{'raw_mode'}){
					
			if ($aConfigs{LoopCode} ne "ASCII") {
				$thisSession->{RAW_OUT} .= $ltrs;
			}

			while (length($thisSession->{OUT}) > 0){
				
				$c = substr($thisSession->{OUT} , 0 , 1, '');
				$d = undef;
			
				if ($aConfigs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'TTY-OUT','RAW_OUT', ord($c), debug_char($c))); }

				if ($CODES{$aConfigs{LoopCode}}->{upshift}) {
					$c = uc($c);
				}
				
				
				# PROCESS ASCII LOOP
				if ($aConfigs{LoopCode} eq "ASCII" ) {
					if ($c eq $lf && $xlate_lf){
						$d = $ascii_end_of_line;
					}
					elsif ($c eq $cr && $xlate_cr) {
						$d = $ascii_end_of_line;
					}
					else {
						$d = $c;
					}
				}
				# PROCESS OTHER ENCODINGS
				else {
	
					# DETECT ESCAPE SEQUENCES
					if ($sEscape eq ''){
						if ($c eq $aConfigs{EscapeChar}){	
							# Escape start detected
							$sEscape .= $c;
							$c = undef;
						}
					}
					else{
						if ($c =~ /^\w$/){
							# Sequence continues
							$sEscape .= $c;
							$c = undef;
						}
						else{
							# End of escape sequence
							$d = $aEscapeCharsDecodeITA{substr($sEscape, 1)};
							if (defined $d){
								# Add it back to the first character
								if ($c ne ' '){
									$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
								}
							}
							# Special action commands !!! experimental
							elsif(uc($sEscape) eq $aConfigs{EscapeChar}.'OVERSTRIKEOFF'){
								$thisSession->{'overstrike_protect'}= 0;
								$d = '';
								# Add it back to the first character
								if ($c ne ' '){
									$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
								}

								last;
							}
							elsif(uc($sEscape) eq $aConfigs{EscapeChar}.'OVERSTRIKEON'){
								$thisSession->{'overstrike_protect'}= 1;
								$d = '';
								# Add it back to the first character
								if ($c ne ' '){
									$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
								}

								last;
							}
							elsif(uc($sEscape) eq $aConfigs{EscapeChar}.'RAWMODEON'){
								$thisSession->{'raw_mode'} = 1;
								$d = '';
								# Add it back to the first character
								if ($c ne ' '){
									$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
								}

								last;
							}
							else{
								# Wasn't a real escape, lets return it to the buffer
								$thisSession->{OUT} = substr($sEscape, 1) .$c. $thisSession->{OUT};
								$c = substr($sEscape, 0, 1);
							}
	
							$sEscape = '';
						}
					}
	
					if (!defined($d)){
						# TRANSCODE ASCII->BAUDOT
						if (defined $c){
							if ($c eq "\n"){
								$d = $end_of_line;
								$xmit_shift = $ltrs;
							}
							elsif (exists($CODES{$aConfigs{LoopCode}}->{'TO-LTRS'}->{$c})) {
								if ($xmit_shift eq $figs) {
									$thisSession->{RAW_OUT} .= $ltrs;
									$xmit_shift = $ltrs;
								}
								$d = $CODES{$aConfigs{LoopCode}}->{'TO-LTRS'}->{$c}
							}
							elsif (exists($CODES{$aConfigs{LoopCode}}->{'TO-FIGS'}->{$c})) {
								if ($xmit_shift eq $ltrs) {
									$thisSession->{RAW_OUT} .= $figs;
									$xmit_shift = $figs;
								}
								$d = $CODES{$aConfigs{LoopCode}}->{'TO-FIGS'}->{$c}
							}
							else {
								$d = undef;
							}
							
							$d = defined($d) ? $d : $loop_no_match_char;
						}
						else{
							$d = undef;
						}
					
					
					
					}
					
				}
				
				
				if (defined $d){
					# Append to the loop
					$thisSession->{RAW_OUT} .= $d;
					
					# Protect from overstrike
					if ($aConfigs{LoopCode} eq "ASCII"){
						if (index($d, $cr) >= 0){
							$thisSession->{column} = 0;
						}
						elsif ($c eq $lf){
		
						}
						elsif (length($d) > 0){
							# We should be checking each character here, not assuming there is only one.
							# This is not a problem now because escaped characters are always of length 1, but in the future, 
							# longer escape sequences may come
							$thisSession->{column}++;
							if ($thisSession->{overstrike_protect} && $thisSession->{column} >= $aConfigs{Columns}){
								$thisSession->{RAW_OUT} .= $ascii_end_of_line;
								$thisSession->{column} = 0;
							}
						}
					}
					else{
						if (index($d, $b_cr) >= 0){
							$thisSession->{column} = 0;
						}
						elsif ($c eq $b_lf){
		
						}
						elsif (length($d) > 0){
							$thisSession->{column}++;
							if ($thisSession->{overstrike_protect} && $thisSession->{column} >= $aConfigs{Columns}){
								$thisSession->{RAW_OUT} .= $end_of_line;
								$xmit_shift = $ltrs;
								$thisSession->{column} = 0;
							}
						}
					}
				}


				$res = 0;
			}
		}
		# Raw Mode
		else{
			
			$sEscape = '';
			while (length($thisSession->{OUT}) > 0){
				
				$c = substr($thisSession->{OUT} , 0 , 1, '');
				$d = undef;
			
				if ($aConfigs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s %s", 'TTY-OUT','RAW_OUT', ord($c), debug_char($c), 'RAW')); }

				# DETECT ESCAPE SEQUENCES
				if ($sEscape eq ''){
					if ($c eq $aConfigs{EscapeChar}){	
						# Escape start detected
						$sEscape .= $c;
						$c = undef;
					}
				}
				else{
					if ($c =~ /^\w$/){
						# Sequence continues
						$sEscape .= $c;
						$c = undef;
					}
					else{
						# End of escape sequence
						$d = $aEscapeCharsDecodeITA{substr($sEscape, 1)};
						if (defined $d){
							# Add it back to the first character
							if ($c ne ' '){
								$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
							}
						}
						# Special action commands !!! experimental
						elsif(uc($sEscape) eq $aConfigs{EscapeChar}.'RAWMODEOFF'){
							$thisSession->{'raw_mode'} = 0;
							$d = '';
							# Add it back to the first character
							if ($c ne ' '){
								$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
							}

							last;
						}
						else{
							# Wasn't a real escape, lets return it to the buffer
							$thisSession->{OUT} = substr($sEscape, 1) .$c. $thisSession->{OUT};
							$c = substr($sEscape, 0, 1);
						}

						$sEscape = '';
					}
				}

				if (!defined($d)){
					$thisSession->{RAW_OUT} .= $c;
				}
				else{
					$thisSession->{RAW_OUT} .= $d;
				}
				
				if (0 && $c eq $nul && $thisSession->{'raw_mode'} > 0){
					# Should be reset back when a non null is received
					$thisSession->{'raw_mode'}--;
					if ($thisSession->{'raw_mode'} < 1){
						last;
					}
				}
			}
		}
	}
		
	return $res;
}


# Process WINDOW -> HOST IN (Session 0)
sub process_window_host{
	my ($res)     = @_;
	my $idSession = 0;
	my $nPos;
	my $sLine;
	
	my $thisSession = $aSessions[$idSession];
	
	if (length($aSessions[0]->{IN}) > 0 && ($nPos = index($aSessions[0]->{IN}, "\n")) >= 0){
		while ($nPos >= 0){
			$sLine = substr($thisSession->{IN}, 0, $nPos + 1, '');
			
			chomp($sLine);
			$sLine =~ s/\r+$//;

			if ($aConfigs{Debug} > 1){ logDebug("\nHOST-IN: $sLine"); }
			
			# Decode escape sequences TO ASCII
			if ($aConfigs{EscapeEnabled} && index($sLine, $aConfigs{EscapeChar}) >= 0){
				$sLine = escape_to_ascii($idSession, $sLine);
			}

			if ($thisSession->{echo_input}){
				$thisSession->{OUT} .= $sLine . "\n";
				$res = process_host_window($res);
			}

			# Detect and execute commands or send message
			process_line($idSession, $sLine);

			# Get the next position for the while loop
			$nPos = index($thisSession->{IN}, "\n");
		}
	}
	return $res;
}



# Process HOST OUT (Session 0) -> WINDOW
sub process_host_window{
	my ($res)     = @_;
	my $idSession = 0;

	my $thisSession = $aSessions[$idSession];

	if (length($thisSession->{OUT}) == 0){
		if ($thisSession->{input_type} eq 'OUT-EMPTY'){
			# Detect and execute commands once the OUT buffer is empty
			process_line($idSession, '');
		}
	}
	else{
		my $nCount = 0;
		
		while (length($thisSession->{OUT}) > 0){
			my $c = substr($thisSession->{OUT} , 0 , 1, '');
			$nCount++;
			
			if ($aConfigs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s %02d ", 'HOST-OUT','WINDOW', ord($c), debug_char($c), $thisSession->{column})); }
			
			if ($c ne $nul){
				
				# Protect from overstrike
				if ($c eq $cr){
					$thisSession->{column} = 0;
				}
				elsif ($c eq $lf){
					if ($thisSession->{column} > 0){
						$thisSession->{column} = 0;
						display_char($cr, '');
					}
				}
				elsif($c ne "\a"){
					$thisSession->{column}++;
					if ($thisSession->{column} >= $aConfigs{Columns}){
						$thisSession->{column} = 0;
						display_char($cr, '');
						display_char($lf, '');
					}
				}
				
				# Display character
				display_char($c, '');
	
				
				$res = 0;
			}
			# We stop here to avoid the program becoming unresponsive
			if ($nCount > 100){
				last;
			}
		}
		$oTkTextarea->see('end');
	}
	return $res;
}





sub main_loop {

	my $io_bored  = (process_pending_io() && (bytes_pending() == 0));

	my $cmd_bored = process_pending_commands();

	my $bored     = ($io_bored && $cmd_bored);

	if ($bCancelSleep) {
		$nTimerSleep  = 0;
		$nSleepRepeat = 0;
		$nSleep       = 0;
		$bCancelSleep = 0;
	}

	if ($bored && $nTimerSleep == 0 && $nSleep > 0) {
		$nTimerSleep = time() + $nSleep;
		$nSleep = 0;
	}
	elsif ($bored && $nTimerSleep == 0 && $nSleepRepeat > 0) {
		$nTimerSleep = time() + $nSleepRepeat;
	}
	elsif ($bored && $nTimerSleep > 0 && time() > $nTimerSleep){
		push(@aCommands, $aSessions[0]->{command_last});
		$nTimerSleep = 0;
		if ($nSleepRepeat > 0){
			$nTimerSleep = time() + $nSleepRepeat;
		}
	}
#	elsif ($bored && ($aConfigs{BatchMode} || $aConfigs{X10Auto})) {
#		if ($batchmode_countdown-- < 0) {
#			if ($aConfigs{X10Auto} && ($x10_motor_state == 1)) {
#				x10_off();
#				$x10_motor_state = 0;
#			}
#			if ($aConfigs{BatchMode}) {
#				exit(0);
#			}
#		}
#	}
#	else {
#		$batchmode_countdown = $batchmode_countdown_delay;
#	}

	if ($nShutDown > 0){
		if ($aConfigs{MsnEnabled}){
			my $nCountPendingMsn = 0;
			foreach my $thisSession (@aSessions){
				if ($thisSession->{'status'} && $thisSession->{'type'} eq 'MSN' && $thisSession->{OUT} ne ''){
					$nCountPendingMsn++;
				}
			}
			if ($nCountPendingMsn == 0){
				if ($aConfigs{Debug} > 0){ logDebug("\nDisconnecting from MSN\n"); }
				$oMSN->disconnect();
				$aConfigs{MsnEnabled} = 0;
			}
		}
		
		if (time() > $nShutDown){
			print "\nShutdown complete! Bye Bye!";
			$oTkMainWindow->destroy();
		}
	}

	$oTkMainWindow->after($polltime, \&main_loop);
}


# This wil handle clean exits from CTRL-C
sub main_exit{
	$nShutDown = 1;
}

#---------------------------------------------------------------------------
# Edit commands
#---------------------------------------------------------------------------
# !!! fix this
sub paste {
	if ($oTkTextarea->tagRanges('sel')){
		my $p_txt = $oTkTextarea->get('sel.first' , 'sel.last');	
		if (defined $p_txt) {
			#text_host_in_no_cr($p_txt);
		}
	}
}

sub select_all {
    $oTkTextarea->tagAdd( "sel" , '1.0' , 'end - 2 chars' );
}

#---------------------------------------------------------------------------
# File commands
#---------------------------------------------------------------------------
sub do_load_file {
  my $res = "";
  my $filebox = $oTkMainWindow->FileSelect(-directory=>'.');
  my $filename = $filebox->Show;
  if (defined ($filename)) {
     if (!open(FH,"$filename")) {
       local_warning("Could not open $filename for reading\n");
     } else {
       $res = join("",<FH>);
       close (FH);
     }
  }
  return $res;
}

sub do_x10_on {
#    push (@commands, \@x10_on_batch);
}

sub do_x10_off {
#    push (@commands, \@x10_off_batch);
}

sub x10_on {
    x10_send($oSerialPort,"$aConfigs{X10House}$aConfigs{X10Device}J");
}

sub x10_off {
    x10_send($oSerialPort,"$aConfigs{X10House}$aConfigs{X10Device}K");
}

sub do_save_file {
  (my $input_str) = @_;
  my $filebox = $oTkMainWindow->FileSelect(-directory=>'.');
  my $filename = $filebox->Show;
  if (defined ($filename)) {
     if (!open(FH,">$filename")) {
       local_warning("Could not open $filename for writing\n");
     } else {
       print FH $input_str;
       close (FH);
     }
  }
}

sub do_saveconfig {
	if (!open(CONFIG, ">$config_file")) {
		local_warning("Could not open heavymetal.cfg for writing\n");
	}
	else {
		foreach my $sVar (sort keys %aConfigs) {
			print CONFIG "-$sVar=$aConfigs{$sVar}\n";
		}
		#print CONFIG "--SERIALINIT\n";
		close (CONFIG);
	}
}



sub save_file {
    do_save_file( $oTkTextarea->get( '1.0','end - 2 chars' ));
}                                                               


sub save_file_raw {
    do_save_file( $loop_archive );
}

sub add_text_from_host {
	my ($sLine) = @_;
	
	if (defined $sLine){
		$aSessions[0]->{IN} .= $sLine."\n";
		if ($aConfigs{Debug}){ logDebug("\nCMD->HOST: $sLine\n"); }
	}
	elsif($sInputValue ne ''){
		if ($aConfigs{Debug}){ logDebug("\nINPUT->HOST: $sInputValue\n"); }
		$aSessions[0]->{IN} .= $sInputValue;
		$sInputValue = '';
	}
}

#---------------------------------------------------------------------------
# Util
#---------------------------------------------------------------------------
sub do_about {
	my $dialog_about = $oTkMainWindow->Dialog(
		-title   => 'About HeavyMetal',
		-width   => 35,
		-bitmap  => 'info',
		-default_button => $ok,
		-buttons => [$ok],
		-text    =>  "Version $sGlobalVersion ($sGlobalRelease)\n\nHeavyMetal is a simple application to interface teletype machines to computers and the internet.\n\nInitially made by Bill Buzbee - Oct 2005\n\nCompletely rewritten into v3.0 by Javier Albinarrate LU8AJA - May 2010\n\nSee:\n http://lu8aja.com.ar/heavymetal.html\n http://github.com/lu8aja/HeavyMetal"
	);

	$dialog_about->configure(
		
    );
    
	my $res = $dialog_about->Show;
}

sub do_repeat {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';

	if (defined $aArgs[0]){
		$nSleepRepeat = int($aArgs[0]);
	}
	else{
    	$nSleep = 1;
	}
    return '';
}

sub do_sleep {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';

    $nSleep = int($aArgs[0]);
    return '';
}


sub load_batch_file {
	(my $sFile) = @_;
	my @batch;
	
	if (open (INPUT, "<$sFile")) {
		while (my $sLine = (<INPUT>)) {
			chomp($sLine);
			push(@batch, $sLine);
		}
		close(INPUT);
	}
	else {
		local_error("Couldn't open $sFile\n");
	}
	process_batch(@batch);
}

sub process_cmdline {
	process_batch(@ARGV);
}


sub process_batch{
	my @batch = @_;
	
	my $sCmdline;
	my $sCmd;
	my $sArgs;
	
	while ($sCmdline = shift(@batch)){
		$sCmd  = $sCmdline;
		$sArgs = '';
		if ($sCmd =~ /=/){
			($sCmd, $sArgs) = split(/=/, $sCmd, 2);
		}
		
		if (uc($sCmd) eq '--BATCH'){
			if ($sArgs){
				load_batch_file($sArgs);
			}
			else{
				print "-- Warning: Missing batch filename";
			}
		}
		elsif ($sCmd =~ /^\-\-/){
			$sCmd = uc(substr($sCmd, 2));
		}
		elsif($sCmd =~ /^\-/){
			$sCmd  =~ s/[^\w\.]//g; # If we don't do this, we might break the call to do_setvar if we receive trash
			$aConfigs{$sCmd} = $sArgs;
			#$sArgs = $sCmd.' '.$sArgs;
			#$sCmd  = 'CONFIG';
			$sCmd = '';
		}
		else{
			$sCmd = '';
			# Should we ignore the command?
			print "-- Unknown cmdline: $sCmdline\n";
		}
		
		if ($sCmd){
			if (exists $aActionCommands{$sCmd}){
				push(@aCommands, $aConfigs{EscapeChar}.$sCmd.' '.$sArgs);
			}
			else{
				print "-- Unknown command: $sCmdline\n";
			}
		}
	}
}


sub redraw_status_window {
	if (defined($oTkStatus)) {
		my $nStopBits;
		my $pseudo_wpm = int($nGlobalWPM);

		if ($pseudo_wpm == 98){
			$pseudo_wpm = 100;
		}
		if (($nStopBits = $aConfigs{SerialStop}) != 1) {
			$nStopBits = ($aConfigs{SerialWord} == 5) ? 1.5 : 2;
		}
			
		my $mode = ($aConfigs{LowercaseLock}) ? "On" : "Off";
		
		$sMainStatus  = "";
		
		$sMainStatus .= $aConfigs{TelnetEnabled} ? "Telnet: ON $aConfigs{TelnetPort} - " : 'Telnet: OFF - ';
		
		$sMainStatus .= $aConfigs{MsnEnabled} ? "MSN: $aConfigs{MsnUsername} - " : 'MSN: OFF - ';
		
		(my $nInbound, my $nOutbound) = session_count();
		$sMainStatus .= "Sessions In: $nInbound - Session Out: $nOutbound";
		
		$sMainStatus .= "\n";
		
		$sMainStatus .= "LC lock:$mode - Code:$aConfigs{LoopCode} - ";
		
		if ($oSerialPort) {
			$sMainStatus .= "Port:$aConfigs{SerialPort} - WPM:$pseudo_wpm - B:$nGlobalBaud - S:$nStopBits - W:$aConfigs{SerialWord} - P:".uc(substr($aConfigs{SerialParity}, 0, 1));
		}
		else {
			$sMainStatus .= "*Port Error:$aConfigs{SerialPort}*";
		}

		$oTkStatus->configure(-text => $sMainStatus, -justify => 'center');
	}

}



sub local_error {
	(my $error_msg) = @_;

	if ($aConfigs{Debug}){ logDebug("ERROR: $error_msg\n");}
	
	message_send('SYS', 0, "-- ERROR: $error_msg"); 
	if ($aConfigs{DebugShowErrors}){
		if ($aConfigs{RemoteMode}){
			
		}
		elsif (defined $oTkMainWindow) {
			$oTkMainWindow->Dialog(
				-title   => 'Error',
				-text    =>  "$error_msg",
				-bitmap  => 'error',
				-buttons => ['OK'],
			)->Show;
		}
	}
}

sub local_warning {
	(my $error_msg) = @_;

	if ($aConfigs{Debug}){ logDebug("Warning: $error_msg\n");}

	message_send('SYS', 0, "-- Warning: $error_msg"); 

	if ($aConfigs{DebugShowErrors}){
		if ($aConfigs{RemoteMode}) {
			
		}
		else {
			if (defined $oTkMainWindow) {
				$oTkMainWindow->Dialog(
					-title   => 'Warning',
					-text    =>  "$error_msg",
					-bitmap  => 'error',
					-buttons => ['OK'],
				)->Show;
			}
		}
	}
}

#---------------------------------------------------------------------------
# Init 
#---------------------------------------------------------------------------


sub initialize_loop {
    redraw_status_window();
}

sub serial_uart_init {

	if ($oSerialPort) {

		my $nStopBits = ( $aConfigs{SerialStop} == 1 ) ? 1 : ( $aConfigs{SerialWord} == 5) ? 1.5 : 2;
    
		$nGlobalBaud = int( (1843200/16) / $aConfigs{SerialDivisor} );

		# To avoid some conflicts, first reset port to innocuous state
		$oSerialPort->stopbits(1);
		$oSerialPort->databits(8);
		$oSerialPort->parity("none");
		$oSerialPort->baudrate(38400);

		# Now, set to desired values.  Must do word size before stop bits
		if ($aConfigs{SerialSetserial}){
			$oSerialPort->baudrate(38400)	|| local_error("Failed setting baudrate 38400");
		}
		else {
			$oSerialPort->baudrate($nGlobalBaud)	|| local_error("Failed setting baudrate $nGlobalBaud");
		}
		
		$oSerialPort->parity($aConfigs{SerialParity})	|| local_error("Failed setting parity $aConfigs{SerialParity}");
		$oSerialPort->databits($aConfigs{SerialWord})	|| local_error("Failed setting word size $aConfigs{SerialWord}");

		my $nStopBitsReal = $nStopBits;
		if (!$bWindows) {
			$nStopBitsReal = ($nStopBits == 1.5) ? 2 : $nStopBits;
		}
		$oSerialPort->stopbits($nStopBitsReal) || local_error("Failed setting stopbits $nStopBitsReal");
		$oSerialPort->handshake("none")	       || local_error("Failed setting handshake");
		$oSerialPort->write_settings()         || local_error("Failed to write settings");

		$nGlobalWPM = (($nGlobalBaud / ($aConfigs{SerialWord} + $nStopBits + 1)) * 60) / 6;

		print "OJO! $aConfigs{SerialPort}\n\n";
		if ($aConfigs{SerialSetserial}) {	
			if ($bWindows) {
				print "OJO! $aConfigs{SerialPort}\n\n";
				if (!defined($aPortAddresses{ $aConfigs{SerialPort} })) {
					local_error("Invalid port name - $aConfigs{SerialPort}");
				}
				else {
					my $cmdline;
					if ($bWindows98) {
						$cmdline="setdiv $aConfigs{SerialAddress} $aConfigs{SerialDivisor}";
					}
					else {
						$cmdline="allowio /a \"setdiv $aConfigs{SerialAddress} $aConfigs{SerialDivisor}\"";
					}
					print $cmdline."\n";
					my $res = `$cmdline`;
					print $res."\n";
				}
			} 
			else {
				my $res = `setserial $aConfigs{SerialPort} spd_cust divisor $aConfigs{SerialDivisor} 2>&1`;
				if (length($res)) {
					$oSerialPort = 0;
				}
			}
		}
	}

	redraw_status_window();
}




sub serial_init_with_address{
	# We guess the address
	
	if ($aConfigs{SerialPort}){
		$aConfigs{SerialAddress} = $aPortAddresses{ $aConfigs{SerialPort} };
		serial_init();
	}
	else{
		$aConfigs{SerialAddress} = 0;
		if ($oSerialPort) {
			serial_close();
		}

	}
}

sub serial_init{
	
	if ($aConfigs{Debug}) { logDebug("\nInitializing serial port $aConfigs{SerialPort}");}
	
	if ($oSerialPort) {
		serial_close();
	}

	if ($aConfigs{SerialPort}){
		serial_open();
		
		if ($oSerialPort) {
	
			my $nStopBits = ( $aConfigs{SerialStop} == 1 ) ? 1 : ( $aConfigs{SerialWord} == 5) ? 1.5 : 2;
	    
			$nGlobalBaud = int( (1843200/16) / $aConfigs{SerialDivisor} );
	
			# to avoid some conflicts, first reset port to innocuous state
			$oSerialPort->stopbits(1);
			$oSerialPort->databits(8);
			$oSerialPort->parity("none");
			$oSerialPort->baudrate(38400);
	
			# now, set to desired values.  Must do word size before stop bits
			if ($aConfigs{SerialSetserial}) {
				#$oSerialPort->baudrate(38400)	|| local_error("Failed setting baudrate 38400");
			}
			else {
				$oSerialPort->baudrate($nGlobalBaud)	|| local_error("Failed setting baudrate $nGlobalBaud");
			}
			
			$oSerialPort->parity($aConfigs{SerialParity})	|| local_error("Failed setting parity $aConfigs{SerialParity}");
			$oSerialPort->databits($aConfigs{SerialWord})	|| local_error("Failed setting word size $aConfigs{SerialWord}");
	
			my $nStopBitsReal = $nStopBits;
			if (!$bWindows) {
				$nStopBitsReal = ($nStopBits == 1.5) ? 2 : $nStopBits;
			}
			$oSerialPort->stopbits($nStopBitsReal) || local_error("Failed setting stopbits $nStopBitsReal");
			$oSerialPort->handshake("none")        || local_error("Failed setting handshake");
			$oSerialPort->write_settings()         || local_error("Failed to write settings");
	
			$nGlobalWPM = (($nGlobalBaud / ($aConfigs{SerialWord} + $nStopBits + 1)) * 60) / 6;
	
			if ($aConfigs{SerialSetserial}) {	
				if ($bWindows) {
					if (!defined($aPortAddresses{ $aConfigs{SerialPort} })) {
						local_error("Invalid port name - $aConfigs{SerialPort}");
					}
					else {
						my $cmdline;
						if ($bWindows98) {
							$cmdline="setdiv $aConfigs{SerialAddress} $aConfigs{SerialDivisor}";
						}
						else {
							$cmdline="allowio /a \"setdiv $aConfigs{SerialAddress} $aConfigs{SerialDivisor}\"";
						}

						#print $cmdline."\n";
						my $res = `$cmdline`;
						#print $res."\n";

					}
				} 
				else {
					my $res = `setserial $aConfigs{SerialPort} spd_cust divisor $aConfigs{SerialDivisor} 2>&1`;
					if (length($res)) {
						$oSerialPort = 0;
					}
				}
			}
		}
	}
	else{
		$aConfigs{SerialAddress} = 0;
	}
	redraw_status_window();
}


sub serial_open {
	if ($aConfigs{Debug}) { logDebug("\nOpening port $aConfigs{SerialPort}\n");}

	if ($bWindows) { 
		$oSerialPort = Win32::SerialPort->new($aConfigs{SerialPort},1);
	}
	else {
		$oSerialPort = Device::SerialPort->new($aConfigs{SerialPort});
		if ($oSerialPort) {
			my $res = `setserial $aConfigs{SerialPort} spd_cust divisor $aConfigs{SerialDivisor} 2>&1`;
		}
	}
	if ($oSerialPort){
		$aSessions[1]->{status} = 1;
	}
	else{
		local_error("Failed open port $aConfigs{SerialPort}");
		if ($aConfigs{Debug}) { logDebug("ERROR: Could not open serial port $aConfigs{SerialPort}\n");}
		$aSessions[1]->{status} = 0;
	}
}

sub serial_close{
	if ($oSerialPort) {
		$oSerialPort->close();
		$oSerialPort = undef;
		if ($aConfigs{Debug}) { logDebug("\nClosed serial port\n");}
	}
	$aSessions[1]->{status} = 0;
}




#-----------------------------------------------------------------------
# Input handling
#-----------------------------------------------------------------------


sub command_start{
	my ($idSession, $sCommand, $sTitle) = @_;

	$aSessions[$idSession]->{command} = $sCommand;
	
	if (defined $sTitle){
		if ($aSessions[$idSession]->{command_calls} == 0){
			message_deliver('SYS', $idSession, "-- CMD: $sTitle --", 0, 1, 1);
		}
		$oTkStatus->configure(-text=> "-- CMD: $sTitle --");
	}

	return $aSessions[$idSession]->{command_calls}++;
}

# For now this is only used for interactive commands
sub command_done{
	my ($idSession, $sText) = @_;
	
	if (defined $sText){
		$sText .= "\n";
		if ($aSessions[$idSession]->{prompt}){
			$sText .= $aConfigs{SystemPrompt};
		}
	
		message_deliver('SYS', $idSession, $sText, 1, 1, 1);
	}

	$aSessions[$idSession]->{command} = '';
	
	return 0;
}

sub command_input{
	my ($idSession, $sVar, $sType, $sValue, $sValidate, $sPrompt, $sCommand) = @_;

	my $sReturn  = '';
	my $bInvalid = 0;
	my $bAbort   = 0;

	# We have an input arg	
	if ($sValue ne ''){
		# Check if we have to abort
		$sReturn = $sValue;
		if ($sReturn =~ /\Q$aConfigs{EscapeChar}\Edel\s*$/i){
			$sReturn  = '';
		}
		elsif ($sReturn =~ /\Q$aConfigs{EscapeChar}\E(abort|cancel)\s*$/i){
			$sReturn  = '';
			$bAbort   = 1;
		}
		elsif ($sValidate ne '' && $sReturn !~ /$sValidate/){
			$sReturn  = '';
			$bInvalid = 1;
		}
	}
	
	# We have a prompted var
	if ($sReturn eq '' && !$bAbort){
		if (exists $aSessions[$idSession]->{VARS}->{$sVar} && $aSessions[$idSession]->{VARS}->{$sVar} ne ''){
			$sReturn = $aSessions[$idSession]->{VARS}->{$sVar};

			if ($sReturn =~ /\Q$aConfigs{EscapeChar}\Edel\s*$/i){
				$sReturn  = '';
			}
			elsif ($sReturn =~ /\Q$aConfigs{EscapeChar}\E(abort|cancel)\s*$/i){
				$sReturn  = '';
				$bAbort   = 1;
			}
			elsif ($sValidate ne '' && $sReturn !~ /$sValidate/){
				$sReturn  = '';
				$bInvalid = 1;
			}
		}
	}

	if ($bAbort){
		if ($aConfigs{Debug} > 1){ logDebug("\nAbort $idSession: $sCommand $sVar");}
			
		$aSessions[$idSession]->{input_type}   = '';
		$aSessions[$idSession]->{'input_var'}    = '';
		$aSessions[$idSession]->{'input_prompt'} = '';
		$aSessions[$idSession]->{command}        = '';
		foreach my $sKey (keys %{$aSessions[$idSession]->{VARS}}){
			$aSessions[$idSession]->{VARS}->{$sKey} = '';
		}
		
		message_deliver('SYS', $idSession, "-- ABORTED");

		return '';		
	}
	
	# We have a valid value
	if($sReturn ne ''){
		$aSessions[$idSession]->{VARS}->{$sVar} = $sReturn;
		return $sReturn;
	}

	if ($aConfigs{Debug} > 1){ logDebug("\nInput $idSession: $sCommand $sVar '".debug_chars(substr($sPrompt, 0, 20), 0, 1)."'");}
	
	# We need to prompt for a value
	$aSessions[$idSession]->{VARS}->{$sVar}= '';
	$aSessions[$idSession]->{input_type}   = $sType;
	$aSessions[$idSession]->{input_var}    = $sVar;
	$aSessions[$idSession]->{input_prompt} = $sType ne 'BLOCK' ? $sPrompt : '';
	$aSessions[$idSession]->{command}      = $sCommand;

	my $bNoCr =( $sType eq 'BLOCK') ? 0 : 1;

	my $sMsg  = '';
	if ($bInvalid){
		$sMsg .= "-- Invalid entry, try again\n";
	}
	if ($sType eq 'BLOCK' && $sPrompt ne ''){
		$sMsg .= $sPrompt;
	}
	
	if ($sPrompt ne '' || $sMsg ne ''){
		message_deliver('SYS', $idSession, $sMsg, $bNoCr, 1, 1);
	}
	
	return '';
}



#---------------------------------------------------------------------------
# Inline Commands
#---------------------------------------------------------------------------


sub lc_shift_lock {
	my ($idSession, $sVar, $sType, $rCommand) = @_;
	$aSessions[$idSession]->{lowercase_lock} = 1;
    redraw_status_window();
    return '';
}

sub lc_shift_unlock {
    $aConfigs{LowercaseLock} = 0;
    redraw_status_window();
}

# NOTE: $DEL $ABORT $CANCEL were implemented differently directly with a regexp in the command_input


#---------------------------------------------------------------------------
# Utility functions
#---------------------------------------------------------------------------

sub clean_html{
	my ($sLine) = @_;
	
	$sLine =~ s/<[^>]*>//gs;   # Clean HTML tags
	$sLine =~ s/&nbsp;/ /gs;   # Convert spaces
	$sLine =~ s/&#[0-7]*;//gs; # Clean escaped characters
	$sLine =~ s/^\s+//gs;      # Clean leading whitespace
	$sLine =~ s/\s+$//gs;      # Clean trailing whitespace
	$sLine =~ s/\s+/ /gs;      # Make all whitespace a single space character
	
	return $sLine;
}

sub cancel_printing {
	do_abort(0, 1);
}


#---------------------------------------------------------------------------
# Action Commands
#---------------------------------------------------------------------------


# Abort current commands and output
sub do_abort {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';
	
	if ($aArgs[0] =~ /^\d+$/){
		my $nId = int($aArgs[0]);
		if (exists $aSessions[$nId]){
			my $thisSession = $aSessions[$nId];
			$thisSession->{IN}  = '';
			$thisSession->{OUT} = '';
			$thisSession->{command}    = '';
			$thisSession->{input_type} = '';
			if ($thisSession->{type} eq 'TTY'){
				$thisSession->{RAW_IN} = '';
				$thisSession->{RAW_OUT} = '';
				if ($oSerialPort) {
					$oSerialPort->purge_all;
				}
			}
			$sOut = "-- ABORTED session ".$nId." by $idSession";
			if ($idSession != $nId && $thisSession->{status}){
				$thisSession->{OUT} = "\n-- ABORTED by session $idSession\n";
			}
			
			if ($nId == 0){
				$bCancelSleep = 1;
			}
		}
		else{
			$sOut = "-- Session $nId does not exist";
		}
	}
	elsif ($aArgs[0] =~ /^ALL$/i){
		my $nCount = 0;
		foreach my $thisSession (@aSessions){
			do_abort($idSession, $thisSession->{id});
			$nCount++;
		}
		$sOut = "-- ABORTED $nCount sessions";
	}
	else{
		do_abort($idSession, $idSession);
		$sOut = "-- ABORTED --";
	}
	
	return ($sOut, 0, 0);
}

# Get an ascii art file
sub do_art {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'ART';

	my @aArgs = split(/\s+/, $sArgs);

	my $sUrl = $aArgs[0];
	command_start($idSession, $sCmd, 'RTTY ART');
	
	if ($aConfigs{Debug} > 1){ logDebug("\ndo_art $idSession: $sArgs");}

	my $sUrlArgs = $sUrl;
	
	if ($bArtCopyOutput && $sArtCopyOutput ne '' && $sArtCopyOutput ne $idSession){
		$sUrlArgs .= ' '.$sArtCopyOutput;
	}
	
    return do_url($idSession, $sUrlArgs, 1);
}

# Get the wheater forecaste for a US city
sub do_weather {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'WEATHER';

	command_start($idSession, $sCmd, 'WEATHER REPORT');
	
	# Get the CITY
	my $sCity = command_input($idSession, 'weather_city', 'LINE', $sArgs, '', "State/city\a: ", $sCmd);
	if ($sCity eq ''){ return ('', 1); }

	$sCity = lc($sCity);
	# Replace first space with / to make things easier in TTY
	if (substr($sCity, 2, 1) eq ' '){
		substr($sCity, 2, 1, '/')
	}
	# Replace any extra space with _
	$sCity =~ tr/ /_/;
	# Append if needed the extension .txt
	if ($sCity !~ /\.txt$/){
		$sCity .= '.txt';
	}
	
	$aSessions[$idSession]->{VARS}->{'weather_city'} = '';
	
	my $sUrlArgs = $aConfigs{WeatherBase}.$sCity;
	
	if ($bArtCopyOutput && $sArtCopyOutput ne '' && $sArtCopyOutput ne $idSession){
		$sUrlArgs .= ' '.$sArtCopyOutput;
	}

    return do_url($idSession, $sUrlArgs, 1);
}

# Get a URL and show its contents, also used as a utility function
sub do_url {
	my ($idSession, $sArgs, $bNoTitle) = @_;
	my $sCmd = 'URL';

	my @aArgs = split(/\s+/, $sArgs);
	
	if ($aConfigs{Debug} > 1){ logDebug("\ndo_url $idSession: $sArgs");}
	
	$bNoTitle = defined($bNoTitle) ? int($bNoTitle) : (defined($aArgs[2]) ? int($aArgs[2]) : 0);
	
	my $sTarget  = defined($aArgs[1]) ? $aArgs[1] : '';
	
	if ($bNoTitle){
		$aSessions[$idSession]->{command_calls}++;
	}
	else{
    	command_start($idSession, $sCmd, 'RETRIEVE URL');
    }

	# Get the URL
	my $sUrl = command_input($idSession, 'url', 'LINE', $aArgs[0], '', "\aURL: ", $sCmd);
	if ($sUrl eq ''){ return ('', 1); }
	
	if (!$bNoTitle){
		# Make sure the OUT buffer is empty before proceeding
		my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Loading...\n\n", $sCmd);
		if ($bReady eq ''){ return ('', 1); }

	}

	my $sContents = LWP::Simple::get($sUrl);
	
	if ($sContents) {
		$aSessions[$idSession]->{VARS}->{'url'}   = '';
		$aSessions[$idSession]->{VARS}->{'ready'} = '';
		
		command_done($idSession);
	
		if ($sTarget){
			message_send('SYS', $sTarget, $sContents);
		}

		return ($sContents."\n-- DONE --", 0, 0);
	
	}
	else {
		$aSessions[$idSession]->{VARS}->{'ready'} = '';
		#local_error("URL failure, couldn't find $sUrl");
		
		command_done($idSession);
	
		return ("-- ERROR: Cannot download URL --", 0, 1);
	}
}

# EVAL a perl sentence
sub do_eval {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'EVAL';
	
	my $sOut = '';
	if ($sArgs ne ''){
		$sOut = eval($sArgs);
	}
	else{
		$sOut  = 'Missing parameters. Usage: EVAL Perl code goes here...';
	}
	
	return $sOut;
}

# List session properties, or set a given property
sub do_session{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'SESSION';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	my $idSessCheck = $idSession;
	if (defined $aArgs[0] && $aArgs[0] =~ /^\d+$/){
		$idSessCheck = int(shift(@aArgs));
	}
	
	if (exists $aSessions[$idSessCheck]){
		if (defined $aArgs[0] && defined $aArgs[1]){
			my $sKey = lc($aArgs[0]);
			$sKey =~ tr/\-/_/; # We do this translation because _ is missing in ITA/USTTY
					
			if ($sKey !~ /^\w+$/){
				$sOut  = "-- ERROR: Invalid setting";
			}
			elsif(!exists $aSessions[$idSessCheck]->{$sKey}){
				$sOut  = "-- ERROR: Non-existent setting";
			}
			else{
				$aSessions[$idSessCheck]->{$sKey} = $aArgs[1];
				$sOut  = "-- Session $idSessCheck - Setting $sKey: ".$aSessions[$idSessCheck]->{$sKey};
			}
		}
		else{
			# Dump the session
			$sOut  = defined $aArgs[0] ? "-- SESSION $idSessCheck -- Settings starting with $aArgs[0]\n" : "-- SESSION $idSessCheck\n";

			foreach my $sKey (sort keys %{$aSessions[$idSessCheck]}){
				if (defined $aArgs[0] && $sKey !~ /^$aArgs[0]/i){
					next;
				}
				if ($sKey eq 'IN' || $sKey eq 'OUT' || $sKey eq 'input_prompt'){
					$sOut .= sprintf(" %15s: (%d) %s\n", $sKey, length($aSessions[$idSessCheck]->{$sKey}), debug_chars(substr($aSessions[$idSessCheck]->{$sKey}, 0, 20), 0, 1));
				}
				elsif ($sKey eq 'RAW_IN' || $sKey eq 'RAW_OUT'){
					$sOut .= sprintf(" %15s: (%d) %s\n", $sKey, length($aSessions[$idSessCheck]->{$sKey}), debug_chars(substr($aSessions[$idSessCheck]->{$sKey}, 0, 20), 1, 1));
				}
				elsif ($sKey eq 'VARS'){
					foreach my $sVar (sort keys %{$aSessions[$idSessCheck]->{VARS}}){
						$sOut .= sprintf(" %15s: HASH %d\n", $sKey, %{$aSessions[$idSessCheck]->{$sKey}});
						if ($aSessions[$idSessCheck]->{VARS}->{$sVar} ne ''){
							$sOut .= sprintf(" %20s: %s\n", 'VARS.'.$sVar, substr($aSessions[$idSessCheck]->{VARS}->{$sVar}, 0, 30));	
						}
					}
				}
				else{
					$sOut .= sprintf(" %15s: %s\n", $sKey, $aSessions[$idSessCheck]->{$sKey});
				}
			}
			$sOut .= "-- DONE --";
		}
	}
	else{
		$sOut = "-- ERROR: Non-existent session $idSessCheck";
	}
	
	return $sOut;
}

# Send a message without touching the source and target of the session. Mail like, can be used for long messages.
sub do_msg{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'MSG';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	command_start($idSession, $sCmd);
	
	my $sTarget = command_input($idSession, 'msg_target', 'LINE', $aArgs[0], '', "\aTo: ", $sCmd);
	if ($sTarget eq ''){ return ('', 1); }

	my $sMsg = '';
	if (defined $aArgs[1]){
	    $sMsg = $sArgs;
		$sMsg =~ s/^\w+\s+//;
	}
	
	$sMsg = command_input($idSession, 'msg_message', 'BLOCK', $sMsg, '', "\aMessage:\n", $sCmd);
	if ($sMsg eq ''){ return ('', 1); }

	my $rv = message_send($idSession, $sTarget, $sMsg);
	if (!defined $rv){
		$sOut = "-- ERROR: Invalid target"; 
	}
	elsif($rv == 0){
		$sOut = "-- ERROR: Target inactive or not found"; 
	}
	else{
		$sOut = "-- SENT ($rv) --"; 
	}
	
	$aSessions[$idSession]->{VARS}->{'msg_target'} = '';
	$aSessions[$idSession]->{VARS}->{'msg_message'} = '';

	command_done($idSession);

	return $sOut;
}

# Send a raw message, a remote command or a redirected output from a local command
sub do_send{
	my ($idSession, $sArgs) = @_;
	my $sCmd     = 'SEND';
	my @aArgs    = split(/\s+/, $sArgs);
	my $sOut     = '';
	
	command_start($idSession, $sCmd);
	
	my $sTarget = command_input($idSession, 'send_target', 'LINE', $aArgs[0], '^\d+|[\w\-]+$', "\aTo: ", $sCmd);
	if ($sTarget eq ''){ return ('', 1); }

	if ($sTarget =~ /^\d+$/){
		$sTarget = int($sTarget);
		if ($idSession == $sTarget){
			$sOut = '-- ERROR: You cannot redirect output to yoursef';
		}
		elsif(!$aSessions[$sTarget]->{status}){
			$sOut = '-- ERROR: Session is disconnected';
		}
	}
	else{
		my $nSessionCount = session_set($sTarget);
		if($nSessionCount < 1){
			$sOut = '-- ERROR: Session does not exist';
		}
		elsif($nSessionCount == 1){
			if (session_get($sTarget, 'id') == $idSession){
				$sOut = '-- ERROR: You cannot redirect output to yoursef';
			}
		}
	}
	
	if ($sOut ne ''){
		$aSessions[$idSession]->{VARS}->{'send_target'}  = '';
		$aSessions[$idSession]->{VARS}->{'send_message'} = '';
		return $sOut;
	}

	my $sMsg = '';
	if (defined $aArgs[1]){
	    $sMsg = $sArgs;
		$sMsg =~ s/^[\w\-]+\s+//;

		if (substr($sMsg, 0, 1) eq $aConfigs{EscapeChar} || substr($sMsg, 0, 1) eq '\\'){
			# Remote command (Line starts with $$)
			if (substr($sMsg, 1, 1) eq $aConfigs{EscapeChar} || substr($sMsg, 1, 1) eq '\\'){
				$sMsg = substr($sMsg, 1);
			}
			# Local command
			elsif($sMsg =~ /^.send/i){
				$aSessions[$idSession]->{VARS}->{'send_target'}  = '';
				$aSessions[$idSession]->{VARS}->{'send_message'} = '';
				return "-- ERROR: Cannot redirect a SEND command";
			}
			else{
				$aSessions[$idSession]->{'command_target'} = $sTarget;
				process_line($idSession, $sMsg);
				$sMsg = '';
			}
		}

	}
	else{

		$sMsg = command_input($idSession, 'send_message', 'BLOCK', $sMsg, '', "\aMessage:\n", $sCmd);
		if ($sMsg eq ''){ return ('', 1); }
	}
	
	
	if ($sMsg ne ''){
		my $rv = message_send($idSession, $sTarget, $sMsg, 0, 1, 0);
		if (!defined $rv){
			$sOut = "-- ERROR: Invalid target"; 
		}
		elsif($rv == 0){
			$sOut = "-- ERROR: Target inactive or not found"; 
		}
		else{
			$sOut = "-- SENT ($rv) --"; 
		}
		
		$aSessions[$idSession]->{VARS}->{'send_target'} = '';
		$aSessions[$idSession]->{VARS}->{'send_message'} = '';
		
		command_done($idSession);

	}
	
	
	return $sOut;
}

# Send a file
sub do_sendfile{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'SENDFILE';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	command_start($idSession, $sCmd, 'SEND FILE');
	
	my $sTarget = command_input($idSession, 'sendfile_target', 'LINE', $aArgs[0], '', "\aTo: ", $sCmd);
	if ($sTarget eq ''){ return ('', 1); }

	my $sFile = command_input($idSession, 'sendfile_file', 'LINE', $aArgs[1], '', "\aFile: ", $sCmd);
	if ($sFile eq ''){ return ('', 1); }

	if (!open(FH, "$sFile")) {
		$sOut = "-- ERROR: Could not open file $sFile";
	}
	else {
		my $sMsg = join("",<FH>);
		close (FH);
		
		my $nLen = length($sMsg);
		my $rv = message_send($idSession, $sTarget, $sMsg, 0, 1, 0);
		
		if (!defined $rv){
			$sOut = "-- ERROR: Invalid target"; 
		}
		elsif($rv == 0){
			$sOut = "-- ERROR: Target inactive or not found"; 
		}
		else{
			$sOut = "-- SENT ($rv) $nLen bytes --"; 
		}

	}

	$aSessions[$idSession]->{VARS}->{'sendfile_target'} = '';
	$aSessions[$idSession]->{VARS}->{'sendfile_file'}   = '';
	
	command_done($idSession);
	
	return $sOut;
}

# Set a var
sub do_setvar{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'SETVAR';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (!defined($aArgs[0]) || !defined($aArgs[1])){
		$sOut = '-- ERROR: Usage: SETVAR VARIABLE VALUE';	
	}
	else{
		my $sVar   = lc($aArgs[0]);
		$sVar      =~ s/\-/_/g;
		
		my $sValue = $sArgs;
		$sValue    =~ s/^[\w\-]+\s+//;
		
		$aSessions[$idSession]->{VARS}->{$sVar} = $sValue;
		$sOut = '-- DONE --';
	}
	
	return $sOut;
}

# Change config
sub do_config{
	my ($idSession, $sArgs, $bNoOutput) = @_;
	my $sCmd = 'CONFIG';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (!defined($aArgs[0]) || !defined($aArgs[1])){
		$sOut = '-- ERROR: Usage: CONFIG VARIABLE NEWVALUE';	
	}
	else{
		my $sVar   = uc($aArgs[0]);
		$sVar      =~ s/\-/_/g;
		
		my $sValue = $sArgs;
		$sValue    =~ s/^[\w\-]+\s+//;
		
		$sOut = '-- ERROR: Setting not found';
		foreach my $sKey (keys %aConfigs){
			if ($sVar eq uc($sKey)){
				$aConfigs{$sKey} = $sValue;
				if (!$bNoOutput){
					$sOut = '-- DONE --';
				}
				last;
			}
		}
	}
	
	return $sOut;
}

# Show configs
sub do_configs{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'CONFIGS';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';

	my $sSearch = defined($aArgs[0]) ? $aArgs[0] : '';
	
	# Dump the configs
	$sOut  = $sSearch eq '' ? "-- CONFIGS:\n" : "-- CONFIGS starting with '$sSearch': \n";
	foreach my $sKey (sort keys %aConfigs){
		if ($sSearch eq '' || $sKey =~ /^$sSearch/i){
			if ($sSearch eq '' && length($aConfigs{$sKey}) > 38){
				$sOut .= sprintf(" %18s: %s... (%d)\n", $sKey, substr($aConfigs{$sKey}, 0, 38), length($aConfigs{$sKey}));
			}
			else{
				$sOut .= sprintf(" %18s: %s\n", $sKey, $aConfigs{$sKey});
			}
		}
	}
	$sOut .= "-- DONE --";
	
	return $sOut;
}

# NOTE: This command is not used from the ActionCommands list,
#       instead it is executed directly in unauthenticated sessions
sub do_login{
	my ($idSession, $sArgs, $rNewSession) = @_;
	my $sCmd = 'LOGIN';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (!defined($aArgs[0]) || !defined($aArgs[1]) || $aArgs[0] eq '' || $aArgs[1] eq ''){
		$sOut = 'Missing username or password';
	}
	else{
		my $sUser = uc($aArgs[0]);
		my $sPass = uc($aArgs[1]);
		if ($sUser !~ /^[\w-]{1,10}$/){
			$sOut = '-- Invalid username';
		}
		elsif($sUser =~ /$sLoginDisallowed/i){
			$sOut = '-- Username not allowed';
		}
		elsif($sPass ne $aConfigs{SystemPassword} && $sPass ne $aConfigs{GuestPassword}){
			$sOut = '-- Invalid username or password';
		}
		else{
			if (!defined $idSession){
				# We use this value as a flag
				$sOut = 'OK';
			}
			else{
				$aSessions[$idSession]->{'auth'} = $sPass eq $aConfigs{SystemPassword} ? 3 : 2;
				$aSessions[$idSession]->{'user'} = $sUser;
				$sOut = "-- Login OK! Session $idSession - Level $aSessions[$idSession]->{auth}\n   You are ready to send data into the TTY\n   $sSessionsHelp";
			}
		}
	}
	return $sOut;
}

# Ping Pong
sub do_ping{
	my ($idSession, $sArgs) = @_;
	return "PONG! $sArgs";
}

# Show uptime
sub do_uptime{
	my ($idSession, $sArgs) = @_;
	return sprintf("System started %1.1f secs ago at %s", (time() - $nTimeStart), get_datetime($nTimeStart));
}

# Show current time
sub do_time{
	my ($idSession, $sArgs) = @_;
	return sprintf("Current time: %s", get_datetime());
}

# Tell me a joke
sub do_joke{
	my ($idSession, $sArgs) = @_;
	$nCurrentJoke = (($nCurrentJoke + 1) >= scalar @aJokes) ? 0 : $nCurrentJoke + 1;
	return Text::Wrap::wrap("", "", '- '.$aJokes[$nCurrentJoke]);
}

# Change your USER
sub do_user{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'USER';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (defined $aArgs[0] && $aArgs[0] ne ''){
		if ($aArgs[0] =~ /^[\w-]{1,10}$/){
			$aSessions[$idSession]->{'user'} = uc($aArgs[0]);
			$sOut  = "-- Your new username: ".$aSessions[$idSession]->{'user'};
		}
		else{
			$sOut  = "-- Invalid username";
		}
	}
	else{
		$sOut  = "-- Your username: ".$aSessions[$idSession]->{'user'};
	}
	
	return $sOut;
}

# Interact with MSN (ON|OFF|LIST|chat target)
sub do_msn{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'MSN';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';


	if (!$Modules{'MSN'}->{loaded}){
		return ('-- ERROR: MSN perl module or dependencies not loaded', 0, 1);
	}
	
	my $sMsg;
	
	# STATUS?
	if (!defined($aArgs[0])){
		if (!$aConfigs{MsnEnabled}){
			$sOut  = '-- MSN is Disabled';
		}
		elsif (!$MsnConnected){
			$sOut  = '-- MSN is not connected';
		}
		elsif($aSessions[$idSession]->{target} =~ /^MSN:/){
			$sOut  = '-- MSN is connected as '.$aConfigs{MsnUsername}.' in chat with '.substr($aSessions[$idSession]->{target}, 4);
		}
		else{
			$sOut  = '-- MSN is connected as '.$aConfigs{MsnUsername};
		}
	}
	# ON|OFF
	elsif ($aArgs[0] =~ /^(ON|OFF|0|1)$/i){
		my $bEnable = ($aArgs[0] =~ /^(ON|1)$/i) ? 1 : 0;
		$sOut = msn_toggle($bEnable);
	}
	elsif (!$aConfigs{MsnEnabled}){
		$sOut  = '-- MSN is disabled';
	}
	elsif (!$MsnConnected){
		$sOut  = '-- MSN is not connected';
	}
	elsif ($aArgs[0] =~ /^LIST$/i){
		$sOut  = do_msnlist($idSession);
	}
	elsif (defined($aArgs[0]) && $aArgs[0] ne ''){
		# Search from contact list (starting with)
		my $sSearch = lc($aArgs[0]);
		foreach (sort keys %{$oMSN->{Notification}->{Lists}->{FL}}){
			if (lc(substr($_, 0, length($sSearch))) eq $sSearch || lc(substr($oMSN->{Notification}->{Lists}->{FL}->{$_}->{Friendly}, 0, length($sSearch))) eq $sSearch){
#				if ($oMSN->{Notification}->{Lists}->{FL}->{$_}->{Status} eq 'OFF'){
#					$sOut = "-- User $_ is offline";
#				}
				$sOut = do_target($idSession, 'MSN:'.$_);
				last;
			}
		}
	}
	else{
		$sOut  = '-- Missing parameters. Usage: MSN [ON,OFF,LIST] -or- MSN [email|nick]';
	}
	
	return $sOut;

}

# Show the MSN contact list
sub do_msnlist{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'MSNLIST';

	my $sOut = '';

	if ($MsnConnected){
		$sOut = "-- MSN Contacts:\n";
		$sOut .= " -EMAIL---------------------- -User------- -S- -STATUS MSG----------\n";
		foreach (sort keys %{$oMSN->{Notification}->{Lists}->{FL}}){
			$sOut .= sprintf(" %-28.28s %-12.12s %3.3s %.21s\n", $_,  $oMSN->{Notification}->{Lists}->{FL}->{$_}->{Friendly},  $oMSN->{Notification}->{Lists}->{FL}->{$_}->{Status}, $oMSN->{Notification}->{Lists}->{FL}->{$_}->{Message});
		}
		
		if (scalar(%MsnContactsRedirected) > 0){
			$sOut .= "-- MSN Redirected Contacts:\n";
			foreach (sort keys %MsnContactsRedirected){
				$sOut .= sprintf(" %25s -> %25s %-s\n", $_, $MsnContactsRedirected{$_}->{Redirector}, $MsnContactsRedirected{$_}->{Email}, $MsnContactsRedirected{$_}->{Friendly});
			}
		}
	}
	else{
		$sOut = "-- MSN Disabled or disconnected";
	}
	$sOut .= "-- DONE --";
	return $sOut;	
}

# KICK a session, only usefull for Telnet and MSN sessions
sub do_kick {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'KICK';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (defined $aArgs[0] && $aArgs[0] ne ''){

		foreach my $thisSession (@aSessions){
			if ($thisSession->{'status'}){
				if (($aArgs[0] =~ /^\d+$/ &&  $thisSession->{'id'} == int($aArgs[0])) || ($aArgs[0] =~ /^\w+$/ && $thisSession->{'user'} eq uc($aArgs[0]))){
					if ($thisSession->{type} eq 'TELNET'){
						$thisSession->{'disconnect'} = 1;
						$thisSession->{OUT} .= "\r\nYou have been kicked by $idSession! Bye Bye!\r\n";
						$sOut .= sprintf("-- Kicked Session: %d  - Address %s  - User: %s\n", $thisSession->{'id'}, $thisSession->{'address'}, $thisSession->{'user'});
					}
					elsif($thisSession->{type} eq 'MSN'){
						$thisSession->{status} = 0;
						$thisSession->{OUT} .= "\r\nYou have been kicked by $idSession! Bye Bye!\r\n";
						$sOut .= sprintf("-- Kicked Session: %d  - Address %s  - User: %s\n", $thisSession->{'id'}, $thisSession->{'address'}, $thisSession->{'user'});
					}
				}
			}

		}
		if ($sOut eq ''){
			$sOut = '-- Session or user not active';
		}
	}
	else{
		$sOut  = "-- Missing username or session id";
	}
	return $sOut;
}


# Set debug options
sub do_debug {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'DEBUG';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	my $nVal;
	
	if (defined($aArgs[0])  && $aArgs[0] =~ /^(ON|OFF)$/i){
		$aConfigs{Debug} = ($aArgs[0] =~ /^(ON)$/i) ? 1 : 0;
		$sOut = "-- Debug: $aConfigs{Debug}";
	}
	elsif (defined($aArgs[0])  && $aArgs[0] =~ /^(0|1|2|3)$/i){
		$aConfigs{Debug} = int($aArgs[0]);
		$sOut = "-- Debug: $aConfigs{Debug}";
	}
	elsif (defined($aArgs[0]) && uc($aArgs[0]) eq 'SESSION'){
		if (!defined($aArgs[1])){
			$sOut = '-- Error: Missing Session';
		}
		elsif ($aArgs[1] =~ /^OFF$/i){
			$rDebugSocket = undef;
			$sOut = '-- Debug output will not be copied anymore';
		}
		elsif ($aArgs[1] !~ /^\d+$/i){
			$sOut = '-- Error: Invalid Session id';
		}
		elsif (!defined $aSessions[$aArgs[1]]){
			$sOut = '-- Error: Non-existent Session id';
		}
		elsif($aSessions[$aArgs[1]]->{type} ne 'TELNET'){
			$sOut = '-- Error: Not a telnet session';
		}
		elsif($aSessions[$aArgs[1]]->{directions} != 0){
			$sOut = '-- Error: Not an inbound session';
		}
		elsif($aSessions[$aArgs[1]]->{status} != 1){
			$sOut = '-- Error: Not an active session';
		}
		else{
			$rDebugSocket = $aSessions[$aArgs[1]]->{SOCKET};
			$sOut = '-- Debug output will be copied to telnet session '.$aArgs[1];
		}
	}
	elsif (defined($aArgs[0])){
		$sOut = '-- Error: Unknown debug option';
	}
	else{
		$sOut .= sprintf("-- Debug: %d File: %s Socket: %s", $aConfigs{Debug}, $sDebugFile, ($rDebugSocket ? 'Yes' : 'No'));
	}			

	return $sOut;
}

# Switch prompt ON and OFF
sub do_prompt {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'PROMPT';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	my $nVal;
	
	if (defined($aArgs[0]) && $aArgs[0] ne ''){
		if (uc($aArgs[0]) eq 'ON'  || ($aArgs[0] =~ /^\d+$/ &&  int($aArgs[0]) == 1)){
			$nVal = 1;
		}
		elsif (uc($aArgs[0]) eq 'OFF' || ($aArgs[0] =~ /^\d+$/ &&  int($aArgs[0]) == 0)){
			$nVal = 0;
		}
		if (defined $nVal){
			$aSessions[$idSession]->{'prompt'} = $nVal;
			$sOut .= "-- Prompt: ".($aSessions[$idSession]->{'prompt'} ? 'ON' : 'OFF');
		}
		else{
			$sOut .= "-- New Prompt: ".($aSessions[$idSession]->{'prompt'} ? 'ON' : 'OFF')." (Unrecognized new value)";
		}
	}
	else{
		$sOut .= "-- Prompt: ".($aSessions[$idSession]->{'prompt'} ? 'ON' : 'OFF');
	}			

	return $sOut;
}

sub do_target {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'TARGET';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	my $nVal;
	my $nId;
	my $bError = 0;

	if (!defined($aArgs[0]) || $aArgs[0] eq ''){
		$sOut = '-- Your current Target is: '.$aSessions[$idSession]->{'target'};
	}			
	else{
		my $xTarget = $aArgs[0];
		my $nVal;
		
		$nId = (defined($aArgs[1]) && $aArgs[1] =~ /^[1-9]\d*$/) ? int($aArgs[1]) : $idSession;
		
		if ($xTarget =~ /^(ALL|IN|OUT|NONE)$/i){
			$xTarget = uc($xTarget);
			$nVal = session_set($nId, 'target', $xTarget);
			if (defined($nVal) && $nVal > 0){
				$sOut = "-- New Target for $nId is: $xTarget";
			}
			else{
				$sOut   = "-- ERROR: Unknown session id to set its Target";
				$bError = 1;
			}
		}
		elsif($xTarget =~ /^MSN\:/i){
			$nVal = session_set($nId, 'target', $xTarget);
			if (defined($nVal) && $nVal > 0){
				$sOut = "-- New MSN Target for $nId is: $xTarget";
				my $sMsnTargetUser = lc(substr($xTarget, 4));
				
				print "ROUTE: '$sMsnTargetUser'\n";
				if (exists $MsnInboundRoute{$sMsnTargetUser}){
					# If the target is not already there we add it
					if (!in_array($MsnInboundRoute{$sMsnTargetUser}, $nId)){
						push(@{$MsnInboundRoute{$sMsnTargetUser}}, $nId);
					}
				}
				else{
					$MsnInboundRoute{$sMsnTargetUser} = [$nId];
				}
			}
			else{
				$sOut = "-- ERROR: Unknown session id to set its Target";
				$bError = 1;
			}
		}
		else{
			$xTarget = uc($xTarget);
			# We will automatically assign the target for outbound connections too
			$nVal = session_get($xTarget, 'direction');
			if (defined $nVal){
				if ($nVal){
					$nVal = session_set($nId, 'target', $xTarget);
					if (defined($nVal) && $nVal > 0){
						$sOut = "-- New Target for $nId is: $xTarget";
						$nVal = session_set($xTarget, 'target', $nId);
						if (defined($nVal) && $nVal > 0){
							$sOut .= "\n-- New Target for outbound session $xTarget is: $nId";
						}
					}
					else{
						$sOut = "-- ERROR: Unknown session id to set its Target";
						$bError = 1;
					}
				}
				else{
					$nVal = session_set($nId, 'target', $xTarget);
					if (defined($nVal) && $nVal > 0){
						$sOut = "-- New Target for $nId is: $xTarget";
					}
					else{
						$sOut = "-- ERROR: Unknown session id to set its Target";
						$bError = 1;
					}
				}
			}
			else{
				$sOut = '-- Unknown Target id/name';
				$bError = 1;
			}
		}
	}
	return ($sOut, 0, $bError);
}


# Switch DND ON and OFF
sub do_dnd {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'DND';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	my $sVal;
	
	if (defined($aArgs[0]) && $aArgs[0] ne ''){
		if (uc($aArgs[0]) eq 'ON'  || ($aArgs[0] =~ /^\d+$/ &&  int($aArgs[0]) == 1)){
			$sVal = 'DND';
		}
		elsif (uc($aArgs[0]) eq 'OFF' || ($aArgs[0] =~ /^\d+$/ &&  int($aArgs[0]) == 0)){
			$sVal = 'ALL';
		}
		if (defined $sVal){
			$aSessions[$idSession]->{source} = $sVal;
			$sOut .= "-- Source: ".$aSessions[$idSession]->{source}.' (DND: '.($aSessions[$idSession]->{source} eq 'DND' ? 'ON' : 'OFF').')';
		}
		else{
			$sOut .= "-- Source: ".$aSessions[$idSession]->{source} ." (Unrecognized new value)";
		}
	}
	else{
		$sOut .= "-- Source: ".$aSessions[$idSession]->{source}.' (DND: '.($aSessions[$idSession]->{source} eq 'DND' ? 'ON' : 'OFF').')';
	}			

	return $sOut;
}

sub do_source {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'SOURCE';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	my $nVal;
	my $nId;
	my $bError = 0;
	
	if (!defined($aArgs[0]) || $aArgs[0] eq ''){
		$sOut = '-- Your current Source is: '.$aSessions[$idSession]->{source};
	}			
	else{
		my $xSource = $aArgs[0];
		my $nVal;
		
		$nId = (defined($aArgs[1]) && $aArgs[1] =~ /^[1-9]\d*$/) ? int($aArgs[1]) : $idSession;
		
		if (!defined $aSessions[$nId] || !$aSessions[$nId]->{status}){
			$sOut   = "-- ERROR 1: Unknown session id to set its Source";
			$bError = 1;
		}
		else{

			if ($xSource =~ /^(ALL|DND|NONE)$/i){
				$xSource = uc($xSource);
				session_set($nId, 'source', $xSource);
				$sOut = "-- New Source for $nId is: $xSource";
			}
			elsif ($xSource =~ /^\d+$/i){
				$xSource = int($xSource);
				if (exists $aSessions[$xSource]){
					session_set($nId, 'source', $xSource);
					$sOut = "-- New Source for $nId is: $xSource";
				}
				else{
					$sOut = "-- ERROR 2: Unknown session id to set as Source";
					$bError = 1;
				}
			}
			elsif ($xSource =~ /^\w+$/i){
				$sOut = "-- ERROR 3: Unknown session id to set its Source";
				$bError = 1;
				$xSource = uc($xSource);
				foreach my $thisSession (@aSessions){
					if ($thisSession->{status} && $thisSession->{auth} && $thisSession->{user} eq $xSource){
						session_set($nId, 'source', $thisSession->{id});
						$sOut = "-- New Source for $nId is: $thisSession->{id} ($thisSession->{user})";
						$bError = 0;
						last;
					}
				}
			}
			else{
				$sOut = '-- ERROR 4: Unknown Source';
				$bError = 1;
			}
		}
	}
	return ($sOut, 0, $bError);
}

sub do_chat {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'CHAT';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	my $nVal;
	my $nId;

	if (!defined($aArgs[0]) || $aArgs[0] eq ''){
		$sOut  = '-- Your current Source is: '.$aSessions[$idSession]->{source}."\n";
		$sOut .= '-- Your current Target is: '.$aSessions[$idSession]->{target}."\n";
	}			
	elsif($aArgs[0] =~ /^ALL$/i){
		# Restore back to ALL
		my $sOutTarget = '';
		my $sOutSource = '';

		($sOutTarget) = do_target($idSession, $aArgs[0]);
		($sOutSource) = do_source($idSession, $aArgs[0]);
		
		$sOut .= $sOutSource."\n".$sOutTarget;
	}
	elsif($aArgs[0] =~ /^\d+$/i || $aArgs[0] =~ /^\w+$/i){
		# Chat peer provided
		my $sOutTarget = '';
		my $sOutSource = '';
		my $bContinue;
		my $bError;
		my $sOldTarget = $aSessions[$idSession]->{target};
		
		($sOutTarget, $bContinue, $bError) = do_target($idSession, $aArgs[0]);
		if ($bError){
			$sOut = "-- ERROR --\n$sOutSource";
		}
		else{
			($sOutSource, $bContinue, $bError) = do_source($idSession, $aArgs[0]);
			if ($bError){
				# Restore original target
				$aSessions[$idSession]->{target} = $sOldTarget;
				$sOut = "-- ERROR --\n$sOutSource";
			}
			else{
				# Notify chat target
				my $sMsg = sprintf('-- User %s from session %d wants to chat. Use %sCHAT %d', $idSession, $aSessions[$idSession]->{user}, $aConfigs{EscapeChar}, $idSession);
				message_send('SYS', $aArgs[0], $sMsg);
				$sOut = $sOutSource."\n".$sOutTarget;
			}
		}
	}
	else{
		# Help
		$sOut = '-- Usage: CHAT ALL -or- CHAT SESSIONID -or- CHAT USERNAME';
	}
	return $sOut;
}

sub do_hmpipe {
	my ($idSession, $sArgs) = @_;
	my $sCmd  = 'HMPIPE';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = "-- PIPE READY: $aConfigs{SystemName} --";

	$aSessions[$idSession]->{prompt}     = 0;
	$aSessions[$idSession]->{echo_msg}   = 0;
	$aSessions[$idSession]->{echo_input} = 0;
	$aSessions[$idSession]->{clean_line} = 0;
	
	return $sOut;
}

sub do_auth {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'AUTH';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';

	if (defined($aArgs[0]) && $aArgs[0] =~ /^\d+$/){
		my $xTarget = int($aArgs[0]);
		my $nVal    = session_get($xTarget, 'direction');
		if (defined $nVal){
			if ($nVal){
				message_deliver('SYS', $xTarget, "\$HMPIPE", 0, 1, 1);

				$aSessions[$xTarget]->{auth}         = 1;
				$aSessions[$xTarget]->{source}       = 'ALL';
				$aSessions[$xTarget]->{target}       = 'ALL';
				$aSessions[$xTarget]->{label_source} = 1;
				
				$aSessions[$idSession]->{target}     = 'ALL';

				$sOut = '-- Session marked as authorized';
			}
			else{
				$sOut = '-- Session is not an OUTBOUND session';
			}
		}
		else{
			$sOut = '-- Session not found. Check with command LIST';
		}
	}
	else{
		$sOut = '-- Missing outbound session ID. Usage: AUTH [ID]';
	}	
	return $sOut;
}

sub do_logout{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'LOGOUT';
	
	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "Bye Bye!\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }

	telnet_close($aSessions[$idSession]->{SOCKET}, "CMD exit");
	
	return '';
}


sub do_news_topnews {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'TOPNEWS';
	
    command_start($idSession, $sCmd, 'AP: TOP NEWS');
    
	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Loading...\n\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }

    my $sOut = '';
    my $sUrl = "http://hosted.ap.org/dynamic/fronts/HOME?SITE=MELEE&SECTION=HOME";
    
    my $sContents = LWP::Simple::get($sUrl);
    
    foreach my $sLine(split(/\n/, $sContents)) {
    	if ($sLine =~ /class="topheadline"/){
			$sLine = clean_html($sLine);
			if (length($sLine) > 0){
				$sOut .= "\n--- ".$sLine . "\n";
			}
		}
    	elsif ($sLine =~ /class="topheadlinebody"/){
            $sLine =~ s/<[^>]*>//gs;
			$sLine = clean_html($sLine);
			if (length($sLine) > 0){
				$sOut .= Text::Wrap::wrap("", "", $sLine). "\n";
			}
		}
	}
	
	if ($sOut eq ''){
		$sOut = 'Sorry, news are unavailable now';
	}
	else{
		$sOut .= "\n-- End of summary --\n";
	}
    
	$aSessions[$idSession]->{VARS}->{'ready'} = '';

    redraw_status_window();
    
	command_done($idSession);
	
	return ($sOut, 0, 0);
}


sub do_news_history {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'HISTORY';
    command_start($idSession, $sCmd, 'AP: TODAY IN HISTORY');
	
	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Loading...\n\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }
	
	my $sUrl = "http://news.yahoo.com/s/ap/history";
	# "http://story.news.yahoo.com/news?tmpl=story&u=/ap/history";
	# "http://customwire.ap.org/dynamic/stories/H/HISTORY_JAN_3?SITE=CAWOO&SECTION=HOME&TEMPLATE=DEFAULT";
    
	my $sOut     = '';

	my $sContents = LWP::Simple::get($sUrl);

    my $bInclude = 0;	    
	foreach my $sLine(split(/\n/, $sContents)) {
		if ($bInclude == 0){
			if ($sLine =~ /<div class="yn-story-content">/i){
				$bInclude = 1;
			}
		}
		elsif ($bInclude == 1){
			if ($sLine =~ /Today.s Birthdays/i){
				$bInclude = 2;
				last;
			}
			else{
				$sLine = clean_html($sLine);
				if (length($sLine) > 0){
					$sOut .= $sLine . "\n";
				}
			}
		}
    }
    
	if ($sOut eq ''){
		$sOut = 'Sorry, news are unavailable now';
	}
	else{
		$sOut .= "-- End of summary --\n";
	}

    redraw_status_window();
    
	$aSessions[$idSession]->{VARS}->{'ready'} = '';
	
	command_done($idSession);
	
	return ($sOut, 0, 0);
}





sub do_shutdown{
	my ($idSession, $sArgs) = @_;

	my $sMsg = "\n\nShutting down Server in 5 seconds initiated by ".$idSession.' '.$aSessions[$idSession]->{'user'}.' from '.$aSessions[$idSession]->{'address'}."\r\nBye Bye!";
	message_send('SYS', 'IN', $sMsg, 0, 1);
	$nShutDown = time() + 5;
	print "\n\n$sMsg\n\n";

	return '';
}

sub do_help {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	
	my $sKey;
    my $s = '';

    if (defined $aArgs[0] && $aArgs[0] !~ /^(SETTINGS|COMMANDS|CHARS)$/i){
    	$sKey = uc($aArgs[0]);
    	if  (defined($aActionCommands{$sKey})){
    		$s .=  "-- Help for command $sKey:\n  ";
	    	$s .=  defined($aActionCommands{$sKey}->{help}) ? $aActionCommands{$sKey}->{help} : "Sorry, no help available";
	    	$s .=  "\n  Arguments:\n    ";
	    	$s .=  defined($aActionCommands{$sKey}->{args}) ? $aActionCommands{$sKey}->{args} : "No args";
	    	$s .=  "\n-- DONE --\n";
	    }
	    else{
	    	$s .=  "-- ERROR: Unknown command or option";
	    }
    }
    else{
	    $s .=  "=============================================================\n";
	    $s .=  "Usage: perl heavymetal.pl [configs=values] [commands=params]\n";
	    $s .=  "  Example: perl heavymetal.pl -config1=value1 --command=params\n";
	    $s .=  "=============================================================\n";
	    $s .=  "\n";
	    
		if (!defined $aArgs[0] || lc($aArgs[0]) eq 'settings'){
		    $s .=  "-- Configuration settings:\n";
		    $s .=  "\n";
		    foreach $sKey (sort(keys(%aConfigDefinitions))) { 
				$s .= sprintf(" %14s: %s -Def: %s\n", $sKey, $aConfigDefinitions{$sKey}->{help}, $aConfigDefinitions{$sKey}->{default});
		    }
		    $s .=  "-------------------------------------------------------------\n";
		    $s .=  "\n";
		}
		if (!defined $aArgs[0] || lc($aArgs[0]) eq 'commands'){
		    $s .=  "-- Commands:\n";
		    $s .=  "\n";
		    foreach $sKey (sort(keys(%aActionCommands))) { 
		    	$s .= sprintf(" %-10s: %s\n", $sKey, $aActionCommands{$sKey}->{help});
		    }
		    $s .=  "-------------------------------------------------------------\n";
		    $s .=  "\n";
		    $s .=  "-- Immediate commands available during input:\n";
		    $s .=  "\n";
		    $s .=  " ABORT or CANCEL: Abort the current command\n";
		    $s .=  " DEL: Delete the current line and rerequest it\n";
		    $s .=  "-------------------------------------------------------------\n";
		    $s .=  "\n";
		}
		if (!defined $aArgs[0] || lc($aArgs[0]) eq 'chars'){
		    $s .=  "-- Escaped characters:\n";
		    $s .=  "\n";
		    $s .=  "ASCII:";
		    foreach $sKey (sort(keys(%aEscapeCharsDecodeASCII))) { 
				$s .= " $sKey";
		    }
		    $s .=  "\nITA2:";
		    foreach $sKey (sort(keys(%aEscapeCharsDecodeITA))) { 
				$s .= " $sKey";
		    }
		    $s .=  "\n";
		}
	    $s .=  "=============================================================\n";
	    $s .=  "\n\n";
    }
	return $s;
}

sub do_telnet {
    my ($idSession, $sArgs) = @_;
	my $sCmd = 'TELNET';
    my @aArgs = split(/\s+/, $sArgs);
    
    if (!defined $idSession){
    	$idSession = 0;
    }

	# Handle ON and OFF
	if ($aArgs[0] =~ /^(ON|OFF|0|1)$/i){
		my $bEnable = ($aArgs[0] =~ /^(ON|1)$/i) ? 1 : 0;
		my $sOut = telnet_toggle($bEnable);
		return $sOut;
	}
    
    # To avoid problems with the menu, the value has to be set to something, so we set it to a single space in the menu.
    if ($aSessions[$idSession]->{VARS}->{'telnet_host'} eq ' '){
    	$aSessions[$idSession]->{VARS}->{'telnet_host'} = '';
    }

    command_start($idSession, $sCmd, $sCmd);
	
	# Get the MSG
	my $sHost = command_input($idSession, 'telnet_host', 'LINE', $aArgs[0], '^\w[\w\.\-]+\w(\:\d+)?$', "\aHost: ", $sCmd);
	if ($sHost eq ''){ return ('', 1); }

	my $nPort;
	
	($sHost, $nPort) = split(/[\:\s]/, $sHost);

	$nPort = defined($nPort) ? int($nPort) : (defined $aArgs[1] ? int($aArgs[1]) : 23);
	if ($nPort == 0){
		$nPort = 23;
	}
	
	telnet_connect($sHost, $nPort, $idSession);
	
	$aSessions[$idSession]->{VARS}->{'telnet_host'} = '';
	
	command_done($idSession);

	return '';
}

sub do_list{
    my ($idSession, $sArgs) = @_;
	my $sOut = '';

	$sOut  = "-- $aConfigs{SystemName} Sessions:\r\n";
	$sOut .= "ID -TYPE- -USER------ I/O LVL -TARGET---- SRC -ADDRESS------ STATUS\r\n";
	foreach my $thisSession (@aSessions){
		$sOut .= sprintf("%2d %-6s %-11.11s %-3s  %d  %-11.11s %3.3s %-14.14s %-6.6s\r\n", 
				$thisSession->{'id'}, 
				$thisSession->{'type'}, 
				$thisSession->{'user'}, 
				$thisSession->{'direction'} ? 'Out' : 'In', 
				$thisSession->{'auth'}, 
				$thisSession->{'target'}, 
				$thisSession->{'source'}, 
				$thisSession->{'address'}, 
				$thisSession->{'status'} ? 'Conn' : 'Disc');
	}

	return $sOut;
}


# Generate eyeball characters for tape puncher
sub do_label {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'LABEL';

    command_start($idSession, $sCmd, 'LABEL TAPE');
    
	# Get the MSG
	my $sLabel = command_input($idSession, 'label_text', 'LINE', $sArgs, '', "Label\a: ", $sCmd);
	if ($sLabel eq ''){ return ('', 1); }

	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Starting to punch in 5 secs...\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }

	my $sOut = '';
	my $c    = '';

  my %aMap = (
		' ' => '$NUL$NUL',
		'A' => 'VSSV',
		'B' => '$LTRS YYR',
		'C' => 'CZZR',
		'D' => '$LTRS ZZC',
		'E' => '$LTRS YYZ',
		'F' => '$LTRS SSE',
		'G' => 'CZYF',
		'H' => '$LTRS$SP$SP$LTRS ',
		'I' => 'Z$LTRS Z',
		'J' => '$BCR TTK',
		'K' => '$LTRS $SP RZ',
		'L' => '$LTRS TTT',
		'M' => '$LTRS$BLF$SP$BLF$LTRS ',
		'N' => '$LTRS$BLF$SP$LTRS ',
		'O' => 'CZZC',
		'P' => '$LTRS SS$BLF ',
		'Q' => 'CZXV',
		'R' => '$LTRS SDL',
		'S' => 'LYYD',
		'T' => 'EE$LTRS EE',
		'U' => 'KTTK',
		'V' => 'U$BCR T$BCR U',
		'W' => 'KTNTK',
		'X' => 'ZR RZ',
		'Y' => 'E$BLF M$BLF E',
		'Z' => 'BYZWZ',
		'0' => 'CZZC',
		'1' => 'L$LTRS T',
		'2' => 'LBYL',
		'3' => 'DZYJ',
		'4' => '$SP$SP I$LTRS ',
		'5' => 'WYYD',
		'6' => 'CYY$BCR ',
		'7' => 'AEXA',
		'8' => 'RYYR',
		'9' => '$BLF YYC',
		'-' => '$BCR$BCR$BCR ',
		'+' => '$BCR M$BCR ',
		'=' => 'HHH',
		'&' => 'RYRH',
		"'" => 'A',
		'(' => 'CZ',
		')' => 'ZC',
		':' => 'R',
		'<' => '$SP RZ',
		'>' => 'ZR$SP ',
		'.' => 'T',
		',' => 'T$BCR ',
		'|' => '$LTRS ',
		'/' => 'T$BCR$SP$NUL$BLF E',
		'\\'=> 'E$BLF$NUL$SP$BCR T',
	);    


	$sLabel = uc($sLabel);    
	while (length($sLabel) > 0) {
		$c = substr($sLabel, 0 , 1, '');

		if (exists($aMap{$c})){
    		$sOut .= '$NUL '.$aMap{$c};
    	}
    }
    
	$aSessions[$idSession]->{VARS}->{'label_text'} = '';
	$aSessions[$idSession]->{VARS}->{'ready'}      = '';

    if ($sOut ne ''){
    	sleep(5);
    	my $sMsg = '$OVERSTRIKEOFF$NUL$NUL'.$sOut.'$NUL$NUL$NUL$NUL$NUL$OVERSTRIKEON ';
    	
    	# This command handles the redirect itself, because it is intended to be redirected to the tape puncher

		if ($aSessions[$idSession]->{'command_target'}){
			message_deliver('SYS', $aSessions[$idSession]->{'command_target'}, $sMsg, 1, 1, 1);
		}
		else{
			message_deliver('SYS', 1, $sMsg, 1, 1, 1);
		}
		$aSessions[$idSession]->{'command_target'} = '';

    	if ($idSession != 1){
    		message_deliver('SYS', $idSession, $sMsg."\n-- DONE --");
    	}
    	
    	return '';
    }
    else{
    	
    	command_done($idSession);
    	return ("-- ERROR: Empty label", 0, 1);
    }
}


sub do_banner {
    my ($idSession, $sArgs) = @_;
    my $sCmd = 'BANNER';
    
	command_start($idSession, $sCmd, 'BANNER');

	# Get the TEXT
	my $sText = command_input($idSession, 'banner_text', 'LINE', $sArgs, '', "Text\a: ", $sCmd);
	if ($sText eq ''){ return ('', 1); }

	my $sBanner =  `echo  $sText | fabs -a`;
	if (/fabs is not recognized/i =~ $sBanner) {
		#local_error("Can't find fabs utility - see README");
		return "Can't find fabs utility - see README";
	}
	else {
		$aSessions[$idSession]->{VARS}->{'banner_text'} = '';
		
		command_done($idSession);
        return $sBanner;
    }
    
    command_done($idSession);
    return '';
}

sub do_host_command {
	my ($idSession, $sArgs) = @_;
    
	my $sCmd = 'HOSTCMD';
	
	# Get the COMMAND
	my $sCommand = command_input($idSession, 'hostcmd_cmd', 'LINE', $sArgs, '', "Cmd\a: ", $sCmd);
	if ($sCommand eq ''){ return ('', 1); }

	my $sOut;
	eval {$sOut = `$sCommand`};
	
	$aSessions[$idSession]->{VARS}->{'hostcmd_cmd'} = '';
	
	return $sOut;
}


sub do_qbf {
    my ($idSession, $sArgs) = @_;
	my $sCmd = 'QBF';
	
	command_start($idSession, $sCmd, 'QBF TEST');

	command_done($idSession);
    return $qbf_string;
}


sub generate_test{
    my ($idSession, $sCmd, $sTitle, $sString, $nLines) = @_;

	if (length($sString) < 1){
		return '';
	}

	command_start($idSession, $sCmd, $sTitle);
	
	my $sTestLine = substr($sString x int($aConfigs{Columns} / length($sString)), 0, $aConfigs{Columns} - 1);
	my $sOut      = '';
	
	if (defined $nLines && $nLines =~ /^\d{1,3}$/){
		$nLines  = int($nLines);
		$sTestLine = substr($sTestLine, 0, $aConfigs{Columns} - 5);
		for (my $n = 1; $n <= $nLines; $n++){
			$sOut .= sprintf('%03d ', $n).$sTestLine."\n";
		}
	}
	else{
		$sOut = $sTestLine."\n";
	}
	
	command_done($idSession);
	return $sOut;
}


sub do_ryry {
    my ($idSession, $sArgs) = @_;
    my @aArgs = split(/\s+/, $sArgs);
    
    return generate_test($idSession, 'RYRY', 'RYRY TEST', 'RY', $aArgs[0]);
}

sub do_r6r6 {
    my ($idSession, $sArgs) = @_;
    my @aArgs = split(/\s+/, $sArgs);
    
    return generate_test($idSession, 'R6R6', 'R6R6 TEST', 'R6', $aArgs[0]);
}

sub do_rrrr {
    my ($idSession, $sArgs) = @_;
    my @aArgs = split(/\s+/, $sArgs);
    
    return generate_test($idSession, 'RRRR', 'RRRR TEST', 'R', $aArgs[0]);
}

sub do_raw_5bit {
    my ($idSession, $sArgs) = @_;
    
	my $sCmd = 'RAW5BIT';
    command_start($idSession, $sCmd, 'RAW TEST 5 BITS');
    
	my $sOut = '';

	#$sOut .= "+------------- LTRS ------------- ------------- FIGS -------------+\n";
	#$sOut .= "+00000000001111111111222222222233 00000000001111111111222222222233+\n";
	#$sOut .= "+01234567890123456789012345678901 01234567890123456789012345678901+\n";
	#$sOut .= "+-------------------------------- --------------------------------+\n";
	$sOut .= '$RAWMODEON ';

# Missing $TRANSCODEOFF escape implementation
	for (my $i = 0; $i < 32; $i++){
		$sOut .= chr($i);
	}	
	$sOut .= " ";
	for (my $i = 0; $i < 32; $i++){
		$sOut .= chr($i);
	}	
	$sOut .= '$RAWMODEOFF ';
	$sOut .= "\n";
	#$sOut .= "+-------------------------------- --------------------------------+\n";

	command_done($idSession);

	return $sOut;
}
    
sub do_raw_6bit {
    my ($idSession, $sArgs) = @_;
    
	my $sCmd = 'RAW6BIT';
    command_start($idSession, $sCmd, 'RAW TEST 6 BITS');
    
	my $sOut = '';

	$sOut .= "+------------- LTRS -------------------------- LTRS -------------+\n";
	$sOut .= "+0000000000111111111122222222223333333333444444444455555555556666+\n";
	$sOut .= "+0123456789012345678901234567890123456789012345678901234567890123+\n";
	$sOut .= "+----------------------------------------------------------------+\n";
	$sOut .= "\n";
	for (my $i = 0; $i < 64; $i++){
		$sOut .= chr($i);
	}	

	$sOut .= "\n";
	$sOut .= "+------------- FIGS -------------------------- FIGS -------------+\n";
	$sOut .= "+0000000000111111111122222222223333333333444444444455555555556666+\n";
	$sOut .= "+0123456789012345678901234567890123456789012345678901234567890123+\n";
	$sOut .= "+----------------------------------------------------------------+\n";
	
	
	$sOut .= "\n";
	for (my $i = 0; $i < 64; $i++){
		$sOut .= chr($i);
	}	
	$sOut .= "\n";
	$sOut .= "+-------------------------------- --------------------------------+\n";

	command_done($idSession);
	return $sOut;
}

# Legacy, left for comparison only
sub raw_test {
	(my $max) = @_;
	
	my $sOut;
	
	$sOut .= "\n------- LTRS ----------\n";
	for (my $i = 0; $i <= $max; $i++){
		$sOut .= "----- $i -----\n".$ltrs;
		for (my $j = 0; $j < 7; $j++){
			$sOut .= chr($i).chr(4);
		}
		$sOut .= $cr.$lf;
	}
    
    $sOut .= "\n------- FIGS ----------\n";

    for (my $i = 0; $i <= $max; $i++) {
		$sOut .= "----- $i -----\n".$figs;
		for (my $j = 0; $j < 7; $j++) {
			$sOut .= chr($i).chr(4);
		}
		$sOut .= $cr.$lf;
	}
	
	return $sOut;
}


sub do_email_send{
    my ($idSession, $sArgs) = @_;
    my $sCmd = 'EMAIL';
    
	my @aArgs = split(/\s+/, $sArgs);

	my $sServer  = $aConfigs{EmailSMTP};
	my $sAccount = $aConfigs{EmailAccount};
	my $sPass    = $aConfigs{EmailPassword};
	my $sFrom    = $aConfigs{EmailFrom};
		
    command_start($idSession, $sCmd, 'SEND EMAIL');
	
	if ($sServer eq '' || $sAccount eq '' || $sPass eq '' || $sFrom eq ''){
		return "Missing SMTP configuration. See README about heavymetal.cfg";
	}

	my $sTo      = '';
	my $sSubject = '';
	my $sMessage = '';

	# Try to get TO from the command line
	$sTo = (exists($aArgs[0]) && $aArgs[0] ne '') ? $aArgs[0] : '';
	
	# Try to get SUBJECT from the command line
	if ($sArgs ne ''){
		$sSubject = $sArgs;
		$sSubject =~ s/^\S+\s+//;
	}

	# Get the TO
	$sTo = command_input($idSession, 'email_to', 'LINE', $sTo, '^[\w\-\.]+[\@\:\$][\w\-\.]+\.\w+$', "\aTo: ", $sCmd);
	if ($sTo      eq ''){ return ('', 1); }

	# Get the SUBJECT
	$sSubject = command_input($idSession, 'email_subject', 'LINE', $sSubject, '', "Subject\a: ", $sCmd);
	if ($sSubject eq ''){ return ('', 1); }
	
	# Get the MESSAGE
	$sMessage = command_input($idSession, 'email_message', 'BLOCK', $sMessage, '', "\aMessage: ", $sCmd);
	if ($sMessage eq ''){ return ('', 1); }
	
	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Sending...\n\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }


	$sTo =~ s/[\@\$\:]/\@/;

	eval {
		my $oSMTP = Net::SMTP->new($sServer);

		# Auth
		$oSMTP->datasend("AUTH LOGIN\n");
		$oSMTP->response();
		#  -- Enter sending email box address username below.  We will use this to login to SMTP --
		$oSMTP->datasend(encode_base64($sAccount));
		$oSMTP->response();
		#  -- Enter email box address password below.  We will use this to login to SMTP --
		$oSMTP->datasend(encode_base64($sPass));
		$oSMTP->response();  
			
		$oSMTP->mail($sFrom);
		$oSMTP->to($sTo);
		$oSMTP->data();
		$oSMTP->datasend("From: $sFrom\r\n");
		$oSMTP->datasend("To: $sTo\r\n");
		$oSMTP->datasend("Subject: $sSubject\r\n\r\n");
		$oSMTP->datasend("$sMessage\r\n");
		$oSMTP->datasend("[Message sent using HeavyMetal v$sGlobalVersion ($sGlobalRelease) Teletype Control Program]");
		$oSMTP->dataend();
		$oSMTP->quit();

		$aSessions[$idSession]->{VARS}->{'email_to'}     = '';
		$aSessions[$idSession]->{VARS}->{'email_subject'}= '';
		$aSessions[$idSession]->{VARS}->{'email_message'}= '';
		$aSessions[$idSession]->{VARS}->{'ready'}	     = '';

		command_done($idSession);
		return ('-- EMAIL SENT --', 0, 1);
		
	};
	if ($@) {
		command_done($idSession);
		return ("-- ERROR: Failed to complete email command: $@", 0, 1);
	}


}


# Is it safe to call $oTkMainWindow->update() here to show progress on mail
# fetching?
# !!! This commands should be made asynch so host can continue operations while retrieving msgs
sub do_email_fetch {
    my ($idSession, $sArgs) = @_;
    
    my $sCmd = 'CHECKMAIL';
    
    command_start($idSession, $sCmd, 'CHECK EMAIL');
    
	my @aArgs = split(/\s+/, $sArgs);

	my $sAction = (exists $aArgs[0] && $aArgs[0] ne '') ? uc($aArgs[0]) : 'HEADERS';
	my $nMsgId  = 0;

	my $sServer  = (exists $aArgs[1] && $aArgs[1] ne '') ? $aArgs[1] : $aConfigs{EmailPOP};
	my $sAccount = (exists $aArgs[2] && $aArgs[2] ne '') ? $aArgs[2] : $aConfigs{EmailAccount};
	my $sPass    = (exists $aArgs[3] && $aArgs[3] ne '') ? $aArgs[3] : $aConfigs{EmailPassword};

	if ($sAction ne '' && $aSessions[$idSession]->{VARS}->{'email_action'} eq ''){
		$aSessions[$idSession]->{VARS}->{'email_action'}   = $sAction;
	}
	if ($sServer ne ''){
		$aSessions[$idSession]->{VARS}->{'email_server'}   = $sServer;
	}
	if ($sAccount ne ''){
		$aSessions[$idSession]->{VARS}->{'email_account'}  = $sAccount;
	}
	if ($sPass ne ''){
		$aSessions[$idSession]->{VARS}->{'email_pass'}     = $sPass;
	}

	# Get Action
	$sAction  = command_input($idSession, 'email_action', 'LINE', '', '^(ALL|HEADERS|GREENKEYS|\d+)$', "Action\a: ", $sCmd);
	if ($sAction eq ''){ return ('', 1); }

	# Get Server
	$sServer  = command_input($idSession, 'email_server', 'LINE', $sServer, '', "Server\a: ", $sCmd);
	if ($sServer eq ''){ return ('', 1); }

	# Get Account
	$sAccount  = command_input($idSession, 'email_account', 'LINE', $sAccount, '', "Account\a: ", $sCmd);
	if ($sAccount eq ''){ return ('', 1); }

	# Get Password
	$sPass  = command_input($idSession, 'email_pass', 'LINE', $sPass, '', "Password\a: ", $sCmd);
	if ($sPass eq ''){ return ('', 1); }

	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Fetching...\n\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }


	if ($sAction =~ /^\d+$/){
		$nMsgId  = $sAction;
		$sAction = 'ALL';
	}

	if ($sAction ne 'ALL' && $sAction ne 'HEADERS' && $sAction ne 'GREENKEYS'){
		$sAction = 'HEADERS';
	}

	if ($sServer eq '' || $sAccount eq '' || $sPass eq '') {
		return "-- ERROR: Missing POP configuration. See README about heavymetal.cfg";
	}
	
	my $sOut = '';
	
	eval {
		my $oPOP;
	
		$oPOP = Net::POP3->new($sServer);
		if (!$oPOP){
			local_warning("Can't open connection to mail server $sServer: $!");
		}

		if (!defined($oPOP->login($sAccount, $sPass))){
			local_warning("Can't login using $sAccount:$sPass: $!");
		}

		my $aMessages = $oPOP->list();
		if ($aMessages){
			local_warning("Can't get message list: $!");
		}

		my $idMsg;

		my $nMessages = scalar (keys %$aMessages);
		
		$sOut = "-- Messages in mailbox: $nMessages\n";

		$sMainStatus = $sOut;
		$oTkStatus->configure(-text=> $sMainStatus);
		
		my $nCount = 0;
		
		my @aList = ();

		if ($nMsgId > 0){
			if (exists $aMessages->{$nMsgId}){
				@aList = ($nMsgId);
			}
			else{
				$sOut .= "-- Error: That email is not in the list\n";
			}
		}
		else{
			@aList = reverse(sort(keys(%$aMessages)));
		}
		
		foreach $idMsg (@aList) {
			$nCount++;
			$sMainStatus = "Fetching message $nCount of $nMessages";
			$oTkStatus->configure( -text=> $sMainStatus);
			$oTkMainWindow->update();
			
#			if ($current_action eq "CANCEL") {
#				$current_action = "";
#				return;
#			}
			
			my $sMessage = $oPOP->get($idMsg);
			if (defined $sMessage) {
				my $sLine;
				my $sHeader = "";
				my $sBody   = "";
				my $bBody   = 0;
				my $bShowHeader = 1;
				my $bShowBody   = ($sAction eq "ALL") ? 1 : 0;

				foreach $sLine (@$sMessage) {
					if ($bBody){
						if ($bShowBody) {
							$sBody .= $sLine;
						}
					}
					elsif($bShowHeader){
						chomp($sLine);
						if ($sLine =~ /^Subject:/i) {
							$sHeader .= $sLine."\n";
							if ($sAction eq "GREENKEYS") {
								if ($sLine =~ /Greenkeys/i) {
									$bShowBody = 1;
								}
								else {
									$bShowHeader = 0;
								}
							}
						}
						elsif ($sLine =~ /^To:/i) {
							$sHeader .= $sLine."\n";;
						}
						elsif ($sLine =~ /^From:/i) {
							$sHeader .= $sLine."\n";;
						}
						elsif ($sLine =~ /^Date:/i) {
							$sHeader .= $sLine."\n";;
						}
						elsif($sLine eq ''){
							$bBody = 1;
						}
					}
					else{
						last;
					}

				}
				if ($bShowHeader) {	
					$sOut .= sprintf("---- Msg: %3d -- ID: %3d ----\n", $nCount, $idMsg);
					$sOut .= $sHeader."\n";
					if ($bShowBody){
						$sOut .= $sBody."\n";
					}
				}
			} 
			else {
				$sOut .= sprintf("---- Msg: %3d -- ID: %3d - Error: %s\n", $nCount, $idMsg, $!);
			}
		}
	};
	if ($@) {
		command_done($idSession);
		return ("-- ERROR: Failed to complete email command: $@", 0, 1);
	}

	$sOut .= "\n-- DONE --";
	
    $aSessions[$idSession]->{VARS}->{'email_action'} = '';
    $aSessions[$idSession]->{VARS}->{'ready'} = '';
    
    redraw_status_window();
    
	command_done($idSession);
	
	return ($sOut, 0, 0);
}


sub do_quote_portfolio {
    my ($idSession, $sArgs) = @_;
    
    my $sCmd = 'QUOTE';
    
    command_start($idSession, $sCmd, 'STOCK PORTFOLIO');
    
	return do_quote($idSession, $aConfigs{StockPortfolio});
}

sub do_quote {
	my ($idSession, $sArgs, $bNoTitle) = @_;

	if (!$Modules{'Finance::YahooQuote'}->{loaded}){
		return '-- ERROR: Finance::YahooQuote perl module not loaded';
	}

	my $sCmd = 'QUOTE';
		
	if ($bNoTitle){
		$aSessions[$idSession]->{command_calls}++;
	}
	else{
    	command_start($idSession, $sCmd, 'STOCK QUOTES');
    }

	# Get Symbols
	my $sSymbols  = command_input($idSession, 'quote_symbols', 'LINE', $sArgs, '', "Symbols\a: ", $sCmd);
	if ($sSymbols eq ''){ return ('', 1); }

	my @aSymbols = split(/\s+/, $sSymbols);

	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Fetching...\n\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }

	my $sOut = '';
	my @aQuotes = getquote(@aSymbols);
	foreach my $aQuote (@aQuotes) {
		my $nChange = $$aQuote[$aStockColumns{"Change"}];
		my $sUpDown = ($nChange < 0) ? 'DOWN' : (($nChange > 0) ? ' UP ' : '-NC-');
		
		$sOut .= sprintf("  %-5s %4s %+ 6.3f % 8.3f %s\n", 
			$$aQuote[$aStockColumns{"Symbol"}], 
			$sUpDown, 
			$nChange, 
			$$aQuote[$aStockColumns{"Last"}],
			$$aQuote[$aStockColumns{"Name"}]);
	}
	
	
	$sOut .= "\n-- DONE --\n";
	
	$aSessions[$idSession]->{VARS}->{'quote_symbols'} = '';
	$aSessions[$idSession]->{VARS}->{'ready'}         = '';
	
	command_done($idSession);
	
	return ($sOut, 0, 0);
}

sub do_quote_full {
    my ($idSession, $sArgs) = @_;
    
	if (!$Modules{'Finance::YahooQuote'}->{loaded}){
		return '-- ERROR: Finance::YahooQuote perl module not loaded';
	}

    my $sCmd = 'FULLQUOTE';
    
    command_start($idSession, $sCmd, 'FULL STOCK QUOTES');

	# Get Symbols
	my $sSymbols  = command_input($idSession, 'quote_symbols', 'LINE', $sArgs, '', "Symbols\a: ", $sCmd);
	if ($sSymbols eq ''){ return ('', 1); }

	my @aSymbols = split(/\s+/, $sSymbols);

	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Fetching...\n\n", $sCmd);
	if ($bReady eq ''){ return ('', 1); }

	my $sOut = '';
	my @aQuotes = getquote(@aSymbols);
	foreach my $aQuote (@aQuotes) {
		my $nChange = $$aQuote[$aStockColumns{"Change"}];
		my $sUpDown = ($nChange < 0) ? 'DOWN' : (($nChange > 0) ? ' UP ' : '-NC-');
		
		$sOut .= sprintf("\n---- %-5s %4s %+ 6.3f % 8.3f %s\n", 
			$$aQuote[$aStockColumns{"Symbol"}], 
			$sUpDown, 
			$nChange, 
			$$aQuote[$aStockColumns{"Last"}],
			$$aQuote[$aStockColumns{"Name"}]);

		foreach my $sCol (keys %aStockColumns){
			$sOut .= sprintf("%20s: %s\n", $sCol, $$aQuote[$aStockColumns{$sCol}]);
		}

	}
	
	
	$sOut .= "\n-- DONE --";
	
	$aSessions[$idSession]->{VARS}->{'quote_symbols'} = '';
	$aSessions[$idSession]->{VARS}->{'ready'}         = '';
	
	command_done($idSession);
	
	return ($sOut, 0, 0);
}


# Very simple helper function in_array()
sub in_array {
     my ($arr,$search_for) = @_;
     my %items = map {$_ => 1} @$arr; # create a hash out of the array values
     return (exists($items{$search_for}))?1:0;
 }

#------------------------------------------------------------------------
# X10 code snagged from Bill Birthisel's Misterhouse
# http://www.misterhouse.org
#------------------------------------------------------------------------

sub send_cm17 {
    return unless ( 2 == @_ );
    return ControlX10::CM17::send (@_);
}
sub send_cm17_ir {
    return unless ( 2 == @_ );
    return ControlX10::CM17::send_ir (@_);
}

sub x10_send {
    my ($oSerialPort, $house_code) = @_;
    
    my ($house, $code) = $house_code =~ /(\S)(\S+)/;

    if (defined $main::config_parms{debug}) {
        $X10_DEBUG = ($main::config_parms{debug} eq 'X10') ? 1 : 0;
    }
    print "CM17: $oSerialPort house=$house code=$code\n" if $X10_DEBUG;
    
    my $data = $table_hcodes{$house};
    unless ($data) {
        print "CM17.pm error. Invalid house code: $house\n";
        return;
    }
        # Check for +-## brighten/dim commands (e.g. 7+5  F-95)
        # Looks like it takes 7 levels to go full bright/dim (14%).
    if ($code =~ /(\S)([\+\-])(\d+)/) {
        my $device= $1;
        my $dir   = $2;
        my $level = $3;
        my $ok;
        print "Running CM17 dim/bright loop: device=$device $dir=$dir level=$level\n" if $X10_DEBUG;
        # The CM17 dim/bright has not device address, so we must first
        # address the device (need to make sure it is on anyway)
        &send($oSerialPort, $house . $device . 'J');
        my $code = ($dir eq '+') ? 'L' : 'M';
        while ($level >= 0) {
            $ok = &send($oSerialPort, $house . $code);
            $level -= 14;
        }
        return $ok;
    }

        # Check for #J/#K or L/M/O/N
    my $data2 = $table_dcodes{$code};
    $data2 = $table_dcodes{substr($code, 1)} unless $data2;

    unless ($data2) {
        print "CM17.pm error. Invalid device code: $code.\n";
        return;
    }
        # Header + data + footer = 40 bits
    &send_bits($oSerialPort, '1101010110101010' . $data . $data2 . '10101101'); 
}

sub send_ir {
    my ($oSerialPort, $device_command) = @_;

        # Device is optional
    my ($device, $command) = $device_command =~ /(\S*) +(\S+)/;
    print "db sending cm17 ir data device=$device command=$command\n" if $main::config_parms{debug} eq 'IR';
    my $data;
        # Send device code
    if ($device) {
        unless ($data = $table_device_codes{uc $device}) {
            print "Warning, cm17 device command not found: $device\n";
            return;
        }
        &send_ir_bits($oSerialPort, $data);
    }

        # Send command code
    unless ($data = $table_ir_codes{uc $command}) {
        print "Warning, cm17 ir command not found: $command\n";
        return;
    }
    &send_ir_bits($oSerialPort, $data);
}

sub send_ir_bits {
    my ($oSerialPort, $data) = @_;
    &send_bits($oSerialPort, '1101010110101010' . $data . '10101101'); 
    $data = '1000001101111111';
    &send_bits($oSerialPort, '1101010110101010' . $data . '10101101'); 
}

sub send_bits {
    my ($oSerialPort, $bits) = @_;
    my @bits = split //, $bits;

        # Reset the device
    $oSerialPort->dtr_active(0);
    $oSerialPort->rts_active(0);
    select (undef, undef, undef, .100); # How long??


        # Turn the device on
    $oSerialPort->dtr_active(1);
    $oSerialPort->rts_active(1);
    select (undef, undef, undef, .20);  # How long??

    print "CM17: Sending: " if $X10_DEBUG;
    while (@bits) {
        my $bit = shift @bits;
        
        if ($bit) {
            $oSerialPort->pulse_dtr_off(1);
            print "1" if $X10_DEBUG;
        }
        else {
            $oSerialPort->pulse_rts_off(1);
            print "0" if $X10_DEBUG;
        }
    }
        # Leave the device on till switch occurs ... emperically derived 
        #  - 50->70  ms seemed to be the minnimum
    $oSerialPort->dtr_active(1);
    $oSerialPort->rts_active(1);
    select (undef, undef, undef, .150);

    print " done\n" if $X10_DEBUG;

        # Turn the device off
    $oSerialPort->dtr_active(0);
    $oSerialPort->rts_active(0);

}



#------------------------------------------------------------------------
# - - - - - - - - - - - - - - TELNET SUBS - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------

sub telnet_negotiate{
	my ($rSocket, $sOptions) = @_;
	print "\nTELNET NEGOTIATE: $sOptions\n";
	return undef;
}

sub telnet_init{
	
	if ($aConfigs{TelnetNegotiate} && !$Modules{'IO::Socket::Telnet'}->{loaded}){
		$aConfigs{TelnetNegotiate} = 0;
	}
		
	if ($aConfigs{TelnetNegotiate}){
		$sckTelnetListener = IO::Socket::Telnet->new(
			LocalAddr => '0.0.0.0', 
			LocalPort => int($aConfigs{TelnetPort}),
			Listen => 10, 
			Reuse=>1
		);
	}
	else{
		$sckTelnetListener = IO::Socket::INET->new(
			LocalAddr => '0.0.0.0', 
			LocalPort => int($aConfigs{TelnetPort}),
			Listen => 10, 
			Reuse=>1
		);
	}
	
	if (!defined($sckTelnetListener) || !$sckTelnetListener){
		if ($aConfigs{Debug}){ logDebug("ERROR: Could not initiate listener socket: $@\n"); }
		$aConfigs{TelnetEnabled} = 0;
    	return 0;
    }
 
	# Do I need to do this?
	$sckTelnetListener->autoflush(1);
	
	# IO Select Sets for main thread
	if (!defined $oTelnetReadSet){
		$oTelnetReadSet      = new IO::Select();
	}
	if (!defined $oTelnetWriteSet){
		$oTelnetWriteSet     = new IO::Select();
	}
	if (!defined $oTelnetExceptionSet){
		$oTelnetExceptionSet = new IO::Select();
	}

    $oTelnetReadSet->add($sckTelnetListener);
    $oTelnetExceptionSet->add($sckTelnetListener);

	if ($aConfigs{Debug}){ logDebug("\nTelnet server listening at port $aConfigs{TelnetPort}");}


    return 1;
}


sub telnet_toggle{
	my ($bEnable) = @_;
	if (defined $bEnable){
		$aConfigs{TelnetEnabled} = $bEnable;
	}
	
	my $sOut = '';
	if ($aConfigs{TelnetEnabled}){
		if ($aConfigs{Debug}){ logDebug("\nEnabled Telnet\n"); }
		telnet_init();
		$sOut = '-- Telnet Enabled';
	}
	else{
		if ($aConfigs{Debug} > 0){ logDebug("\nDisabled Telnet\n"); }
		my $nCount = telnet_close('ALL', 'Telnet Disabled');
		$sOut = '-- Telnet Disabled: '.$nCount.' socket(s) disconnected';
	}
	
	redraw_status_window();
	return $sOut;
}

sub telnet_io{
	
	my $sckRead;
	my $sckWrite;
	
	my $n;
	
	my ($aReadyRead, $aReadyWrite, $aReadyException) = IO::Select->select($oTelnetReadSet, $oTelnetWriteSet, $oTelnetExceptionSet, 0.001);

	# Loop all exceptions in connections
	foreach $sckRead (@$aReadyException){
		telnet_close($sckRead, "Socket Exception");
	}
	
	
	# Loop all read connections
	if (defined($aReadyRead)){
		foreach $sckRead (@$aReadyRead){

			
				
			if ($sckRead eq $sckTelnetListener){
				# NEW CONNECTION
				if ($aConfigs{TelnetEnabled}){
					$nSessionsCount++;
					
					my $idSession  = $NewSessionId++;
					
					my $sckClient  = $sckRead->accept();
					
					if ($aConfigs{TelnetNegotiate}){
						$sckClient->telnet_simple_callback(\&telnet_negotiate);
						$sckClient->do(chr(1));
					}
					
					my $remoteip   = $sckClient->peerhost();
					my $remoteport = $sckClient->peerport();
					my $localip    = $sckClient->sockhost();
					my $localport  = $sckClient->sockport();
					
					$oTelnetReadSet->add($sckClient);
					$oTelnetWriteSet->add($sckClient);
					$oTelnetExceptionSet->add($sckClient);
					
				
					$aSessions[$idSession] = {
						'id'          => $idSession, 
						'type'        => 'TELNET', 
						'IN'          => '', 
						'OUT'         => '',
						'SOCKET'      => $sckClient,
						'status'      => 1, 
						'direction'   => 0, 
						'auth'        => 0, 
						'target'      => 'ALL', 
						'source'      => 'ALL', 
						'user'        => '', 
						'remote_ip'   => $remoteip,
						'remote_port' => $remoteport,
						'prompt'      => 1,
						'disconnect'  => 0,
						'address'     => $remoteip,
						'command_last'=> '',
						'input_type'  => '', 
						'input_var'   => '', 
						'input_prompt'=> '',
						'echo_input'  => 1,
						'echo_msg'    => 0, 
						'clean_line'  => 1,
						'command'     => '',
						'column'      => 0,
						'label_source'=> 1
					};
					
					$aTelnetSockets{"$sckClient"} = $idSession;
						
					$aSessions[$idSession]->{OUT} = "\r\n$aConfigs{TelnetWelcome}\n$aConfigs{SystemPrompt}";
					
					
					if ($aConfigs{Debug}){ logDebug("\nNew client ($idSession) from $remoteip\n");}
				}
				else{
					my $sckClient = $sckRead->accept();         
					my $remoteip  = $sckClient->peerhost();
					$sckClient->close();
					
					# Note: As we were not really connected yet we don't increment/decrement the telnet counter
					
					if ($aConfigs{Debug}){ logDebug("\nNew client from $remoteip rejected\n");}
				}
			}
			else{
				# CLIENT->SERVER
				
				my $idSession = $aTelnetSockets{"$sckRead"};
				
				my $sChunk;
				my $nBytes = $sckRead->sysread($sChunk, 4096); #sysread
				
				# We have incomming data
				if(defined($nBytes) && $nBytes > 0){
				#if(defined($nBytes)){
					
					# Fix issue with backspace not deleting character
					$sChunk =~ s/$bs/$bs $bs/g;
					
					$aSessions[$idSession]->{IN} .= $sChunk;
					
					my $nPosChunk;
								
					# INBOUND
					if ($aSessions[$idSession]->{'direction'} == 0){
						
						
						my $nPos = index($aSessions[$idSession]->{IN}, "\n");
						if ($nPos >= 0){

							
														
							# Echo the first part of the chunk up to the \n including it
							my $nLinesCount = 0;
							if ($aSessions[$idSession]->{echo_input}){
								$aSessions[$idSession]->{OUT} .= substr($sChunk, 0, index($sChunk, "\n") + 1, '');	
							}

							while($nPos >= 0){
								
								if ($nLinesCount > 0){
									if ($aSessions[$idSession]->{echo_input}){
										$aSessions[$idSession]->{OUT} .= substr($sChunk, 0, index($sChunk, "\n") + 1, '');	
									}
								}

								# Get the complete line and clean the \r\n
								my $sLine = substr($aSessions[$idSession]->{IN}, 0, $nPos + 1, '');
								$sLine =~ s/[\r\n]+$//g;
								
								# Process backspaces
								while (($n = index($sLine, $bs)) >= 0){
									if ($n > 0){
										substr($sLine, $n - 1, 2, '');
									}
									else{
										substr($sLine, 0, 1, '');
									}
								}
								
								# Decode escape sequences TO ASCII
								if ($aConfigs{EscapeEnabled} && index($sLine, $aConfigs{EscapeChar}) >= 0){
									$sLine = escape_to_ascii($idSession, $sLine);
								}
								
								# AUTHENTICATED SESSION
								if ($aSessions[$idSession]->{'auth'}){
									# Detect and execute commands or send message
									process_line($idSession, $sLine);
									
									if ($aSessions[$idSession]->{input_type} eq '' && $aSessions[$idSession]->{prompt}){
										#$aSessions[$idSession]->{OUT} .= "\r\n$aConfigs{SystemPrompt}";
									}
									
								}
								# UNAUTHENTICATED SESSION
								else{
									# Catchall for unauthenticated sessions
									my $sResult = "-- Unauthenticated user";
									if (substr($sLine, 0, 1) eq '\\' || substr($sLine, 0, 1) eq $aConfigs{EscapeChar}){
										# PING		
										if( $sLine =~ /^.ping$/i ){
											$sResult = 'PONG!';
										}
										# LOGIN
										elsif( $sLine =~ /^.login(\s+(\S.*))?$/i ){
											$sResult = do_login($idSession, $2);
										}
									}
									elsif ($sLine eq ''){
										$sResult = '';
									}
	
									
									$aSessions[$idSession]->{OUT} .= $sResult."\r\n$aConfigs{SystemPrompt}";
	
								}
								
								$nLinesCount++;
								$nPos = index($aSessions[$idSession]->{IN}, "\n");
							}
							
							# Echo the remaining input
							if ($aSessions[$idSession]->{echo_input}){
								if ($sChunk ne ''){
									$aSessions[$idSession]->{OUT} .= $sChunk;
								}
							}
						}
						else{
							# Echo the available input
							if ($aSessions[$idSession]->{echo_input}){
								$aSessions[$idSession]->{OUT} .= $sChunk;
							}
						}
	
					}
					# OUTBOUND Connection, incomming data
					else{
						# Detect if we have to send the prompt or not
						#my $bNoPrompt = substr($aSessions[$idSession]->{IN}, -1, 1) eq "\n" ? 0 : 1;
						#message_send($idSession, $aSessions[$idSession]->{target}, $aSessions[$idSession]->{IN}, $bNoPrompt, 0, $bNoPrompt);

						#my $bNoPrompt = substr($aSessions[$idSession]->{IN}, -1, 1) eq "\n" ? 0 : 1;
						#message_send($idSession, $aSessions[$idSession]->{target}, $aSessions[$idSession]->{IN}, 1, 0, $bNoPrompt);

						message_send($idSession, $aSessions[$idSession]->{target}, $aSessions[$idSession]->{IN}, 1,1,1);

						$aSessions[$idSession]->{IN} = '';
					}

					
				}
				# Either the client or the server has closed the socket remove the socket and close it
				else{
					telnet_close($sckRead, "Connection Closed");
				}
				
				
			}
		}
	}
	
	
	# Loop all write connections
	if (defined($aReadyWrite)){
		# SERVER->CLIENT
		foreach $sckWrite (@$aReadyWrite){
			my $idSession = $aTelnetSockets{"$sckWrite"};
			
			if (defined $idSession && $aSessions[$idSession]->{'type'} eq 'TELNET'){

				if ($aSessions[$idSession]->{'disconnect'} > 0){
					telnet_close($sckWrite, "CMD exit");
				}
				elsif (length($aSessions[$idSession]->{OUT}) == 0){
					if ($aSessions[$idSession]->{input_type} eq 'OUT-EMPTY'){
						# Detect and execute commands once the OUT buffer is empty
						process_line($idSession, '');
					}
				}
				else{
					
					my $sBuffer = $aSessions[$idSession]->{OUT};
					$aSessions[$idSession]->{OUT} = '';
					$sBuffer =~ s/\n/\r\n/g; # Fix the CR LF issue
					
					# Keep tracking of the current column
					for (my $n = 0; $n < length($sBuffer); $n++){
						my $c = substr($sBuffer, $n, 1);
						if ($c eq $cr){
							$aSessions[$idSession]->{column} = 0;
						}
						elsif ($c eq $bs){
							if ($aSessions[$idSession]->{column} > 0){
								$aSessions[$idSession]->{column}--;
							}
						}
						elsif ($c ne $lf && $c ne "\a"){
							$aSessions[$idSession]->{column}++;
						}
					}
					
					$sckWrite->send($sBuffer);
					
				}
			}
		}
	}

	return 1;
}



sub telnet_connect{
	(my $sHost, my $nPort, my $xTarget) = @_;
	
	$nPort = int($nPort);
	
	my $sckClient = new IO::Socket::INET(
		Proto    => 'tcp',
		PeerHost => $sHost,
		PeerPort => $nPort, 
		Timeout  => 10
	);

	if (!$sckClient){
		if (defined $xTarget){
			message_send('SYS', $xTarget, "Could not connect to $sHost:$nPort");
		}
		if ($aConfigs{Debug}){ logDebug("\nCould not connect to $sHost $nPort\n");}
		return '';
	}

	$nSessionsCount++;
	my $idSession  = $NewSessionId++;

	if (defined $xTarget){
		message_send($idSession, $xTarget, "Connected exclusively to session $idSession to $sHost:$nPort\r\n");
	}
	
	my $xSource = defined($xTarget) && $xTarget =~ /^\d+$/ ? $xTarget : 'ALL';
	$xTarget = defined($xTarget) ? $xTarget : 'IN';

	my $sRemoteIP   = $sckClient->peerhost();
	my $nRemotePort = $sckClient->peerport();
	my $sLocalIP    = $sckClient->sockhost();
	my $nLocalPort  = $sckClient->sockport();
					
	$oTelnetReadSet->add($sckClient);
	$oTelnetWriteSet->add($sckClient);
	$oTelnetExceptionSet->add($sckClient);
	
	$aSessions[$idSession] = {
		'id'          => $idSession,
		'type'        => 'TELNET', 
		'IN'          => '', 
		'OUT'         => '',
		'SOCKET'      => $sckClient,
		'status'      => 1, 
		'direction'   => 1, 
		'auth'        => 0, 
		'user'        => '', 
		'target'      => $xTarget, 
		'source'      => $xSource,
		'remote_ip'   => $sRemoteIP,
		'remote_port' => $nRemotePort,
		'prompt'      => 0,
		'disconnect'  => 0,
		'address'     => $sRemoteIP,
		'command_last'=> '',
		'input_type'  => '', 
		'input_var'   => '', 
		'input_prompt'=> '',
		'echo_input'  => 1,
		'echo_msg'    => 0, 
		'clean_line'  => 0,
		'command'     => '',
		'label_source'=> 0,
	};

	$aTelnetSockets{"$sckClient"} = $idSession;
	
	if (exists $aSessions[$xTarget]){
		$aSessions[$xTarget]->{target} = $idSession;
	}
	if ($aConfigs{Debug}){ logDebug("\nNew server ($idSession) $sRemoteIP\n");}
	
	redraw_status_window();
	
	return $idSession;
}


sub telnet_close{
	(my $sckSocket, my $sReason) = @_;
	
	# We kill all inbound connections and the main listener. We do not touch outbound connections.
	if ($sckSocket eq 'ALL'){
		my $nCount = 1;
		
		if ($sckTelnetListener){
			telnet_close($sckTelnetListener, $sReason);
		}
		
		foreach my $thisSession (@aSessions){
			if ($thisSession->{type} eq 'TELNET' && $thisSession->{status} && $thisSession->{direction} == 0){
				telnet_close($thisSession->{SOCKET}, $sReason);
				$nCount++;
			}
		}
		return $nCount;
	}
	
	# Remove from selects
	$oTelnetReadSet->remove($sckSocket);
	$oTelnetWriteSet->remove($sckSocket);
	$oTelnetExceptionSet->remove($sckSocket);

	# Close the socket
	$sckSocket->close();
	
	$nSessionsCount--;
	
	my $idSession = defined($aTelnetSockets{"$sckSocket"}) ? $aTelnetSockets{"$sckSocket"} : 0;
	my $sIP       = 'unknown';
	
	if ($idSession){
		$aSessions[$idSession]->{'status'} = 0;
		$sIP = $aSessions[$idSession]->{'remote_ip'};
	}
	
	if ($aConfigs{Debug}){ logDebug("\nTelnet connection $idSession from $sIP closed: $sReason\n");}

	return 1;
}



#------------------------------------------------------------------------
# - - - - - - - - - - - - - - SESSIONS  - - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------




sub session_set{
	(my $sTarget, my $sVar, my $xVal) = @_;

	my $idSession;
	
	$sTarget = uc($sTarget);
	
	my $nType = 0;
	
	# id is simple and fast
	if ($sTarget =~ /^\d+$/){
		if (exists $aSessions[int($sTarget)]){
			if ($sVar){
				$aSessions[int($sTarget)]->{$sVar} = $xVal;
			}
			return 1;
		}
		else{
			return 0;
		}
	}


	# Choose the condition for selecting the targets
	if ($sTarget eq 'ALL'){
		$nType = 1;
	}
	elsif ($sTarget eq 'TTY' || $sTarget eq 'HOST'){
		$nType = 2;
	}
	elsif ($sTarget eq 'OUT'){
		$nType = 4;
	}
	elsif ($sTarget eq 'IN'){
		$nType = 5;
	}
	elsif ($sTarget =~ /^[\w-]+$/){
		$nType = 3;
	}
	
	if ($nType == 0){
		return undef;
	}
	
	my $nCount = 0;
	
	foreach my $thisSession (@aSessions){
		if ($thisSession->{'status'}){
			
			if ($nType == 1
			|| ($nType == 2 && $thisSession->{'type'}      eq $sTarget) 
			|| ($nType == 3 && $thisSession->{'user'}      eq $sTarget) 
			|| ($nType == 4 && $thisSession->{'direction'} == 1) 
			|| ($nType == 5 && $thisSession->{'direction'} == 0))
			{
				if ($sVar){
					$thisSession->{$sVar} = $xVal;
				}
				$nCount++;
			}
		}
	}

	return $nCount;
}

sub session_get{
	(my $inTarget, my $sVar) = @_;
	
	my $sTarget = lc($inTarget);
	
	my $sField;
	my $nEq    = 0;
	
	# Choose the condition for selecting the targets
	if ($inTarget =~ /^\d+$/){
		if (exists $aSessions[int($inTarget)]){
			return $aSessions[int($inTarget)]->{$sVar};
		}
		return undef;
	}
	elsif ($sTarget eq 'all'){
		$sField  = '';
	}
	elsif ($sTarget eq 'out'){
		$sField  = 'direction';
		$sTarget = 0;
		$nEq     = 1;
	}
	elsif ($sTarget eq 'in'){
		$sField  = 'direction';
		$sTarget = 0;
		$nEq     = 1;
	}
	elsif ($sTarget =~ /^[\w\-]+$/){
		$sField  = 'user';
	}
	elsif ($inTarget =~ /^(\w+)=(.+)$/){
		$sField  = $1;
		$sTarget = $2;
		$nEq     = 0;
		if ($sTarget =~ /^\d+$/){
			$nEq     = 1;
			$sTarget = int($sTarget);
		}
	}
	else{
		return undef;
	}
	
	foreach my $thisSession (@aSessions){
		if ($thisSession->{'status'}){
			if (!$sField || ($nEq == 0 && lc($thisSession->{$sField}) eq $sTarget) || ($nEq == 1 && $thisSession->{$sField} == $sTarget)){
				return $thisSession->{$sVar};
			}
		}
	}
	
	return undef;
}


sub session_count {
	my $nInbound  = 0;
	my $nOutbound = 0;
	my $idSession;
	
	foreach my $thisSession (@aSessions){
		if ($thisSession->{'status'}){
			if ($thisSession->{'direction'} == 0){
				$nInbound++;
			}
			else{
				$nOutbound++;
			}
		}
	}	
	
	return ($nInbound, $nOutbound);
}



#------------------------------------------------------------------------
# - - - - - - - - - - - - - - MESSAGES  - - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------


sub message_send{
	(my $idSource, my $inTarget, my $sText, my $bNoCr, my $bNoSource, my $bNoPrompt) = @_;
	
	my $sOutText;
	my $sPad;
	my $xTarget = uc($inTarget);
	
	my $nSendType = 0;
	
	if ($sText eq ''){
		# We don't deliver empty msgs
		return 0;
	}

	# Choose the condition for selecting the targets
	if ($inTarget =~ /^\d+$/){
		# Most of the time, delivery is done in this way, fast.
		return message_deliver($idSource, int($inTarget), $sText, $bNoCr, $bNoSource, $bNoPrompt);
	}
	elsif ($xTarget eq 'ALL'){
		$nSendType = 1;
	}
	elsif ($xTarget eq 'TTY' || $xTarget eq 'HOST'){
		$nSendType = 2;
	}
	elsif ($xTarget eq 'OUT'){
		$nSendType = 4;
	}
	elsif ($xTarget eq 'IN'){
		$nSendType = 5;
	}
	elsif ($xTarget =~ /^[\w-]+$/){
		$nSendType = 3;
	}
	elsif ($inTarget =~ /^MSN:([\w\.\-]+\@\w+[\w\.\-]+\.\w+)$/i){
		# Deliver external message directly to MSN
		my $sMsnTarget      = $1;
		
		if (!$aConfigs{MsnEnabled}){
			return 'MSN is not enabled';
		}
		elsif(!$MsnConnected){
			return 'MSN is not connected';
		}
		else{
			my $sSource = ($idSource =~ /^\d+$/) ? $aSessions[$idSource]->{user} : $idSource;
			
			$oMSN->call($sMsnTarget, $sText, 'Name'=>'TTY-MSN '.$sSource, 'Effect' => '', 'Color' => '000000', 'Font' => 'Courier');
		}

		return 1;
	}
	
	if ($nSendType == 0){
		return undef;
	}
	
	my $nCount = 0;
	foreach my $thisSession (@aSessions){
		if ($thisSession->{'status'} && $thisSession->{'auth'} > 0){
			if ($nSendType == 1 
				|| ($nSendType == 2 && $thisSession->{'type'} eq $xTarget) 
				|| ($nSendType == 3 && $thisSession->{'user'} eq $xTarget) 
				|| ($nSendType == 4 && $thisSession->{'direction'} == 1) 
				|| ($nSendType == 5 && $thisSession->{'direction'} == 0))
			{
				
				if ($idSource != $thisSession->{'id'} || $thisSession->{echo_msg}){
					if ($aConfigs{Debug} > 1){ logDebug(sprintf("\nSend %d bytes type %d from %d to %d", length($sText), $nSendType, $idSource, $thisSession->{'id'}));}
					my $rv = message_deliver($idSource, $thisSession->{'id'}, $sText, $bNoCr, $bNoSource, $bNoPrompt);
					if ($rv > 0){
						$nCount++;
					}
				}
			}
		}
	}
	return $nCount;
}

sub message_deliver{
	(my $idSource, my $idSession, my $sText, my $bNoCr, my $bNoSource, my $bNoPrompt) = @_;
	
	if (!exists $aSessions[$idSession]){
		if ($aConfigs{Debug} > 1){ logDebug("\nNot delivered $idSession: Invalid");}
		return 0;
	}
	
	my $thisSession = $aSessions[$idSession];

	if (!$thisSession->{'status'}){
		if ($aConfigs{Debug} > 1){ logDebug("\nNot delivered $idSession: Disconnected");}
		return 0;
	}
	
	if ($idSource ne 'SYS' && $thisSession->{'source'} ne 'ALL' && $thisSession->{'source'} ne $idSource){
		if ($aConfigs{Debug} > 1){ logDebug("\nNot delivered $idSession: Source does not match");}
		return 0;
	}
	

	if (!$bNoCr){
		chomp($sText);
	}

	my $sOutText = '';
	my $sPad;
	
	my $sSource = '';
	if (!$bNoSource){
		$sSource = ($idSource =~ /^\d+$/) ? $aSessions[$idSource]->{user} : ($idSource eq 'SYS' ? '' : $idSource);
	}
	
	# Label the source
	$sOutText = $sText;
	if ($thisSession->{'label_source'} && $sSource ne '' && (!$thisSession->{'direction'} || substr($sText, 0 ,1) ne $aConfigs{EscapeChar})){
		$sOutText = "$sSource: $sText";
	}

	# Deal according to session type
	if ($thisSession->{'type'} eq 'HOST'){
		if (!$bNoCr){
			if ($thisSession->{column} > 0){
				$sPad     = ($thisSession->{column} > length($sOutText)) ? " " x ($thisSession->{column} - length($sOutText)) : '';
				$sOutText =  "\r$sOutText$sPad";
			}
			$sOutText .= "\n";
		}
	}
	elsif ($thisSession->{'type'} eq 'TTY'){
		if ($thisSession->{column} > 0){
			# Prepend a new line
			$sOutText = "\n".$sOutText;
		}
		if (!$bNoCr){
			$sOutText .= "\n";
		}
	}
	elsif ($thisSession->{'type'} eq 'MSN'){

	}
	elsif ($thisSession->{'type'} eq 'TELNET'){

		# Outbound
		if ($thisSession->{'direction'}){
			if (!$bNoCr){
				$sOutText .= "\n";
			}
		}
		# Inbound
		else{
			if (!$bNoCr){
				if ($thisSession->{column} > 0){
					if ($thisSession->{clean_line}){
						$sPad     = ($thisSession->{column} > length($sOutText)) ? " " x ($thisSession->{column} - length($sOutText)) : '';
						$sOutText =  "\r$sOutText$sPad";
					}
					else{
						$sOutText =  "\n$sOutText";
					}
				}
				$sOutText .= "\n";
			}
		}
	}

	# Only for inbound
	if ($thisSession->{'direction'} == 0){
		# Deal with System Prompt
		if ($thisSession->{input_type} eq ''){
			if ($thisSession->{'prompt'} && !$bNoPrompt){
				$sOutText .= $aConfigs{SystemPrompt};
			}
			if ($thisSession->{echo_input} && length($thisSession->{IN}) > 0 && index($thisSession->{IN}, "\n") < 0){
				$sOutText .= $thisSession->{IN};
			}
		}
		# Deal with Input Prompt
		else{
			if ($thisSession->{'input_prompt'} ne ''){
				$sOutText .= $thisSession->{'input_prompt'};
			}
			if ($thisSession->{echo_input} && length($thisSession->{IN}) > 0 && index($thisSession->{IN}, "\n") < 0){
				$sOutText .= $thisSession->{IN};
			}
		}
	}
	
	# Append to buffer
	$thisSession->{OUT} .= $sOutText;
			
	if ($aConfigs{Debug} > 1){ logDebug(sprintf("\nDelivered %d (%d): %s%s", $idSession, length($sOutText), debug_chars(substr($sOutText, 0, 40), 0, 1), (length($sOutText) > 30 ? '...' : '')));}

	return 1;
}


#------------------------------------------------------------------------
# - - - - - - - - - - - - - - COMMANDS  - - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------


sub process_line{
	(my $idSession, my $sLine) = @_;

	if ($aConfigs{Debug} > 1){ logDebug(sprintf("\nLine %d (%d): %s%s", $idSession, length($sLine), debug_chars(substr($sLine, 0, 40), 0, 1), (length($sLine) > 30 ? '...' : '')));}

	# Detect and execute commands
	if ($aSessions[$idSession]->{input_type} eq ''){
		if (substr($sLine, 0, 1) eq $aConfigs{EscapeChar} || substr($sLine, 0, 1) eq '\\'){
			my $sResult    = '';
			# REMOTE COMMAND (Line starts with $$)
			if (substr($sLine, 1, 1) eq $aConfigs{EscapeChar} || substr($sLine, 1, 1) eq '\\'){
				my $nCount = session_set($aSessions[$idSession]->{target});
				if ($nCount > 1){
					$sResult = '-- ERROR: You can only send remote commands to single targets';
				}
				elsif ($nCount < 1){
					$sResult = '-- ERROR: Invalid target';
				}
				elsif(session_get($aSessions[$idSession]->{target}, 'status') == 0){
					$sResult = '-- ERROR: Disconnected target';
				}
				elsif(session_get($aSessions[$idSession]->{target}, 'direction') == 0){
					$sResult = '-- ERROR: You can only send commands to outbound connections';
				}
				else{
					# Send the command
					message_send($idSession, $aSessions[$idSession]->{target}, substr($sLine, 1), 0, 1, 1);
				}
				if ($sResult ne ''){
					message_deliver('SYS', $idSession, $sResult, 0, 1, 0);
				}
				return 0;
			}
			# LOCAL COMMAND (Line starts with $)
			else{
				
				my $sOut = '';
				my $nPos = index($sLine, ' ');
				my $sCmd = uc($nPos >= 0 ? substr($sLine, 1, $nPos - 1)  : substr($sLine, 1));
				
				my $sArgs = $sLine;
				$sArgs =~ s/^\S+\s*//;
				$sArgs =~ s/\s+$//;

				my $bContinued = 0;
				my $bError     = 0;
				
				if (exists $aActionCommands{$sCmd}){
					if ($aActionCommands{$sCmd}->{auth} <= $aSessions[$idSession]->{auth}){
						if ($aConfigs{Debug}) { logDebug("\nAction: '$sCmd' Args: '$sArgs'\n"); }
						if ($sCmd ne 'REPEAT'){
							$aSessions[$idSession]->{command_last}  = $sLine;
						}
						$aSessions[$idSession]->{command_calls} = 0;
						($sResult, $bContinued, $bError) = &{$aActionCommands{$sCmd}->{command}}($idSession, $sArgs);
					}
					else{
						$sResult = "-- ERROR: Not enough permissions to execute \"$sCmd\"";	
						$bError  = 1;
					}
				}
				else{
					$sResult = sprintf('-- ERROR: Unknown command "%s%s"', substr($sCmd, 0, 10), length($sCmd) > 10 ? '...':'');	
					$bError  = 1;
				}

				if ($sResult ne ''){
					$bContinued = $bContinued == 1 ? 1 : 0;
					message_deliver('SYS', $idSession, $sResult, $bContinued, $bContinued, $bContinued);
					
					if (!$bError && !$bContinued && $aSessions[$idSession]->{'command_target'}){
						message_send($idSession, $aSessions[$idSession]->{'command_target'}, $sResult, 0, 1, 0);
						$aSessions[$idSession]->{'command_target'} = '';
					}
				}
				return 1;
			}
		}
		else{
			if ($aSessions[$idSession]->{echo_input}){
				message_deliver('SYS', $idSession, '');
			}
			message_send($idSession, $aSessions[$idSession]->{target}, $sLine);
			return 0;
		}
	}
	else {
		# AWAITING INPUT: LINE
		if ($aSessions[$idSession]->{input_type} eq 'LINE'){
			if ($aSessions[$idSession]->{'input_var'} ne ''){
				$sLine =~ s/\s+$//;
				$aSessions[$idSession]->{'VARS'}->{$aSessions[$idSession]->{'input_var'}} = $sLine;
			}
			$aSessions[$idSession]->{input_type} = '';
		}
		# AWAITING INPUT: BLOCK
		elsif ($aSessions[$idSession]->{input_type} eq 'BLOCK'){
			if ($sLine !~ /^NNNN\s*$/i){
				if ($aSessions[$idSession]->{'input_var'} ne ''){
					$aSessions[$idSession]->{'VARS'}->{$aSessions[$idSession]->{'input_var'}} .= $sLine."\n";
				}
			}
			else{
				$aSessions[$idSession]->{input_type} = '';
			}
		}
		# AWAITING INPUT: OUT-EMPTY
		if ($aSessions[$idSession]->{input_type} eq 'OUT-EMPTY'){
			if ($aSessions[$idSession]->{'input_var'} ne ''){
				$aSessions[$idSession]->{'VARS'}->{$aSessions[$idSession]->{'input_var'}} = 1;
			}
			$aSessions[$idSession]->{input_type} = '';
		}

		
		# NEXT COMMAND
		if ($aSessions[$idSession]->{input_type} eq ''){

			if ($aSessions[$idSession]->{command}){
				
				my $sCmdRef = $aSessions[$idSession]->{command};
				
				my $sResult    = '';
				my $bContinued = 0;
				my $bError     = 0;
				
				$aSessions[$idSession]->{command} = '';
				
				if (exists($aActionCommands{$sCmdRef})){
					if ($aActionCommands{$sCmdRef}->{auth} <= $aSessions[$idSession]->{auth}){
						($sResult, $bContinued, $bError) = &{$aActionCommands{$sCmdRef}->{command}}($idSession, '');	
					}
					else{
						$sResult = "-- ERROR: Not enough permissions to execute \"$sCmdRef\"";	
						$bError  = 1;
					}
				}
				else{
					$sResult = sprintf('-- ERROR: Unknown command "%s%s"', substr($sCmdRef, 0, 10), length($sCmdRef) > 10 ? '...':'');	
					$bError  = 1;
				}
				
				if ($sResult ne ''){
					$bContinued = $bContinued == 1 ? 1 : 0;
					message_deliver('SYS', $idSession, $sResult, $bContinued, $bContinued, $bContinued);
					
					if (!$bError && !$bContinued && $aSessions[$idSession]->{'command_target'}){
						message_send($idSession, $aSessions[$idSession]->{'command_target'}, $sResult, 0, 1, 0);
						$aSessions[$idSession]->{'command_target'} = '';
					}

				}

				return 1;
			}
		}
		return 0;
	}
	return 0;
}






#------------------------------------------------------------------------
# - - - - - - - - - - - - - - MSN MESSENGER - - - - - - - - - - - - - - -
#------------------------------------------------------------------------

sub msn_init{
	
	# Check dependencies
	if ( !$Modules{'MSN'}->{loaded}           || !$Modules{'URI::Escape'}->{loaded}    || !$Modules{'Data::Dumper'}->{loaded}
	  || !$Modules{'HTTP::Request'}->{loaded} || !$Modules{'LWP::UserAgent'}->{loaded} || !$Modules{'HTML::Entities'}->{loaded}
	  || !$Modules{'Digest::MD5'}->{loaded}   || !$Modules{'Digest::SHA1'}->{loaded}   || !$Modules{'Math::BigInt'}->{loaded}
	  || !$Modules{'MIME::Base64'}->{loaded}
	)
	{
		# Block and disable MSN itself
		$Modules{'MSN'}->{loaded} = 0;
		$aConfigs{MsnEnabled} = 0;
		
		if ($aConfigs{Debug}){ logDebug("\nMSN disabled due to dependencies not fulfilled\n");}
		
		return 0;
	}
	
	
	if ($aConfigs{MsnEnabled}){
		
		if ($aConfigs{MsnDebug} == 1){
			# create an MSN object showing all server errors and other errors
			$oMSN = new MSN('Handle' => $aConfigs{MsnUsername}, 'Password' => $aConfigs{MsnPassword});
		}
		elsif ($aConfigs{MsnDebug} == 2){
			# OR create an MSN object with full debugging info
			$oMSN = new MSN('Handle' => $aConfigs{MsnUsername}, 'Password' => $aConfigs{MsnPassword}, 'AutoloadError' => 1, 'Debug' => 1, 'ShowTX' => 1, 'ShowRX' => 1 );
		}
		else{
			# OR create an MSN object with all error messages turned off
			$oMSN = new MSN('Handle' => $aConfigs{MsnUsername}, 'Password' => $aConfigs{MsnPassword}, 'ServerError' => 0, 'Error' => 0 );
		}
		
		
		# example of setting client info
		$oMSN->setClientInfo('Client' => 'MSNC2');
		
		# example of setting client capabilites (caps)
		$oMSN->setClientCaps('Client-Name' => "HeavyMetal v$sGlobalVersion ($sGlobalRelease)", 'Chat-Logging' => 'N', 'Client-Template' => 'None');
		
		# example of setting the default message style and P4 name
		$oMSN->setMessageStyle('Effect' => '', 'Color' => '000000', 'Name' => 'TTY-MSN', 'Font' => 'Courier');
		
		
		# set handlers
		$oMSN->setHandler('Connected'    => \&msn_statusConnected );
		$oMSN->setHandler('Disconnected' => \&msn_statusDisconnected);
		$oMSN->setHandler('Message'      => \&msn_receiveMessage );
		
		
		# connect to the server
		$oMSN->connect();
		
	}
}



sub msn_toggle{
	my ($bEnable) = @_;
	if (defined $bEnable){
		$aConfigs{MsnEnabled} = $bEnable;
	}
	
	my $sOut = '';
	if ($aConfigs{MsnEnabled}){
		if ($aConfigs{MsnUsername} ne ''){
			if ($aConfigs{Debug}){ logDebug("\nEnabled MSN: $aConfigs{MsnUsername}\n"); }
			
			$oTkStatus->configure(-text => 'Connecting to MSN...\nThis may freeze the window for a few seconds!', -justify => 'center');
			redraw_status_window();
			
			if (defined $oMSN){
				# connect to the server
				$oMSN->connect();
				
			}
			else{
				msn_init();
			}
			
			
			$sOut = '-- MSN Connecting';
		}
		else{
			$sOut = '-- ERROR: MSN not configured';
			$aConfigs{MsnEnabled} = 0;
		}
	}
	else{
		if ($aConfigs{Debug} > 0){ logDebug("\nDisabled MSN\n"); }
		if (defined $oMSN){
			# connect to the server
			$oMSN->disconnect();
		}
		redraw_status_window();
		$sOut = '-- MSN Disconnected';
	}
	return $sOut;
}



sub msn_io{
	if ($aConfigs{MsnEnabled}){
		
		foreach my $thisSession (@aSessions){
			if ($thisSession->{'status'} && $thisSession->{'type'} eq 'MSN'){
				if ($thisSession->{'direction'} == 0){
					if (length($thisSession->{OUT}) > 0){
						
						my $sMsg = '';
						# Decently cut long messages by lines
						if (length($thisSession->{OUT}) < 1400 || index($thisSession->{OUT}, "\n") < 0){
							$sMsg = $thisSession->{OUT};
							$thisSession->{OUT} = '';
						}
						else{
							# Get the initial line
							my $nPos = index($thisSession->{OUT}, "\n");
							$sMsg .= substr($thisSession->{OUT}, 0, $nPos + 1, '');
							
							$nPos = index($thisSession->{OUT}, "\n");
							while(length($thisSession->{OUT}) > 0 && $nPos >= 0 && (length($sMsg) + $nPos) < 1300){
								# Add as many lines as possible before reaching the limit or reaching the last line
								$sMsg .= substr($thisSession->{OUT}, 0, $nPos + 1, '');
								$nPos  = index($thisSession->{OUT}, "\n");
							}
							if (length($thisSession->{OUT}) > 0 && $nPos < 0){
								# If we still have a last line and we can add it, then do it
								if ((length($sMsg) + length($thisSession->{OUT})) < 1300){
									$sMsg .= $thisSession->{OUT};
									$thisSession->{OUT} = '';
								}
							}
						}
						
						chomp($sMsg);
						
						$oMSN->call($thisSession->{'address'}, $sMsg, 'Effect' => '', 'Color' => '000000', 'Font' => 'Courier');
						
						
						if ($thisSession->{input_type} eq 'OUT-EMPTY' && length($thisSession->{OUT}) == 0){
							# Detect and execute commands once the OUT buffer is empty
							process_line($thisSession->{id}, '');
						}

						
					}
					elsif ($thisSession->{'disconnect'} > 0){
						$thisSession->{'status'} = 0;
					}
				}
			}
		}
		
		$oMSN->do_one_loop();
	}


	return 1;
}

sub msn_statusConnected{
	my $self = shift;

	if ($aConfigs{Debug} > 0){ logDebug("\nMSN Connected as $aConfigs{MsnUsername}\n" ); }

	$MsnConnected = 1;

	redraw_status_window();	

	#$oMSN->{Notification}->send( 'LST', 'FL');

	# example of a call with style and P4 name
	#$msn->call( $admin, "I am connected!", 'Effect' => 'BI', 'Color' => '00FF00', 'Name' => 'TTY' );
}

sub msn_statusDisconnected{
	my $self = shift;

	if ($aConfigs{Debug} > 0){ logDebug("MSN $aConfigs{MsnUsername} Disconnected\n" );  }
	
	$MsnConnected = 0;
	
	redraw_status_window();
	
}

sub msn_receiveMessage{
	my ($self, $sAddress, $sName, $sMessage, %aStyle) = @_;

	my $sSourceEmail;
	#my $sSourceUser;

	if ($sMessage eq ''){
		return 0;
	}

	$aStyle{'Color'}  = '000000';
	$aStyle{'Font'}   = 'Courier';
	$aStyle{'Effect'} = '';
		
	my $sOut = '';

	#$sMessage = decode("utf8", $sMessage);
	if ($sMessage =~ /<msnobj creator="([\w-\.]+\@[\w-\.]+)".+?>/i){
		$sSourceEmail  = $1;
		#$sSourceUser   = decode("utf16", decode_base64(chr(0xfe).chr(0xff).$2));
		
		if ($sSourceEmail ne $sAddress){
			$MsnContactsRedirected{$sSourceEmail} = {'Email' => $sSourceEmail, 'Redirector' => $sAddress};
			
			if ($aConfigs{Debug} > 1){ logDebug("\nMSN Decoded: $sSourceEmail"); }
		}
		
		$sMessage =~ s/<msnobj.+?>//i;
	}


	if ($aConfigs{Debug} > 0){ logDebug("\nMSN $sAddress: $sMessage"); }

	my $idSession = session_get("address=$sAddress", 'id');

	if (!defined $idSession){
		# UNAUTHENTICATED
		if (substr($sMessage, 0, 1) eq '\\' || substr($sMessage, 0, 1) eq $aConfigs{EscapeChar}){
			# Generic commands allowed to anyone
			
			# PING		
			if( $sMessage =~ /^.ping$/i ){
				$sOut = 'PONG!';
			}
			# LOGIN
			elsif($sMessage =~ /^.login(\s+(\S.*))?$/i ){
				my $sArgs = $2;
				$sOut = do_login(undef, $sArgs); 
				
				if ($sOut eq 'OK'){
					$nSessionsCount++;
					
					my $idSession  = $NewSessionId++;
				
					$aSessions[$idSession] = {
						'id'          => $idSession, 
						'type'        => 'MSN', 
						'IN'          => '', 
						'OUT'         => '',
						'status'      => 1, 
						'direction'   => 0, 
						'auth'        => 0, 
						'user'        => '', 
						'target'      => 'ALL', 
						'source'      => 'ALL', 
						'remote_ip'   => '',
						'remote_port' => '',
						'prompt'      => 0,
						'disconnect'  => 0,
						'address'     => $sAddress,
						'command_last'=> '',
						'input_type'  => '', 
						'input_var'   => '', 
						'input_prompt'=> '',
						'echo_input'  => 1,
						'echo_msg'    => 0, 
						'command'     => '',
						'label_source'=> 1,
					};
					
					# We call it a second time to get the correct result string in a unified way for all session types
					$sOut = do_login($idSession, $sArgs);
				}
				else{
					$aStyle{'Color'} = 'FF0000';
				}
			}
	
			# Catchall for unauthenticated sessions
			elsif (!defined $idSession){
				$aStyle{'Color'} = 'FF0000';
				$sOut = "-- Unauthenticated user";
			}
		}
		elsif(exists $MsnInboundRoute{lc($sAddress)}){
			for (@{$MsnInboundRoute{lc($sAddress)}}){
				message_send("MSN $sAddress", $_, $sMessage);
			}
		}
		elsif($aConfigs{MsnListen}){
			if (defined $sSourceEmail){
				message_send("MSN $sSourceEmail", 'IN', $sMessage);
			}
			else{
				message_send("MSN $sAddress", 'IN', $sMessage);
			}
			
		}
	}
	else{
		#AUTHENTICATED
		process_line($idSession, $sMessage);
	}
	
	if ($sOut ne ''){
		$sOut =~ tr/\r//;
		$self->sendMessage($sOut, %aStyle);
	}

	return 1;
}


#------------------------------------------------------------------------
# - - - - - - - - - - - - - - DEBUG - - - - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------

sub debug_chars{
	my($sIn, $bTranscode, $bTags) = @_;
	my $sOut = '';
	my $n;
	
	for ($n = 0; $n < length($sIn); $n++){
		$sOut .= debug_char(substr($sIn, $n, 1), $bTranscode, $bTags);
	}
	return $sOut;
}

sub debug_char{
	my($c, $bTranscode, $bTags) = @_;
	
	if ($bTranscode){
		if (exists $aEscapeCharsDebugITA2{$c}){
			if ($bTags){
				return '<'.$aEscapeCharsDebugITA2{$c}.'>';
			}
			else{
				return $aEscapeCharsDebugITA2{$c};
			}
		}
		else{
			if ($rcv_shift eq $ltrs) {
				return $CODES{$aConfigs{LoopCode}}->{'FROM-LTRS'}->{$c}
			}
			else {
				return $CODES{$aConfigs{LoopCode}}->{'FROM-FIGS'}->{$c}
			}
		}
	}
	else{
		if (exists $aEscapeCharsDebugASCII{$c}){
			if ($bTags){
				return '<'.$aEscapeCharsDebugASCII{$c}.'>';
			}
			else{
				return $aEscapeCharsDebugASCII{$c};
			}
		}
		else{
			return $c;
		}
	}
}


sub logDebug{
	my($sLine) = @_;

	if ($aConfigs{Debug} > 0 && $aConfigs{DebugFile} ne ''){
		if (!defined $rDebugHandle){
			
			$sDebugFile = $aConfigs{DebugFile};
			
			my $sNow = get_datetime();
			
			my $sDatetime = $sNow;
			$sDatetime    =~ s/\D//g;
			my $sDate     = substr($sDatetime, 0, 10);
			
			# Note: Very primitive way to replace datetime and date in file
			$sDebugFile   =~ s/\$DATETIME/$sDatetime/;
			$sDebugFile   =~ s/\$DATE/$sDate/;
			
			open($rDebugHandle, $sDebugFile);
			
			
			if ($rDebugHandle){
				print "\n-- HeavyMetal v$sGlobalVersion ($sGlobalRelease) - Debug $aConfigs{Debug} - $sNow --\n";
				
				print $rDebugHandle "-- HeavyMetal v$sGlobalVersion ($sGlobalRelease) - Debug $aConfigs{Debug} - $sNow --\n";
			}
			else{
				print "\nERROR when opening debug file\n"
			}
		}

		if ($rDebugHandle){
			print $rDebugHandle $sLine;
		}
	}
	elsif ($rDebugHandle){
		close($rDebugHandle);
		$rDebugHandle = undef;
	}
	
	if ($rDebugSocket){
		my $sLineSocket = $sLine;
		$sLineSocket =~ s/\n/\r\n/g; # Fix the CR LF issue
		$rDebugSocket->send($sLineSocket);
	}

	print $sLine;
	
	return 1;	
}

sub get_datetime{
	my ($nTime) = @_;
	if (!defined $nTime){
		$nTime = time();
	}
	
	my ($Sec, $Min, $Hour, $Day, $Mon, $Year) = localtime($nTime); 
	return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $Year + 1900, $Mon + 1, $Day, $Hour, $Min, $Sec);
}


#------------------------------------------------------------------------
# - - - - - - - - - - - - - - ESCAPE & TRANSCODE  - - - - - - - - - - - -
#------------------------------------------------------------------------


sub escape_to_ascii{
	my($idSession, $sLine) = @_;
	my $n;
	my $c;
	my $d;
	my $sEscape = '';
	my $sLine2  = '';
	my $sCode   = '';
	
	# Decode escape sequences TO ASCII
	if ($aConfigs{EscapeEnabled} && index($sLine, $aConfigs{EscapeChar}) >= 0){
		for ($n = 0; $n < length($sLine); $n++){
			$c = substr($sLine, $n, 1);	
			if ($sEscape eq ''){
				if ($c eq $aConfigs{EscapeChar}){	
					# Escape start detected
					$sEscape .= $c;
				}
				else{
					# Non escaped
					$sLine2 .= $c;
				}
			}
			else{
				if ($c =~ /^\w$/){
					# Sequence continues
					$sEscape .= $c;
				}
				else{
					# End of escape sequence
					$sCode = uc(substr($sEscape, 1));
					
					if (exists $aEscapeCharsDecodeASCII{$sCode}){
						# An escaped character
						$sLine2 .= $aEscapeCharsDecodeASCII{$sCode};
					}
					elsif (exists $aEscapeCommands{$sCode}){
						# An escape immediate action
						$sLine2 .= &{$aEscapeCommands{$sCode}}($idSession);
					}
					else{
						# Not an escape sequence at all
						$sLine2 .= $sEscape;
					}
					
					if ($c eq $aConfigs{EscapeChar}){
						# New escape start detected
						$sEscape = $c;
					}
					elsif ($c eq ' ' && defined $d){
						# Space after successful escape sequence is ignored
						$sEscape = '';
					}
					else{
						# Other character is added
						$sLine2 .= $c;
						$sEscape = '';	
					}
				}
			}
		}
		if ($sEscape ne ''){
			# End of escape sequence (there might be an escape at the end of the line)
			$d = $aEscapeCharsDecodeASCII{uc(substr($sEscape, 1))};
			$sLine2 .= (defined $d) ? $d : $sEscape;
		}
	}
	else{
		return $sLine;
	}
	
	return $sLine2;
}







sub transcode_to_loop{
	my($sLine) = @_;
	my $n;
	my $c;
	my $d;
	my $sOut         = '';
	my $sStatusShift = $ltrs;
	
	for ($n = 0; $n < length($sLine); $n++){
		# TRANSCODE ASCII->BAUDOT
		$c = substr($sLine, $n, 1);

		# PROCESS ASCII LOOP
		if ($aConfigs{LoopCode} eq "ASCII" ) {
			if ($c eq $lf && $xlate_lf){
				$d = $ascii_end_of_line;
			}
			elsif ($c eq $cr && $xlate_cr) {
				$d = $ascii_end_of_line;
			}
			else {
				$d = $c;
			}
		}
		# PROCESS OTHER ENCODINGS
		else {

			if ($CODES{$aConfigs{LoopCode}}->{upshift}){
				$c = uc($c);
			}
		
			if ($c eq "\n"){
				$d = $end_of_line;
				$sStatusShift = $ltrs;
			}
			elsif (exists($CODES{$aConfigs{LoopCode}}->{'TO-LTRS'}->{$c})){
				if ($sStatusShift eq $figs) {
					$sOut        .= $ltrs;
					$sStatusShift = $ltrs;
				}
				$d = $CODES{$aConfigs{LoopCode}}->{'TO-LTRS'}->{$c}
			}
			elsif (exists($CODES{$aConfigs{LoopCode}}->{'TO-FIGS'}->{$c})){
				if ($sStatusShift eq $ltrs) {
					$sOut        .= $figs;
					$sStatusShift = $figs;
				}
				$d = $CODES{$aConfigs{LoopCode}}->{'TO-FIGS'}->{$c}
			}
			else {
				$d = undef;
			}
		}
			
		$sOut .= defined($d) ? $d : $loop_no_match_char;
	}
	
	return $sOut;
}




#------------------------------------------------------------------------
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------







#-----------------------------------------------------------------------------
# Weather reports from tgftp.nws.noaa.gov
#-----------------------------------------------------------------------------
sub weather_init{
	my %states_ak = (
		"anchorage" => 'anchorage.txt',
		"bethel" => 'bethel.txt',
		"fairbanks" => 'fairbanks.txt',
		"juneau" => 'juneau.txt',
		"ketchikan" => 'ketchikan.txt',
		"nome" => 'nome.txt',
		"old_man" => 'old_man.txt',
		"sitka" => 'sitka.txt',
		"yakutat" => 'yakutat.txt',
	);
	my %states_al = (
		"birmingham" => 'birmingham.txt',
		"dothan" => 'dothan.txt',
		"evergreen" => 'evergreen.txt',
		"huntsville" => 'huntsville.txt',
		"mobile" => 'mobile.txt',
		"montgomery" => 'montgomery.txt',
		"muscle_shoals" => 'muscle_shoals.txt',
	);
	my %states_ar = (
		"de_queen" => 'de_queen.txt',
		"el_dorado" => 'el_dorado.txt',
		"fayetteville" => 'fayetteville.txt',
		"fort_smith" => 'fort_smith.txt',
		"harrison" => 'harrison.txt',
		"hot_springs" => 'hot_springs.txt',
		"jonesboro" => 'jonesboro.txt',
		"little_rock" => 'little_rock.txt',
		"pine_bluff" => 'pine_bluff.txt',
		"texarkana" => 'texarkana.txt',
	);
	my %states_az = (
		"flagstaff" => 'flagstaff.txt',
		"kingman" => 'kingman.txt',
		"page" => 'page.txt',
		"phoenix" => 'phoenix.txt',
		"prescott" => 'prescott.txt',
		"tucson" => 'tucson.txt',
		"winslow" => 'winslow.txt',
		"yuma" => 'yuma.txt',
	);
	my %states_bc = (
	);
	my %states_ca = (
		"arcata" => 'arcata.txt',
		"bakersfield" => 'bakersfield.txt',
		"bishop" => 'bishop.txt',
		"blue_canyon" => 'blue_canyon.txt',
		"blythe" => 'blythe.txt',
		"crescent_city" => 'crescent_city.txt',
		"daggett" => 'daggett.txt',
		"fresno" => 'fresno.txt',
		"imperial" => 'imperial.txt',
		"livermore" => 'livermore.txt',
		"mammoth_lakes" => 'mammoth_lakes.txt',
		"monterey" => 'monterey.txt',
		"mount_shasta" => 'mount_shasta.txt',
		"red_bluff" => 'red_bluff.txt',
		"sacramento" => 'sacramento.txt',
		"san_diego" => 'san_diego.txt',
		"san_francisco" => 'san_francisco.txt',
		"san_jose" => 'san_jose.txt',
		"santa_rosa" => 'santa_rosa.txt',
		"south_lake_tahoe" => 'south_lake_tahoe.txt',
		"ukiah" => 'ukiah.txt',
	);
	my %states_co = (
		"alamosa" => 'alamosa.txt',
		"aspen" => 'aspen.txt',
		"burlington" => 'burlington.txt',
		"colorado_springs" => 'colorado_springs.txt',
		"denver" => 'denver.txt',
		"durango" => 'durango.txt',
		"eagle" => 'eagle.txt',
		"grand_junction" => 'grand_junction.txt',
		"la_junta" => 'la_junta.txt',
		"lamar" => 'lamar.txt',
		"leadville" => 'leadville.txt',
		"montrose" => 'montrose.txt',
		"pueblo" => 'pueblo.txt',
		"trinidad" => 'trinidad.txt',
	);
	my %states_ct = (
		"bridgeport" => 'bridgeport.txt',
		"danbury" => 'danbury.txt',
		"groton_new_london" => 'groton_new_london.txt',
		"meriden" => 'meriden.txt',
		"new_haven" => 'new_haven.txt',
		"willimantic" => 'willimantic.txt',
		"windsor_locks" => 'windsor_locks.txt',
	);
	my %states_de = (
		"dover_afb" => 'dover_afb.txt',
		"georgetown" => 'georgetown.txt',
		"wilmington" => 'wilmington.txt',
	);
	my %states_fl = (
		"brooksville" => 'brooksville.txt',
		"cross_city" => 'cross_city.txt',
		"daytona_beach" => 'daytona_beach.txt',
	        "destin" => 'destin.txt',
		"fort_lauderdale" => 'fort_lauderdale.txt',
		"fort_myers" => 'fort_myers.txt',
		"gainesville" => 'gainesville.txt',
		"jacksonville" => 'jacksonville.txt',
		"key_west" => 'key_west.txt',
		"marathon_key" => 'marathon_key.txt',
		"melbourne" => 'melbourne.txt',
		"miami" => 'miami.txt',
		"naples" => 'naples.txt',
		"ocala" => 'ocala.txt',
		"orlando" => 'orlando.txt',
		"panama_city" => 'panama_city.txt',
		"pensacola" => 'pensacola.txt',
		"sarasota_bradenton" => 'sarasota_bradenton.txt',
		"st_augustine" => 'st_augustine.txt',
		"tallahassee" => 'tallahassee.txt',
		"tampa" => 'tampa.txt',
		"vero_beach" => 'vero_beach.txt',
		"west_palm_beach" => 'west_palm_beach.txt',
		"winter_haven" => 'winter_haven.txt',
	);
	my %states_ga = (
		"albany" => 'albany.txt',
		"alma" => 'alma.txt',
		"athens" => 'athens.txt',
		"atlanta" => 'atlanta.txt',
		"augusta" => 'augusta.txt',
		"brunswick" => 'brunswick.txt',
		"columbus" => 'columbus.txt',
		"gainesville" => 'gainesville.txt',
		"macon" => 'macon.txt',
		"rome" => 'rome.txt',
		"savannah" => 'savannah.txt',
		"valdosta" => 'valdosta.txt',
	);
	my %states_hi = (
		"honolulu" => 'honolulu.txt',
	);
	my %states_hn = (
		"manchester" => 'manchester.txt',
	);
	my %states_ia = (
		"ames" => 'ames.txt',
		"burlington" => 'burlington.txt',
		"cedar_rapids" => 'cedar_rapids.txt',
		"des_moines" => 'des_moines.txt',
		"dubuque" => 'dubuque.txt',
		"estherville" => 'estherville.txt',
		"fort_dodge" => 'fort_dodge.txt',
		"iowa_city" => 'iowa_city.txt',
		"marshalltown" => 'marshalltown.txt',
		"mason_city" => 'mason_city.txt',
		"ottumwa" => 'ottumwa.txt',
		"quad_cities" => 'quad_cities.txt',
		"sioux_city" => 'sioux_city.txt',
		"spencer" => 'spencer.txt',
		"waterloo" => 'waterloo.txt',
	);
	my %states_id = (
		"boise" => 'boise.txt',
		"mccall" => 'mccall.txt',
		"pocatello" => 'pocatello.txt',
		"twin_falls" => 'twin_falls.txt',
	);
	my %states_il = (
		"carbondale_murphysboro" => 'carbondale_murphysboro.txt',
		"champaign_urbana" => 'champaign_urbana.txt',
		"chicago" => 'chicago.txt',
		"decatur" => 'decatur.txt',
		"lawrenceville" => 'lawrenceville.txt',
		"mattoon_charleston" => 'mattoon_charleston.txt',
		"moline" => 'moline.txt',
		"mount_vernon" => 'mount_vernon.txt',
		"peoria" => 'peoria.txt',
		"quincy" => 'quincy.txt',
		"rockford" => 'rockford.txt',
		"salem" => 'salem.txt',
		"springfield" => 'springfield.txt',
	);
	my %states_in = (
		"bloomington" => 'bloomington.txt',
		"columbus" => 'columbus.txt',
		"evansville" => 'evansville.txt',
		"fort_wayne" => 'fort_wayne.txt',
		"indianapolis" => 'indianapolis.txt',
		"kokomo" => 'kokomo.txt',
		"lafayette" => 'lafayette.txt',
		"michigan_city" => 'michigan_city.txt',
		"muncie" => 'muncie.txt',
		"rochester" => 'rochester.txt',
		"south_bend" => 'south_bend.txt',
		"terre_haute" => 'terre_haute.txt',
	);
	my %states_ks = (
		"chanute" => 'chanute.txt',
		"coffeyville" => 'coffeyville.txt',
		"concordia" => 'concordia.txt',
		"dodge_city" => 'dodge_city.txt',
		"elkhart" => 'elkhart.txt',
		"emporia" => 'emporia.txt',
		"garden_city" => 'garden_city.txt',
		"goodland" => 'goodland.txt',
		"great_bend" => 'great_bend.txt',
		"hays" => 'hays.txt',
		"hill_city" => 'hill_city.txt',
		"hutchinson" => 'hutchinson.txt',
		"lawrence" => 'lawrence.txt',
		"liberal" => 'liberal.txt',
		"manhattan" => 'manhattan.txt',
		"newton" => 'newton.txt',
		"olathe" => 'olathe.txt',
		"russell" => 'russell.txt',
		"salina" => 'salina.txt',
		"topeka" => 'topeka.txt',
		"wichita" => 'wichita.txt',
		"winfield_arkansas_city" => 'winfield_arkansas_city.txt',
	);
	my %states_ky = (
		"ashland" => 'ashland.txt',
		"bowling_green" => 'bowling_green.txt',
		"campbell_aaf_hopkinsville" => 'campbell_aaf_hopkinsville.txt',
		"covington" => 'covington.txt',
		"frankfort" => 'frankfort.txt',
		"henderson" => 'henderson.txt',
		"jackson" => 'jackson.txt',
		"lexington" => 'lexington.txt',
		"london" => 'london.txt',
		"louisville" => 'louisville.txt',
		"paducah" => 'paducah.txt',
		"somerset" => 'somerset.txt',
	);
	my %states_la = (
		"baton_rouge" => 'baton_rouge.txt',
		"england_afb_alexandria" => 'england_afb_alexandria.txt',
		"lafayette" => 'lafayette.txt',
		"lake_charles" => 'lake_charles.txt',
		"monroe" => 'monroe.txt',
		"new_orleans" => 'new_orleans.txt',
		"shreveport" => 'shreveport.txt',
	);
	my %states_ma = (
		"boston" => 'boston.txt',
		"hyannis" => 'hyannis.txt',
		"lawrence" => 'lawrence.txt',
		"nantucket" => 'nantucket.txt',
		"orange" => 'orange.txt',
		"pittsfield" => 'pittsfield.txt',
		"taunton" => 'taunton.txt',
		"westover_afb_chicopee_falls" => 'westover_afb_chicopee_falls.txt',
		"worcester" => 'worcester.txt',
	);
	my %states_md = (
		"baltimore-washington_intl_airport" => 'baltimore-washington_intl_airport.txt',
		"hagerstown" => 'hagerstown.txt',
		"ocean_city" => 'ocean_city.txt',
		"salisbury" => 'salisbury.txt',
	);
	my %states_me = (
		"auburn_lewiston" => 'auburn_lewiston.txt',
		"augusta" => 'augusta.txt',
		"bangor" => 'bangor.txt',
		"bar_harbor" => 'bar_harbor.txt',
		"brunswick_nas" => 'brunswick_nas.txt',
		"caribou" => 'caribou.txt',
		"eastport" => 'eastport.txt',
		"frenchville" => 'frenchville.txt',
		"fryeburg" => 'fryeburg.txt',
		"houlton" => 'houlton.txt',
		"millinocket" => 'millinocket.txt',
		"portland" => 'portland.txt',
		"presque_isle" => 'presque_isle.txt',
		"rockland" => 'rockland.txt',
		"sanford" => 'sanford.txt',
		"waterville" => 'waterville.txt',
		"wiscasset" => 'wiscasset.txt',
	);
	my %states_mi = (
		"adrian" => 'adrian.txt',
		"alpena" => 'alpena.txt',
		"benton_harbor" => 'benton_harbor.txt',
		"detroit" => 'detroit.txt',
		"escanaba" => 'escanaba.txt',
		"flint" => 'flint.txt',
		"grand_rapids" => 'grand_rapids.txt',
		"hancock" => 'hancock.txt',
		"iron_mountain" => 'iron_mountain.txt',
		"ironwood" => 'ironwood.txt',
		"k_i_sawyer_afb_gwinn" => 'k_i_sawyer_afb_gwinn.txt',
		"lansing" => 'lansing.txt',
		"manistique" => 'manistique.txt',
		"marquette" => 'marquette.txt',
		"menominee" => 'menominee.txt',
		"muskegon" => 'muskegon.txt',
		"newberry" => 'newberry.txt',
		"saginaw" => 'saginaw.txt',
		"traverse_city" => 'traverse_city.txt',
	);
	my %states_mn = (
		"alexandria" => 'alexandria.txt',
		"baudette" => 'baudette.txt',
		"bemidji" => 'bemidji.txt',
		"brainerd" => 'brainerd.txt',
		"duluth" => 'duluth.txt',
		"international_falls" => 'international_falls.txt',
		"mankato" => 'mankato.txt',
		"marshall" => 'marshall.txt',
		"minneapolis" => 'minneapolis.txt',
		"ortonville" => 'ortonville.txt',
		"park_rapids" => 'park_rapids.txt',
		"rochester" => 'rochester.txt',
		"st_cloud" => 'st_cloud.txt',
		"wheaton" => 'wheaton.txt',
		"willmar" => 'willmar.txt',
		"worthington" => 'worthington.txt',
	);
	my %states_mo = (
		"cape_girardeau" => 'cape_girardeau.txt',
		"columbia" => 'columbia.txt',
		"jefferson_city" => 'jefferson_city.txt',
		"joplin" => 'joplin.txt',
		"kaiser_lake_ozark" => 'kaiser_lake_ozark.txt',
		"kansas_city" => 'kansas_city.txt',
		"kansas_city_int_l_airport" => 'kansas_city_int_l_airport.txt',
		"kirksville" => 'kirksville.txt',
		"sedalia" => 'sedalia.txt',
		"springfield" => 'springfield.txt',
		"st_joseph" => 'st_joseph.txt',
		"st_louis" => 'st_louis.txt',
		"vichy_rolla" => 'vichy_rolla.txt',
		"west_plains" => 'west_plains.txt',
	);
	my %states_ms = (
		"gulfport" => 'gulfport.txt',
		"jackson" => 'jackson.txt',
		"mccomb" => 'mccomb.txt',
		"meridian" => 'meridian.txt',
		"stoneville" => 'stoneville.txt',
		"tupelo" => 'tupelo.txt',
	);
	my %states_mt = (
		"billings" => 'billings.txt',
		"bozeman" => 'bozeman.txt',
		"butte" => 'butte.txt',
		"cut_bank" => 'cut_bank.txt',
		"dillon" => 'dillon.txt',
		"glasgow" => 'glasgow.txt',
		"glendive" => 'glendive.txt',
		"great_falls" => 'great_falls.txt',
		"havre" => 'havre.txt',
		"helena" => 'helena.txt',
		"kalispell" => 'kalispell.txt',
		"lewistown" => 'lewistown.txt',
		"miles_city" => 'miles_city.txt',
		"missoula" => 'missoula.txt',
		"sidney" => 'sidney.txt',
		"west_yellowstone" => 'west_yellowstone.txt',
		"wolf_point" => 'wolf_point.txt',
	);
	my %states_nc = (
		"asheville" => 'asheville.txt',
		"billy_mitchell_field" => 'billy_mitchell_field.txt',
		"charlotte" => 'charlotte.txt',
		"elizabeth_city" => 'elizabeth_city.txt',
		"fayetteville" => 'fayetteville.txt',
		"greensboro" => 'greensboro.txt',
		"hickory" => 'hickory.txt',
		"lumberton" => 'lumberton.txt',
		"morehead_city_newport" => 'morehead_city_newport.txt',
		"new_bern" => 'new_bern.txt',
		"pit_greenville" => 'pit_greenville.txt',
		"raleigh_durham" => 'raleigh_durham.txt',
		"rocky_mount" => 'rocky_mount.txt',
		"seymour_johnson_afb_goldsboro" => 'seymour_johnson_afb_goldsboro.txt',
		"wilmington" => 'wilmington.txt',
	);
	my %states_nd = (
		"bismarck" => 'bismarck.txt',
		"devils_lake" => 'devils_lake.txt',
		"dickinson" => 'dickinson.txt',
		"fargo" => 'fargo.txt',
		"grand_forks" => 'grand_forks.txt',
		"hettinger" => 'hettinger.txt',
		"jamestown" => 'jamestown.txt',
		"minot" => 'minot.txt',
		"williston" => 'williston.txt',
	);
	my %states_ne = (
		"chadron" => 'chadron.txt',
		"falls_city" => 'falls_city.txt',
		"grand_island" => 'grand_island.txt',
		"hastings" => 'hastings.txt',
		"kearney" => 'kearney.txt',
		"lincoln" => 'lincoln.txt',
		"mccook" => 'mccook.txt',
		"norfolk-stefan_memorial_airport" => 'norfolk-stefan_memorial_airport.txt',
		"north_platte" => 'north_platte.txt',
		"omaha" => 'omaha.txt',
		"ord" => 'ord.txt',
		"scottsbluff" => 'scottsbluff.txt',
		"sidney" => 'sidney.txt',
		"tekamah" => 'tekamah.txt',
		"valentine" => 'valentine.txt',
	);
	my %states_nh = (
		"berlin" => 'berlin.txt',
		"concord" => 'concord.txt',
		"keene" => 'keene.txt',
		"laconia" => 'laconia.txt',
		"lebanon" => 'lebanon.txt',
		"pease_int_l_tradeport_portsmouth" => 'pease_int_l_tradeport_portsmouth.txt',
		"whitefield" => 'whitefield.txt',
	);
	my %states_nj = (
		"atlantic_city" => 'atlantic_city.txt',
		"millville" => 'millville.txt',
		"newark" => 'newark.txt',
		"teterboro" => 'teterboro.txt',
		"trenton" => 'trenton.txt',
	);
	my %states_nm = (
		"albuquerque" => 'albuquerque.txt',
		"carlsdad" => 'carlsdad.txt',
		"santa_fe" => 'santa_fe.txt',
		"tucumcari" => 'tucumcari.txt',
	);
	my %states_nv = (
		"elko" => 'elko.txt',
		"ely" => 'ely.txt',
		"fallon_nas" => 'fallon_nas.txt',
		"las_vegas" => 'las_vegas.txt',
		"lovelock" => 'lovelock.txt',
		"reno" => 'reno.txt',
		"tonopah" => 'tonopah.txt',
		"winnemucca" => 'winnemucca.txt',
	);
	my %states_ny = (
		"albany" => 'albany.txt',
		"batavia" => 'batavia.txt',
		"binghamton" => 'binghamton.txt',
		"buffalo" => 'buffalo.txt',
		"dansville" => 'dansville.txt',
		"dunkirk" => 'dunkirk.txt',
		"elmira" => 'elmira.txt',
		"farmingdale" => 'farmingdale.txt',
		"fulton" => 'fulton.txt',
		"glens_falls" => 'glens_falls.txt',
		"islip" => 'islip.txt',
		"ithaca" => 'ithaca.txt',
		"jamestown" => 'jamestown.txt',
		"la_guardia_airport" => 'la_guardia_airport.txt',
		"massena" => 'massena.txt',
		"montgomery" => 'montgomery.txt',
		"monticello" => 'monticello.txt',
		"new_york" => 'new_york.txt',
		"niagara_falls" => 'niagara_falls.txt',
		"penn_yan" => 'penn_yan.txt',
		"poughkeepsie" => 'poughkeepsie.txt',
		"rochester" => 'rochester.txt',
		"saranac_lake" => 'saranac_lake.txt',
		"syracuse" => 'syracuse.txt',
		"utica" => 'utica.txt',
		"watertown" => 'watertown.txt',
		"wellsville" => 'wellsville.txt',
		"westhampton_beach" => 'westhampton_beach.txt',
		"white_plains" => 'white_plains.txt',
	);
	my %states_oh = (
		"akron" => 'akron.txt',
		"cleveland" => 'cleveland.txt',
		"columbus" => 'columbus.txt',
		"dayton" => 'dayton.txt',
		"defiance" => 'defiance.txt',
		"findlay" => 'findlay.txt',
		"lima" => 'lima.txt',
		"mansfield" => 'mansfield.txt',
		"new_philadelphia" => 'new_philadelphia.txt',
		"toledo" => 'toledo.txt',
		"wilmington" => 'wilmington.txt',
		"youngstown" => 'youngstown.txt',
		"zanesville" => 'zanesville.txt',
	);
	my %states_ok = (
		"ardmore" => 'ardmore.txt',
		"bartlesville" => 'bartlesville.txt',
		"durant" => 'durant.txt',
		"enid" => 'enid.txt',
		"gage" => 'gage.txt',
		"guyman" => 'guyman.txt',
		"hobart" => 'hobart.txt',
		"lawton" => 'lawton.txt',
		"mcalester" => 'mcalester.txt',
		"muskogee" => 'muskogee.txt',
		"oklahoma_city" => 'oklahoma_city.txt',
		"ponca_city" => 'ponca_city.txt',
		"stillwater" => 'stillwater.txt',
		"tulsa" => 'tulsa.txt',
		"woodward" => 'woodward.txt',
	);
	my %states_or = (
		"astoria" => 'astoria.txt',
		"baker" => 'baker.txt',
		"burns" => 'burns.txt',
		"eugene" => 'eugene.txt',
		"klamath_falls" => 'klamath_falls.txt',
		"lakeview" => 'lakeview.txt',
		"medford" => 'medford.txt',
		"north_bend" => 'north_bend.txt',
		"pendleton" => 'pendleton.txt',
		"portland" => 'portland.txt',
		"roseburg" => 'roseburg.txt',
		"salem" => 'salem.txt',
	);
	my %states_pa = (
		"allentown" => 'allentown.txt',
		"altoona" => 'altoona.txt',
		"bradford" => 'bradford.txt',
		"du_bois" => 'du_bois.txt',
		"erie" => 'erie.txt',
		"franklin" => 'franklin.txt',
		"johnstown" => 'johnstown.txt',
		"lancaster" => 'lancaster.txt',
		"latrobe" => 'latrobe.txt',
		"middletown" => 'middletown.txt',
		"mt_pocono" => 'mt_pocono.txt',
		"philadelphia" => 'philadelphia.txt',
		"pittsburgh" => 'pittsburgh.txt',
		"selinsgrove" => 'selinsgrove.txt',
		"state_college" => 'state_college.txt',
		"wilkesbarre-scranton" => 'wilkesbarre-scranton.txt',
		"williamsport" => 'williamsport.txt',
		"york" => 'york.txt',
	);
	my %states_pr = (
		"san_juan" => 'san_juan.txt',
	);
	my %states_ri = (
		"providence" => 'providence.txt',
		"westerly" => 'westerly.txt',
	);
	my %states_sc = (
		"anderson" => 'anderson.txt',
		"beaufort_mcas" => 'beaufort_mcas.txt',
		"charleston" => 'charleston.txt',
		"columbia" => 'columbia.txt',
		"florence" => 'florence.txt',
		"greenville_spartanburg" => 'greenville_spartanburg.txt',
		"myrtle_beach_afb" => 'myrtle_beach_afb.txt',
		"orangeburg" => 'orangeburg.txt',
		"shaw_afb_sumter" => 'shaw_afb_sumter.txt',
	);
	my %states_sd = (
		"aberdeen" => 'aberdeen.txt',
		"huron" => 'huron.txt',
		"mitchell" => 'mitchell.txt',
		"mobridge" => 'mobridge.txt',
		"philip" => 'philip.txt',
		"pierre" => 'pierre.txt',
		"pine_ridge" => 'pine_ridge.txt',
		"rapid_city" => 'rapid_city.txt',
		"sioux_falls" => 'sioux_falls.txt',
		"watertown" => 'watertown.txt',
		"yankton" => 'yankton.txt',
	);
	my %states_tn = (
		"bristol" => 'bristol.txt',
		"chattanooga" => 'chattanooga.txt',
		"clarksville" => 'clarksville.txt',
		"crossville" => 'crossville.txt',
		"jackson" => 'jackson.txt',
		"knoxville" => 'knoxville.txt',
		"memphis" => 'memphis.txt',
		"nashville" => 'nashville.txt',
	);
	my %states_tx = (
		"abilene" => 'abilene.txt',
		"alice" => 'alice.txt',
		"amarillo" => 'amarillo.txt',
		"austin" => 'austin.txt',
		"beaumont-port_arthur" => 'beaumont-port_arthur.txt',
		"borger" => 'borger.txt',
		"brownsville" => 'brownsville.txt',
		"college_station" => 'college_station.txt',
		"corpus_christi" => 'corpus_christi.txt',
		"corsicana" => 'corsicana.txt',
		"cotulla" => 'cotulla.txt',
		"dalhart" => 'dalhart.txt',
		"dallas" => 'dallas.txt',
		"dallas_ft_worth" => 'dallas_ft_worth.txt',
		"del_rio" => 'del_rio.txt',
		"denton" => 'denton.txt',
		"el_paso" => 'el_paso.txt',
		"ft_stockton" => 'ft_stockton.txt',
		"galveston" => 'galveston.txt',
		"houston" => 'houston.txt',
		"junction" => 'junction.txt',
		"laredo" => 'laredo.txt',
		"longview" => 'longview.txt',
		"lubbock" => 'lubbock.txt',
		"lufkin" => 'lufkin.txt',
		"marfa" => 'marfa.txt',
		"mcallen" => 'mcallen.txt',
		"mckinney" => 'mckinney.txt',
		"midland" => 'midland.txt',
		"paris" => 'paris.txt',
		"rockport" => 'rockport.txt',
		"san_angelo" => 'san_angelo.txt',
		"san_antonio" => 'san_antonio.txt',
		"temple" => 'temple.txt',
		"terrell" => 'terrell.txt',
		"tyler" => 'tyler.txt',
		"victoria" => 'victoria.txt',
		"waco" => 'waco.txt',
		"wichita_falls" => 'wichita_falls.txt',
	);
	my %states_ut = (
		"cedar_city" => 'cedar_city.txt',
		"salt_lake_city" => 'salt_lake_city.txt',
		"vernal" => 'vernal.txt',
	);
	my %states_va = (
		"blacksburg" => 'blacksburg.txt',
		"charlottesville" => 'charlottesville.txt',
		"danville" => 'danville.txt',
		"lynchburg" => 'lynchburg.txt',
		"newport_news" => 'newport_news.txt',
		"norfolk_intl_airport" => 'norfolk_intl_airport.txt',
		"richmond" => 'richmond.txt',
		"wakefield" => 'wakefield.txt',
		"washington_dulles_intl_airport" => 'washington_dulles_intl_airport.txt',
		"washington_national_airport" => 'washington_national_airport.txt',
	);
	my %states_vi = (
		"charlotte_amalie" => 'charlotte_amalie.txt',
	);
	my %states_vt = (
		"barre_montpelier" => 'barre_montpelier.txt',
		"burlington" => 'burlington.txt',
		"rutland" => 'rutland.txt',
		"springfield" => 'springfield.txt',
	);
	my %states_wa = (
		"pasco" => 'pasco.txt',
		"seattle" => 'seattle.txt',
		"spokane" => 'spokane.txt',
		"walla_walla" => 'walla_walla.txt',
		"yakima" => 'yakima.txt',
	);
	my %states_wi = (
		"ashland" => 'ashland.txt',
		"boscobel" => 'boscobel.txt',
		"eau_claire" => 'eau_claire.txt',
		"fond_du_lac" => 'fond_du_lac.txt',
		"green_bay" => 'green_bay.txt',
		"hayward" => 'hayward.txt',
		"kenosha" => 'kenosha.txt',
		"la_crosse" => 'la_crosse.txt',
		"madison" => 'madison.txt',
		"medford" => 'medford.txt',
		"milwaukee" => 'milwaukee.txt',
		"rhinelander" => 'rhinelander.txt',
		"sheboygan" => 'sheboygan.txt',
		"wausau" => 'wausau.txt',
	);
	my %states_wv = (
		"beckley" => 'beckley.txt',
		"bluefield" => 'bluefield.txt',
		"charleston" => 'charleston.txt',
		"clarksburg" => 'clarksburg.txt',
		"elkins" => 'elkins.txt',
		"huntington" => 'huntington.txt',
		"lewisburg" => 'lewisburg.txt',
		"martinsburg" => 'martinsburg.txt',
		"morgantown" => 'morgantown.txt',
		"parkersburg" => 'parkersburg.txt',
		"wheeling" => 'wheeling.txt',
	);
	my %states_wy = (
		"buffalo" => 'buffalo.txt',
		"casper" => 'casper.txt',
		"cheyenne" => 'cheyenne.txt',
		"cody" => 'cody.txt',
		"douglas" => 'douglas.txt',
		"gillette" => 'gillette.txt',
		"greybull" => 'greybull.txt',
		"jackson" => 'jackson.txt',
		"lander" => 'lander.txt',
		"laramie" => 'laramie.txt',
		"rawlins" => 'rawlins.txt',
		"riverton" => 'riverton.txt',
		"rock_springs" => 'rock_springs.txt',
		"sheridan" => 'sheridan.txt',
		"torrington" => 'torrington.txt',
		"worland" => 'worland.txt',
	);
	
	
	my %weather_cities = (
		"AK" => \%states_ak,
		"AL" => \%states_al,
		"AR" => \%states_ar,
		"AZ" => \%states_az,
		"BC" => \%states_bc,
		"CA" => \%states_ca,
		"CO" => \%states_co,
		"CT" => \%states_ct,
		"DE" => \%states_de,
		"FL" => \%states_fl,
		"GA" => \%states_ga,
		"HI" => \%states_hi,
		"HN" => \%states_hn,
		"IA" => \%states_ia,
		"ID" => \%states_id,
		"IL" => \%states_il,
		"IN" => \%states_in,
		"KS" => \%states_ks,
		"KY" => \%states_ky,
		"LA" => \%states_la,
		"MA" => \%states_ma,
		"MD" => \%states_md,
		"ME" => \%states_me,
		"MI" => \%states_mi,
		"MN" => \%states_mn,
		"MO" => \%states_mo,
		"MS" => \%states_ms,
		"MT" => \%states_mt,
		"NC" => \%states_nc,
		"ND" => \%states_nd,
		"NE" => \%states_ne,
		"NH" => \%states_nh,
		"NJ" => \%states_nj,
		"NM" => \%states_nm,
		"NV" => \%states_nv,
		"NY" => \%states_ny,
		"OH" => \%states_oh,
		"OK" => \%states_ok,
		"OR" => \%states_or,
		"PA" => \%states_pa,
		"PR" => \%states_pr,
		"RI" => \%states_ri,
		"SC" => \%states_sc,
		"SD" => \%states_sd,
		"TN" => \%states_tn,
		"TX" => \%states_tx,
		"UT" => \%states_ut,
		"VA" => \%states_va,
		"VI" => \%states_vi,
		"VT" => \%states_vt,
		"WA" => \%states_wa,
		"WI" => \%states_wi,
		"WV" => \%states_wv,
		"WY" => \%states_wy,
	);
	
	return %weather_cities;
}
	
#-----------------------------------------------------------------------------
# RTTY Art files from RTTY.COM's Royer Art Pavilion
#-----------------------------------------------------------------------------

sub art_init{
	
	my %rtty_art_a_b = (
		"1R_Balloon" => '1R_Balloon.pix',
		"2ElFamosoCarlitosMoreno_W4NG" => 'ElFamosoCarlitosMoreno_W4NG.pix',
		"AdamAndEve" => 'AdamAndEve.pix',
		"AmericanDreamMachine_K9WRL" => 'AmericanDreamMachine_K9WRL.pix',
		"andycap" => 'andycap.pix',
		"AnotherGirl_K1PLP" => 'AnotherGirl_K1PLP.pix',
		"apegirl" => 'apegirl.pix',
		"ARRL" => 'ARRL.pix',
		"AtlasBrick_WA5EHA" => 'AtlasBrick_WA5EHA.pix',
		"b_boop" => 'b_boop.pix',
		"BatGirl" => 'BatGirl.pix',
		"batman" => 'batman.pix',
		"BatMan_W2NWQ" => 'BatMan_W2NWQ.pix',
		"bbardot" => 'bbardot.pix',
		"bcarter" => 'bcarter.pox',
		"BeepBeep_Unknown" => 'BeepBeep_Unknown.pix',
		"BeepBeepRoadRunner" => 'BeepBeepRoadRunner.pix',
		"Beethoven" => 'Beethoven.pix',
		"BerryXmasBanner2" => 'BerryXmasBanner2.pix',
		"bigben" => 'bigben.pox',
		"BigMac_W2UIC" => 'BigMac_W2UIC.pix',
		"Boat_Unknown" => 'Boat_Unknown.pix',
		"Buffalo_WB4WWC" => 'Buffalo_WB4WWC.pix',
		"BunnyFlowerPower_K9WRL" => 'BunnyFlowerPower_K9WRL.pix',
	);
	
	my %rtty_art_c_d = (
		"calvin" => 'calvin.pix',
		"camels" => 'camels.pix',
		"Casper_K1PLP" => 'Casper_K1PLP.pix',
		"castle" => 'castle.pix',
		"CatStevens1977" => 'CatStevens1977.pix',
		"caveman" => 'caveman.pix',
		"chamglas" => 'chamglas.pix',
		"Charlie_WA9WJE" => 'Charlie_WA9WJE.pix',
		"cookie" => 'cookie.pix',
		"cougar" => 'cougar.pix',
		"cowboy" => 'cowboy.pix',
		"crane" => 'crane.pox',
		"cy" => 'cy.pix',
		"cylonrdr" => 'cylonrdr.pix',
		"DateWithLucy" => 'DateWithLucy.pix',
		"dog" => 'dog.pox',
		"dtchme" => 'dtchme.pix',
	);
	
	my %rtty_art_e_f = (
		"edison" => 'edison.pix',
		"entrpriz" => 'entrpriz.pix',
		"f4e" => 'f4e.pix',
		"F-4EPhantom_K9WRL" => 'F-4EPhantom_K9WRL.pix',
		"facegirl" => 'facegirl.pix',
		"Faces" => 'Faces.pix',
		"fang" => 'fang.pix',
		"fccgirl" => 'fccgirl.pix',
		"ffstone" => 'ffstone.pix',
		"FinalFrontier_WA5OZH" => 'FinalFrontier_WA5OZH.pix',
		"flinstones" => 'flinstones.pix',
		"FlushWithPride_WB7OKG" => 'FlushWithPride_WB7OKG.pix',
		"frnchnd" => 'frnchnd.pix',
		"fshnfrg" => 'fshnfrg.pix',
	);
	
	my %rtty_art_g_h = (
		"garfield" => 'garfield.pix',
		"Garfield_WB9ZKI" => 'Garfield_WB9ZKI.pix',
		"garroway" => 'garroway.pix',
		"genhtrk" => 'genhtrk.pix',
		"george" => 'george.pix',
		"getinout" => 'getinout.pox',
		"girl" => 'girl.pix',
		"girlface" => 'girlface.pix',
		"grchomrx" => 'grchomrx.pix',
		"GreatAmericanEgal_K9WRL" => 'GreatAmericanEgal_K9WRL.pix',
		"HalloweenWitch_K1PLP" => 'HalloweenWitch_K1PLP.pix',
		"HappyEaster" => 'HappyEaster.pix',
		"HappyHalloween_WA9BXH" => 'HappyHalloween_WA9BXH.pix',
		"HappyNewYear" => 'HappyNewYear.pix',
		"HappyTurkeyDay" => 'HappyTurkeyDay.pix',
		"heart" => 'heart.pix',
		"HeathcliffCat" => 'HeathcliffCat.pix',
		"HighlandDanc" => 'HighlandDanc.pix',
		"hippo" => 'hippo.pix',
		"Hitshot_K9WRL" => 'Hitshot_K9WRL.pix',
		"holly" => 'holly.pix',
		"horshead" => 'horshead.pix',
	);
	
	my %rtty_art_i_l = (
		"indy500" => 'indy500.pix',
		"Indy500_WA6PIR" => 'Indy500_WA6PIR.pix',
		"karate" => 'karate.pix',
		"knucertp" => 'knucertp.pix',
		"lincoln" => 'lincoln.pix',
		"LittleAnnieFannie" => 'LittleAnnieFannie.pix',
		"LittleDrummerBoy_K9WRL" => 'LittleDrummerBoy_K9WRL.pix',
		"ltuhura" => 'ltuhura.pix',
		"lucy" => 'lucy.pix',
	);
	
	my %rtty_art_m = (
		"madmag" => 'madmag.pix',
		"Madonna" => 'Madonna.pix',
		"MerryXmas" => 'MerryXmas.pix',
		"MerryXmas_Edzell" => 'MerryXmas_Edzell.pix',
		"MerryXmasBanner1" => 'MerryXmasBanner1.pix',
		"MexicanBoy" => 'MexicanBoy.pix',
		"mickymouse" => 'mickymouse.pix',
		"misdec66" => 'misdec66.pix',
		"mismarch" => 'mismarch.pix',
		"MissAfro_WA6PIR" => 'MissAfro_WA6PIR.pix',
		"MissAnonomous" => 'MissAnonomous.pix',
		"missanta" => 'missanta.pix',
		"missclns" => 'missclns.pix',
		"MissCollins1973_WA6PIR" => 'MissCollins1973_WA6PIR.pix',
		"MissFebruary1972_WA6PIR" => 'MissFebruary1972_WA6PIR.pix',
		"MissJan1973_K9WRL" => 'MissJan1973_K9WRL.pix',
		"MissJuly_K9WRL" => 'MissJuly_K9WRL.pix',
		"MissMarch1971_WA6PIR" => 'MissMarch1971_WA6PIR.pix',
		"MissMarch1972_WA6PIR" => 'MissMarch1972_WA6PIR.pix',
		"MissMay1970" => 'MissMay1970.pix',
		"MissOct1972_WA6PIR" => 'MissOct1972_WA6PIR.pix',
		"MissOct1979" => 'MissOct1979.pix',
		"MissPlaymate_WA6PIR" => 'MissPlaymate_WA6PIR.pix',
		"misspt66" => 'misspt66.pix',
		"mmarch01" => 'mmarch01.pix',
		"modelafo" => 'modelafo.pix',
		"mozart" => 'mozart.pix',
		"Mystery_1" => 'Mystery_1.pix',
		"Mystery_2" => 'Mystery_2.pix',
		"Mystery_3" => 'Mystery_3.pix',
		"Mystery_4" => 'Mystery_4.pix',
		"Mystery_5" => 'Mystery_5.pix',
		"Mystery_6" => 'Mystery_6.pix',
		"Mystery_7" => 'Mystery_7.pix',
		"Mystery_8" => 'Mystery_8.pix',
	);
	
	my %rtty_art_n_r = (
		"OldDanishWindmill_OZ3UL" => 'OldDanishWindmill_OZ3UL.pix',
		"OldNavyShip_WA6EZW" => 'OldNavyShip_WA6EZW.pix',
		"OlivarHardy_K9WRL" => 'OlivarHardy_K9WRL.pix',
		"OlynpicDiver_WB4WWC" => 'OlynpicDiver_WB4WWC.pix',
		"PeaceOnEarth" => 'PeaceOnEarth.pix',
		"PinkPanther_WA6PIR" => 'PinkPanther_WA6PIR.pix',
		"PlayboyBunny" => 'PlayboyBunny.pix',
		"poison" => 'poison.pix',
		"QuickBrownFox" => 'QuickBrownFox.pix',
		"RingRing_KA9OPR" => 'RingRing_KA9OPR.pix',
		"rose" => 'rose.pix',
	);
	
	my %rtty_art_s_t = (
		"SeasonsGreetings1962" => 'SeasonsGreetings1962.pix',
		"SiamesePussycat_WA6PIR" => 'SiamesePussycat_WA6PIR.pix',
		"smiley" => 'smiley.pix',
		"Snoopy" => 'Snoopy.pix',
		"SnoopySkating_WA0PCM" => 'SnoopySkating_WA0PCM.pix',
		"StanLaurel_K9WRL" => 'StanLaurel_K9WRL.pix',
		"StarWars_K7YNC" => 'StarWars_K7YNC.pix',
		"TheChgeeseDigger" => 'TheChgeeseDigger.pix',
		"TheDisster_N9AHP" => 'TheDisster_N9AHP.pix',
		"TheMisses_WA6PIR" => 'TheMisses_WA6PIR.pix',
		"TheWrestler_G3MEJ" => 'TheWrestler_G3MEJ.pix',
		"ThreeWiseMen_WB2YXY" => 'ThreeWiseMen_WB2YXY.pix',
		"thumper" => 'thumper.pix',
		"tweetybird" => 'tweetybird.pix',
		"TwoWomen_W5SOQ" => 'TwoWomen_W5SOQ.pix',
	);
	
	my %rtty_art_u_z = (
		"UPILine_W2CY" => 'UPILine_W2CY.pix',
		"USATrain1975" => 'USATrain1975.pix',
		"valentine" => 'valentine.pix',
		"VargasGirl1968_K9WRL" => 'VargasGirl1968_K9WRL.pix',
		"VargasGirl1973_K9WRL" => 'VargasGirl1973_K9WRL.pix',
		"WA6LPY" => 'WA6LPY.pix',
		"WCFields_K9WRL" => 'WCFields_K9WRL.pix',
		"WhoIsBoss_K9TKE" => 'WhoIsBoss_K9TKE.pix',
		"Wolf" => 'Wolf.pix',
		"WorldPeace" => 'WorldPeace.pix',
		"WyomingCowboy_W7RPV" => 'WyomingCowboy_W7RPV.pix',
		"xmastree" => 'xmastree.pix',
		"YosemiteSam1" => 'YosemiteSam1.pix',
		"YosemiteSam2" => 'YosemiteSam2.pix',
		"YosemiteSam2" => 'YosemiteSam2.pix',
	);
	
	my %rtty_art_main = (
	    "0 - B" => \%rtty_art_a_b,
	    "C - D" => \%rtty_art_c_d,
	    "E - F" => \%rtty_art_e_f,
	    "G - H" => \%rtty_art_g_h,
	    "I - L" => \%rtty_art_i_l,
	    "M    " => \%rtty_art_m,
	    "N - R" => \%rtty_art_n_r,
	    "S - T" => \%rtty_art_s_t,
	    "U - Z" => \%rtty_art_u_z,
	);
	
	my %christmas_rtty_art = (
		"12 Days" => 'Christmas_tty.txt',
		"Madonna & Child" => 'Pittsburgh.txt',
		"Greeting" => 'greeting.txt',
		"Griffin" => 'griffin.pix',
		#"Pittm" => 'pittm.txt',
		"Santa" => 'santa.pix',
		"Christmas" => 'xmas.txt',
	);
	
	my %new_years_rtty_art = (
		"Year's Up" => 'yearsup.pix',
	);
		
	my %rtty_art_special = (
		"Christmas" => \%christmas_rtty_art,
		"New Year's Day" => \%new_years_rtty_art,
	);

	my %rtty_art = (
		"- Special Events -" => \%rtty_art_special,
		"- Links to Royer Pavilion @ RTTY.COM -" => \%rtty_art_main,
		"- LU8AJA Tests -" => {'LNET' => 'http://lucille/'},
	);
	
	# Prepend the base url to everything
	
	my $sSubCat;
	my $sLabel;
	my $sCategory;
	my $sBase;

	$sCategory = '- Special Events -';
	$sBase     = 'http://www.buzbee.net/heavymetal/asciiart/';
	for $sSubCat (keys %{$rtty_art{$sCategory}}){
		for $sLabel (keys %{$rtty_art{$sCategory}->{$sSubCat}}){
			$rtty_art{$sCategory}->{$sSubCat}->{$sLabel} = $sBase.$rtty_art{$sCategory}->{$sSubCat}->{$sLabel};
		}
	}

	$sCategory = '- Links to Royer Pavilion @ RTTY.COM -';
	$sBase     = 'http://www.rtty.com/gallery/';
	for $sSubCat (keys %{$rtty_art{$sCategory}}){
		for $sLabel (keys %{$rtty_art{$sCategory}->{$sSubCat}}){
			$rtty_art{$sCategory}->{$sSubCat}->{$sLabel} = $sBase.$rtty_art{$sCategory}->{$sSubCat}->{$sLabel};
		}
	}
	
	return %rtty_art;
}


