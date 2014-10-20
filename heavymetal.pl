#!/usr/bin/perl -X
# You may need to modify the above line in Linux to point to the ActivePerl installation

##############################################################################
#
# HeavyMetal v3.1.002
#
# Teletype control program.
#
# By Bill Buzbee and Javier Albinarrate (LU8AJA)
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# v3.0.000 2010-06-25 Finished complete rewrite started in May 2010
# v3.0.001 2010-11-20 Fixes to Serial port handling in Windows XP
# v3.0.002 2010-12-05 Changes to FTP fetch to use NET-FTP with Pasive Mode
# v3.0.003 2010-12-11 Bugfix
# v3.0.004 2011-10-04 Added ConsoleOnly mode and HMNet Directory support
# v3.1.000 2012-02-28 Total rewrite droping Tk and using Txx perl module
#                     Support for multiple TTYs. Enhanced GUI with configs in tabs. 
#                     Custom commands. VERSION command. RSS Feeds support.
#                     Full news for Reuters & BBC.
# v3.1.001 2012-03-10 Rewrite Full news retrieval, now it is based in a real HTML Parser
#                     Added support for full news to AP, TELAM, RIA, Spiegel, INTERPRESS
#                     Rewrote HOST window code, fixed cursor, colored commands, added progressbar.
# v3.1.002 2012-03-25 Changes to METAR provider. Added METAR HISTORIC. Added NOAA CLIMATE. 
#                     Tiny changes in UI. Added twitter via RSS. New BANNER module. New CRON
#                     
# Special thanks to Jim Haynes for his help in making HM3 run in Linux.
#
##############################################################################

use strict;


my $sGlobalVersion = "3.1.002";
my $sGlobalRelease = '2012-03-25';

my $sAboutMessage = "Version $sGlobalVersion ($sGlobalRelease)\n\n
HeavyMetal is a simple application to interface teletype machines to computers and the internet.

Initially made by Bill Buzbee - Oct 2005
Totally rewritten into v3.0 by Javier Albinarrate - May 2010

v3.0.000 2010-06-25 Finished complete rewrite started in May 2010
v3.0.001 2010-11-20 Fixes to Serial port handling in Windows XP
v3.0.002 2010-12-05 Changes to FTP fetch to use NET-FTP with PASV
v3.0.003 2010-12-11 Bugfix
v3.0.004 2011-10-04 Added ConsoleOnly mode and HMNet Directory 
v3.1.000 2012-02-28 Droping Tk, new GUI using Tkx. Multiple serial ports
                    RSS News Feeds. Version control and autoupdates.
v3.1.001 2012-03-10 Rewrite Full news retrieval, now it is based in a real HTML Parser
                    Added support for full news to AP, TELAM, RIA, Spiegel, INTERPRESS
                    Rewrote HOST window code, fixed cursor, colored commands.
                    Weather based on Google API
v3.2.002 2012-03-25 Added METAR HISTORIC. New: Twitter via RSS, BANNER module, CRON.

See:
  http://lu8aja.com.ar/heavymetal.html
  http://github.com/lu8aja/HeavyMetal";

### TODO LIST
# Allow the tty to be used as with LF to behave as CRLF
# Nothing for X10 has been tested
# Solve issue with LoopSuppress not being updated from the interfase
# Validate user names via configs/gui
# Status at the bottom
# X10
# users and permissions
# reinit button
# update name tty1
# doubleecho protect
# $LIST tab
# perhaps rfc2217?

#-----------------------------------------------------------------------------
# Module imports
#-----------------------------------------------------------------------------

use lib "./lib";

# This holds custom modifications and also some modules so they don't need to be installed
use lib "./lib.custom";


use Encode::Unicode;

my %Modules;

$Modules{'Win32::SerialPort'}  = {order => 1,  loaded => 0, required => 1, os => 'Win32'};
$Modules{'Win32::API'}         = {order => 2,  loaded => 0, required => 1, os => 'Win32'};
$Modules{'File::Spec::Win32'}  = {order => 3,  loaded => 0, required => 1, os => 'Win32'};
$Modules{'Device::SerialPort'} = {order => 5,  loaded => 0, required => 1, os => 'Linux'}; #This surely will need to be tweaked
$Modules{'LWP::Simple'}        = {order => 6,  loaded => 0, required => 1, os => ''};
$Modules{'Net::POP3'}          = {order => 7,  loaded => 0, required => 0, os => ''};
$Modules{'Net::SMTP'}          = {order => 8,  loaded => 0, required => 0, os => ''};
$Modules{'Net::FTP'}           = {order => 8,  loaded => 0, required => 0, os => ''};
$Modules{'MIME::Base64'}       = {order => 9,  loaded => 0, required => 0, os => ''};
$Modules{'IO::Handle'}         = {order => 10, loaded => 0, required => 1, os => ''};
$Modules{'IO::Socket'}         = {order => 11, loaded => 0, required => 1, os => ''};
$Modules{'IO::Select'}         = {order => 12, loaded => 0, required => 1, os => ''};
$Modules{'POSIX'}              = {order => 12, loaded => 0, required => 0, os => '', 'args'=>"('tmpnam')"};
$Modules{'Text::Wrap'}         = {order => 13, loaded => 0, required => 0, os => ''};
$Modules{'Text::Unidecode'}    = {order => 13, loaded => 0, required => 1, os => ''};
$Modules{'Text::Banner'}       = {order => 13, loaded => 0, required => 0, os => ''};
$Modules{'Time::HiRes'}        = {order => 15, loaded => 0, required => 1, os => ''};



$Modules{'Tkx'}                = {order => 20, loaded => 0, required => 1, os => ''};
$Modules{'Tkx::Scrolled'}      = {order => 21, loaded => 0, required => 0, os => ''};

$Modules{'Math::BigInt'}       = {order => 42, loaded => 0, required => 0, os => ''};
$Modules{'URI::Escape'}        = {order => 43, loaded => 0, required => 0, os => ''};
$Modules{'Data::Dumper'}       = {order => 44, loaded => 0, required => 0, os => ''};
$Modules{'HTTP::Request'}      = {order => 45, loaded => 0, required => 0, os => ''};
$Modules{'LWP::UserAgent'}     = {order => 46, loaded => 0, required => 0, os => ''};
$Modules{'Finance::YahooQuote'}= {order => 47, loaded => 0, required => 0, os => ''};
$Modules{'Digest::MD5'}        = {order => 48, loaded => 0, required => 0, os => '', args => "('md5','md5_hex','md5_base64')"};
$Modules{'Digest::SHA1'}       = {order => 49, loaded => 0, required => 0, os => '', args => "('sha1','sha1_hex','sha1_base64')"};
$Modules{'Crypt::SSLeay'}      = {order => 50, loaded => 0, required => 0, os => ''};
$Modules{'MSN'}                = {order => 51, loaded => 0, required => 0, os => ''};
$Modules{'Cwd'}                = {order => 52, loaded => 0, required => 0, os => ''};
$Modules{'Data::Dumper'}       = {order => 53, loaded => 0, required => 0, os => ''};
$Modules{'JSON'}               = {order => 54, loaded => 0, required => 0, os => ''};
$Modules{'File::Copy'}         = {order => 55, loaded => 0, required => 0, os => ''};
$Modules{'Clipboard'}          = {order => 56, loaded => 0, required => 0, os => ''};
$Modules{'XML::DOM'}         = {order => 57, loaded => 0, required => 0, os => ''};
$Modules{'XML::RSS::Parser'}   = {order => 58, loaded => 0, required => 0, os => ''};

$Modules{'HTML::Entities'}     = {order => 58, loaded => 0, required => 0, os => '', args => "('decode_entities')"};
$Modules{'HTML::TreeBuilder'}  = {order => 59, loaded => 0, required => 0, os => ''};
$Modules{'Weather::Google'}    = {order => 60, loaded => 0, required => 0, os => ''};
$Modules{'Geo::METAR'}         = {order => 62, loaded => 0, required => 0, os => ''};



#-----------------------------------------------------------------------------
# Configuration settings.  Edit these to change defauts.
#-----------------------------------------------------------------------------
my %Configs;              # Array for all configs
my %ConfigsDefault;       # Array for all default configs (copied before loading cfg file)

#- - - - - - - - - - System Configs - - - - - - - - - - - - - - - - - - - -

$Configs{SystemName}      = 'HM';
$Configs{SystemPrompt}    = $Configs{SystemName}.': ';
$Configs{SystemPassword}  = 'BAUDOT';
$Configs{GuestPassword}   = 'GUEST';
$Configs{Debug}           = 0;
$Configs{DebugFile}       = 'debug/debug-$DATETIME.log';
$Configs{DebugShowErrors} = 0;
$Configs{SerialSetserial} = 1;
$Configs{ConsoleOnly}     = 0;
$Configs{CommandsMaxHistory} = 10;
$Configs{CronEnabled}     = 0;

#-- Code converstion settings.  Current choices are ASCII, USTTY, ITA2, TTS-M20

#-- Operating entirely from Teletype keyboard?
$Configs{RemoteMode} = 0;	# If 1, suppress dialog boxes. Set to 1 if operating
			# from a teletype keyboard and don't want to have
			# to click "OK" on warning and error dialog boxes.

$Configs{LoopTest}     = 0; # Skip output to loop?


#- - - - - - - - - - Control Options - - - - - - - - - - - - - - - - - - - -

$Configs{EscapeEnabled} = 1;    # Enable "$" & "\" escapes to create special chars and execute commands
$Configs{EscapeChar}    = '$';  # Escape character to use
$Configs{RunInProtect}  = 20;   # This prevents that the user on tty gets interfered with a message while writting, unless it has been idle for N secs
$Configs{BatchMode}     = 0;    # Auto-exit when nothing left to do. If 1, exit when command-line actions complete.

#- - - - - - - - - - Email Configs - - - - - - - - - - - - - - - - - -
#   Edit these to reflect your accounts.  If you don't know your
#   pop & stmp hosts, look in the setting file for your browser or
#   email program.  If your incoming mail host is IMAP rather than
#   pop, put its name for $Configs{EmailPOP} anyway.

$Configs{EmailPOP}      = "";    # Typically something like pop.myhost.com 
$Configs{EmailSMTP}     = "";    # Typically something like mail.myhost.com
$Configs{EmailAccount}  = "";                                                       
$Configs{EmailPassword} = "";                                                   
$Configs{EmailFrom}     = "";                                             

#- - - - - - - - - - Telnet Configs - - - - - - - - - - - - - - - - - - - -
$Configs{TelnetEnabled}   = 0;
$Configs{TelnetPort}      = 1078;
$Configs{TelnetWelcome}   = "Welcome to $Configs{SystemName} using HeavyMetal TTY controller";
$Configs{TelnetNegotiate} = 1;

#- - - - - - - - - - HMNet Internet Directory - - - - - - - - - - - - - - -
$Configs{HMNetEnabled}= 0;
$Configs{HMNetName}   = 'Station Name';
$Configs{HMNetPass}   = 'HMNET Password';
$Configs{HMNetOwner}  = 'Your Name';
$Configs{HMNetEmail}  = 'Contact Email';
$Configs{HMNetUrl}    = 'http://lu8aja.com.ar/heavymetal/';
	
#- - - - - - - - - - MSN Configs - - - - - - - - - - - - - - - - - - - - -
$Configs{MsnEnabled}  = 0;                   
$Configs{MsnUsername} = '';
$Configs{MsnPassword} = '';
$Configs{MsnListen}   = 0;                   
$Configs{MsnDebug}    = 0;

#- - - - - - - - - - TTY Configs - - - - - - - - - - - - - - - - - - - - -
$Configs{'TTY.1.Port'} = "OFF";
$Configs{'TTY.2.Port'} = "OFF";

#- - - - - - - - - - RSS Configs - - - - - - - - - - - - - - - - - - - - -

# Main history file
$Configs{'RSS.Feed.HISTORY'}           = 'http://lu8aja.com.ar/heavymetal/history/rss.xml';

# AP
$Configs{'RSS.Feed.AP'}                = 'http://hosted.ap.org/lineups/TOPHEADS.rss?SITE=WHIZ&SECTION=HOME';
$Configs{'RSS.Feed.AP.WORLD'}          = 'http://hosted.ap.org/lineups/WORLDHEADS.rss?SITE=WHIZ&SECTION=HOME';
$Configs{'RSS.Feed.AP.US'}             = 'http://hosted.ap.org/lineups/USHEADS.rss?SITE=WHIZ&SECTION=HOME';
$Configs{'RSS.Feed.AP.POLITICS'}       = 'http://hosted.ap.org/lineups/POLITICSHEADS.rss?SITE=WHIZ&SECTION=HOME';
$Configs{'RSS.Feed.AP.SCIENCE'}        = 'http://hosted.ap.org/lineups/SCIENCEHEADS.rss?SITE=WHIZ&SECTION=HOME';
# ANSA (Italian)
$Configs{'RSS.Feed.ANSA'}              = 'http://www.ansa.it/web/notizie/rubriche/topnews/topnews_rss.xml';
$Configs{'RSS.Feed.ANSA.WORLD'}        = 'http://www.ansa.it/web/notizie/rubriche/mondo/mondo_rss.xml';
$Configs{'RSS.Feed.ANSA.POLITICA'}     = 'http://www.ansa.it/web/notizie/rubriche/politica/politica_rss.xml';
$Configs{'RSS.Feed.ANSA.ECONOMIA'}     = 'http://www.ansa.it/web/notizie/rubriche/economia/economia_rss.xml';
# BBC
$Configs{'RSS.Feed.BBC'}               = 'http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml';
$Configs{'RSS.Feed.BBC.WORLD'}         = 'http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/world/rss.xml';
$Configs{'RSS.Feed.BBC.POLITICS'}      = 'http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/uk_politics/rss.xml';
# GOOGLE
$Configs{'RSS.Feed.GOOGLE'}            = 'http://news.google.com/news?ned=us&topic=h&output=rss';
$Configs{'RSS.Feed.GOOGLE.WORLD'}      = 'http://news.google.com/news?ned=us&topic=w&output=rss';
$Configs{'RSS.Feed.GOOGLE.US'}         = 'http://news.google.com/news?ned=us&topic=n&output=rss';
# REUTERS
$Configs{'RSS.Feed.REUTERS'}           = 'http://feeds.reuters.com/reuters/topNews';
$Configs{'RSS.Feed.REUTERS.WORLD'}     = 'http://feeds.reuters.com/reuters/worldNews';
$Configs{'RSS.Feed.REUTERS.US'}        = 'http://feeds.reuters.com/reuters/domesticNews';
$Configs{'RSS.Feed.REUTERS.POLITICS'}  = 'http://feeds.reuters.com/reuters/PoliticsNews';
$Configs{'RSS.Feed.REUTERS.MARKETS'}   = 'http://feeds.reuters.com/reuters/globalmarketsNews';
# INTERPRESS
$Configs{'RSS.Feed.INTERPRESS'}        = 'http://ipsnews.net/rss/headlines.xml';
# RIA (Russian)
$Configs{'RSS.Feed.RIA'}               = 'http://ria.ru/export/rss2/index.xml';
# SPIEGEL (German)
$Configs{'RSS.Feed.SPIEGEL'}           = 'http://www.spiegel.de/schlagzeilen/index.rss';
# TASS (Russian)
$Configs{'RSS.Feed.TASS'}              = 'http://www.itar-tass.com/rss/all.xml';
# TELAM (Spanish)
$Configs{'RSS.Feed.TELAM'}             = 'http://www.telam.com.ar/xml/rss/';
$Configs{'RSS.Feed.TELAM.WORLD'}       = 'http://www.telam.com.ar/xml/rss/6';
$Configs{'RSS.Feed.TELAM.POLITICS'}    = 'http://www.telam.com.ar/xml/rss/1';
$Configs{'RSS.Feed.TELAM.ECONOMY'}     = 'http://www.telam.com.ar/xml/rss/2';
# UPI
$Configs{'RSS.Feed.UPI'}               = 'http://rss.upi.com/news/top_news.rss';
$Configs{'RSS.Feed.UPI.LATEST'}        = 'http://rss.upi.com/news/news.rss';
$Configs{'RSS.Feed.UPI.BUSINESS'}      = 'http://rss.upi.com/news/business_news.rss';
# YAHOO NEWS
$Configs{'RSS.Feed.YAHOO'}             = 'http://news.yahoo.com/rss';
$Configs{'RSS.Feed.YAHOO.US'}          = 'http://news.yahoo.com/rss/us';
$Configs{'RSS.Feed.YAHOO.POLITICS'}    = 'http://news.yahoo.com/rss/politics';
$Configs{'RSS.Feed.YAHOO.WORLD'}       = 'http://news.yahoo.com/rss/world';
$Configs{'RSS.Feed.YAHOO.EUROPE'}      = 'http://news.yahoo.com/rss/europe';
$Configs{'RSS.Feed.YAHOO.WEATHER'}     = 'http://news.yahoo.com/rss/weather';
# YAHOO WEATHER
$Configs{'RSS.Feed.WEATHER.AR.BUENOSAIRES'} = 'http://weather.yahooapis.com/forecastrss?p=ARBA0009&u=c';
$Configs{'RSS.Feed.WEATHER.DE.BERLIN'}  = 'http://weather.yahooapis.com/forecastrss?p=GMXX1273&u=c';
$Configs{'RSS.Feed.WEATHER.ES.MADRID'}  = 'http://weather.yahooapis.com/forecastrss?p=SPXX0050&u=c';
$Configs{'RSS.Feed.WEATHER.FR.PARIS'}   = 'http://weather.yahooapis.com/forecastrss?p=FRXX0076&u=c';
$Configs{'RSS.Feed.WEATHER.RU.MOSCOW'}  = 'http://weather.yahooapis.com/forecastrss?p=RSXX0063&u=c';
$Configs{'RSS.Feed.WEATHER.UK.LONDON'}  = 'http://weather.yahooapis.com/forecastrss?p=UKXX0085&u=f';
$Configs{'RSS.Feed.WEATHER.US.NEWYORK'} = 'http://weather.yahooapis.com/forecastrss?p=USNY0996&u=f';


# TWITTER Gateway
$Configs{'RSS.Feed.TWITTER.TELETYPES'} = 'http://api.twitter.com/1/statuses/user_timeline.rss?screen_name=teletypes';

# Defaults for favorite menues
$Configs{'RSS.Menu.0'} = 'TITLES REUTERS';
$Configs{'RSS.Menu.1'} = 'SUMMARY AP';
$Configs{'RSS.Menu.2'} = 'FULL BBC.WORLD';

$Configs{'Twitter.Menu.0'} = 'teletypes';

$Configs{'WeatherFavorite.0'} = 'New York, NY, US';




#- - - - - - - - - - MISC Configs - - - - - - - - - - - - - - - - - - - - -

#- QBF test

$Configs{TestQBF} = "The quick brown fox jumped over a lazy dog's back 1234567890 HM3 SENDING.";



#-- Set up your portfolio here.  To get the right ticker symbols, go to Yahoo.com.
$Configs{StockPortfolio} = "DJI SPC AOL IBM";

#-- Number of columns for TTY & HOST window
$Configs{Columns} = 100; 

$Configs{CopyHostOutput} = 'OFF';

#-- Weather reports from tgftp.nws.noaa.gov
$Configs{WeatherNoaaForecastBase} = 'ftp://tgftp.nws.noaa.gov/data/forecasts/city/';
$Configs{WeatherNoaaClimateBase}  = 'ftp://tgftp.nws.noaa.gov/data/climate/daily/';

$Configs{WeatherDefaultSource} = 'WWO';

#-- X10 stuff
$Configs{X10House}  = 'A';
$Configs{X10Device} = '1';
$Configs{X10Auto}   = 0;



#-----------------------------------------------------------------------------
# Global vars
#-----------------------------------------------------------------------------

my %Global;

my $nTimeStart       = time();
my $sDebugFile       = ''; # Full filename for debug
my $rDebugHandle;          # File handle for debug output
my $rDebugSocket;          # Allows to copy debug output to a socket
my $sLoginDisallowed = '^(ALL|IN|OUT|MSN|TTY|SYS|TELNET|HOST|OFF|NONE|UNKNOWN)$'; # Disallowed Usernames
my $sSessionsHelp    = "Use command ".$Configs{EscapeChar}."HELP\r\n";
my $nSessionsCount   = 0;  # Sessions counter
my $NewSessionId     = 10;  # Session id
my @aSessions;             # Array for all sessions
my %oSessionsData;

my %aStatusLabels;
my $nShutDown        = 0;  # At any moment, setting this to a unixtime will shutdown at that moment or later
my $bExitMainLoop    = 0;
my $nSleep           = 0;
my $nTimerSleep      = 0;
my $nSleepRepeat     = 0;
my $nCount           = 0;
my $nMax             = 0;
my $sOS              = $^O;
my $bWindows         = ($sOS eq "MSWin32") ? 1 : 0;
my $bWindows98       = 0;
my $sGlobalAvailableBuildBeta     = '';
my $sGlobalAvailableBuildReleased = '';

$Global{VersionsAvailable} = {};
$Global{Links}             = [];
$Global{Images}            = {};

my $sGlobalTextTag     = '';
my $nGlobalTime        = 0;
my $nGlobalCronNextRun = 0;
my $oGlobalBanner;
my $sGlobalConfigsFile = "heavymetal.cfg";        # Config file
my $nGlobalSerialChunk = 10;

#- - - - - - - - - - Code & UART Settings - - - - - - - - - - - - - - - - - -

#-- Optional millisecond delay between character transmission
my $char_delay = 0;





my %aPORTS;
#-- Windows only - addresses of serial IO ports
if ($bWindows) {
	%aPORTS = (
		'OFF'   => {label => 'Disabled',address => 0,     order => 0},
		'COM1'  => {label => 'COM1' ,  address => 0x3f8, order => 1},
		'COM2'  => {label => 'COM2' ,  address => 0x2f8, order => 2},
		'COM3'  => {label => 'COM3' ,  address => 0x3e8, order => 3},
		'COM4'  => {label => 'COM4' ,  address => 0x2e8, order => 4},
		'COM5'  => {label => 'COM5' ,  address => 0x3f0, order => 5},
		'COM6'  => {label => 'COM6' ,  address => 0x2f0, order => 6},
		'COM7'  => {label => 'COM7' ,  address => 0x3e0, order => 7},
		'COM8'  => {label => 'COM8' ,  address => 0x2e0, order => 8},
		'COM9'  => {label => 'COM9' ,  address => 0,     order => 9},
		'COM10' => {label => 'COM10',  address => 0,     order => 10},
		'COM11' => {label => 'COM11',  address => 0,     order => 11},
		'COM12' => {label => 'COM12',  address => 0,     order => 12},
		'COM16' => {label => 'COM16',  address => 0,     order => 16},
		'COM17' => {label => 'COM17',  address => 0,     order => 17} 
	);
}
else {
	%aPORTS = (
		'OFF'        => {label => 'Disabled'   , address => 0, order => 0},       
		'/dev/ttyS0' => {label => '/dev/ttyS0' , address => 0, order => 1},       
		'/dev/ttyS1' => {label => '/dev/ttyS1' , address => 0, order => 2},
		'/dev/ttyS2' => {label => '/dev/ttyS2' , address => 0, order => 3},
		'/dev/ttyS3' => {label => '/dev/ttyS3' , address => 0, order => 4},
		'/dev/ttyS4' => {label => '/dev/ttyS4' , address => 0, order => 5},
		'/dev/ttyS5' => {label => '/dev/ttyS5' , address => 0, order => 6},
		'/dev/ttyS6' => {label => '/dev/ttyS6' , address => 0, order => 7},
		'/dev/ttyS7' => {label => '/dev/ttyS7' , address => 0, order => 8}
	);
}

my %aPortAddresses = (
	0x3f8 => {label => '0x3F8', order => 1},
	0x2f8 => {label => '0x2F8', order => 2},
	0x3e8 => {label => '0x3E8', order => 3},
	0x2e8 => {label => '0x2E8', order => 4},
	0x3f0 => {label => '0x3F0', order => 5},
	0x2f0 => {label => '0x2F0', order => 6},
	0x3e0 => {label => '0x3E0', order => 7},
	0x2e0 => {label => '0x2E0', order => 8},
);

$Configs{'TTY.1.Address'} = $aPORTS{ $Configs{'TTY.1.Port'} }->{address};
$Configs{'TTY.2.Address'} = $aPORTS{ $Configs{'TTY.2.Port'} }->{address};

#my $BAUD51  = 2235;	# 60 wpm gear for 6-bit codes w/ 1.5 stop bits
#my $BAUD51  = 2111;	# 60 wpm gear for 6-bit codes w/ 2 stop bits
#my $BAUD51  = 2180;	# 60 wpm gear for 6-bit codes w/ 2 stop bits (slowed)
   		   
my %aBaudRates = (
	'BAUD45'    => {order => 1,  divisor => 2534, label => '45.5 Baud (60WPM)'              , label_short => '45.5 Bb'}, # 45.5 baud
	'BAUD51'    => {order => 2,  divisor => 2190, label => '51 Baud (60WPM for 6-bit codes)', label_short => '60WPM'}, # 60 wpm gear for 6-bit codes w/ 1 stop bits (slowed)
	'BAUD50'    => {order => 3,  divisor => 2304, label => '50 Baud (66WPM)'                , label_short => '50 Bb'}, # 50 baud
	'BAUD56'    => {order => 4,  divisor => 2057, label => '56 Baud (75WPM)'                , label_short => '75WPM'}, # 75 wpm for 5-bit codes
	'BAUD66'    => {order => 5,  divisor => 1697, label => '74 Baud (100WPM)'               , label_short => '100WPM'}, #
	'WPM100'    => {order => 6,  divisor => 1555, label => '66 Baud'                        , label_short => '66 Bb'}, # 74 baud
	'BAUD110'   => {order => 7,  divisor => 1047, label => '110 Baud'                       , label_short => '110 Bb'}, #
	'BAUD300'   => {order => 8,  divisor =>  384, label => '300 Baud'                       , label_short => '300'}, #
	'BAUD1200'  => {order => 9,  divisor =>   96, label => '1200 Baud'                      , label_short => '1200'}, #
	'BAUD2400'  => {order => 10, divisor =>   48, label => '2400 Baud'                      , label_short => '2400'}, #
	'BAUD4800'  => {order => 11, divisor =>   24, label => '4800 Baud'                      , label_short => '4800'}, #
	'BAUD9600'  => {order => 12, divisor =>   12, label => '9600 Baud'                      , label_short => '9600'}, #
	'BAUD19200' => {order => 13, divisor =>    6, label => '19200 Baud'                     , label_short => '19200'}, #
	'BAUD38400' => {order => 14, divisor =>    2, label => '38400 Baud'                     , label_short => '38400'}, #
);                                                                                 

my %aDataBits = (
	5 => {order => 0, label => '5 bits'},
	6 => {order => 1, label => '6 bits'},
	7 => {order => 2, label => '7 bits'},
	8 => {order => 3, label => '8 bits'}
);
 
my %aParity = (
	'none' => {order => 0, label => 'None'},
	'even' => {order => 1, label => 'Even'},
	'odd'  => {order => 2, label => 'Odd'}

);
my %aStopBits = (
	1   => {order => 0, label => '1 bit'},
	1.5 => {order => 1, label => '1.5 bits'},
	2   => {order => 2, label => '2 bits'}
);


my %aDebugLevels = (
	0 => {order => 0, label => '0 - Disabled'},
	1 => {order => 1, label => '1 - Basic debug'},
	2 => {order => 2, label => '2 - Function calls'},
	3 => {order => 3, label => '3 - Full byte-level dump'}
);

my %aOutputTargets = (
	'OFF' => {order => 0, label => 'Disabled'},
	'1'   => {order => 1, label => '1 - TTY1'},
	'2'   => {order => 2, label => '2 - TTY2'}
);

#-- Derived variables for status line - don't change.  These will be generated based on SerialDivisor
my $nGlobalWPM  = 0;
my $nGlobalBaud = 0;

#- - - - - - - - - - Windowing & Display options - - - - - - - - - - - - - -






my $bCancelSleep  = 0;

#these configs seem to be obsolete?
my $batchmode_countdown_delay;

$batchmode_countdown_delay = $bWindows ? 10 : 200;

my $batchmode_countdown = $batchmode_countdown_delay;  # Make sure we're done

#
#-- Update interval
my $polltime = 50;	# How frequently do we check for something to do


#-- Font for Menu items [unimplemented]
my $sGlobalLabelFont = $bWindows ? "Courier 12 normal" : "-adobe-courier-bold-r-normal--12-120-75-75-m-70-iso8859-1";






#- - - - - - - - - - Telnet - - - - - - - - - - - - - - - - - - - -

# Global vars
my $sckTelnetListener;   # Listener socket
my %aTelnetSockets;      # Map for sockets->sessions
my $nTelnetSockets = 0;
my $oTelnetReadSet;      # IO Select Set for Socket READ
my $oTelnetWriteSet;     # IO Select Set for Socket WRITE
my $oTelnetExceptionSet; # IO Select Set for Socket EXCEPTION


#- - - - - - - - - - Msn - - - - - - - - - - - - - - - - - - - -

# Global vars
my $MsnConnected   = 0;
my $MsnLastContact = '';
my $MsnConnectBy   = 0;
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
	'ABOUT'     => {command => \&do_about,           auth => 2, help => 'Display information about HM', args => 'No args'},
	'PING'      => {command => \&do_ping,            auth => 1, help => 'Ping Pong communication test', args => 'echo-text (optional)'},
	'UPTIME'    => {command => \&do_uptime,          auth => 1, help => 'Show uptime',                  args => 'No args'},
	'TIME'      => {command => \&do_time,            auth => 1, help => 'Show current localtime',       args => 'No args'},
	'JOKE'      => {command => \&do_joke,            auth => 0, help => 'Tell me a joke',               args => 'No args'},
	'LOGOUT'    => {command => \&do_logout,          auth => 0, help => 'Disconnect a session (telnet only)', args => 'No args'},
	'QUIT'      => {command => \&do_logout,          auth => 0, help => 'Alias for logout',             args => 'No args'},
	'EXIT'      => {command => \&do_logout,          auth => 0, help => 'Alias for logout',             args => 'No args'},
	'SHUTDOWN'  => {command => \&do_shutdown,        auth => 3, help => 'Clean up and exit',            args => 'No args'},
	'LIST'      => {command => \&do_list,            auth => 2, help => 'List existing sessions',       args => 'No args'},
	'LABEL'     => {command => \&do_label,           auth => 3, help => 'Print a punched tape label',   args => 'label-text (optional)'},
	'TELNET'    => {command => \&do_telnet,          auth => 3, help => 'Connect to a telnet server',   args => 'hostname (optional) port (optional)'},
	'TELNETREVERSE'=> {command => \&do_telnet_reverse,  auth => 3, help => 'Connect to a telnet server and AUTH it as IN',   args => 'hostname (optional) port (optional)'},
	'VERSION'   => {command => \&do_version,         auth => 3, help => 'Check the available versions to download',   args => 'No args'},
	'EVAL'      => {command => \&do_eval,            auth => 3, help => 'Execute perl code',                args => 'perl-code'},
	'PROMPT'    => {command => \&do_prompt,          auth => 2, help => 'Change the prompt mode for this session', args => 'On/Off'},
	'ECHO'      => {command => \&do_echo,            auth => 0, help => 'Change the echo mode for this session', args => 'On/Off'},
	'DEBUG'     => {command => \&do_debug,           auth => 2, help => 'View/Change debug settings',       args => '0,1,2,3 (optional) -or- SESSION session-id (to copy to session)'},
	'SOURCE'    => {command => \&do_source,          auth => 2, help => 'Change the source of a session',   args => 'source-session (optional) -or- source-session session-id (to set the source of another session)'},
	'DND'       => {command => \&do_dnd,             auth => 2, help => 'Do Not Disturb',                   args => 'On/Off'},
	'TARGET'    => {command => \&do_target,          auth => 2, help => 'Change the target of a session' ,  args => 'target-session (optional) -or- target-session session-id (to set the target of another session)'},
	'CHAT'      => {command => \&do_chat,            auth => 2, help => 'Change the source and target of your session', args => 'session-id -or- ALL'},
	'AUTH'      => {command => \&do_auth,            auth => 3, help => 'Switches a session to authorized', args => 'session-id'},
	'INVERT'    => {command => \&do_invert,          auth => 3, help => 'Changes direction of a telnet session', args => 'session-id IN/OUT (optional)'},
	'HMPIPE'    => {command => \&do_hmpipe,          auth => 2, help => 'Switches a session to piped mode (No prompt, no echo)', args => 'No args'},
	'USER'      => {command => \&do_user,            auth => 2, help => 'Change your username',             args => 'username'},
	'ABORT'     => {command => \&do_abort,           auth => 2, help => 'Abort current actions',            args => 'No args'},
	'SESSION'   => {command => \&do_session,         auth => 3, help => 'Show/change session parameters',   args => 'session-id (optional) -or- session-id setting value (to change a setting)'},
	'SETVAR'    => {command => \&do_setvar,          auth => 2, help => 'Change a command variable',        args => 'variable value'},
	'CONFIG'    => {command => \&do_config,          auth => 3, help => 'Change a config setting',          args => 'config-name config-value'},
	'CONFIGS'   => {command => \&do_configs,         auth => 3, help => 'Show config settings',             args => 'search-start (optional)'},
	'SAVECONFIG'=> {command => \&do_saveconfig,      auth => 3, help => 'Save config file',                 args => 'No args'},
	'PORT'      => {command => \&do_port,            auth => 3, help => 'Change serial port configs',       args => 'port bauds word-parity-stop code (optional)'},
	'SERIALINIT'=> {command => \&serial_init,        auth => 3, help => 'Initialize the serial port',       args => 'session-id'},
	'KICK'      => {command => \&do_kick,            auth => 3, help => 'Kick a telnet session',            args => 'session-id'},
	'HOSTCMD'   => {command => \&do_host_command,    auth => 3, help => 'Execute command on host',          args => 'console-command'},
	'MSG'       => {command => \&do_msg,             auth => 2, help => 'Send a message to a target',       args => 'target message'},
	'SEND'      => {command => \&do_send,            auth => 3, help => 'Send a message to a target without source label',     args => 'target message -or- target command'},
	'SENDFILE'  => {command => \&do_sendfile,        auth => 3, help => 'Send file contents to a target without source label', args => 'target filename'},
	'MSN'       => {command => \&do_msn,             auth => 2, help => 'Interact with MSN (See help)',     args => 'On/Off'},
	'HMNET'     => {command => \&do_hmnet,           auth => 3, help => 'Interact with HMNET (See help)',   args => 'On/Off/List'},
	'MSNLIST'   => {command => \&do_msnlist,         auth => 2, help => 'Show the MSN contact list',        args => 'No args'},
	'BANNER'    => {command => \&do_banner,          auth => 2, help => 'Generate a banner',                args => 'banner-text'},
	'CHECKMAIL' => {command => \&do_email_fetch,     auth => 3, help => 'Check POP email',                  args => 'No args'},
	'SENDMAIL'  => {command => \&do_email_send,	     auth => 3, help => 'Send email (Interactive command)', args => 'email-to subject (optional)'},
	'EMAIL'     => {command => \&do_email_send,	     auth => 3, help => 'Send email (Interactive command)', args => 'email-to subject (optional)'},
	'QBF'       => {command => \&do_qbf,             auth => 2, help => 'Test QBF',                         args => 'No args'},
	'RYRY'      => {command => \&do_ryry,            auth => 2, help => 'Test RYRY',                        args => 'num-lines (optional) show-nums (optional)'},
	'R6R6'      => {command => \&do_r6r6,            auth => 2, help => 'Test R6R6',                        args => 'num-lines (optional) show-nums (optional)'},
	'RRRR'      => {command => \&do_rrrr,            auth => 2, help => 'Test RRRR',                        args => 'num-lines (optional) show-nums (optional)'},
	'RAW5BIT'   => {command => \&do_raw_5bit,        auth => 2, help => 'Test Raw 5 bits',                  args => 'No args'},
	'RAW6BIT'   => {command => \&do_raw_6bit,        auth => 2, help => 'Test Raw 6 bits',                  args => 'No args'},
	'ECHOTEST'  => {command => \&do_echotest,        auth => 3, help => 'Test for echo in TTY loop',        args => 'id-session-of-tty'},
	'SUPPRESS'  => {command => \&do_suppress,        auth => 3, help => 'Enable/Disable loop echo supression', args => 'On/Off'},
	'URL'       => {command => \&do_url,             auth => 2, help => 'Get any FTP/HTTP URL',             args => 'url'},
	'WEB'       => {command => \&do_web,             auth => 2, help => 'Browse HTML pages',                args => 'url-or-link-id'},
	'FTP'       => {command => \&do_ftp,             auth => 2, help => 'Get any FTP (PASV) URL',           args => 'url'},
	'WEATHER'   => {command => \&do_weather,         auth => 2, help => 'Get Weather report',               args => 'source-or-2-letter-country-code varies-by-source'},
	'NOAA'      => {command => \&do_weather_noaa,    auth => 2, help => 'Get NOAA weather report from NOAA',args => '2-letter-state city'},
	'METAR'     => {command => \&do_weather_metar,   auth => 2, help => 'Get METAR Weather report',         args => 'output stations'},
	'ART'       => {command => \&do_art,             auth => 2, help => 'Get RTTY ART images',              args => 'path'},
	'QUOTE'     => {command => \&do_quote,           auth => 2, help => 'Get stock quotes',                 args => 'stock-id -or- sotck-id stock-id ...'},
	'QUOTES'    => {command => \&do_quote,           auth => 2, help => 'Get stock quotes',                 args => 'stock-id -or- sotck-id stock-id ...'},
	'FULLQUOTE' => {command => \&do_quote_full,      auth => 2, help => 'Get full stock quotes',            args => 'stock-id -or- sotck-id stock-id ...'},
	'FULLQUOTES'=> {command => \&do_quote_full,      auth => 2, help => 'Get full stock quotes',            args => 'stock-id -or- sotck-id stock-id ...'},
	'PORTFOLIO' => {command => \&do_quote_portfolio, auth => 2, help => 'Get quotes for a given portfolio', args => 'No args'},
	#'TOPNEWS'   => {command => \&do_news_topnews,    auth => 0, help => 'AP news summary',                  args => 'No args'},
	'NEWS'      => {command => \&do_news,            auth => 1, help => 'RSS news summary',                 args => 'channel-or-url (TITLES,SUMMARY,FULL) -or- link-id'},
	'TWITTER'   => {command => \&do_twitter,         auth => 1, help => 'Twitter access via RSS',           args => 'twitter-account'},
	#'HISTORY'   => {command => \&do_news_history,    auth => 2, help => 'AP Today in History',              args => 'No args'},
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
	'ARROWN'  => chr(0x2191),
	'ARROWNE' => chr(0x2197),
	'ARROWE'  => chr(0x2192),
	'ARROWSE' => chr(0x2198),
	'ARROWS'  => chr(0x2193),
	'ARROWSW' => chr(0x2199),
	'ARROWW'  => chr(0x2190),
	'ARROWNW' => chr(0x2196),
	'WXCLR'   => chr(0x25CC),
	'WXSCT'   => chr(0x229D),
	'WXBKN'   => chr(0x229C),
	'WXOVC'   => chr(0x2A01)
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
	#"\007"	=> 'BEL',  # ITA2/USTTY Bell
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

my $EOL = "\015\012";


my $loop_no_match_char = chr(4); # Use this if no code conversion match
my $host_no_match_char = undef;  # Use this if no code conversion match


# Scalar character buffers

my $loop_archive  = "Sorry, not implemented yet..."; 	# Copy of all incoming raw loop data


# Performing the actions...

my @aCommands = ();		# Array of commands to carry out in list form.
			# New commands are pushed onto the commands array
			# and shifted out as they are carried out.

my $sCurrentCommand = '';


# Windowing variables
my $oTkMainWindow;         # Main window
my $bTkEnabled       = 1;  # Will be disabled in ConsoleOnly mode (We need this as a global var instead of a changeable config)
my $bTkInitialized   = 0;  # Will be disabled in ConsoleOnly mode (We need this as a global var instead of a changeable config)
my %oTkMenues;             # Holds the menu elements
my %oTkControls;           # Holds the UI controls
my $UI_TkParent;
my $UI_Row = 0;
my $UI_Col = 0;
my $sInputValue      = ''; # Text entered in via keyboard in text box
my $oTkTextarea;           # Displayed text window
my $oTkAbout;
my $oTkStatus;
my $nGlobalPendingBytes  = 0;
my $nGlobalProgressBusy  = 0;

my $sPrinthead;         # current printhead position
my $sGlobalCursorChar    = '_';  # char used as cursor
my $bGlobalCursorReplace = 0;    # The cursor inserts or replaces?

# This was not implemented, it might be needed in future versions
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
	CronEnabled     => {help => 'Enable the builtin CRON'},
	CommandsMaxHistory=>{help=> 'Number of commands to store on history. Def: 10'},
	EmailAccount    => {help => 'Email account for POP and SMTP'},
	EmailFrom       => {help => 'Email from to use for email'},
	EmailPOP        => {help => 'POP server for email'},
	EmailPassword   => {help => 'Email password for POP and SMTP'},
	EmailSMTP       => {help => 'SMTP server for email'},
	EscapeChar      => {help => 'Enable character to use'},
	EscapeEnabled   => {help => 'Enable cmd escapes'},
	GuestPassword   => {help => 'Password for GUEST sessions'},
	LoopTest        => {help => 'Skip data in-out to loop'},
	MsnDebug        => {help => 'Enabled debug of MSN protocol'},
	MsnEnabled      => {help => 'Enable MSN account'},
	MsnListen       => {help => 'Broadcast msgs from unauthenticated users'},
	MsnPassword     => {help => 'MSN account password'},
	MsnUsername     => {help => 'MSN account username'},
	HMNetName       => {help => 'HMNet Sation Name'},
	HMNetPass       => {help => 'HMNet Sation Password'},
	HMNetOwner      => {help => 'HMNet Owner'},
	HMNetEmail      => {help => 'HMNet Email'},
	HMNetEnabled    => {help => 'HMNet Enabled (HM Internet Directory)'},
	HMNetUrl        => {help => 'HMNet URL'},
	PollingTime     => {help => 'Update polling interval'},
	RemoteMode      => {help => 'Control from TTY'},
	RunInProtect    => {help => 'Protect from msgs overriding TTY input (secs)'},
	SerialSetserial => {help => 'Use setserial (linux) or setdiv (Win)'},
	StockPortfolio  => {help => 'Stock symbols separated by space'},
	SystemName      => {help => 'System name'},
	SystemPassword  => {help => 'System full auth level password'},
	SystemPrompt    => {help => 'System prompt'},
	TelnetEnabled   => {help => 'Listen for incoming Telnet (TCP)'},
	TelnetPort      => {help => 'TCP port to use for Telnet listening'},
	TelnetWelcome   => {help => 'Telnet Welcome Message'},
	TelnetNegotiate => {help => 'Negotiate Telnet echo'},
	'TTY.x.Name'          => {help => 'Station name for the TTY session'},
	'TTY.x.Code'          => {help => 'Which code set to use',                  command => \&session_set_eol},
	'TTY.x.BaudRate'      => {help => 'UART baud rate of serial port',          command => \&serial_init},
	'TTY.x.Divisor'       => {help => 'UART divisor of serial port',            command => \&serial_init},
	'TTY.x.Parity'        => {help => 'UART parity setting',                    command => \&serial_init},
	'TTY.x.Port'          => {help => 'Which serial port to use for TTY',       command => \&serial_init},
	'TTY.x.Address'       => {help => 'Address of serial port (WIN only)',      command => \&serial_init},
	'TTY.x.StopBits'      => {help => 'UART stop bits',                         command => \&serial_init},
	'TTY.x.DataBits'      => {help => 'UART word size bits',                    command => \&serial_init},
	'TTY.x.LoopSuppress'  => {help => 'Suppress the loop-out -> loop-in echo'},
	'TTY.x.Echo'          => {help => 'Echo input back to serial port loop-in -> loop-out'},
	'TTY.x.ExtraCR'       => {help => 'How many extra CR (non-ASCII) to add on new line',   command => \&session_set_eol},
	'TTY.x.ExtraLF'       => {help => 'How many extra LF (non-ASCII) to add on new line',   command => \&session_set_eol},
	'TTY.x.ExtraLTRS'     => {help => 'How many extra LTRS to add on new line',             command => \&session_set_eol},
	'TTY.x.TranslateCR'   => {help => 'Translate input CR to CRLF'},
	'TTY.x.TranslateLF'   => {help => 'Translate input LF to CRLF'},
	'TTY.x.UnshiftOnSpace'=> {help => 'Unshift on space'},
	WeatherNoaaForecastBase  => {help => 'Weather URL FTP base for NOAA forecast'},
	WeatherNoaaClimateBase   => {help => 'Weather URL FTP base for NOAA climate'},
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
	'ASCII'      => {label => "ASCII",                                    upshift => 0, order => 0}, 
	'ITA2'       => {label => "ITA2 (5-level)",                           upshift => 1, order => 1}, 
	'ITA2-S100A' => {label => "ITA2-S100A (5-level) for Siemens T100a",   upshift => 1, order => 2}, 
	'TTS-M20'    => {label => "TTS-M20 (6-level) for Teletype Model 20",  upshift => 0, order => 3},
	'USTTY'      => {label => "USTTY (5-level)",                          upshift => 1, order => 4},
	'USTTY-WX'   => {label => "USTTY-WX (5-level) for Weather Svc",       upshift => 1, order => 5}
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


# USTTY-WX
# LTRS is equal to USTTY
$CODES{'USTTY-WX'}->{'FROM-LTRS'} =  $CODES{'USTTY'}->{'FROM-LTRS'};

$CODES{'USTTY-WX'}->{'FROM-FIGS'} = {# NOTES: \xa = LF \xd = CR \x7 = BELL
	"\001" => "3", "\002" => "\xa", "\003" => chr(0x2191), "\004" => "-", "\005" => "\x7", "\006" => "8",
	"\007" => "7", "\010" => "\xd", "\011" => chr(0x2197), "\012" => "4", "\013" => chr(0x2199),   "\014" => chr(0x229C),
	"\015" => chr(0x2192), "\016" => chr(0x25CC),   "\017" => chr(0x2190), "\020" => "5", "\021" => '+',   "\022" => chr(0x2196),
	"\023" => "2", "\024" => chr(0x2193),   "\025" => "6", "\026" => "0", "\027" => "1",   "\030" => "9",
	"\031" => chr(0x2A01), "\032" => chr(0x2198),   "\034" => ".", "\035" => "/", "\036" => chr(0x229D)
};

# USTTY WX - WEATHER SYMBOLS mapped to UTF-8
# Name          = LETTER = Unicode
# ARROW N       = A      = 2191
# ARROW NE      = D      = 2197
# ARROW E       = F      = 2192
# ARROW SE      = G      = 2198
# ARROW S       = H      = 2193
# ARROW SW      = J      = 2199
# ARROW W       = K      = 2190
# ARROW NW      = L      = 2196
# CLEAR     ( ) = C      = 25CC
# SCATTERED (|) = V      = 229D
# BROKEN    (=) = N      = 229C
# OVERCAST  (+) = B      = 2A01 / 2295
# PLUS       +  = Z      = 2B
# MINUS      -  = Blank  = 2D


# Notes about Unicode
# BELL SYMBOL 0x237E



# Generate the reverse: ASCII -> BAUDOT
$CODES{'USTTY'}->{'TO-LTRS'}      = {reverse %{$CODES{'USTTY'}->{'FROM-LTRS'}}};
$CODES{'USTTY'}->{'TO-FIGS'}      = {reverse %{$CODES{'USTTY'}->{'FROM-FIGS'}}};

$CODES{'ITA2'}->{'TO-LTRS'}       = {reverse %{$CODES{'ITA2'}->{'FROM-LTRS'}}};
$CODES{'ITA2'}->{'TO-FIGS'}       = {reverse %{$CODES{'ITA2'}->{'FROM-FIGS'}}};

$CODES{'TTS-M20'}->{'TO-LTRS'}    = {reverse %{$CODES{'TTS-M20'}->{'FROM-LTRS'}}};
$CODES{'TTS-M20'}->{'TO-FIGS'}    = {reverse %{$CODES{'TTS-M20'}->{'FROM-FIGS'}}};

$CODES{'ITA2-S100A'}->{'TO-LTRS'} = {reverse %{$CODES{'ITA2-S100A'}->{'FROM-LTRS'}}};
$CODES{'ITA2-S100A'}->{'TO-FIGS'} = {reverse %{$CODES{'ITA2-S100A'}->{'FROM-FIGS'}}};

$CODES{'USTTY-WX'}->{'TO-LTRS'} = {reverse %{$CODES{'USTTY-WX'}->{'FROM-LTRS'}}};
$CODES{'USTTY-WX'}->{'TO-FIGS'} = {reverse %{$CODES{'USTTY-WX'}->{'FROM-FIGS'}}};

#-----------------------------------------------------------------------------
# RTTY Art files from RTTY.COM's Royer Art Pavilion
#-----------------------------------------------------------------------------

my %aArtOptions = art_init();

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

my @aWeatherStates = qw(AK AL AR AZ BC CA CO CT DE FL GA HI HN IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA PR RI SC SD TN TX UT VA VI VT WA WI WV WY);

#-----------------------------------------------------------------------------
# Main program begins here (Not really, but I like to think of it that way...)
#-----------------------------------------------------------------------------

{
	# Handler for CTRL-C
	$SIG{'INT'} = 'main_exit';

	# Set the defaults for the configs
	foreach my $sKey (keys %Configs){
		if (defined $aConfigDefinitions{$sKey}){
			$aConfigDefinitions{$sKey}->{default} = $Configs{$sKey};
		}
		$ConfigsDefault{$sKey} = $Configs{$sKey};
	}
	
	# See if another non default cfg file was provided
	foreach my $sCmdline (@ARGV){
		if ($sCmdline =~ /^--CONFIGSFILE=["']?(.+?\.cfg)\1?$/){
			if (0){/"/;} # This is here just to fix my idiot text editor highlighter (quotes problem)
			$sGlobalConfigsFile = $1;
			last;
		}
	}
	
	# Load configs from cfg file
	if (-e $sGlobalConfigsFile) {
		load_batch_file($sGlobalConfigsFile);
	}
	
	# Process Command line options
	process_cmdline();

	# This simply cannot be empty
	if (!$Configs{TelnetWelcome}){
		$Configs{TelnetWelcome} = $ConfigsDefault{TelnetWelcome};
	}

	logDebug("Heavy Metal initializing - ".get_datetime()." - please wait\n");
	
	# Enabled ConsoleOnly mode
	if ($Configs{ConsoleOnly}){
		logDebug("Initialization will be in ConsoleOnly mode (No GUI)\n");
		$bTkEnabled = 0;
	}
	
	# Load modules dynamically
	# Find the last one
	foreach my $sKey (keys(%Modules)){ 
		if (exists($Modules{$sKey}->{order})){
			if ($Modules{$sKey}->{order} > $nMax){
				$nMax = $Modules{$sKey}->{order};
			}
		}
	}
	# Load one by one
	for ($nCount = 0; $nCount <= $nMax; $nCount++){
		foreach my $sKey (keys(%Modules)){
			if (exists($Modules{$sKey}->{order}) && ($Modules{$sKey}->{order} == $nCount)){
				my $bLoad = 1;
				# Check if it must be disabled for ConsoleOnly mode
				if (!$bTkEnabled && ($sKey =~ /^Tk/)){
					$bLoad = 0;
				}
				# Check OS to determine if it should be loaded
				elsif (exists($Modules{$sKey}->{'os'}) && $Modules{$sKey}->{'os'} ne ''){
					$bLoad = ($sOS =~ /$Modules{$sKey}->{'os'}/ix);
				}

				if ($bLoad){
					logDebug (sprintf("Loading Module %25s ", $sKey));
					my $sModule = exists($Modules{$sKey}->{'args'}) ? $sKey : $sKey.' '.$Modules{$sKey}->{'args'};
					eval("use $sModule");
					if ($@){
						my  $sFilePM = $sKey;
						$sFilePM =~ s/\:\:/\//g;
						
						if (exists($Modules{$sKey}->{'required'}) && $Modules{$sKey}->{'required'}){
							logDebug("FATAL ERROR\n-----------------------------------------------------------\n".$@."\n-----------------------------------------------------------\nSorry, the required package $sKey is missing.\nCheck the readme.txt and try to install it with ppm.\nGoodbye!\n\n");
							exit;
						}
						else{
							if ($@ =~ /^Can\'t locate $sFilePM.pm in /){
								logDebug("ERROR (OPTIONAL)\n");
							}
							else{
								logDebug("ERROR (OPTIONAL)\n-----------------------------------------------------------\n".$@."\n-----------------------------------------------------------\n");
							}
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
		$Configs{SerialSetserial} = 1;
	}

	# This determines how HM will split lines when doing AP news summary
	$Text::Wrap::columns = $Configs{Columns};

	initialize_buffers();
	
	UI_updateStatus();
	
	if (-e 'tmp/noaa-ftp.json'){
		if (open(my $FH, '<', 'tmp/noaa-ftp.json')) {
			$Global{'NoaaFtpTree'} = decode_json(join("",<$FH>));
			close($FH);
		}
	}

	
	if ($bTkEnabled){
		Tkx::set("perl_bgerror", \&main_tk_error);
		Tkx::eval('proc bgerror {msg} {'."\n".'global perl_bgerror'."\n".'$perl_bgerror $msg'."\n".'}');
		
		initialize_windows();
		
		UI_updateStatus();
		
		message_deliver('SYS', 0, '', 1);
	}
	else{
		# Lets mark it as disconnected
		$aSessions[0]->{status} = 0;
	}
	
	if ($Configs{TelnetEnabled}){
		telnet_init();
	}
	
	if ($Configs{MsnEnabled}){
		msn_init();
	}
	
	logDebug("\nHeavy Metal initialization complete, ".get_datetime().$lf);
	
	main_loop();
	
	
	
	if ($bTkEnabled){
		Tkx::MainLoop();
	}
	else{
		while (!$bExitMainLoop){
			main_loop();
			Time::HiRes::usleep($polltime);
		}
	}

	# Closing everything
	foreach my $thisSession (@aSessions){
		if ($thisSession->{type} eq 'TTY' && $thisSession->{status}){
			serial_close($thisSession->{id});
		}
	}
	
	if ($rDebugHandle){
		close($rDebugHandle);
		$rDebugHandle = undef;
	}
	
	exit;

}

#-----------------------------------------------------------------------------
# Subroutine definitions
#-----------------------------------------------------------------------------

sub session_set_eol {
	my ($idSession) = @_;
	if ($Configs{"TTY.$idSession.Code"} eq 'ASCII'){
		$aSessions[$idSession]->{eol} = $EOL;
	}
	else{
		$aSessions[$idSession]->{eol} = $b_cr . $b_cr x $Configs{"TTY.$idSession.ExtraCR"} . $b_lf. $b_lf x $Configs{"TTY.$idSession.ExtraLR"} . $ltrs. $ltrs x $Configs{"TTY.$idSession.ExtraLTRS"};
	}
}

sub config_set {
	my ($sKey, $sVal, $bDoNotUpdateGUI, $bDoNotExecuteCmd) = @_;
	
	$Configs{$sKey} = $sVal;
	

	if ($sKey =~ /^TTY\.(\d+)\.(\w+)$/){
		my $idSession = int($1);
		my $sConfig   = $2;
	
		my $thisSession = $aSessions[$idSession];

		if ($thisSession->{type} eq 'TTY'){
			if ($sConfig eq 'Name'){
				$thisSession->{user} = $sVal;
			}
			elsif ($sConfig eq 'Port'){
				$thisSession->{address} = $sVal;
			}
			elsif ($sConfig eq 'LoopSuppress' && $sVal && $Configs{"TTY.$idSession.Echo"}){
				config_set("TTY.$idSession.Echo", 0);
			}
			elsif ($sConfig eq 'Echo'){
				$thisSession->{echo_input} = int($sVal);
	 			if ($sVal && $Configs{"TTY.$idSession.LoopSuppress"}){
					config_set("TTY.$idSession.LoopSuppress", 0);
				}
			}
			elsif ($sConfig eq 'TranslateLF' && $sVal && $Configs{"TTY.$idSession.TranslateCR"}){
				config_set("TTY.$idSession.TranslateCR", 0);
			}
			elsif ($sConfig eq 'TranslateCR' && $sVal && $Configs{"TTY.$idSession.TranslateLF"}){
				config_set("TTY.$idSession.TranslateLF", 0);
			}
			elsif (exists($thisSession->{lc($sConfig)}) && lc($sConfig) ne 'type' && lc($sConfig) ne 'id' && lc($sConfig) ne 'address'){
				$thisSession->{lc($sConfig)} = $sVal;
			}
		}

	}
	
	# here we can call handlers at the UI to reflect the change (i.e. to solve Combobox synch problem)
	
	if ($bTkEnabled){
		if (!$bDoNotUpdateGUI){
			UI_updateControl($sKey, $sVal);
		}
	}
	
	if (!$bDoNotExecuteCmd){
		my $sKeyGeneric = $sKey;
		$sKeyGeneric =~ s/^TTY\.(\d+)\./TTY.x./;
		if (exists($aConfigDefinitions{$sKeyGeneric}) && exists($aConfigDefinitions{$sKeyGeneric}->{command})){
			
			if ($Configs{Debug} > 2) { logDebug("config_set($sKey) cmd\n");}
			if ($1){
				&{$aConfigDefinitions{$sKeyGeneric}->{command}}($1);
			}
			else{
				&{$aConfigDefinitions{$sKeyGeneric}->{command}}();
			}
		}
	}
}

sub initialize_buffers{

	my $idSession;
	
	$idSession = 0;

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
		'label'       => 1,
		'COMMANDS'    => [],
		'command_num' => -1,
		'VARS'        => {}
	};
	if ($Configs{Debug}){ logDebug("\nNew session for HOST: $idSession\n");}
	
	if ($aSessions[$idSession]->{prompt}){
		#$aSessions[$idSession]->{OUT} = $Configs{SystemPrompt};
	}
	
	session_new_tty(1);
	session_new_tty(2);
#	my $idTTY = 1;
#	while (exists $Configs{"TTY.$idTTY.Port"}){
#		session_new_tty($idTTY);
#		$idTTY++;
#	}
	
}




sub session_new_tty{
	my ($idTTY) = @_;
	my $idSession;
	
	if (!defined $Configs{"TTY.$idTTY.Name"}          ){ $Configs{"TTY.$idTTY.Name"}          = "";        }
	if (!defined $Configs{"TTY.$idTTY.Port"}          ){ $Configs{"TTY.$idTTY.Port"}          = "OFF";     }
	if (!defined $Configs{"TTY.$idTTY.LoopSuppress"}  ){ $Configs{"TTY.$idTTY.LoopSuppress"}  = 0;         }
	if (!defined $Configs{"TTY.$idTTY.Code"}          ){ $Configs{"TTY.$idTTY.Code"}          = 'ASCII';   }
	if (!defined $Configs{"TTY.$idTTY.BaudRate"}      ){ $Configs{"TTY.$idTTY.BaudRate"}      = 'BAUD1200';}
	if (!defined $Configs{"TTY.$idTTY.Address"}       ){ $Configs{"TTY.$idTTY.Address"}       = 0;         }
	if (!defined $Configs{"TTY.$idTTY.DataBits"}      ){ $Configs{"TTY.$idTTY.DataBits"}      = 8;         }
	if (!defined $Configs{"TTY.$idTTY.Parity"}        ){ $Configs{"TTY.$idTTY.Parity"}        = 'none';    }
	if (!defined $Configs{"TTY.$idTTY.StopBits"}      ){ $Configs{"TTY.$idTTY.StopBits"}      = 1;         }
	if (!defined $Configs{"TTY.$idTTY.Echo"}          ){ $Configs{"TTY.$idTTY.Echo"}          = 0;         }
	if (!defined $Configs{"TTY.$idTTY.ExtraCR"}       ){ $Configs{"TTY.$idTTY.ExtraCR"}       = 3;         }
	if (!defined $Configs{"TTY.$idTTY.ExtraLF"}       ){ $Configs{"TTY.$idTTY.ExtraLF"}       = 0;         }
	if (!defined $Configs{"TTY.$idTTY.TranslateCR"}   ){ $Configs{"TTY.$idTTY.TranslateCR"}   = 0;         }
	if (!defined $Configs{"TTY.$idTTY.TranslateLF"}   ){ $Configs{"TTY.$idTTY.TranslateLF"}   = 0;         }
	if (!defined $Configs{"TTY.$idTTY.UnshiftOnSpace"}){ $Configs{"TTY.$idTTY.UnshiftOnSpace"}= 0;         }
	if (!defined $Configs{"TTY.$idTTY.Label"}         ){ $Configs{"TTY.$idTTY.Label"}         = 1;         }
	if (!defined $Configs{"TTY.$idTTY.Prompt"}        ){ $Configs{"TTY.$idTTY.Prompt"}        = 1;         }
	if (!defined $Configs{"TTY.$idTTY.Source"}        ){ $Configs{"TTY.$idTTY.Source"}        = 'ALL';     }
	if (!defined $Configs{"TTY.$idTTY.Target"}        ){ $Configs{"TTY.$idTTY.Target"}        = 'ALL';     }
	if (!defined $Configs{"TTY.$idTTY.Direction"}     ){ $Configs{"TTY.$idTTY.Direction"}     = 0;         }
	if (!defined $Configs{"TTY.$idTTY.Auth"}          ){ $Configs{"TTY.$idTTY.Auth"}          = 3;         }
	if (!defined $Configs{"TTY.$idTTY.Columns"}       ){ $Configs{"TTY.$idTTY.Columns"}       = 68;        }
	if (!defined $Configs{"TTY.$idTTY.OverstrikeProtect"}){ $Configs{"TTY.$idTTY.OverstrikeProtect"} = 1;  }
	
	$idSession  = $idTTY;
	if ($idTTY >= $NewSessionId){
		$NewSessionId = $idTTY + 1;
	}

	$aSessions[$idSession] = {
		'type'        => 'TTY', 
		'IN'          => '', 
		'OUT'         => '',
		'RAW_IN'      => '', 
		'RAW_OUT'     => '',
		'id'          => $idSession, 
		'status'      => 1, 
		'direction'   => $Configs{"TTY.$idTTY.Direction"}, 
		'auth'        => $Configs{"TTY.$idTTY.Auth"}, 
		'user'        => $Configs{"TTY.$idTTY.Name"}, 
		'target'      => $Configs{"TTY.$idTTY.Target"}, 
		'source'      => $Configs{"TTY.$idTTY.Source"},
		'prompt'      => $Configs{"TTY.$idTTY.Prompt"},
		'disconnect'  => 0,
		'address'     => $Configs{"TTY.$idTTY.Port"},
		'input_type'  => '', 
		'input_var'   => '',
		'input_prompt'=> '',
		'echo_input'  => $Configs{"TTY.$idTTY.Echo"},
		'label'       => $Configs{"TTY.$idTTY.Label"},
		'eol'         => $EOL,
		'echo_msg'    => 0, 
		'clean_line'  => 0,
		'raw_mode'    => 0,
		'column'      => 0,      # Keep track of the current column at the TTY
		'rx_last'     => 0,      # Keeps the time of the last receptions from the TTY
		'rx_count'    => 0,
		'rx_shift'    => $ltrs,
		'tx_shift'    => $ltrs,
		'runin_count' => 0,
		'lowercase_lock' => 0,
		'time_start'  => time(),
		'VARS'        => {}
	};
	if ($Configs{Debug}){ logDebug("\nNew session for TTY: $idSession\n");}
	
	serial_init($idSession);
	session_set_eol($idSession);
	
	return $idSession;
}


sub session_new_telnet{
	my ($rOptions) = @_;
	
	$nSessionsCount++;
	
	my $idSession = $NewSessionId++;
	
	$aSessions[$idSession] = {
		'id'          => $idSession, 
		'type'        => 'TELNET', 
		'IN'          => '', 
		'OUT'         => '',
		'VARS'        => {},
		'status'      => 1, 
		'direction'   => 0, 
		'auth'        => 0, 
		'user'        => '', 
		'target'      => 'ALL', 
		'source'      => 'ALL',
		'prompt'      => 0,
		'disconnect'  => 0,
		'address'     => '',
		'input_type'  => '', 
		'input_var'   => '',
		'input_prompt'=> '',
		'echo_input'  => 1,
		'label'       => 0,
		'echo_msg'    => 0, 
		'clean_line'  => 0,
		'rx_last'     => 0,
		'rx_count'    => 0,
		'COMMANDS'    => [],
		'command_num' => -1,
		'remote_ip'   => '',
		'remote_port' => 0,
		'negotiate'   => $Configs{TelnetNegotiate},
		'time_start'  => time()
	};
	
	if ($rOptions){
		foreach my $sKey (keys %{$rOptions}){
			$aSessions[$idSession]->{$sKey} = $rOptions->{$sKey};
		}
	}
	
	if ($Configs{Debug}){ logDebug("\nNew session for TELNET: $idSession\n");}
	
	return $idSession;
}

sub initialize_menu {
		
	# MENU: Main
	$oTkMenues{Main} = $oTkMainWindow->new_menu();
	
	# MENU: File
	$oTkMenues{File} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "File", -menu => $oTkMenues{File}, -underline => 0);
	$oTkMenues{File}->add_command(-label => "Send ASCII file to TTY1",-command => \&UI_do_sendfile);
	#$oTkMenues{File}->add_command(-label => "Send RAW file to TTY",   -command => \&do_send);
	$oTkMenues{File}->add_command(-label => "Save buffer as ASCII",   -command => \&save_file);
	#$oTkMenues{File}->add_command(-label => "Save buffer raw",       -command => \&save_file_raw);
	$oTkMenues{File}->add_command(-label => "Exec host comand",       -command => \&do_host_command);
	$oTkMenues{File}->add_command(-label => "Save Configuration",     -command => \&do_saveconfig);
	#$oTkMenues{File}->add_command(-label => "X10 On",                -command => \&do_x10_on);
	#$oTkMenues{File}->add_command(-label => "X10 Off",               -command => \&do_x10_off);
	$oTkMenues{File}->add_command(-label => "Exit",                   -command => \&main_exit);
	#$oTkMenues{File}->add_command(-label => "Debug: Cause error",                   -command => sub { Tkx::foo(); }, -underline => 1);
	
	# MENU: Edit
	$oTkMenues{Edit} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Edit", -menu => $oTkMenues{Edit});
	$oTkMenues{Edit}->add_command(-label => "Copy",       -command => \&clipboard_copy);
	$oTkMenues{Edit}->add_command(-label => "Copy All",   -command => \&textarea_copy_all);
	$oTkMenues{Edit}->add_command(-label => "Paste",      -command => \&clipboard_paste);
	#$oTkMenues{Edit}->add_command(-label => "Select All", -command => \&textarea_select_all);
	$oTkMenues{Edit}->add_command(-label => "Clear All",  -command => \&textarea_clear_all);
	
	
	
	# MENU: Commands
	$oTkMenues{Commands} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Commands", -menu => $oTkMenues{Commands});
	$oTkMenues{Commands}->add_command(-label => "LIST sessions ($Configs{EscapeChar}LIST)",        -command => [\&host_add_text, "$Configs{EscapeChar}LIST\n"]);
	$oTkMenues{Commands}->add_command(-label => "CONFIGS list ($Configs{EscapeChar}CONFIGS)",      -command => [\&host_add_text, "$Configs{EscapeChar}CONFIGS\n"]);
	$oTkMenues{Commands}->add_command(-label => "UPTIME for system ($Configs{EscapeChar}UPTIME)",  -command => [\&host_add_text, "$Configs{EscapeChar}UPTIME\n"]);

	$oTkMenues{Commands}->add_separator();
	$oTkMenues{Commands}->add_command(-label => "Custom", -font =>"FontMenuGroup");
	$nCount = 0;
	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^CommandMenu\.\d+$/ && $Configs{$sKey} ne ''){
			$nCount++;
			$oTkMenues{Commands}->add_command(
				-label    => '    '.substr($Configs{$sKey}, 0, 35).(length($Configs{$sKey}) > 35 ? '...' : '')
				, -command  => [\&host_add_text, $Configs{$sKey}]);
			if ($nCount++ >= 15){
				last;
			}
		}
	}
	$oTkMenues{Commands}->add_command(-label=>'- Click here to change your favorites -', -font => 'FontMenuNote', -command => sub {$oTkControls{MainTabs}->select($oTkControls{TabFavorites});});

	
	# MENU: Internet
	$oTkMenues{Internet} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Internet", -menu => $oTkMenues{Internet});

	# MENU: Internet / Telnet server
	$oTkMenues{Internet}->add_command(-label => "Telnet", -font =>"FontMenuGroup");
	$oTkMenues{Internet}->add_checkbutton(-label => "    Enable local Telnet server", -variable => \$Configs{TelnetEnabled}, -command => \&telnet_toggle);
	# MENU: Internet / Telnet client
	$oTkMenues{Internet}->add_command(-label    => "    Connect to external TCP port", -command  => [\&host_add_text, "$Configs{EscapeChar}TELNET\n"]);
	
	$oTkMenues{TelnetHosts} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Internet}->add_cascade(-label => "    Telnet connect to",	-menu => $oTkMenues{TelnetHosts});
	my $nCount = 0;
	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^TelnetHost\.\d+$/ && $Configs{$sKey} ne ''){
			$nCount++;
			$oTkMenues{TelnetHosts}->add_command(-label => $Configs{$sKey}, -command => [\&host_add_text, "$Configs{EscapeChar}TELNET $Configs{$sKey}\n"]);
		}
	}
	$oTkMenues{TelnetHosts}->add_command(-label=>'- Click here to change your favorites -', -font => 'FontMenuNote', -command => sub {$oTkControls{MainTabs}->select($oTkControls{TabFavorites});});
	

	$oTkMenues{Internet}->add_separator();
	# MENU: Internet / HMNET
	
	
	$oTkMenues{Internet}->add_command(-label => "HM Net", -font =>"FontMenuGroup");
	$oTkMenues{Internet}->add_command(-label => "    Register",      -command  => [\&host_add_text, "$Configs{EscapeChar}HMNET ON\n"]);
	$oTkMenues{Internet}->add_command(-label => "    Unregister",    -command  => [\&host_add_text, "$Configs{EscapeChar}HMNET OFF\n"]);
	$oTkMenues{Internet}->add_command(-label => "    Show configs",  -command  => [\&host_add_text, "$Configs{EscapeChar}HMNET CONFIGS\n"]);
	$oTkMenues{Internet}->add_command(-label => "    List stations", -command  => [\&host_add_text, "$Configs{EscapeChar}HMNET LIST\n"]);

	# Internet - Email
	$oTkMenues{Internet}->add_separator();
	$oTkMenues{Internet}->add_command(-label => "eMail", -font =>"FontMenuGroup");
	$oTkMenues{Internet}->add_command(-label => "    Send email",                -command => [\&host_add_text, "$Configs{EscapeChar}SENDMAIL"]);
	$oTkMenues{Internet}->add_command(-label => "    Check email headers",       -command => [\&host_add_text, "$Configs{EscapeChar}CHECKMAIL HEADERS"]);
	$oTkMenues{Internet}->add_command(-label => "    Read all email",            -command => [\&host_add_text, "$Configs{EscapeChar}CHECKMAIL ALL"]);
	$oTkMenues{Internet}->add_command(-label => "    Read GreenKeys list email", -command => [\&host_add_text, "$Configs{EscapeChar}CHECKMAIL GREENKEYS"]);

	
	# Internet - MSN
	$oTkMenues{Internet}->add_separator;
	$oTkMenues{Internet}->add_command(-label => "MSN Messenger", -font =>"FontMenuGroup");
	$oTkMenues{Internet}->add_command(-label => "    Enable",        -command  => [\&host_add_text, "$Configs{EscapeChar}MSN ON\n"]);
	$oTkMenues{Internet}->add_command(-label => "    Disable",       -command  => [\&host_add_text, "$Configs{EscapeChar}MSN OFF\n"]);
	$oTkMenues{Internet}->add_command(-label => "    List contacts", -command  => [\&host_add_text, "$Configs{EscapeChar}MSN LIST\n"]);

	
	# Internet - TWITTER
	$oTkMenues{Internet}->add_separator;
	$oTkMenues{Internet}->add_command(-label => "Twitter", -font =>"FontMenuGroup", -command  => [\&host_add_text, "$Configs{EscapeChar}TWITTER\n"]);

	$oTkMenues{TwitterAccounts} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Internet}->add_cascade(-label => "    Check twits for",	-menu => $oTkMenues{TwitterAccounts});
	my $nCount = 0;
	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^Twitter.Menu\.\d+$/ && $Configs{$sKey} ne ''){
			$nCount++;
			$oTkMenues{TwitterAccounts}->add_command(-label => $Configs{$sKey}, -command => [\&host_add_text, "$Configs{EscapeChar}TWITTER $Configs{$sKey}\n"]);
		}
	}
	$oTkMenues{TwitterAccounts}->add_command(-label=>'- Click here to change your favorites -', -font => 'FontMenuNote', -command => sub {$oTkControls{MainTabs}->select($oTkControls{TabFavorites});});
	
	
	# Internet - HTTP/FTP
	$oTkMenues{Internet}->add_separator();
	$oTkMenues{Internet}->add_command(-label => "Fetch file (FTP/HTTP)", -command => [\&host_add_text, "$Configs{EscapeChar}URL\n"]);
	
	
	
	# MENU: Newswire
	$oTkMenues{News} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Newswire", -menu => $oTkMenues{News});
	
	# Newswire - AP newswires
	#$oTkMenues{News}->add_command(-label => "AP Top Stories",        -command => [\&host_add_text, "$Configs{EscapeChar}TOPNEWS\n"]);
	#$oTkMenues{News}->add_command(-label => "AP Today in History",   -command => [\&host_add_text, "$Configs{EscapeChar}HISTORY\n"]);
	$oTkMenues{News}->add_command(-label => "Historical Records",     -command => [\&host_add_text, "$Configs{EscapeChar}NEWS SUMMARY HISTORY\n"]);
	# Newswire - Stock quotes
	$oTkMenues{News}->add_separator();
	$oTkMenues{News}->add_command(-label => "Stock Quote",           -command => [\&host_add_text, "$Configs{EscapeChar}QUOTE\n"]);
	$oTkMenues{News}->add_command(-label => "Stock Portfolio",       -command => [\&host_add_text, "$Configs{EscapeChar}PORTFOLIO\n"]);
	$oTkMenues{News}->add_command(-label => "Full Stock quote",      -command => [\&host_add_text, "$Configs{EscapeChar}FULLQUOTE\n"]);

	$oTkMenues{News}->add_separator();
	$oTkMenues{News}->add_command(-label => "RSS News", -font =>"FontMenuGroup");
	my $nCount = 0;
	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^RSS\.Menu\.\d+$/){
			if ($Configs{$sKey} =~ /^((\S+)\s+)?(\S+)$/){
				my $sType = $2 ? $2 : 'SUMMARY';
				my $sFeed = $3;
				$oTkMenues{News}->add_command(-label => "    $sType $sFeed",   -command => [\&host_add_text, "$Configs{EscapeChar}NEWS $sType $sFeed\n"]);
				if ($nCount++ >= 20){
					last;
				}
				
			}
		}
	}
	
	$oTkMenues{News}->add_command(-label=>'- Click here to change your favorites -', -font => 'FontMenuNote', -command => sub {$oTkControls{MainTabs}->select($oTkControls{TabFavorites});});



	# MENU: RTTY ART
	$oTkMenues{Art} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Art", -menu => $oTkMenues{Art});
	
	# Banner & Label
	$oTkMenues{Art}->add_command(-label => "Create Banner",           -command => [\&host_add_text, "$Configs{EscapeChar}BANNER\n"]);
	$oTkMenues{Art}->add_command(-label => "Create Tape Label",       -command => [\&host_add_text, "$Configs{EscapeChar}LABEL\n"]);
	
	for my $sArtCategory (keys %aArtOptions){
		$oTkMenues{Art}->add_separator();
		$oTkMenues{Art}->add_command(-label => $sArtCategory);
		
		foreach my $sSubLabel (sort(keys %{$aArtOptions{$sArtCategory}})) {
			if (ref(\$aArtOptions{$sArtCategory}->{$sSubLabel}) eq 'SCALAR'){
				my $sValue    = $aArtOptions{$sArtCategory}->{$sSubLabel};
				$oTkMenues{Art}->add_command(-label => $sSubLabel, -command  => [\&host_add_text, "$Configs{EscapeChar}ART $sValue\n"]);
			}
			else{
				# Submenu
				my $oTkMenuSub = $oTkMenues{Main}->new_menu();
				$oTkMenues{Art}->add_cascade(-label => $sSubLabel, -menu => $oTkMenuSub);
				
				foreach my $sKey (sort(keys %{$aArtOptions{$sArtCategory}->{$sSubLabel}})){
					my $sValue    = $aArtOptions{$sArtCategory}->{$sSubLabel}->{$sKey};
					$oTkMenuSub->add_command(-label => $sKey, -command  => [\&host_add_text, "$Configs{EscapeChar}ART $sValue\n"]);
				}
			}
		}
	}
	
	
	
	# MENU: Weather
	$oTkMenues{Weather} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Weather", -menu => $oTkMenues{Weather});
	
	$oTkMenues{Weather_NOAA_forecast_US} = $oTkMenues{Weather}->new_menu();
	$oTkMenues{Weather}->add_cascade(-label =>'US Cities forecast from NOAA FTP', -menu => $oTkMenues{Weather_NOAA_forecast_US});

	$oTkMenues{Weather_NOAA_climate_US} = $oTkMenues{Weather}->new_menu();
	$oTkMenues{Weather}->add_cascade(-label =>'US Cities climate from NOAA FTP', -menu => $oTkMenues{Weather_NOAA_climate_US});

	
	my $nCount = 0;
	foreach my $sSubLabel (sort @aWeatherStates) {
		$nCount++;
		my $nColumnBreak = ($bWindows && ($nCount % 20) == 0) ? 1 : 0;

		my $sMenuLevel = "Weather_NOAA_forecast_US_$sSubLabel";
		$oTkMenues{$sMenuLevel} = $oTkMenues{Weather_NOAA_forecast_US}->new_menu();
		$oTkMenues{Weather_NOAA_forecast_US}->add_cascade(-label => $sSubLabel, -menu => $oTkMenues{$sMenuLevel}, -columnbreak =>  $nColumnBreak);
		
		# Load from cache
		my $rCities = $Global{'NoaaFtpTree'}->{forecast} ? $Global{'NoaaFtpTree'}->{forecast}->{$sSubLabel} : undef;
		if ($rCities){
			foreach my $sCity (@$rCities){
				$oTkMenues{$sMenuLevel}->add_command(-label => $sCity, -command  => [\&host_add_text, "$Configs{EscapeChar}WEATHER NOAA $sSubLabel $sCity\n"]);
			}
			$oTkMenues{$sMenuLevel}->add_command(-label => "- Click to reload cities from NOAA FTP -", -command  => [\&UI_weather_FTP_init, $sMenuLevel, 'forecast', $sSubLabel]);
		}
		else{
			$oTkMenues{$sMenuLevel}->add_command(-label => "- Click to load cities from NOAA FTP -", -command  => [\&UI_weather_FTP_init, $sMenuLevel, 'forecast', $sSubLabel]);
		}


		my $sMenuLevel = "Weather_NOAA_climate_US_$sSubLabel";
		$oTkMenues{$sMenuLevel} = $oTkMenues{Weather_NOAA_climate_US}->new_menu();
		$oTkMenues{Weather_NOAA_climate_US}->add_cascade(-label => $sSubLabel, -menu => $oTkMenues{$sMenuLevel}, -columnbreak =>  $nColumnBreak);
		
		# Load from cache
		my $rCities = $Global{'NoaaFtpTree'}->{climate} ? $Global{'NoaaFtpTree'}->{climate}->{$sSubLabel} : undef;
		if ($rCities){
			foreach my $sCity (@$rCities){
				$oTkMenues{$sMenuLevel}->add_command(-label => $sCity, -command  => [\&host_add_text, "$Configs{EscapeChar}WEATHER NOAA CLIMATE $sSubLabel $sCity\n"]);
			}
			$oTkMenues{$sMenuLevel}->add_command(-label => "- Click to reload cities from NOAA FTP -", -font => 'FontMenuNote', -command  => [\&UI_weather_FTP_init, $sMenuLevel, 'climate', $sSubLabel]);
		}
		else{
			$oTkMenues{$sMenuLevel}->add_command(-label => "- Click to load cities from NOAA FTP -", -font => 'FontMenuNote', -command  => [\&UI_weather_FTP_init, $sMenuLevel, 'climate' , $sSubLabel]);
		}

	}
	
	$oTkMenues{Weather}->add_separator();
	
	# Here we add quick favorite cities
	$oTkMenues{Weather}->add_command(-label=>'- Favorite Sources/Cities -');
	$nCount = 0;
	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^WeatherFavorite\.\d+$/ && $Configs{$sKey} ne ''){
			$oTkMenues{Weather}->add_command(
				-label => substr($Configs{$sKey}, 0, 35).(length($Configs{$sKey}) > 35 ? '...' : ''),
				-command  => [ \&host_add_text, "$Configs{EscapeChar}WEATHER $Configs{$sKey}\n"]);
			if ($nCount++ >= 20){
				last;
			}

		}
	}
	$oTkMenues{Weather}->add_command(-label=>'- Click here to change your favorites -', -font => 'FontMenuNote', -command => sub {$oTkControls{MainTabs}->select($oTkControls{TabFavorites});});




	
	
	# MENU: Tests
	$oTkMenues{Tests} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Tests", -menu => $oTkMenues{Tests});
	$oTkMenues{Tests}->add_command(-label => "Quick brown fox",       -command => [\&host_add_text, "$Configs{EscapeChar}QBF\n"]);
	$oTkMenues{Tests}->add_command(-label => "RYRY",                  -command => [\&host_add_text, "$Configs{EscapeChar}RYRY 10\n"]);
	$oTkMenues{Tests}->add_command(-label => "RRRR",                  -command => [\&host_add_text, "$Configs{EscapeChar}RRRR 10\n"]);
	$oTkMenues{Tests}->add_command(-label => "Raw 5-bit codes",       -command => [\&host_add_text, "$Configs{EscapeChar}RAW5BIT\n"]);
	$oTkMenues{Tests}->add_command(-label => "Raw 6-bit codes",       -command => [\&host_add_text, "$Configs{EscapeChar}RAW6BIT\n"]);
	
	# MENU: Cancel
	$oTkMenues{Cancel} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Cancel", -menu => $oTkMenues{Cancel});
	$oTkMenues{Cancel}->add_command(-label => "Cancel I/O & action in Host", -command => [\&do_abort, 0, 0, 1]);
	$oTkMenues{Cancel}->add_command(-label => "Cancel I/O & action in TTYs", -command => [\&do_abort, 0, 'TTY']);
	$oTkMenues{Cancel}->add_command(-label => "Cancel I/O & action in ALL",  -command => [\&do_abort, 0, 'ALL']);
	
	# MENU: Help
	$oTkMenues{Help} = $oTkMenues{Main}->new_menu();
	$oTkMenues{Main}->add_cascade(-label => "Help", -menu => $oTkMenues{Help});
	$oTkMenues{Help}->add_command(-label => "About HeavyMetal",       -command => \&do_about);
	$oTkMenues{Help}->add_command(-label => "Usage",                  -command => [\&host_add_text, "$Configs{EscapeChar}HELP\n"]);
	$oTkMenues{Help}->add_command(-label => "Check latest version",   -command => [\&host_add_text, "$Configs{EscapeChar}VERSION CHECK\n"]);
	$oTkMenues{Help}->add_command(-label => "Autoupdate this version",-command => [\&host_add_text, "$Configs{EscapeChar}VERSION CHECK UPDATE\n"]);
	
	$oTkMainWindow->configure(-menu => $oTkMenues{Main});
	
}

sub initialize_windows {
	
	print "Initialize window\n";
	
	Tkx::option_add("*tearOff", 0);
	
	$oTkMainWindow = Tkx::widget->new(".");
	$oTkMainWindow->g_wm_title("Heavy Metal TTY Program, v$sGlobalVersion");
	$oTkMainWindow->g_wm_minsize(600, 350);
	
	Tkx::font_create("FontMenuGroup", -family => "TkMenuFont",    -size => 9, -weight => "bold");
	Tkx::font_create("FontMenuNote",  -family => "TkMenuFont",    -size => 8, -slant => "italic");
	Tkx::font_create("FontSmallNote", -family => "TkDefaultFont", -size => 8, -slant => "italic");

	$Global{Images}->{'heavymetal'} = '';
	$Global{Images}->{'tty-on'}      = '';
	$Global{Images}->{'tty-off'}     = '';
	$Global{Images}->{'telnet-on'}   = '';
	$Global{Images}->{'telnet-off'}  = '';
	$Global{Images}->{'msn-on'}      = '';
	$Global{Images}->{'msn-off'}     = '';

	foreach my $sImg (keys %{$Global{Images}}){
		if (-e "icons/icon-$sImg.gif"){
			Tkx::image_create_photo($sImg, -file => "icons/icon-$sImg.gif");
			$Global{Images}->{$sImg} = $sImg;
		}
	}
	
	if ($bWindows){
		if (-e 'icons/heavymetal.ico'){
			Tkx::wm_iconbitmap($oTkMainWindow, -default => 'icons/heavymetal.ico');
		}
	}
	elsif($Global{Images}->{'heavymetal'}){
		Tkx::wm_iconphoto($oTkMainWindow, -default => 'heavymetal');
	}
	
	
	initialize_menu();
	
	initialize_statusbar($oTkMainWindow);

	
	$oTkControls{'MainTabs'}    = $oTkMainWindow->new_ttk__notebook();
	$oTkControls{'TabHost'}     = $oTkControls{'MainTabs'}->new_ttk__frame();
	#$oTkControls{'TabSessions'} = $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 2);
	$oTkControls{'TabConfigs'}  = $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 5);
	$oTkControls{'TabPorts'}    = $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 5);
	$oTkControls{'TabFavorites'}= $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 5);
	$oTkControls{'TabNews'}     = $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 2);
	$oTkControls{'TabCron'}     = $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 5);
	$oTkControls{'TabCommands'} = $oTkControls{'MainTabs'}->new_ttk__frame(-padding => 5);
	
	$oTkControls{'MainTabs'}->add($oTkControls{'TabHost'},     -text => "HOST");
	#$oTkControls{'MainTabs'}->add($oTkControls{'TabSessions'}, -text => "Sessions");
	$oTkControls{'MainTabs'}->add($oTkControls{'TabConfigs'},  -text => "Configs");
	$oTkControls{'MainTabs'}->add($oTkControls{'TabPorts'},    -text => "Serial Ports");
	$oTkControls{'MainTabs'}->add($oTkControls{'TabNews'},     -text => "RSS News");
	$oTkControls{'MainTabs'}->add($oTkControls{'TabFavorites'},-text => "Favorites");
	$oTkControls{'MainTabs'}->add($oTkControls{'TabCron'},     -text => "Cron");
	$oTkControls{'MainTabs'}->add($oTkControls{'TabCommands'}, -text => "Custom Commands");
	$oTkControls{'MainTabs'}->g_pack(-side=>'top',-fill=>'both');

	initialize_tab_host($oTkControls{'TabHost'});
	initialize_tab_configs($oTkControls{'TabConfigs'});
	initialize_tab_ports($oTkControls{'TabPorts'});
	initialize_tab_favorites($oTkControls{'TabFavorites'});
	initialize_tab_commands($oTkControls{'TabCommands'});
	initialize_tab_cron($oTkControls{'TabCron'});
	initialize_tab_news($oTkControls{'TabNews'});
	#initialize_tab_sessions($oTkControls{'TabSessions'});
	
	
	$bTkInitialized = 1;
	
	# Set all values as some of these may need explicit setting (i.e. combos)
	foreach my $sKey (keys %Configs){
		UI_updateControl($sKey);
	}
}


sub initialize_statusbar{
	my ($tkFrame) = @_;
	
	$oTkControls{FrameStatus} = $tkFrame->new_ttk__frame(-padding => '0 0 3 0');
	$oTkControls{FrameStatus}->g_pack(-side=>'bottom',-fill=>'x');
	
	my $idSession;
	
	# TTY 1
	$idSession = 1;
	if ($Global{Images}->{'tty-on'} && $Global{Images}->{'tty-off'}){
		$oTkControls{"SessionIcon-$idSession"}  = $oTkControls{FrameStatus}->new_label(-height => 32, -width => 32, -padx => 0, -image => $Global{Images}->{'tty-off'}, -compound => 'center', -text => $idSession);
		$oTkControls{"SessionIcon-$idSession"}->g_pack(-side=>'left');
	}
	$oTkControls{"SessionLabel-$idSession"} = $oTkControls{FrameStatus}->new_label(-textvariable => \$aStatusLabels{"TTY$idSession"} ,  -justify => 'left', -padx => 0, -width => 10, -height => 3, -anchor => 'w');
	$oTkControls{"SessionLabel-$idSession"}->g_pack(-side=>'left');

	# TTY 2
	$idSession = 2;
	if ($Global{Images}->{'tty-on'} && $Global{Images}->{'tty-off'}){
		$oTkControls{"SessionIcon-$idSession"}  = $oTkControls{FrameStatus}->new_label(-height => 32, -width => 32, -padx => 0, -image => $Global{Images}->{'tty-off'}, -compound => 'center', -text => $idSession);
		$oTkControls{"SessionIcon-$idSession"}->g_pack(-side=>'left');
	}
	$oTkControls{"SessionLabel-$idSession"} = $oTkControls{FrameStatus}->new_label(-textvariable => \$aStatusLabels{"TTY$idSession"} ,  -justify => 'left', -padx => 0, -width => 10, -height => 3, -anchor => 'w');
	$oTkControls{"SessionLabel-$idSession"}->g_pack(-side=>'left');
	
	# TELNET
	if ($Global{Images}->{'telnet-on'} && $Global{Images}->{'telnet-off'}){
		$oTkControls{"TelnetIcon"}  = $oTkControls{FrameStatus}->new_label(-height => 32, -width => 32, -padx => 0, -image => $Global{Images}->{'telnet-off'});
		$oTkControls{"TelnetIcon"}->g_pack(-side=>'left');
	}
	$oTkControls{"TelnetLabel"} = $oTkControls{FrameStatus}->new_label(-textvariable => \$aStatusLabels{Telnet} ,  -justify => 'left', -padx => 0, -width => 10, -height => 3, -anchor => 'nw');
	$oTkControls{"TelnetLabel"}->g_pack(-side=>'left');
	
	# MSN
	if ($Global{Images}->{'msn-on'} && $Global{Images}->{'msn-off'}){
		$oTkControls{"MsnIcon"}  = $oTkControls{FrameStatus}->new_label(-height => 32, -width => 32, -padx => 0, -image => $Global{Images}->{'msn-off'});
		$oTkControls{"MsnIcon"}->g_pack(-side=>'left');
	}
	$oTkControls{"MsnLabel"} = $oTkControls{FrameStatus}->new_label(-textvariable => \$aStatusLabels{MSN} ,  -justify => 'left', -padx => 0, -width => 10, -height => 3, -anchor => 'nw');
	$oTkControls{"MsnLabel"}->g_pack(-side=>'left');
	
	# PROGRESSBAR
	$oTkControls{"StatusProgress"} = $oTkControls{FrameStatus}->new_ttk__progressbar(-orient => 'vertical', -mode => 'determinate', -length => 30);
	$oTkControls{"StatusProgress"}->g_pack(-side=>'right',-fill=>'y');
	
	# STATUS
	$oTkStatus  = $oTkControls{FrameStatus}->new_label(-text=> " - Initialization -", -height => 3, -justify => 'center', -padx => 0);
	$oTkStatus->g_pack(-side=>'right',-fill=>'both', -expand => 1);
	
}

sub initialize_tab_host{
	my ($tkFrame) = @_;
	
 	# Frame for text entry
	my $oTkFrameInput = $tkFrame->new_ttk__frame();
	$oTkFrameInput->g_pack(-side => 'bottom', -fill => 'x');

	# Label, entry box & enter button
	$oTkFrameInput->new_label(-text=> "Enter text here=>")->g_pack(-side=>'left');

	
	$oTkControls{'MainInput'} = $oTkFrameInput->new_entry(-textvariable => \$sInputValue);
	$oTkControls{'MainInput'}->g_pack(-side=>'left',-anchor => 'w', -fill => 'x', -expand => 1);

	$oTkControls{'MainInput'}->g_bind('<Return>' => sub { $sInputValue .= $lf ; host_add_text();});
	$oTkControls{'MainInput'}->g_bind('<Key-Up>' => sub { 
		my $thisSession = $aSessions[0];
		
		$thisSession->{command_num}++;
		if ($thisSession->{command_num} >= scalar @{$thisSession->{COMMANDS}}){
			$thisSession->{command_num} = 0;
		}
		$sInputValue = $thisSession->{COMMANDS}->[$thisSession->{command_num}];
	});
	$oTkControls{'MainInput'}->g_bind('<Key-Down>' => sub { 
		my $thisSession = $aSessions[0];
		
		$thisSession->{command_num}--;
		if ($thisSession->{command_num} < 0){
			$thisSession->{command_num} = scalar @{$thisSession->{COMMANDS}} - 1;
		}
		$sInputValue = $thisSession->{COMMANDS}->[$thisSession->{command_num}];
	});
	$oTkControls{'MainInput'}->g_focus();

	$oTkFrameInput->new_button(-text => "Cancel",  -command => [\&do_abort, 0, 0, 1])->g_pack(-side => 'right');
	$oTkFrameInput->new_button(-text => "No <cr>", -command => \&host_add_text)->g_pack(-side => 'right');
	
	# Text display window
	if ($Modules{'Tkx::Scrolled'}->{loaded}){
		$oTkTextarea = $tkFrame->new_tkx_Scrolled('text', -width => $Configs{Columns}+4, -height => '24', -scrollbars=>'e', -state => "disabled");
	}
	else{
		$oTkTextarea = $tkFrame->new_text(-width => $Configs{Columns}+4, -height => '24', -state => "disabled");
	}
	$oTkTextarea->g_pack(-expand=>'yes',-fill=>'both');


	# Init insertion vars
	$sPrinthead = "1.0";

	# Add pseudo block cursor
	$oTkTextarea->tag_configure('tagCursor', -background => 'blue', -foreground => 'black');

	$oTkTextarea->tag_configure('tagSent',   -foreground => 'darkgreen');
	$oTkTextarea->tag_configure('tagAction', -foreground => 'red');
	$oTkTextarea->tag_raise('tagAction');

	$oTkTextarea->configure(-state => "normal");
	$oTkTextarea->insert($sPrinthead, " ", 'tagCursor');
	$oTkTextarea->configure(-state => "disabled");
}

sub initialize_tab_favorites{
	my ($tkFrame) = @_;
	
	UI_addControlsFamily($tkFrame, 'WeatherFavorite', 'Weather favorites (at the Menu "Weather")', 9, 3, 'Favorite');

	UI_addControlsFamily($tkFrame, 'TelnetHost',      'Telnet favorites (at the Menu "Internet")', 3, 3, 'Host');

	UI_addControlsFamily($tkFrame, 'RSS.Menu',        'News favorites (at the Menu "Newswire")', 9, 3, 'Feed');
	
	UI_addControlsFamily($tkFrame, 'Twitter.Menu',    'Twitter feeds (at the Menu "Internet")', 6, 3, 'Nick');
	
	UI_addControlsFamily($tkFrame, 'CommandMenu',     'Favorite Commands (at Menu "Commands")', 9, 3, 'Cmd');
	
	my $tkNote = $tkFrame->new_label(-text => 'Note: Changes will only show up in the menu after saving configs and restarting the application. To add more, edit heavymetal.cfg');
	$tkNote->g_pack(-side => 'bottom', -fill =>'x');
}

sub initialize_tab_cron{
	my ($tkFrame) = @_;
	
	
	UI_setParent($tkFrame, 0, 0);
	UI_addControl('FrameCronMain', 'labelframe', '', {-text => "Cron main settings"});
	
	UI_setParent('FrameCronMain', 0, 1, [50,150]);
	UI_addControl('CronEnabled','checkbutton', ' ', {-variable => \$Configs{CronEnabled}, -text => 'Enable HM builtin crons'});

	UI_addControlsFamily($tkFrame, 'Cron', 'Scheduled Tasks (Commands)', 12, 1, 'Cron', 'Note: You must use the format <minute> <hour> <day> <month> <day of week> <uptime mins> <command> <arguments>', {-width => 80});

}

sub initialize_tab_commands{
	my ($oTkFrame) = @_;
	
	my $nEl = 0;
	my $sCfgFamily;
	my $nMaxFamily = 10;


	$sCfgFamily = 'CommandCustom';
	$nMaxFamily = 12;

	my $oTkFrameCustCmd = $oTkFrame->new_ttk__labelframe(-text => "Custom Commands (User defined)");
	
	$oTkFrameCustCmd->g_pack(-side => 'top', -fill =>'x');
	$oTkFrameCustCmd->g_grid_columnconfigure(0, -minsize =>80);
	$oTkFrameCustCmd->g_grid_columnconfigure(1, -minsize =>80);
	$oTkFrameCustCmd->g_grid_columnconfigure(2, -minsize =>80);
	$oTkFrameCustCmd->g_grid_columnconfigure(3, -minsize =>300);

	# Generate the rows
	UI_setParent($oTkFrameCustCmd);
	for ($nEl = 0; $nEl < $nMaxFamily; $nEl++){
		UI_addControl("$sCfgFamily-$nEl-Key", 'entry', 'Command',   {-width => 12})->g_bind('<FocusOut>' => [\&UI_changedControl, "$sCfgFamily-$nEl-Key"]);
		UI_addControl("$sCfgFamily-$nEl-Val", 'entry', 'Executes:', {-width => 50})->g_bind('<FocusOut>' => [\&UI_changedControl, "$sCfgFamily-$nEl-Val"]);
		UI_addControl("$sCfgFamily-$nEl-Del", 'button', '', {-text => 'Delete', -command => [\&UI_clickControl, "$sCfgFamily-$nEl-Del"]});
		UI_newRow();
	}
	UI_addControl('$sCfgFamily-Note','label', '', {-text => "Note: The command name must be only letters. Don't forget to save the configs! To add more than $nMaxFamily, manually edit heavymetal.cfg", -font => 'FontSmallNote'}, 6);


	# Load values into entries for custom commands
	$nEl = 0;
	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^$sCfgFamily\.(\w+)$/){
			$oTkControls{"$sCfgFamily-$nEl-Key"}->{value}          = $1;
			$oTkControls{"$sCfgFamily-$nEl-Key"}->{value_original} = $1;
			$oTkControls{"$sCfgFamily-$nEl-Val"}->{value}          = $Configs{$sKey};
			$nEl++;
			if ($nEl >= $nMaxFamily){
				last;
			}
		}
	}
}


sub initialize_tab_news{
	my ($oTkFrame) = @_;
	
	Tkx::package_require("Tktable");
	
	my $nMaxRows = 3;
	
	$oTkControls{'FrameNewsBottom'} = $oTkFrame->new_ttk__labelframe(-text => "Add/Edit RSS News Feed", -padding => 8);
	$oTkControls{'FrameNewsBottom'}->g_pack(-side => 'bottom', -fill => 'x', -expand => 1);
	
	UI_setParent($oTkControls{'FrameNewsBottom'});
	UI_addControl('RSS.Feed-0-New', 'button', '',        {-text => '+',    -command => [\&UI_selectListRssFeeds, 'ListRssFeeds', 'Clear'],   -width => 1});
	UI_addControl('RSS.Feed-0-Key', 'entry', 'Name:',    { -width => 18});
	UI_addControl('RSS.Feed-0-Val', 'entry', 'RSS URL:', { -width => 50});
	UI_addControl('RSS.Feed-0-Save','button', '',        {-text => 'Save',   -state => 'disabled', -command => [\&UI_changedControl, "RSS.Feed-0-Key"], -width => 7});
	UI_addControl('RSS.Feed-0-Del', 'button', '',        {-text => 'Delete', -state => 'disabled', -command => [\&UI_clickControl, "RSS.Feed-0-Del"], -width => 7});
	
	
	$oTkControls{'ListRssFeeds'} = $oTkFrame->new_listbox(-height => 20, -font => 'TkFixedFont');
	$oTkControls{'ListRssFeeds'}->g_bind("<<ListboxSelect>>" => [\&UI_selectListRssFeeds, 'ListRssFeeds', 'ListboxSelect']);
	$oTkControls{'ListRssFeeds'}->g_bind("<Double-1>" => [\&UI_selectListRssFeeds, 'ListRssFeeds', 'Double-1']);
	my $tkScrollbar = $oTkFrame->new_ttk__scrollbar(-command => [$oTkControls{'ListRssFeeds'}, "yview"], -orient => "vertical");
	$tkScrollbar->g_pack(-side => 'right', -fill => 'y');
	$oTkControls{'ListRssFeeds'}->configure(-yscrollcommand => [$tkScrollbar, "set"]);
	$oTkControls{'ListRssFeeds'}->g_pack(-side => 'right', -fill => 'both', -expand => 1);
	
	UI_updateListRssFeeds();
}




sub initialize_tab_sessions{
	my ($oTkFrame) = @_;
	
	Tkx::package_require("Tktable");
		
	$oTkControls{'TableSessions'} = $oTkFrame->new_tkx_Scrolled('table',
		-scrollbars => 'e',
		-rows => 10,
		-cols => 9,
		-colstretchmode => 'all',
		-variable => \%oSessionsData);
	$oTkControls{'TableSessions'}->g_pack(-fill => 'both', -expand => 1);
	$oTkControls{'TableSessions'}->width(0, 4);  # id
	$oTkControls{'TableSessions'}->width(1, 4);  # type
	$oTkControls{'TableSessions'}->width(2, 10); # user
	$oTkControls{'TableSessions'}->width(3, 2);  # in out
	$oTkControls{'TableSessions'}->width(4, 2);  # lvl
	$oTkControls{'TableSessions'}->width(5, 10);  # target
	$oTkControls{'TableSessions'}->width(6, 10);  # src
	$oTkControls{'TableSessions'}->width(7, 10);  # address
	$oTkControls{'TableSessions'}->width(8, 5);  # status
	
#	for (my $x = 0; $x < 9; $x++){
#		for (my $y = 0; $y < 6; $y++){
#			#$oTkControls{'TableSessions'}->state("$x,$y", 0);
#		}
#	}
	$oSessionsData{"0,0"} = 'ID';
	$oSessionsData{"0,1"} = 'Type';
	$oSessionsData{"0,2"} = 'User';
	$oSessionsData{"0,3"} = 'I/O';
	$oSessionsData{"0,4"} = 'Lvl';
	$oSessionsData{"0,5"} = 'Target';
	$oSessionsData{"0,6"} = 'Source';
	$oSessionsData{"0,7"} = 'Address';
	$oSessionsData{"0,8"} = 'Status';


	UI_updateSessionsList()


}

sub initialize_tab_ports{
	my ($oTkFramePorts) = @_;
		
	# Ports
	my $oTkFramePortsCommon = $oTkFramePorts->new_ttk__labelframe(-text => "Common settings");
	$oTkFramePortsCommon->g_pack(-side => 'top', -fill =>'x');
	$oTkFramePortsCommon->g_grid_columnconfigure(0, -minsize =>150);
	$oTkFramePortsCommon->g_grid_columnconfigure(1, -minsize =>150);
	$oTkFramePortsCommon->g_grid_columnconfigure(2, -minsize =>150);
	$oTkFramePortsCommon->g_grid_columnconfigure(3, -minsize =>150);

	
	UI_setParent($oTkFramePortsCommon);
	
	UI_addControl('SerialSetserial','checkbutton', '', {-variable => \$Configs{SerialSetserial}, -text => 'Use setserial (linux) or setdiv (Win)'}, 2);
	UI_addControl('LoopTest',       'checkbutton', '', {-variable => \$Configs{LoopTest},        -text => 'Local loop test (bypass port)'}, 2);
	UI_newRow();
	UI_addControl('EscapeEnabled',  'checkbutton', '', {-variable => \$Configs{EscapeEnabled},   -text => "Enable '$Configs{EscapeChar}' escapes"}, 2);
	UI_addControl('CopyHostOutput', 'combobox', "Copy commands' output from HOST to TTY", {-values => \%aOutputTargets,  -width => 8})->g_bind('<FocusOut>' => [\&UI_changedControl, 'CopyHostOutput']);

	UI_newRow();
	UI_addControl("RunInProtect", 'entry', 'Run-in Protect', {-textvariable => \$Configs{"RunInProtect"}, -width => 5});
	UI_addControl('', 'label', '', {-text => 'Time in seconds that TTY must be idle before sending output'}, 2);
		
	#$oTkMenues{Configs}->add_checkbutton(-label => "Remote mode (from TTY)",  -variable => \$Configs{RemoteMode});
	#$oTkMenues{Configs}->add_checkbutton(-label => "X10 Auto Mode",           -variable => \$Configs{X10Auto});
	
	my $oTkTabsPorts = $oTkFramePorts->new_ttk__notebook;
	$oTkTabsPorts->g_pack(-side=>'top',-fill=>'x');
	
	initialize_tab_port_tty(1, $oTkTabsPorts);
	initialize_tab_port_tty(2, $oTkTabsPorts);
}

sub initialize_tab_port_tty{
	my ($nTTY, $oTkParent) = @_;

	my $oTkFramePortsTTY = $oTkParent->new_ttk__frame();
	$oTkParent->add($oTkFramePortsTTY, -text => "Session $nTTY: ".$Configs{"TTY.$nTTY.Name"});

	UI_setParent($oTkFramePortsTTY);
	
	UI_addControl("TTY.$nTTY.Name", 'entry', 'Name', {-textvariable => \$Configs{"TTY.$nTTY.Name"}, -width => 12})->g_bind('<FocusOut>' => [\&UI_changedControl, "TTY.$nTTY.Name"]);
	UI_addControl("TTY-$nTTY-Status", 'label', 'Status:',      {-text => 'OFF'}, 5);
	
	UI_newRow();
	UI_addControl("TTY.$nTTY.Port", 'combobox', 'Serial Port',{-values => \%aPORTS});
	UI_addControl("TTY.$nTTY.Address", 'combobox', 'Address', {-values => \%aPortAddresses, -width => 5});

	UI_addControl("FramePortsTests-$nTTY", 'frame', 'Tests:', {}, 3);
	
	UI_newRow();
	UI_addControl("TTY.$nTTY.BaudRate", 'combobox', 'Baud rate', {-values => \%aBaudRates, -state => 'readonly', -width => 30});
	UI_addControl("TTY.$nTTY.DataBits", 'combobox', 'Data bits', {-values => \%aDataBits,  -state => 'readonly', -width => 6});
	UI_addControl("TTY.$nTTY.Parity",   'combobox', 'Parity',    {-values => \%aParity,    -state => 'readonly', -width => 6});
	UI_addControl("TTY.$nTTY.StopBits", 'combobox', 'Stop bits', {-values => \%aStopBits,  -state => 'readonly', -width => 6});

	UI_newRow(1);
	UI_addControl("TTY.$nTTY.LoopSuppress",   'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.LoopSuppress"},   -text => 'Suppress loop echo', -onvalue => 1, -offvalue => 0});
	UI_addControl("TTY.$nTTY.Echo", 'checkbutton', '',           {-variable => \$Configs{"TTY.$nTTY.Echo"}, -text => 'Echo input back to TTY',   -onvalue => 1, -offvalue => 0}, 3);
	UI_addControl("TTY.$nTTY.OverstrikeProtect", 'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.OverstrikeProtect"}, -text => 'Overstrike protect',   -onvalue => 1, -offvalue => 0}, 2);

	UI_newRow(1);
	UI_addControl("TTY.$nTTY.TranslateCR", 'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.TranslateCR"}, -text => 'Translate input CR to CRLF', -onvalue => 1, -offvalue => 0});
	UI_addControl("TTY.$nTTY.TranslateLF", 'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.TranslateLF"}, -text => 'Translate input LF to CRLF', -onvalue => 1, -offvalue => 0}, 3);
	UI_addControl("TTY.$nTTY.Columns",     'entry', 'Columns', {-textvariable => \$Configs{"TTY.$nTTY.Columns"}, -width => 3})->g_bind('<FocusOut>' => [\&UI_changedControl, "TTY.$nTTY.Columns"]);

	UI_newRow();
	UI_addControl("TTY.$nTTY.Code", 'combobox', 'Code',       {-values => \%CODES, -state => 'readonly', -width => 30}, {-sticky => 'nw'});
	UI_addControl("FramePortBaudot-$nTTY",    'labelframe', '', {-text => 'Baudot Codes'}, {-sticky => 'n', -columnspan => 6});

	UI_newRow();
	UI_addControl("FramePortSession-$nTTY",    'labelframe', '', {-text => 'Session configs'}, {-sticky => 'n', -columnspan => 8});

	# Inner frames now...
	UI_setParent("FramePortBaudot-$nTTY");
	UI_addControl("TTY.$nTTY.ExtraCR",     'combobox', 'Extra CRs', {-textvariable => \$Configs{"TTY.$nTTY.ExtraCR"}, -values => [(0 .. 9)], -state => 'readonly', -width => 2});
	UI_addControl("TTY.$nTTY.ExtraLF",     'combobox', 'Extra LFs', {-textvariable => \$Configs{"TTY.$nTTY.ExtraLF"}, -values => [(0 .. 9)], -state => 'readonly', -width => 2});
	UI_addControl("TTY.$nTTY.ExtraLTRS",   'combobox', 'Extra LTRs',{-textvariable => \$Configs{"TTY.$nTTY.ExtraLTRS"}, -values => [(0 .. 9)], -state => 'readonly', -width => 2});
	UI_newRow(1);
	UI_addControl("TTY.$nTTY.UnshiftOnSpace", 'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.UnshiftOnSpace"}, -text => 'Unshift on space',   -onvalue => 1, -offvalue => 0}, 3);

	UI_setParent("FramePortsTests-$nTTY");
	UI_addControl("ButtonPortsTestRYRY-$nTTY",    'button', '', {-text => 'RYRY',      -state => 'disabled', -command => [\&host_add_text, "$Configs{EscapeChar}SEND $nTTY $Configs{EscapeChar}RYRY\n", 1]});
	UI_addControl("ButtonPortsTestRYRY100-$nTTY", 'button', '', {-text => 'RYRY 100',  -state => 'disabled', -command => [\&host_add_text, "$Configs{EscapeChar}SEND $nTTY $Configs{EscapeChar}RYRY 100\n", 1]});
	UI_addControl("ButtonPortsTestQBF-$nTTY",     'button', '', {-text => 'QBF',       -state => 'disabled', -command => [\&host_add_text, "$Configs{EscapeChar}SEND $nTTY $Configs{EscapeChar}QBF 100\n", 1]});
	UI_addControl("ButtonPortsTestEcho-$nTTY",    'button', '', {-text => 'Echo test', -state => 'disabled', -command => [\&host_add_text, "$Configs{EscapeChar}ECHOTEST $nTTY\n", 1]});

	UI_setParent("FramePortSession-$nTTY", 1);
	UI_addControl("TTY.$nTTY.Label",      'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.Label"}, -text => 'Show source label',   -onvalue => 1, -offvalue => 0}, 3)->g_bind('<FocusOut>' => [\&UI_changedControl, "TTY.$nTTY.Label"]);
	UI_addControl("TTY.$nTTY.Prompt",     'checkbutton', '', {-variable => \$Configs{"TTY.$nTTY.Prompt"},      -text => 'Show command prompt', -onvalue => 1, -offvalue => 0}, 3)->g_bind('<FocusOut>' => [\&UI_changedControl, "TTY.$nTTY.Prompt"]);
	UI_newRow(0);
	UI_addControl("TTY.$nTTY.Source",     'combobox', 'Initial Source',{-values => ['HOST', 'ALL'], -width => 10});
	UI_addControl("TTY.$nTTY.Target",     'combobox', 'Initial Target',{-values => ['HOST', 'ALL'], -width => 10});
	UI_addControl("TTY.$nTTY.Direction",  'combobox', 'Direction',     {-values => ['In', 'Out'],   -width => 4,  -state => 'readonly'});
	UI_addControl("TTY.$nTTY.Auth",       'combobox', 'Auth level',    {-values => [0,1,2,3],       -width => 4,  -state => 'readonly'});

	return;
}

sub initialize_tab_configs{

	my ($oTkFrame) = @_;

	UI_setParent($oTkFrame, 0, 0, [320, 320]);
	UI_addControl('FrameConfigsSystem', 'labelframe', '', {-text => "System Configs"}, {-sticky =>'n', -columnspan => 2});
	UI_newRow();
	my $tkLeft  = UI_addControl('FrameConfigsLeft',  'frame', '', {}, {-sticky =>'nw'});
	my $tkRight = UI_addControl('FrameConfigsRight', 'frame', '', {}, {-sticky =>'ne'});
	
	UI_setParent('FrameConfigsSystem', 0, 0, [80, 120, 80, 120, 80, 120]);
	UI_addControl('SystemName', 'entry', 'System Name', {-textvariable => \$Configs{SystemName}, -width => 10});
	UI_addControl('SystemPassword', 'entry', 'System Password', {-textvariable => \$Configs{SystemPassword}, -width => 15});
	UI_addControl('GuestPassword', 'entry', 'Guest Password', {-textvariable => \$Configs{GuestPassword}, -width => 15});
	UI_newRow();
	UI_addControl('SystemPrompt', 'entry', 'System Prompt', {-textvariable => \$Configs{SystemPrompt}, -width => 10});
	UI_addControl('Columns', 'entry', 'Host Columns', {-textvariable => \$Configs{Columns}, -width => 3});
	UI_addControl('CommandsMaxHistory', 'entry', 'Commands History', {-textvariable => \$Configs{CommandsMaxHistory}, -width => 3});
	UI_newRow();
	UI_addControl('Debug', 'combobox', 'Debug',{-values => \%aDebugLevels, -state => 'readonly'}, 2);
	UI_addControl('DebugFile', 'entry', 'Debug File', {-textvariable => \$Configs{DebugFile}, -width => 30}, 2);
	UI_newRow();
	UI_addControl('TelnetWelcome', 'entry', 'Welcome Message', {-textvariable => \$Configs{TelnetWelcome}, -width => 85}, 5);

	my $oTkFrameConfigsTelnet = $tkLeft->new_ttk__labelframe(-text => "Telnet server (Incomming)");
	UI_setParent($oTkFrameConfigsTelnet, 0, 1, [20, 80, 110, 110]);
	UI_addControl('TelnetEnabled', 'checkbutton', ' ', {-text => 'Enabled', -variable => \$Configs{TelnetEnabled}, -command => \&telnet_toggle, -onvalue=> 1, -offvalue => 0});
	UI_addControl('TelnetPort', 'entry', 'Listening port', {-textvariable => \$Configs{TelnetPort}, -width => 5});

	my $oTkFrameConfigsMsn = $tkLeft->new_ttk__labelframe(-text => "MSN messenger");
	UI_setParent($oTkFrameConfigsMsn, 1, 1, [100, 100, 120]);
	UI_addControl('MsnEnabled', 'checkbutton', '', {-text => 'Enabled', -variable => \$Configs{MsnEnabled}, -command => \&msn_toggle, -onvalue=> 1, -offvalue => 0});
	UI_addControl('MsnListen',  'checkbutton', '', {-text => 'Listen input msgs',  -variable => \$Configs{MsnListen}, -onvalue=> 1, -offvalue => 0});
	UI_newRow();
	UI_addControl('MsnUsername', 'entry', 'Username', {-textvariable => \$Configs{MsnUsername}, -width => 20}, 2);
	UI_newRow();
	UI_addControl('MsnPassword', 'entry', 'Password', {-textvariable => \$Configs{MsnPassword}, -width => 20}, 2);


	my $oTkFrameConfigsHmnet = $tkLeft->new_ttk__labelframe(-text => "HM Net (Directory)");
	UI_setParent($oTkFrameConfigsHmnet, 0, 1, [100, 220]);
	UI_addControl('HMNetName', 'entry', 'Station name', {-textvariable => \$Configs{HMNetName}, -width => 15});
	UI_newRow();
	UI_addControl('HMNetPass', 'entry', 'Password', {-textvariable => \$Configs{HMNetPass}, -width => 15});
	UI_newRow();
	UI_addControl('HMNetOwner', 'entry', 'Owner name', {-textvariable => \$Configs{HMNetOwner}, -width => 30});
	UI_newRow();
	UI_addControl('HMNetEmail', 'entry', 'Contact e-mail', {-textvariable => \$Configs{HMNetEmail}, -width => 30});
	

	
	# RIGHT SIDE
	my $oTkFrameConfigsMail = $tkRight->new_ttk__labelframe(-text => "E-mail");
	UI_setParent($oTkFrameConfigsMail, 0, 1, [130, 190]);
	UI_addControl('EmailFrom', 'entry', 'e-Mail', {-textvariable => \$Configs{EmailFrom}, -width => 25});
	UI_newRow();
	UI_addControl('EmailAccount', 'entry', 'Account', {-textvariable => \$Configs{EmailAccount}, -width => 25});
	UI_newRow();
	UI_addControl('EmailPassword', 'entry', 'Password', {-textvariable => \$Configs{EmailPassword}, -width => 25});
	UI_newRow();
	UI_addControl('EmailPOP', 'entry', 'POP3 Server (In)', {-textvariable => \$Configs{EmailPOP}, -width => 25});
	UI_newRow();
	UI_addControl('EmailSMTP', 'entry', 'SMTP Server (Out)', {-textvariable => \$Configs{EmailSMTP}, -width => 25});

	#my $oTkFrameConfigsWeather = $tkRight->new_ttk__labelframe(-text => "Weather");
	#UI_setParent($oTkFrameConfigsWeather, 0, 1, [100, 220]);
	#UI_addControl('WeatherDefaultSource', 'combobox', 'Default Source', {-values => ['WWO', 'GOOGLE', 'NOAA', 'METAR'], -state => 'readonly', -width => 15});
	#UI_newRow();
	#UI_addControl('WeatherNoaaForecastBase', 'entry', 'NOAA FTP Forecast Base', {-textvariable => \$Configs{WeatherNoaaForecastBase}, -width => 35});
	#UI_newRow();
	#UI_addControl('WeatherNoaaClimateBase', 'entry', 'NOAA FTP Climate Base', {-textvariable => \$Configs{WeatherNoaaClimateBase}, -width => 35});


	my $oTkFrameConfigsMisc = $tkRight->new_ttk__labelframe(-text => "Misc Configs");
	UI_setParent($oTkFrameConfigsMisc, 0, 1, [100, 220]);
	UI_addControl('WeatherDefaultSource', 'combobox', 'Default Weather Source', {-values => ['WWO', 'GOOGLE', 'NOAA', 'METAR'], -state => 'readonly', -width => 15});
	UI_newRow();
	UI_addControl('StockPortfolio', 'entry', 'Stock Portfolio', {-textvariable => \$Configs{StockPortfolio}, -width => 35});
	UI_newRow();
	UI_addControl('TestQBF', 'entry', 'QBF Test String', {-textvariable => \$Configs{TestQBF}, -width => 35});



}


sub UI_setParent{
	my ($oTkParent, $nCol, $bPack, $rCols) = @_;
	
	if (ref(\$oTkParent) eq 'SCALAR'){
		$UI_TkParent = $oTkControls{$oTkParent}->{control};
	}
	elsif(ref($oTkParent) eq 'Tkx::widget'){
		$UI_TkParent = $oTkParent;
	}
	else{
		die ("ERROR: Invalid GUI element used as parent");
	}
	
	$UI_Row = 0; 
	$UI_Col = defined $nCol ? $nCol : 0;
	
	if ($bPack){
		$UI_TkParent->g_pack(-fill => 'x');
	}
	
	if (defined($rCols) && scalar(@$rCols) > 0){
		for (my $n = 0; $n < scalar(@$rCols); $n++){
			$UI_TkParent->g_grid_columnconfigure($n, -minsize => $rCols->[$n]);
		}
	}
	
	return $UI_Row;
}

sub UI_newRow{
	my ($nCol) = @_;
	if (defined $nCol){
		$UI_Col = $nCol;
	}
	else{
		$UI_Col = 0;
	}
	$UI_Row++; 
	
	return $UI_Row;
}

sub UI_updateControl{
	my ($sName, $sValue) = @_;
	if (defined $oTkControls{$sName}){
		if (!defined $sValue && defined $Configs{$sName}){
			$sValue = $Configs{$sName};
		}
		my $sText = $sValue;
		
		if ($oTkControls{$sName}->{type} eq 'combobox'){
			if (ref($oTkControls{$sName}->{values}) eq 'HASH'){
				$sText = $oTkControls{$sName}->{values}->{$sValue}->{label};
			}
			
			#print "\n$sName = $oTkControls{$sName}->{type} $sValue\n";
			$oTkControls{$sName}->{control}->set($sText);
			
		}
		
		if ($sName =~ /^RSS\.Feed\./){
			UI_updateListRssFeeds();
		}
		
		
	}
}

sub UI_clickControl{
	my ($sName) = @_;
	
	if (defined $oTkControls{$sName}){
		if ($sName =~ /^(RSS\.Feed|CommandCustom)-(\d+)-Del$/){
			my $idEl  = $1;
			my $idNum = $2;
			
			# delete the value itself
			if (exists $oTkControls{"$idEl-$idNum-Key"}->{value_original}){
				if ($oTkControls{"$idEl-$idNum-Key"}->{value_original}){
					my $sCfgKey = uc($oTkControls{"$idEl-$idNum-Key"}->{value_original});
					if (exists $Configs{$idEl.'.'.$sCfgKey}){
						delete $Configs{$idEl.'.'.$sCfgKey};
					}
					$oTkControls{"$idEl-$idNum-Key"}->{value_original} = '';
				}
			}
			else{
				my $sCfgKey = uc($oTkControls{"$idEl-$idNum-Key"}->{value});
				if (exists $Configs{$idEl.'.'.$sCfgKey}){
					delete $Configs{$idEl.'.'.$sCfgKey};
				}
			}
			
			# Clear the entries
			$oTkControls{"$idEl-$idNum-Key"}->{value} = '';
			$oTkControls{"$idEl-$idNum-Val"}->{value} = '';
			
			if ($idEl eq 'RSS.Feed'){
				UI_updateListRssFeeds();
			}
		}
	}
	
}

sub UI_changedControl{
	my ($sName) = @_;
	
	if (defined $oTkControls{$sName}){
		my $thisControl = $oTkControls{$sName};
		my $sText;
		my $sCfgVal;
		my $sCfgKey = $sName;
		my $bAllowCreate = 0;
		
		my $idEl;
		
		if ($thisControl->{type} eq 'checkbutton' || $thisControl->{type} eq 'radiobutton'){
			$sText = index($thisControl->{control}->state(), 'selected') >= 0 ? $thisControl->{control}->cget('-onvalue') : $thisControl->{control}->cget('-offvalue');
		}
		else{
			$sText = $thisControl->{control}->get();
		}
		$sCfgVal = $sText;

		# HANDLE NAUGTHY COMBOBOXES
		if ($thisControl->{type} eq 'combobox' && ref($thisControl->{values}) eq 'HASH'){
			my $rValues = $thisControl->{values};
			foreach my $sKey (keys %{$rValues}){
				if ($rValues->{$sKey}->{label} eq $sText) {
					$sCfgVal = $sKey;
					last;
				}
			}
		}
		
		# CUSTOM COMMANDS and RSS FEEDS
		if ($sName =~ /^(RSS\.Feed|CommandCustom)-(\d+)-(Key|Val)$/){
			$idEl = $1;
			my $idNum= $2;
			
			my $tkKey = $oTkControls{"$idEl-$idNum-Key"};
			my $tkVal = $oTkControls{"$idEl-$idNum-Val"};
			
			$sCfgKey = uc($tkKey->{value});
			$sCfgVal = $tkVal->{value};
			
			if ($sCfgKey !~ /^[A-Z][\w\.]*$/){
				return 0;
			}
			
			if ($tkKey->{value_original} && $tkKey->{value_original} ne $sCfgKey){
				if (defined $Configs{$idEl.'.'.$tkKey->{value_original}}){
					delete $Configs{$idEl.'.'.$tkKey->{value_original}};
				}
			}
			
			$tkKey->{value}          = $sCfgKey;
			$tkKey->{value_original} = $sCfgKey;
			
			if ($sCfgKey ne '' && $sCfgVal ne ''){
				$sCfgKey = $idEl.'.'.$sCfgKey;
				$bAllowCreate = 1;
			}
			
		}

		if (defined($Configs{$sCfgKey}) || $bAllowCreate){
			config_set($sCfgKey, $sCfgVal, 1);
		}
		
		if ($idEl eq 'RSS.Feed'){
			UI_updateListRssFeeds();
		}

	}
	

}

sub UI_addControl{
	my ($sName, $sType, $sLabel, $oOptions, $oGrid) = @_;
	
	if(!defined $UI_TkParent){
		return;
	}
	
	if ($sLabel){
		my $sStickyLabel = 'e';
		if ($oGrid && ref($oGrid) eq 'HASH' && defined $oGrid->{'-sticky'}){
			if (index($oGrid->{'-sticky'}, 'n') >= 0){
				$sStickyLabel = 'ne';
			}
			elsif (index($oGrid->{'-sticky'}, 's') >= 0){
				$sStickyLabel = 'se';
			}
		}
		$UI_TkParent->new_label(-text=> $sLabel)->g_grid(-row => $UI_Row, -column => $UI_Col++, -sticky => $sStickyLabel,  -padx => 2, -pady => 2);
	}
	if ($sType){
		my @aOptions;
		my $rValues;
		
		$oTkControls{$sName} = {};
		$oTkControls{$sName}->{type}    = $sType;
		$oTkControls{$sName}->{value}    = '';
		$oTkControls{$sName}->{valueref} = \$oTkControls{$sName}->{value};
		
		if ($sType eq 'checkbutton' && !defined $oOptions->{'-command'}){
			$oOptions->{'-command'} = [\&UI_changedControl, $sName];
		}

		if ($sType eq 'entry'){
			if (defined $oOptions->{'-textvariable'}){
				$oTkControls{$sName}->{valueref} = $oOptions->{'-textvariable'};
			}
			else{
				$oOptions->{'-textvariable'} = $oTkControls{$sName}->{valueref};
			}
		}
		
		foreach my $sKey (keys %{$oOptions}){
			if ($sKey eq '-values' and ref($oOptions->{$sKey}) eq 'HASH'){
				$rValues = $oOptions->{$sKey};
				my @aValues = ();
				foreach my $sKeyVal (sort {$rValues->{$a}->{order} <=> $rValues->{$b}->{order}} keys %{$rValues}){
					push(@aValues, $rValues->{$sKeyVal}->{label});
				}
				push(@aOptions, $sKey, [@aValues]);
			}
			else{
				push(@aOptions, $sKey, $oOptions->{$sKey});
			}
		}
		
		my @aGrid = ('-row', $UI_Row, '-column', $UI_Col++, '-sticky', 'w',  '-padx', 2, '-pady', 2);
		if (ref($oGrid) eq 'HASH'){
			foreach my $sKey (keys %{$oGrid}){
				push(@aGrid, $sKey, $oGrid->{$sKey});
				if ($sKey eq '-columnspan'){
					$UI_Col += $oGrid->{$sKey} - 1;
				}
			}
		}
		elsif (ref(\$oGrid) eq 'SCALAR' && $oGrid > 1){
			push(@aGrid, '-columnspan', $oGrid);
			$UI_Col += $oGrid - 1;
		}
		
		my $sMethod = ($sType eq 'combobox' || $sType eq 'checkbutton' || $sType eq 'radiobutton' || $sType eq 'labelframe') ? "new_ttk__$sType" : "new_$sType";
		
		my $oTkEl = $UI_TkParent->$sMethod(@aOptions);
		$oTkEl->g_grid(@aGrid);
	
		

		$oTkControls{$sName}->{control} = $oTkEl;
		$oTkControls{$sName}->{values}  = $rValues;
		$oTkControls{$sName}->{value}   = $rValues;
		if ($sType eq 'combobox'){
			$oTkEl->g_bind('<<ComboboxSelected>>' => [\&UI_changedControl, $sName]);
		}
		
		return $oTkEl;
	}
	
	return;
}

sub UI_addControlsFamily{
	my  ($tkParent, $sCfgFamily, $sTitle, $nMaxFamily, $nColumns, $sPrefix, $sNote, $rProperties) = @_;
	
	my $nEl;
	
	my $tkFrame = $tkParent->new_ttk__labelframe(-text => $sTitle);
	$tkFrame->g_pack(-side => 'top', -fill =>'x');
	
	for ($nEl = 0; $nEl < $nColumns; $nEl++){
		$tkFrame->g_grid_columnconfigure($nEl * 2, -minsize =>80);
	}

	UI_setParent($tkFrame);
	
	if (!defined $rProperties){
		$rProperties = {};
	}
	
	
	for ($nEl = 0; $nEl < $nMaxFamily; $nEl++){
		if ($nEl > 0 && $nEl % $nColumns == 0){
			UI_newRow();
		}
		$rProperties->{-textvariable} = \$Configs{"$sCfgFamily.$nEl"};
		UI_addControl("$sCfgFamily.$nEl",'entry', "$sPrefix $nEl", $rProperties);
	}
	
	if ($sNote){
		UI_newRow();
		UI_addControl("$sCfgFamily-Note",'label', '', {-text => $sNote, -font => 'FontSmallNote'}, 6);
	}

}

sub UI_selectListRssFeeds{ 
	my ($sControl, $sEvent) = @_;
	
	if ($sEvent eq 'Double-1'){
		my $nIndex = $oTkControls{'ListRssFeeds'}->curselection();
		if (defined $nIndex){
			my $sLine = $oTkControls{'ListRssFeeds'}->get($nIndex);
			if ($sLine =~ /^\s*(\S+)\s+(\S+)$/){
				host_add_text("$Configs{EscapeChar}NEWS SUMMARY $1\n");
			}
		}
		return;
	}
	
	if ($sEvent eq 'Clear'){
		$oTkControls{'RSS.Feed-0-Key'}->{value_original} = '';
		$oTkControls{'RSS.Feed-0-Key'}->{control}->delete(0, 'end');
		$oTkControls{'RSS.Feed-0-Val'}->{control}->delete(0, 'end');
		$oTkControls{'RSS.Feed-0-Save'}->{control}->configure(-state => 'normal');
		$oTkControls{'RSS.Feed-0-Del'}->{control}->configure(-state => 'disabled');
		
		return;
	}
	
	if ($sEvent eq 'ListboxSelect'){
		my $nIndex = $oTkControls{'ListRssFeeds'}->curselection();
		if (defined $nIndex){
			my $sLine = $oTkControls{'ListRssFeeds'}->get($nIndex);
			if ($sLine =~ /^\s*(\S+)\s+(\S+)$/){
				$oTkControls{'RSS.Feed-0-Key'}->{value_original} = $1;
				
				$oTkControls{'RSS.Feed-0-Key'}->{control}->delete(0, 'end');
				$oTkControls{'RSS.Feed-0-Key'}->{control}->insert(0, $1);
				
				$oTkControls{'RSS.Feed-0-Val'}->{control}->delete(0, 'end');
				$oTkControls{'RSS.Feed-0-Val'}->{control}->insert(0, $2);
				
				$oTkControls{'RSS.Feed-0-Save'}->{control}->configure(-state => 'normal');
				$oTkControls{'RSS.Feed-0-Del'}->{control}->configure(-state => 'normal');
				
			}
		}
		return;
	}
}
	
sub UI_updateListRssFeeds{
	if (!$bTkEnabled){
		return;
	}
	
	#$oTkControls{'ListRssFeeds'}->selection_set(0);
	my $n = 0;
	foreach my $sKey (sort keys %Configs){
		if ($sKey =~ /^RSS\.Feed\.([\w\.]+)$/){
			$oTkControls{'ListRssFeeds'}->insert($n, sprintf('%25s %s', uc($1), $Configs{$sKey}));
			$oTkControls{'ListRssFeeds'}->itemconfigure($n, -background => ($n % 2 ? "#f0f0ff" : "#ffffff"));
			$n++;
		}
	}
	$oTkControls{'ListRssFeeds'}->delete($n, 'end');
}

sub UI_updateSessionsList{
	if (!$bTkEnabled){
		return;
	}
	my $n = 1;
	foreach my $thisSession (@aSessions){
		if (!defined $thisSession->{type}){
			next;
		}
		$oSessionsData{"$n,0"} = $thisSession->{id};
		$oSessionsData{"$n,1"} = $thisSession->{type};
		$oSessionsData{"$n,2"} = $thisSession->{user};
		$oSessionsData{"$n,3"} = $thisSession->{direction} ? 'Out' : 'In';
		$oSessionsData{"$n,4"} = $thisSession->{auth};
		$oSessionsData{"$n,5"} = $thisSession->{target};
		$oSessionsData{"$n,6"} = $thisSession->{source};
		$oSessionsData{"$n,7"} = $thisSession->{address};
		$oSessionsData{"$n,8"} = $thisSession->{status} ? 'Conn' : 'Disc';
		$n++;
	}

}



sub bytes_pending {
	my ($idSession) = @_;
	
	my $BlockingFlags;
	my $InBytes = 0;
	my $LatchErrorFlags;
	my $OutBytes = 0;
	

	if ($idSession && $aSessions[$idSession] && $aSessions[$idSession]->{status} && $aSessions[$idSession]->{type} eq 'TTY') {
		if ($aSessions[$idSession]->{PORT}){
			($BlockingFlags, $InBytes, $OutBytes, $LatchErrorFlags) = $aSessions[$idSession]->{PORT}->{'status'};
		}
		return $OutBytes + length($aSessions[$idSession]->{RAW_IN}) + length($aSessions[$idSession]->{RAW_OUT});
	}
	return 0;
	
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
	
	UI_updateStatus();
	
	my $idSession = defined $Configs{BatchSession} ? $Configs{BatchSession} : 0;

	for (my $i=0;$i < 10;$i++) {
		while ($aSessions[$idSession]->{command} eq '' && $aSessions[$idSession]->{input_type} eq '' && (bytes_pending($idSession) == 0 && $sCurrentCommand ne '')){
			if ($bTkEnabled){
				Tkx::update();
			}
			
			if ($aSessions[$idSession]->{echo_input}){
				$aSessions[$idSession]->{OUT} .= $sCurrentCommand . $lf;
				process_host_out();
			}

			process_line($idSession, $sCurrentCommand);
			
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

sub UI_host_display_char { 
	my ($c, $sTag) = @_;

	if (!$bTkEnabled){
		return;
	}
	
	if ($Configs{Debug} > 2){ logDebug(" DIS: $sPrinthead ". debug_char(0, $c) .' ('.ord($c).')'); }
	
	# Ignore non printable characters: Bell SI SO
	if ($c eq "\a"){
		return 0;
	}
	elsif ($c eq $si){
		$sGlobalTextTag = 'tagSent';
		return 0;
	}
	elsif ($c eq $so){
		$sGlobalTextTag = '';
		return 0;
	}
	
	# What markup tag should be used? (Color mainly)
	if (!$sTag){
		$sTag = $sGlobalTextTag;
	}
	
	# This is useless
	#if ($char_delay) {
	#	Tkx::after($char_delay);
	#}

	$oTkTextarea->configure(-state => "normal");

#print "\n$sPrinthead ".debug_char(0, $c)." '".debug_char(0, $oTkTextarea->get("$sPrinthead", "$sPrinthead + 1 char"))."' $bGlobalCursorReplace ->";
	$oTkTextarea->delete("$sPrinthead", "$sPrinthead + 1 char");
	if ($c eq $lf){
		$oTkTextarea->replace("$sPrinthead lineend", "$sPrinthead lineend + 1 char", $c.' ', $sTag);
		$sPrinthead = $oTkTextarea->index("$sPrinthead + 1 line");
		# Insert the cursor
		$oTkTextarea->insert($sPrinthead, $sGlobalCursorChar, 'tagCursor');
	}
	elsif ($c eq $cr){
		$sPrinthead = $oTkTextarea->index("$sPrinthead linestart");
		# Insert the cursor
		$oTkTextarea->insert($sPrinthead, $sGlobalCursorChar, 'tagCursor');
	}
	elsif($c eq $bs){
		$sPrinthead = $oTkTextarea->index("$sPrinthead - 1 char");
		# Insert the cursor
		$oTkTextarea->replace($sPrinthead, "$sPrinthead + 1 char", $sGlobalCursorChar, 'tagCursor');
	}
	else {
		$oTkTextarea->insert("$sPrinthead", $c, $sTag);
		$sPrinthead = $oTkTextarea->index("$sPrinthead + 1 char");
		# Insert the cursor
		$oTkTextarea->replace($sPrinthead, "$sPrinthead + 1 char", $sGlobalCursorChar, 'tagCursor');
	}
	$oTkTextarea->configure(-state => "disabled");
#print " $sPrinthead '".debug_char(0, $oTkTextarea->get("$sPrinthead", "$sPrinthead + 1 char"))."' $bGlobalCursorReplace";
}

sub UI_host_display_char_legacy { 
	my ($c, $sTag) = @_;

	my $curr_line;
	my $curr_column;
	my $end_line;
	my $end_column;
	my $sCursorChar ; #this was global!!! but I removed it from the global scope
	if (!$bTkEnabled){
		return;
	}
	
	if ($Configs{Debug} > 2){ logDebug(' DIS: '. debug_char(0, $c) .' ('.ord($c).')'); }
	
	# Ignore bells
	if ($c eq "\a"){
		return 0;
	}
	elsif ($c eq $si){
		$sGlobalTextTag = 'tagSent';
		return 0;
	}
	elsif ($c eq $so){
		$sGlobalTextTag = '';
		return 0;
	}
	
	if (!$sTag){
		$sTag = $sGlobalTextTag;
	}
	
	if ($char_delay) {
		Tkx::after($char_delay);
	}

	$oTkTextarea->configure(-state => "normal");
	
	# Delete the cursor
	$oTkTextarea->delete($sPrinthead, "$sPrinthead + 1 char");
	
	if (defined($sCursorChar)) {
		$oTkTextarea->insert("$sPrinthead", $sCursorChar);
		$sCursorChar = undef;
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
			$oTkTextarea->insert("$sPrinthead lineend", $lf);
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
		$oTkTextarea->insert("$sPrinthead", $c, $sTag);
		($curr_line,$curr_column) = split(/\./,$sPrinthead);
		
		# Overstrike simulation
		if ($curr_column < ($Configs{Columns} - 1)) {
			$sPrinthead = $oTkTextarea->index("$sPrinthead + 1 char");
		}
	}

	$sCursorChar = $oTkTextarea->get("$sPrinthead","$sPrinthead + 1 char");
	if ($sCursorChar eq "\n") {
		$sCursorChar = undef;
	}
	else {
		$oTkTextarea->delete("$sPrinthead","$sPrinthead + 1 char");
	}
	$oTkTextarea->insert($sPrinthead, ' ', 'tagCursor');
	$oTkTextarea->configure(-state => "disabled");
}

# This sub is not actually used and does not move the column counter for session 0
sub UI_host_display_string {
	my ($sLine, $sTag) = @_;
	for (my $i = 0; $i < length($sLine); $i++){
		UI_host_display_char(substr($sLine, $i, 1), $sTag);
	}
}

sub UI_host_blinkCursor{
	my $sColor = (time() % 2 || length($aSessions[0]->{OUT}) > 0) ? 'blue' : 'white';
	$oTkTextarea->tag_configure('tagCursor', -background => $sColor, -foreground => 'black');
}

sub UI_showProgress{
	my ($nValue, $nMax, $bIdleOnly) = @_;
	if (!$bTkEnabled){
		return;
	}
	if ($bIdleOnly && $nGlobalProgressBusy){
		return;
	}
	
	if (!defined $nMax){
		if ($nValue){
			$oTkControls{"StatusProgress"}->configure(-mode => 'indeterminate');
			$oTkControls{"StatusProgress"}->start();
			if (!$bIdleOnly){
				$nGlobalProgressBusy = 1;
			}
		}
		else{
			$oTkControls{"StatusProgress"}->stop();
			$oTkControls{"StatusProgress"}->configure(-mode => 'determinate', -maximum => 0, -value => 0);
			if (!$bIdleOnly){
				$nGlobalProgressBusy = 0;
			}
		}
	}
	elsif($nMax == 0){
		$oTkControls{"StatusProgress"}->stop();
		$oTkControls{"StatusProgress"}->configure(-mode => 'determinate', -maximum => 0, -value => 0);
		if (!$bIdleOnly){
			$nGlobalProgressBusy = 0;
		}
	}
	elsif($nMax > 0){
		$oTkControls{"StatusProgress"}->configure(-mode => 'determinate', -maximum => $nMax, -value => $nValue);
		if (!$bIdleOnly){
			$nGlobalProgressBusy = 1;
		}
	}
	Tkx::update();
}

sub UI_updateStatus {
	my ($sText, $nProgressValue, $nProgressMax) = @_;
	
	if (!$bTkInitialized){
		return;
	}

	UI_host_blinkCursor();
	
	if (defined $nProgressValue){
		UI_showProgress($nProgressValue, $nProgressMax, 0);
	}
	
	if (!$sText){
		$sText = '';

		my $nBytesTotal = 0;
		my $nBytes;
		
		my ($nInbound, $nOutbound) = session_count();
		$sText .= "Sessions In: $nInbound - Session Out: $nOutbound\n";
		
		$nBytes = length($aSessions[0]->{OUT});
		$nBytesTotal += $nBytes;
		$sText .= 'Pending Bytes: HOST = '.$nBytes;
		
		if ($aSessions[1]->{status}){
			$nBytes       = bytes_pending(1);
			$nBytesTotal += $nBytes;
			$sText       .= "\n TTY1 = " . $nBytes;
		}
		if ($aSessions[2]->{status}){
			$nBytes       = bytes_pending(2);
			$nBytesTotal += $nBytes;
			$sText       .= "/ TTY2 = " . $nBytes;
		}
		
		if ($nBytesTotal > $nGlobalPendingBytes){
			$nGlobalPendingBytes = $nBytesTotal;
		}
		if ($nBytesTotal == 0){
			$nGlobalPendingBytes = 0;
		}
		
		if (!$nGlobalProgressBusy){
			if ($nBytesTotal == 0){
				UI_showProgress(0, 0, 1);
			}
			else{
				UI_showProgress($nBytesTotal, $nGlobalPendingBytes, 1);
			}
		}
		
		
	}
	
	$aStatusLabels{TTY1}   = $Configs{"TTY.1.Port"}."\n".$Configs{"TTY.1.Code"}."\n".$aBaudRates{$Configs{"TTY.1.BaudRate"}}->{label_short}.' '.$Configs{"TTY.1.DataBits"}.uc(substr($Configs{"TTY.1.Parity"}, 0, 1)).$Configs{"TTY.1.StopBits"};
	$aStatusLabels{TTY2}   = $Configs{"TTY.2.Port"}."\n".$Configs{"TTY.2.Code"}."\n".$aBaudRates{$Configs{"TTY.2.BaudRate"}}->{label_short}.' '.$Configs{"TTY.2.DataBits"}.uc(substr($Configs{"TTY.2.Parity"}, 0, 1)).$Configs{"TTY.2.StopBits"};
	$aStatusLabels{Telnet} = $Configs{TelnetEnabled} ? "Telnet: ON\n$Configs{TelnetPort}" : 'Telnet: OFF';
	$aStatusLabels{MSN}    = $Configs{MsnEnabled} ? "MSN:\n".$Configs{MsnUsername} : 'MSN: OFF';

	if ($oTkControls{"SessionIcon-1"}){
		$oTkControls{"SessionIcon-1"}->configure(-image => ($aSessions[1]->{status}  ? $Global{Images}->{'tty-on'} : $Global{Images}->{'tty-off'}));
	}
	if ($oTkControls{"SessionIcon-2"}){
		$oTkControls{"SessionIcon-2"}->configure(-image => ($aSessions[2]->{status}  ? $Global{Images}->{'tty-on'} : $Global{Images}->{'tty-off'}));
	}
	if ($oTkControls{"TelnetIcon"}){
		$oTkControls{"TelnetIcon"}->configure(   -image => ($Configs{TelnetEnabled} ? $Global{Images}->{'telnet-on'} : $Global{Images}->{'telnet-off'}));
	}
	if ($oTkControls{"MsnIcon"}){
		$oTkControls{"MsnIcon"}->configure(      -image => ($Configs{MsnEnabled}    ? $Global{Images}->{'msn-on'}    : $Global{Images}->{'msn-off'}));
	}
	
	$oTkStatus->configure(-text => $sText);
	Tkx::update();

}


# Main I/O
sub process_pending_io {

	my $res = 1; # Assume nothing to do
	
	# NOTE: With some minor changes (i.e. moving all confs to the session) this would support n TTYs
	
	foreach my $thisSession (@aSessions){
		if ($thisSession->{status}){
			if ($thisSession->{type} eq 'TTY'){
				# SERIAL -> TTY-RAW-IN
				if (!$Configs{LoopTest}){
					$res = process_tty_serial_rawin($thisSession->{id}, $res);
				}
			
				# TTY-RAW-IN -> TTY-IN
				$res = process_tty_rawin_in($thisSession->{id}, $res);
	
				# TTY-IN
				$res = process_tty_in($thisSession->{id}, $res);

				# TTY-OUT -> TTY-RAW-OUT
				$res = process_tty_out_rawout($thisSession->{id}, $res);
				
				# TTY-RAW-OUT -> SERIAL
				$res = process_tty_rawout_serial($thisSession->{id}, $res);

			}
		}
	}
	

	# WINDOW -> HOST-IN
	$res = process_host_in($res);

	# HOST-OUT -> WINDOW
	$res = process_host_out($res);

	
	# TELNET
	if ($nTelnetSockets > 0){
		telnet_io();
	}
	
	# MSN
	if ($Configs{MsnEnabled}){
		msn_io();
	}
	
	return $res;
}



# SERIAL -> TTY RAW-IN
sub process_tty_serial_rawin{
	my ($idSession, $res)     = @_;
	my $c;
	my $n;
	my $sLine;
	my $thisSession = $aSessions[$idSession];
	
	if ($thisSession->{PORT}){
		$sLine = $thisSession->{PORT}->input();
		if (length($sLine) > 0){
			if ($Configs{Debug} > 2){ 
				for ($n = 0; $n < length($sLine); $n++){
					$c = substr($sLine, $n, 1);
					logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'SERIAL','RAW_IN', ord($c), debug_char($idSession, $c)));
				}
			}
			
			$thisSession->{RAW_IN} .= $sLine; 
			
			$res = 0;
		}
	}

	return $res;
}


# TTY RAW-IN -> TTY IN
sub process_tty_rawin_in{
	my ($idSession, $res)     = @_;
	my $c;
	my $d;
	
	my $thisSession = $aSessions[$idSession];
	my $sCode = $Configs{"TTY.$idSession.Code"};
	
	while (length($thisSession->{RAW_IN}) > 0){
		$c = substr($thisSession->{RAW_IN} , 0 , 1, '');
		
		if ($Configs{Debug} > 2){ 
			my $nSup = length($thisSession->{'SUPPRESS'}) ? ord(substr($thisSession->{'SUPPRESS'}, 0, 1)) : '';
			logDebug(sprintf("\n%-8s -> %-8s %03d %3s S:%3s ", 'RAW_IN','TTY-IN', ord($c), debug_char($idSession, $c), $nSup)); 
		}
		
		if (length($thisSession->{'SUPPRESS'}) > 0 && $c eq substr($thisSession->{'SUPPRESS'}, 0, 1)) {
			if ($Configs{Debug} > 2){ logDebug('Supp '); }
			substr($thisSession->{'SUPPRESS'}, 0, 1, '');
		}
		else{
			$thisSession->{rx_last} = time();
			$thisSession->{rx_count}++;
			
			if ($sCode eq "ASCII" ) {
				$d = $c;
			}
			else {
				# TRANSCODE BAUDOT->ASCII
				if ($c eq $ltrs || $c eq $figs) {
					$thisSession->{rx_shift} = $c;
				}
				elsif ($c eq $space && $Configs{"TTY.$idSession.UnshiftOnSpace"}){
					$thisSession->{rx_shift} = $ltrs;
				}
				if ($thisSession->{rx_shift} eq $ltrs) {
					$d = $CODES{$sCode}->{'FROM-LTRS'}->{$c};
				}
				else {
					$d = $CODES{$sCode}->{'FROM-FIGS'}->{$c};
				}
				if (!defined($d)) {
					$d = $host_no_match_char;
				}
				
				if ($thisSession->{'lowercase_lock'}){ 
					$d = lc($d); 
				}
			}
			
			
			# If we have echo then we add it here
			if ($thisSession->{echo_input}){
				my $o = $c;
				my $bUseASCII = $sCode eq "ASCII" ? 1 : 0;
				
				# Columns tracking
				if (($bUseASCII && $c eq $cr) || (!$bUseASCII && $c eq $b_cr)){
					# On CR we always return the column to 0
					$thisSession->{column} = 0;
					if ($Configs{"TTY.$idSession.TranslateCR"}) {
						$o = $thisSession->{eol};
					}
				}
				elsif (($bUseASCII && $c eq $lf) || (!$bUseASCII && $c eq $b_lf)){
					# On LF we only return the column to 0 if the translate is enabled
					if ($Configs{"TTY.$idSession.TranslateLF"}) {
						$thisSession->{column} = 0;
						$o = $thisSession->{eol};
					}
				}
				elsif ($bUseASCII && $c eq $bs && !$Configs{"TTY.$idSession.DisableBS"}){
					$thisSession->{column}--;
					if ($thisSession->{column} < 0){
						$thisSession->{column} = 0;
					}
				}
				elsif ($c eq $nul || ($bUseASCII && ($c eq $si || $c eq $so)) || (!$bUseASCII && ($c eq $ltrs || $c eq $figs))){
					# We ignore these specifically
				}
				else{
					# Otherwise we increment
					$thisSession->{column}++;
				}
				
				# Overstrike protect
				if ($thisSession->{column} >= $Configs{"TTY.$idSession.Columns"} && $Configs{"TTY.$idSession.OverstrikeProtect"}){
					$o .= $thisSession->{eol};
					$thisSession->{column} = 0;
				}
				
				# ECHO
				if ($Configs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'ECHOIN','SERIAL', ord($c), debug_char($idSession, $c))); }
				
				if (!$thisSession->{PORT} || !serial_wait($thisSession->{PORT}) || !$thisSession->{PORT}->write($o)){
					$thisSession->{active} = 0;
					logDebug("\nERROR: Cannot write to port, dropping echoed character ".ord($c));
				}
			}
			
			# Translate Line endings
			if ($d eq $lf && $Configs{"TTY.$idSession.TranslateLF"}){
				$d = $EOL;
			}
			elsif ($d eq $cr && $Configs{"TTY.$idSession.TranslateCR"}) {
				$d = $EOL;
			}
			
			# Append to buffer
			$thisSession->{IN} .= $d; 
			
		}
	}
	return $res;
}


# Process TTY IN
sub process_tty_in{
	my ($res)     = @_;
	my $idSession = 1;
	my $n;
	my $sLine;
	my $nPos;
	
	my $thisSession = $aSessions[$idSession];
	
	if (length($thisSession->{IN}) > 0 && ($nPos = index($thisSession->{IN}, $lf)) >= 0){
		while ($nPos >= 0){
			$sLine = substr($thisSession->{IN}, 0, $nPos);
			$sLine =~ s/\r+$//;
			
			$thisSession->{IN} = substr($thisSession->{IN}, $nPos+1);
			
			if ($Configs{Debug} > 1){ logDebug("\nTTY-IN: $sLine"); }

			# Decode escape sequences TO ASCII
			if ($sLine && $Configs{EscapeEnabled} && index($sLine, $Configs{EscapeChar}) >= 0){
				$sLine = escape_to_ascii($idSession, $sLine);
			}
			
			# Process backspaces
			if ($sLine){
				while (($n = index($sLine, $bs)) >= 0){
					substr($sLine, $n - 1, 2, '');
				}
			}
			
			# Detect and execute commands or send message
			process_line($idSession, $sLine);

			# Get the next position for the while loop
			$nPos = index($thisSession->{IN}, $lf);
		}
	}
	return $res;
}

# RAW-OUT -> SERIAL
sub process_tty_rawout_serial{
	my ($res)     = @_;
	my $idSession = 1;
	my $c;
	my $d;
	
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
		if ($Configs{RunInProtect} == 0 || length($thisSession->{IN}) == 0 || (time() - $thisSession->{rx_last}) > $Configs{RunInProtect}){
			
			# Runin protect for TTY implies:
			# 1- Prepending a new line
			# 2- Output the OUT buffer, which "should" end with a new line (Note, we should detect this and append a newline if not)
			# 3- Output the IN buffer and end with the correct shift
			# Note: We use a counter to avoid sending a newline with every processed byte
			if ($Configs{RunInProtect} > 0 && length($thisSession->{IN}) > 0 &&  $thisSession->{runin_count} == 0){
				#$thisSession->{runin_count} = $thisSession->{rx_count};
				if ($Configs{"TTY.$idSession.Code"} eq "ASCII") {
					$thisSession->{RAW_OUT} = $EOL . $thisSession->{RAW_OUT} . $thisSession->{IN};
				}
				else{
					$thisSession->{RAW_OUT} = $aSessions[$idSession]->{eol} . $thisSession->{RAW_OUT} . transcode_to_loop($idSession, $thisSession->{IN}).$thisSession->{rx_shift};
				}
				$thisSession->{runin_count} = length($thisSession->{RAW_OUT});
			}
			
			# Loop and output characters
			my $sOutputBuffer = '';
			while (length($thisSession->{RAW_OUT}) > 0){
				$c = substr($thisSession->{RAW_OUT} , 0 , 1, '');
				if ($thisSession->{runin_count} > 0){
					$thisSession->{runin_count}--;
				}
	
				if ($Configs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'RAW_OUT','SERIAL', ord($c), debug_char($idSession, $c, 1))); }
	
	
				if (defined $c){
					# Columns tracking
					if ($Configs{"TTY.$idSession.Code"} eq 'ASCII'){
						if ($c eq $cr){
							$thisSession->{column} = 0;
						}
						elsif($c ne $lf && $c ne $nul && $c ne $so && $c ne $si){
							$thisSession->{column}++;
						}
					}
					else{
						if ($c eq $b_cr){
							$thisSession->{column} = 0;
						}
						elsif($c ne $b_lf && $c ne $nul && $c ne $ltrs && $c ne $figs){
							$thisSession->{column}++;
						}
					}
					
					# Overstrike protect
					if ($thisSession->{column} >= $Configs{"TTY.$idSession.Columns"} && $Configs{"TTY.$idSession.OverstrikeProtect"}){
						$c .= $thisSession->{eol};
						$thisSession->{column} = 0;
					}
					
					# Add to Tiny small buffer
					$sOutputBuffer .= $c;
					if (length($sOutputBuffer) >= $nGlobalSerialChunk){
						last;
					}
				}
				
			}
			
			# Output the tiny buffer
			if ($sOutputBuffer){
				# For testing we do absolutely everything just like we would do with a regular setup, and we only 
				# avoid the serial output. At that point instead we simply copy the OUTPUT into the INPUT
				if ($Configs{LoopTest}){
					$thisSession->{RAW_IN}.= $sOutputBuffer;
					# If enabled we add to the SUPPRESS buffer
					if ($Configs{"TTY.$idSession.LoopSuppress"}){
						$thisSession->{SUPPRESS} .= $sOutputBuffer;
					}
				}
				else{
					if ($thisSession->{PORT} && serial_wait($thisSession->{PORT}) && $thisSession->{PORT}->write( $sOutputBuffer)){
						# If enabled we add to the SUPRESS buffer
						if ($Configs{"TTY.$idSession.LoopSuppress"}){
							$thisSession->{SUPPRESS} .= $sOutputBuffer;
							
							if (length($thisSession->{SUPPRESS}) > 500){
								# This is definitely too much for the supress buffer, so almost surely we don't have an echo in the loop
								$Configs{"TTY.$idSession.LoopSuppress"} = 0;
								$thisSession->{SUPPRESS} = '';
							}
						}
					}
					else{
						$thisSession->{active} = 0;
						logDebug("\nERROR: Cannot write to port, dropping character ".ord($c));
					}
				}
			}
		}
	}
	return $res;
}


# TTY-OUT -> RAW-OUT (TRANSCODE OUT)
sub process_tty_out_rawout{
	my ($res)     = @_;
	my $idSession = 1;
	my $c;
	my $d;
	my $sEscape = '';
	
	my $thisSession = $aSessions[$idSession];
	
	if (length($thisSession->{OUT}) > 0){
		my $sCode = $Configs{"TTY.$idSession.Code"};
		
		$res = 0;
		if ($Configs{X10Auto} && ($x10_motor_state == 0)) {
			x10_on();
			sleep(2);
			$x10_motor_state = 1;
		}

		# RAWMODE OFF
		if (!$thisSession->{'raw_mode'}){
					
			if ($sCode ne "ASCII") {
				# I don't remember why I am doing this??
				$thisSession->{RAW_OUT} .= $ltrs;
				$thisSession->{tx_shift} = $ltrs;
			}

			while (length($thisSession->{OUT}) > 0){
				
				$c = substr($thisSession->{OUT} , 0 , 1, '');
				$d = undef;
			
				if ($Configs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s ", 'TTY-OUT','RAW_OUT', ord($c), debug_char($idSession, $c))); }

				if ($CODES{$sCode}->{upshift}) {
					$c = uc($c);
				}
				
				
				# PROCESS ASCII LOOP
				if ($sCode eq "ASCII" ) {
					if (ord($c) > 255 && $Modules{'Text::Unidecode'}->{loaded}){
						$c = unidecode($c);
					}
					$d = ($c eq $lf) ? $thisSession->{eol} : $c;
				}
				# PROCESS OTHER ENCODINGS
				else {
					# DETECT ESCAPE SEQUENCES
					if ($sEscape eq ''){
						if ($c eq $Configs{EscapeChar}){	
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
							elsif(uc($sEscape) eq $Configs{EscapeChar}.'OVERSTRIKEOFF'){
								$Configs{"TTY.$idSession.OverstrikeProtect"} = 0;
								$d = '';
								# Add it back to the first character
								if ($c ne ' '){
									$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
								}

								last;
							}
							elsif(uc($sEscape) eq $Configs{EscapeChar}.'OVERSTRIKEON'){
								$Configs{"TTY.$idSession.OverstrikeProtect"} = 1;
								$d = '';
								# Add it back to the first character
								if ($c ne ' '){
									$thisSession->{OUT} = $c . $aSessions[1]->{OUT};
								}

								last;
							}
							elsif(uc($sEscape) eq $Configs{EscapeChar}.'RAWMODEON'){
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
					# End of detect escape sequence
	
					if (!defined($d)){
						# TRANSCODE ASCII->BAUDOT
						if (defined $c){
							if ($c eq $lf){
								$d = $aSessions[$idSession]->{eol};
								$thisSession->{tx_shift} = $ltrs;
							}
							elsif ($thisSession->{tx_shift} eq $ltrs && exists($CODES{$sCode}->{'TO-LTRS'}->{$c})){
								$d = $CODES{$sCode}->{'TO-LTRS'}->{$c}
							}
							elsif ($thisSession->{tx_shift} eq $figs && exists($CODES{$sCode}->{'TO-FIGS'}->{$c})){
								$d = $CODES{$sCode}->{'TO-FIGS'}->{$c}
							}
							elsif (exists($CODES{$sCode}->{'TO-LTRS'}->{$c})) {
								$d = $ltrs . $CODES{$sCode}->{'TO-LTRS'}->{$c};
								$thisSession->{tx_shift} = $ltrs;
							}
							elsif (exists($CODES{$sCode}->{'TO-FIGS'}->{$c})) {
								$d = $figs . $CODES{$sCode}->{'TO-FIGS'}->{$c};
								$thisSession->{tx_shift} = $figs;
							}
							# We currently don't support any NATL shift (used to be 0x00 in some TTYs)
							else {
								if ($Modules{'Text::Unidecode'}->{loaded}){
									$c = unidecode($c);
									if (length($c) > 1){
										# Was more than one character as a result, and we can only work one char at a time
										$thisSession->{OUT} = substr($c, 1) . $thisSession->{OUT};
										$c = substr($c, 0, 1);
									}
									
									if (exists($CODES{$sCode}->{'TO-LTRS'}->{$c})){
										if ($thisSession->{tx_shift} ne $ltrs){
											$d = $ltrs.$CODES{$sCode}->{'TO-LTRS'}->{$c};
											$thisSession->{tx_shift} = $ltrs;
										}
										else{
											$d = $CODES{$sCode}->{'TO-LTRS'}->{$c};
										}
									}
									elsif (exists($CODES{$sCode}->{'TO-FIGS'}->{$c})){
										if ($thisSession->{tx_shift} ne $figs){
											$d = $figs.$CODES{$sCode}->{'TO-FIGS'}->{$c};
											$thisSession->{tx_shift} = $figs;
										}
										else{
											$d = $CODES{$sCode}->{'TO-FIGS'}->{$c};
										}
									}
								}

								$d = $loop_no_match_char;
							}
						}
						else{
							$d = undef;
						}
					}
				}
				# End of non ASCII
				
				
				
				if (defined $d){
					# Append to the loop
					$thisSession->{RAW_OUT} .= $d;
					
					# Protect from overstrike
#					if ($Configs{"TTY.$idSession.Code"} eq "ASCII"){
#						if (index($d, $cr) >= 0){
#							$thisSession->{column} = 0;
#						}
#						elsif ($c eq $lf){
#		
#						}
#						elsif (length($d) > 0){
#							# We should be checking each character here, not assuming there is only one.
#							# This is not a problem now because escaped characters are always of length 1, but in the future, 
#							# longer escape sequences may come
#							$thisSession->{column}++;
#							if ($Configs{"TTY.$idSession.OverstrikeProtect"} && $thisSession->{column} >= $Configs{"TTY.$idSession.Columns"}){
#								$thisSession->{RAW_OUT} .= $EOL;
#								$thisSession->{column} = 0;
#							}
#						}
#					}
#					else{
#						if (index($d, $b_cr) >= 0){
#							$thisSession->{column} = 0;
#						}
#						elsif ($c eq $b_lf){
#		
#						}
#						elsif (length($d) > 0){
#							$thisSession->{column}++;
#							if ($Configs{"TTY.$idSession.OverstrikeProtect"} && $thisSession->{column} >= $Configs{"TTY.$idSession.Columns"}){
#								$thisSession->{RAW_OUT} .= $aSessions[$idSession]->{eol};
#								$thisSession->{tx_shift} = $ltrs;
#								$thisSession->{column} = 0;
#							}
#						}
#					}
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
			
				if ($Configs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s %s", 'TTY-OUT','RAW_OUT', ord($c), debug_char($idSession, $c), 'RAW')); }

				# DETECT ESCAPE SEQUENCES
				if ($sEscape eq ''){
					if ($c eq $Configs{EscapeChar}){	
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
						elsif(uc($sEscape) eq $Configs{EscapeChar}.'RAWMODEOFF'){
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
				
				# I disabled this for now...
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
sub process_host_in{
	my ($res)     = @_;
	my $idSession = 0;
	my $nPos;
	my $sLine;
	
	my $thisSession = $aSessions[$idSession];
	
	if (length($aSessions[0]->{IN}) > 0 && ($nPos = index($aSessions[0]->{IN}, $lf)) >= 0){
		while ($nPos >= 0){
			$sLine = substr($thisSession->{IN}, 0, $nPos + 1, '');
			
			chomp($sLine);
			$sLine =~ s/\r+$//;

			if ($Configs{Debug} > 1){ logDebug("\nHOST-IN: $sLine"); }
			
			# Decode escape sequences TO ASCII
			if ($Configs{EscapeEnabled} && index($sLine, $Configs{EscapeChar}) >= 0){
				$sLine = escape_to_ascii($idSession, $sLine);
			}

			if ($thisSession->{echo_input}){
				$thisSession->{OUT} .= $si.$sLine.$so. $lf;
				$res = process_host_out($res);
			}

			# Detect and execute commands or send message
			process_line($idSession, $sLine);

			# Get the next position for the while loop
			$nPos = index($thisSession->{IN}, $lf);
		}
	}
	return $res;
}



# Process HOST OUT (Session 0) -> WINDOW
sub process_host_out{
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
			
			if ($Configs{Debug} > 2){ logDebug(sprintf("\n%-8s -> %-8s %03d %3s %02d ", 'HOST-OUT','WINDOW', ord($c), debug_char($idSession, $c), $thisSession->{column})); }
			
			# Protect from overstrike
			if ($c eq $cr){
				$thisSession->{column} = 0;
				UI_host_display_char($c, '');
			}
			elsif ($c eq $lf){
				if ($thisSession->{column} > 0){
					$thisSession->{column} = 0;
					UI_host_display_char($cr, '');
				}
				UI_host_display_char($c, '');
			}
			elsif($c ne $nul && $c ne "\a"){
				$thisSession->{column}++;
				if ($thisSession->{column} >= $Configs{Columns}){
					$thisSession->{column} = 0;
					UI_host_display_char($cr, '');
					UI_host_display_char($lf, '');
				}
				UI_host_display_char($c, '');
			}
			
			$res = 0;
			
			# We stop here to avoid the program becoming unresponsive
			if ($nCount > 70){
				last;
			}
		}
		if ($bTkEnabled){
			$oTkTextarea->see('end');
			Tkx::update();
		}
		
	}
	return $res;
}





sub main_loop {

	my $io_bored  = (process_pending_io() && (bytes_pending(1) == 0) && (bytes_pending(2) == 0));

	$nGlobalTime = time();

	if ($Configs{CronEnabled} && $nGlobalTime >= $nGlobalCronNextRun){
		process_cron();
	}

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
		push(@aCommands, $aSessions[0]->{COMMANDS}->[0]);
		$nTimerSleep = 0;
		if ($nSleepRepeat > 0){
			$nTimerSleep = time() + $nSleepRepeat;
		}
	}
#	elsif ($bored && ($Configs{BatchMode} || $Configs{X10Auto})) {
#		if ($batchmode_countdown-- < 0) {
#			if ($Configs{X10Auto} && ($x10_motor_state == 1)) {
#				x10_off();
#				$x10_motor_state = 0;
#			}
#			if ($Configs{BatchMode}) {
#				exit(0);
#			}
#		}
#	}
#	else {
#		$batchmode_countdown = $batchmode_countdown_delay;
#	}

	if ($nShutDown > 0){
		if ($Configs{MsnEnabled}){
			my $nCountPendingMsn = 0;
			foreach my $thisSession (@aSessions){
				if ($thisSession->{'status'} && $thisSession->{'type'} eq 'MSN' && $thisSession->{OUT} ne ''){
					$nCountPendingMsn++;
				}
			}
			if ($nCountPendingMsn == 0){
				if ($Configs{Debug} > 0){ logDebug("\nDisconnecting from MSN\n"); }
				$oMSN->disconnect();
				$Configs{MsnEnabled} = 0;
			}
		}
		
		if (time() > $nShutDown){
			print "\nShutdown complete! Bye Bye!\n";
			if ($bTkEnabled){
				$oTkMainWindow->g_destroy();
			}
			$bExitMainLoop = 1;
		}
	}

	if ($bTkEnabled){
		Tkx::after($polltime, \&main_loop);
	}
}


# This wil handle clean exits from CTRL-C
sub main_exit{
	for my $idSession (1 .. 9){
		serial_close($idSession);
	}
	
	$nShutDown = 1;
	$bExitMainLoop = 1;
}

sub main_tk_error{
	my $sMsg = shift;
	logDebug("\n\nTK ERROR: $sMsg\n");
	# Try to recover
	do_abort(0, 'ALL', 1);
	message_send('SYS', 'ALL', '-- WARNING: And error has ocurred, the system has recovered');
	message_deliver('SYS', 0, "\n-- WARNING: And error has ocurred, the system has recovered.\n$sMsg\n", 0, 0, 0);
	main_loop();
}

#---------------------------------------------------------------------------
# Edit commands
#---------------------------------------------------------------------------
sub clipboard_copy {
	if ($bTkEnabled){
		if ($oTkTextarea->tag_ranges('sel')){
			my $sTxt = $oTkTextarea->get('sel.first' , 'sel.last');
			if (defined $sTxt) {
				Clipboard->copy($sTxt);
			}
		}
	}
}

sub clipboard_paste {
	host_add_text(Clipboard->paste());
}

sub textarea_copy_all {
	if ($bTkEnabled){
		Clipboard->copy($oTkTextarea->get('1.0' , 'end - 2 chars' ));
	}
}


sub textarea_select_all {
	if ($bTkEnabled){
		$oTkTextarea->configure(-state => "normal");
		$oTkTextarea->tag_add( "sel", '1.0' , 'end - 2 chars' );
		$oTkTextarea->configure(-state => "disabled");
		$oTkControls{MainTabs}->select(0);
	}
}

sub textarea_clear_all {
	if ($bTkEnabled){
		$sPrinthead = "1.0";
		$oTkTextarea->configure(-state => "normal");
		$oTkTextarea->delete('1.0', 'end');
		$oTkTextarea->insert($sPrinthead, " ", 'tagCursor');
		$oTkTextarea->configure(-state => "disabled");
		$oTkControls{MainTabs}->select(0);
	}
}

#---------------------------------------------------------------------------
# File commands
#---------------------------------------------------------------------------
sub do_load_file {
  my $res = "";
  my $filename = Tkx::tk___getOpenFile(-parent => $oTkMainWindow, -title => 'Open file');
  if (defined ($filename)) {
     if (!open(my $FH, '<', "$filename")) {
       local_warning("Could not open $filename for reading\n");
     } else {
       $res = join("",<$FH>);
       close($FH);
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
	my ($oPort) = @_;
	x10_send($oPort,"$Configs{X10House}$Configs{X10Device}J");
}

sub x10_off {
	my ($oPort) = @_;
	x10_send($oPort,"$Configs{X10House}$Configs{X10Device}K");
}

sub do_save_file {
	(my $input_str) = @_;
	
	my $filename = Tkx::tk___getSaveFile(-parent => $oTkMainWindow, -title => 'Save file as');
	if (defined ($filename)) {
		if (!open(my $FH, '>', $filename)) {
			local_warning("Could not open $filename for writing\n");
		}
		else {
			print $FH $input_str;
			close($FH);
		}
	}
}

sub do_saveconfig {
	if (!open(my $CONFIG, '>', $sGlobalConfigsFile)) {
		local_warning("Could not open $sGlobalConfigsFile for writing\n");
	}
	else {
		foreach my $sVar (sort keys %Configs) {
			if (!defined($ConfigsDefault{$sVar}) || $Configs{$sVar} ne $ConfigsDefault{$sVar}){
				print $CONFIG "-$sVar=$Configs{$sVar}\n";
			}
		}
		#print CONFIG "--SERIALINIT\n";
		close($CONFIG);
		return "DONE";
	}
}



sub save_file {
	do_save_file( $oTkTextarea->get( '1.0','end - 2 chars' ));
}

sub save_file_raw {
	do_save_file( $loop_archive );
}

sub host_add_text {
	my ($inLine, $bDoNotSwitchTab) = @_;
	
	if (defined $inLine){
		my $sLine = (ref(\$inLine) eq 'REF') ? ${$inLine} : $inLine;
		$aSessions[0]->{IN} .= $sLine.$lf;
		if ($Configs{Debug}){ logDebug("\nCMD->HOST: $sLine\n"); }
	}
	elsif($sInputValue ne ''){
		if ($Configs{Debug}){ logDebug("\nINPUT->HOST: $sInputValue\n"); }
		$aSessions[0]->{IN} .= $sInputValue;
		$sInputValue = '';
	}
	if ($bTkEnabled && !$bDoNotSwitchTab){
		$oTkControls{MainTabs}->select(0);
	}
}



#---------------------------------------------------------------------------
# Util
#---------------------------------------------------------------------------


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
	
	if (open (my $INPUT, '<', $sFile)) {
		while (my $sLine = (<$INPUT>)) {
			chomp($sLine);
			push(@batch, $sLine);
		}
		close($INPUT);
	}
	else {
		local_error("Couldn't open $sFile\n");
	}
	process_batch(@batch);
}

sub process_cmdline {
	process_batch(@ARGV);
}

sub process_cron{
	my $idCron = 0;
	
	my ($Sec, $Min, $Hour, $Day, $Mon, $Year, $WDay, $YDay) = localtime(); 
	my $nUpt = int((time() - $nTimeStart) / 60);
	
	#<minute> <hour> <day> <month> <day of week> <uptime minutes> <command line>
	my $sKey = 'Cron.'.$idCron;
	while (exists $Configs{$sKey}){
		my $nDiv;
		if ($Configs{$sKey}){
			my $sCron = $Configs{$sKey};
			if ($sCron =~ /^(\d|\d\d|\*|\*\/\d+)\s+(\d|\d\d|\*|\*\/\d+)\s+(\d|\d\d|\*|\*\/\d+)\s+(\d|\d\d|\*|\*\/\d+)\s+(\d|\d\d|\*|\*\/\d+)\s+(\d|\d\d|\*|\*\/\d+)\s+(.+)$/){
				if (($1 eq '*' || $1 == $Min  || (substr($1, 0, 2) eq '*/' && ($nDiv = int(substr($1, 2))) && $Min  % $nDiv == 0))
				 && ($2 eq '*' || $2 == $Hour || (substr($2, 0, 2) eq '*/' && ($nDiv = int(substr($2, 2))) && $Hour % $nDiv == 0))
				 && ($3 eq '*' || $3 == $Day  || (substr($3, 0, 2) eq '*/' && ($nDiv = int(substr($3, 2))) && $Day  % $nDiv == 0))
				 && ($4 eq '*' || $4 == $Mon  || (substr($4, 0, 2) eq '*/' && ($nDiv = int(substr($4, 2))) && $Mon  % $nDiv == 0))
				 && ($5 eq '*' || $5 == $WDay || (substr($5, 0, 2) eq '*/' && ($nDiv = int(substr($5, 2))) && $WDay % $nDiv == 0))
				 && ($6 eq '*' || $6 == $nUpt || (substr($6, 0, 2) eq '*/' && ($nDiv = int(substr($6, 2))) && $nUpt % $nDiv == 0))
				){
					push(@aCommands, $7);
				}
			}
			elsif($sCron !~ /^[-!]/){
				$Configs{$sKey} = '!'.$sCron;
				local_warning("Cron.$idCron configuration is invalid and it has been disabled.");
			}
		}
		$idCron++;
		$sKey = 'Cron.'.$idCron;
	}
	
	$nGlobalTime        = time();
	$nGlobalCronNextRun = $nGlobalTime - ($nGlobalTime % 60) + 60;
}

sub process_batch{
	my @batch = @_;
	
	my $sCmdline;
	my $sCmd;
	my $sArgs;
	
	while ($sCmdline = shift(@batch)){
		$sCmd  = $sCmdline;
		$sCmd  =~ s/\s+$//;
		$sArgs = '';
		if ($sCmd =~ /=/){
			($sCmd, $sArgs) = split(/=/, $sCmd, 2);
		}
		
		if (uc($sCmd) eq '--BATCH'){
			if ($sArgs){
				if (-e $sArgs) {
					load_batch_file($sArgs);
				}
				else{
					print "-- Error: Batch file $sArgs does not exist";
				}
			}
			else{
				print "-- Warning: Missing batch filename";
			}
		}
		elsif (uc($sCmd) eq '--CONFIGSFILE'){
			# Ignore this, it is not really a command, it just specifies where to load the initial configs file
			$sCmd = '';
		}
		elsif ($sCmd =~ /^\-\-/){
			$sCmd = uc(substr($sCmd, 2));
		}
		elsif($sCmd =~ /^\-/){
			$sCmd  =~ s/[^\w\.]//g; # If we don't do this, we might break the call to do_setvar if we receive trash
			if ($sCmd){
				config_set($sCmd, $sArgs);
			}
			$sCmd = '';
		}
		else{
			$sCmd = '';
			# Should we ignore the command?
			print "-- Unknown cmdline: $sCmdline\n";
		}
		
		if ($sCmd){
			if (exists $aActionCommands{$sCmd} || exists($Configs{"CommandCustom.$sCmd"})){
				push(@aCommands, $Configs{EscapeChar}.$sCmd.' '.$sArgs);
			}
			else{
				print "-- Unknown command: $sCmdline\n";
			}
		}
	}
}






sub local_error {
	(my $error_msg) = @_;

	if ($Configs{Debug}){ logDebug("ERROR: $error_msg\n");}
	
	message_send('SYS', 0, "-- ERROR: $error_msg", 0, 1, 1); 

}

sub local_warning {
	(my $error_msg) = @_;

	if ($Configs{Debug}){ logDebug("Warning: $error_msg\n");}

	message_send('SYS', 0, "-- Warning: $error_msg", 0, 1, 1); 


}

#---------------------------------------------------------------------------
# Init 
#---------------------------------------------------------------------------



sub serial_init{
	my ($idSession) = @_;
	if (!defined($idSession) || !defined($aSessions[$idSession])){
		#if ($Configs{Debug}) { logDebug("\nERROR: Invalid TTY session\n");}
		return 0;
	}
	if ($aSessions[$idSession]->{'type'} ne 'TTY'){
		#if ($Configs{Debug}) { logDebug("\nERROR: Not a TTY session\n");}
		return 0;
	}
	if ($Configs{Debug} > 2) { logDebug("serial_init($idSession)\n");}
		
	my $thisSession = $aSessions[$idSession];
	
	my $sPort       = $Configs{"TTY.$idSession.Port"};
	my $sBaudRate   = $Configs{"TTY.$idSession.BaudRate"};
	my $nDivisor    = $Configs{"TTY.$idSession.Divisor"};
	my $nAddress    = $Configs{"TTY.$idSession.Address"};
	my $nDataBits   = $Configs{"TTY.$idSession.DataBits"};
	my $nStopBits   = $Configs{"TTY.$idSession.StopBits"};
	my $sParity     = $Configs{"TTY.$idSession.Parity"};
	
	# Important note:
	# For LINUX this value MUST be 38400. For Windows it can be 38400, but it can be other value
	my $nDefaultBauds = 38400;
	my $sError   = '';
	my $sWarning = '';
	my $sMsg     = '';
	
	if (!$nDivisor){
		$nDivisor = $aBaudRates{$sBaudRate}->{divisor};
	}
	
	if (!$nAddress){
		$nAddress = $aBaudRates{$sBaudRate}->{address};
	}
	
	if ($thisSession->{PORT}){
		serial_close($idSession);
	}
	
	if (!$Configs{"TTY.$idSession.Name"}){
		$Configs{"TTY.$idSession.Name"}  = 'TTY'.$idSession;
	}

	$thisSession->{address} = $sPort;
	$thisSession->{user} = $Configs{"TTY.$idSession.Name"};

	if (!$sPort || $sPort eq "OFF"){
		$thisSession->{PORT} = 0;
		#local_warning("Session $idSession: Port disabled for $thisSession->{user}");
		$thisSession->{status} = 0;
		$sMsg = 'OFF';
	}
	elsif($Configs{LoopTest}){
		if ($Configs{Debug}) { logDebug("\nOpening FAKE port $sPort for testing. Loop Bypassed.\n");}
		message_send('SYS', 0, "-- INFO: Session $idSession $thisSession->{user} at $sPort is UP!\n-- INFO: FAKE, Port is bypassed for testing!)", 0, 1, 1);
		$sMsg = "Session $idSession at Port $sPort is UP! (FAKE)";
		$thisSession->{status} = 1;
	}
	else{
		if ($Configs{Debug}) { logDebug("\nOpening port $sPort\n");}

		if (!$nAddress && $Configs{SerialSetserial} && $bWindows) {
			$sWarning = "Session $idSession: setdiv cannot run, verify port address";
			local_warning($sWarning);
		}

		if ($bWindows) { 
			$thisSession->{PORT} = Win32::SerialPort->new($sPort,1);
		}
		else {
			$thisSession->{PORT} = Device::SerialPort->new($sPort);
		}
		
		if (!$thisSession->{PORT}){
			$thisSession->{status} = 0;
			
			$sError = "Failed open serial port $sPort";
			local_error($sError);
		
			if ($Configs{Debug}) { logDebug("ERROR: $sError\n");}
		}
		else{
			
			$thisSession->{status}  = 0;
			$thisSession->{address} = $sPort;

			$nGlobalBaud = int( (1843200/16) / $nDivisor );
			
			# Linux does not like 1.5 
			my $nStopBitsReal = $nStopBits;
			if (!$bWindows && $nStopBits == 1.5){
				$nStopBitsReal = 2;
			}
		
			# to avoid some conflicts, first reset port to innocuous state
			$thisSession->{PORT}->databits(8);
			$thisSession->{PORT}->stopbits(1);
			$thisSession->{PORT}->parity("none");
			$thisSession->{PORT}->baudrate($nDefaultBauds);
		
			# now, set to desired values.  Must do word size before stop bits
			if (!$Configs{SerialSetserial}) {
				$thisSession->{PORT}->baudrate($nGlobalBaud) or local_error($sError = "Failed setting baudrate $nGlobalBaud");
			}
			
			$thisSession->{PORT}->parity($sParity)         or local_error($sError = "Failed setting parity $sParity");
			$thisSession->{PORT}->databits($nDataBits)     or local_error($sError = "Failed setting word size $nDataBits");
			$thisSession->{PORT}->stopbits($nStopBitsReal) or local_error($sError = "Failed setting stopbits $nStopBitsReal");
			$thisSession->{PORT}->handshake('none')        or local_error($sError = 'Failed setting handshake');
			$thisSession->{PORT}->write_settings()         or local_error($sError = 'Failed to write settings');
		
		
			$nGlobalWPM = (($nGlobalBaud / ($nDataBits + $nStopBits + 1)) * 60) / 6;
		
			if ($Configs{SerialSetserial}) {
				if ($bWindows) {
					if (!defined($aPORTS{$sPort})) {
						local_error("Invalid port name - $sPort");
					}
					elsif($nAddress) {
						my $sCmd = "setdiv $nAddress $nDivisor";
						if (!$bWindows98) {
							$sCmd = "allowio /a \"$sCmd\"";
						}
						
						my $sResult = `$sCmd`;
						if ($Configs{Debug} >1) { logDebug("\n$sCmd\n$sResult\n");}
					}
				} 
				else {
					# LINUX
					my $sCmd    = "setserial $sPort spd_cust divisor $nDivisor 2>&1"; # Use 2>&1 at the end to force only errors to be returned
					my $sResult = `$sCmd`;
					
					# Only errors should be retrieved with that redirect
					if (length($sResult)){
						$thisSession->{PORT} = 0;
						if ($Configs{Debug} >1) { logDebug("\n$sCmd\n$sResult\n");}
					}
				}
			}
			
			if (!$sError){
				$sMsg = "Session $idSession at Port $sPort is UP!";
				$thisSession->{status} = 1;
				#message_send('SYS', 'IN', "-- INFO: Session $idSession $thisSession->{user} at $thisSession->{address} is UP!", 0, 1, 1);
				message_send('SYS', 0, "-- INFO: $sMsg", 0, 1, 1);
			}
		}
	}
	
	if ($sError){
		$sMsg = $sError;
	}


	if ($bTkEnabled){
		if (defined $oTkControls{"ButtonPortsTestRYRY-$idSession"}){
			$oTkControls{"ButtonPortsTestRYRY-$idSession"}->{control}->configure(-state => ($thisSession->{status} ? 'normal' : 'disabled'));
		}
		if (defined $oTkControls{"ButtonPortsTestRYRY100-$idSession"}){
			$oTkControls{"ButtonPortsTestRYRY100-$idSession"}->{control}->configure(-state => ($thisSession->{status} ? 'normal' : 'disabled'));
		}
		if (defined $oTkControls{"ButtonPortsTestQBF-$idSession"}){
			$oTkControls{"ButtonPortsTestQBF-$idSession"}->{control}->configure(-state => ($thisSession->{status} ? 'normal' : 'disabled'));
		}
		if (defined $oTkControls{"ButtonPortsTestEcho-$idSession"}){
			$oTkControls{"ButtonPortsTestEcho-$idSession"}->{control}->configure(-state => ($thisSession->{status} ? 'normal' : 'disabled'));
		}
		if (defined $oTkControls{"TTY-$idSession-Status"}){
			$oTkControls{"TTY-$idSession-Status"}->{control}->configure(-text => $sMsg);
		}
	}

	UI_updateStatus();
}




sub serial_close{
	my ($idSession) = @_;
	
	if (!defined($idSession) || !defined($aSessions[$idSession])){
		#if ($Configs{Debug}) { logDebug("\nERROR: Invalid TTY session\n");}
		return 0;
	}
	my $thisSession = $aSessions[$idSession];
	
	if ($thisSession->{'type'} ne 'TTY'){
		#if ($Configs{Debug}) { logDebug("\nERROR: not a TTY session ($thisSession->{type})\n");}
		return 0;
	}
	
	
	
	if ($thisSession->{PORT}) {
		$thisSession->{PORT}->close();
		$thisSession->{PORT} = undef;
		if ($Configs{Debug}) { logDebug("\nSession $idSession: Closed serial port $thisSession->{address} for $thisSession->{user}\n");}
	}
	$thisSession->{status}  = 0;
	
	return 1;
}

sub serial_wait{
	my ($rPort) = @_;
	
	if ($bWindows) {
		my ($bDone, $nCount) = $rPort->write_done(0);
		while (!$bDone){ ($bDone, $nCount) = $rPort->write_done(0); }
	}
	else{
		while (!$rPort->write_drain()){;}
	}
	return 1;
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
		UI_updateStatus("-- CMD: $sTitle --");
	}

	return $aSessions[$idSession]->{command_calls}++;
}

# For now this is only used for interactive commands
sub command_done{
	my ($idSession, $sText, $sCleanupVars) = @_;
	
	if ($sCleanupVars){
		foreach my $sVar (keys %{$aSessions[$idSession]->{VARS}}){
			if ($sVar =~ /$sCleanupVars/){
				delete $aSessions[$idSession]->{VARS}->{$sVar};
			}
		}
	}
	delete $aSessions[$idSession]->{VARS}->{ready};
	
	$aSessions[$idSession]->{command} = '';
	
	if ($sText){
		$sText .= $lf;
		if ($aSessions[$idSession]->{prompt}){
			$sText .= $Configs{SystemPrompt};
		}
	
		message_deliver('SYS', $idSession, $sText, 1, 1, 1);
	}
	
	return 0;
}

sub command_input{
	my ($idSession, $sVar, $sType, $sValue, $sValidate, $sPrompt, $sCommand, $bUpperCase) = @_;

	my $sReturn  = '';
	my $bInvalid = 0;
	my $bAbort   = 0;

	# We have an input arg
	if ($sValue ne ''){
		# Check if we have to abort
		$sReturn = $bUpperCase ? uc($sValue) : $sValue;
		if ($sReturn =~ /\Q$Configs{EscapeChar}\Edel\s*$/i){
			$sReturn  = '';
		}
		elsif ($sReturn =~ /\Q$Configs{EscapeChar}\E(abort|cancel)\s*$/i){
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
			
			if ($bUpperCase){
				$sReturn = uc($sReturn);
			}
			
			if ($sReturn =~ /\Q$Configs{EscapeChar}\Edel\s*$/i){
				$sReturn  = '';
			}
			elsif ($sReturn =~ /\Q$Configs{EscapeChar}\E(abort|cancel)\s*$/i){
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
		if ($Configs{Debug} > 1){ logDebug("\nAbort $idSession: $sCommand $sVar");}
			
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

	if ($Configs{Debug} > 1){ logDebug("\nInput $idSession: $sCommand $sVar '".debug_chars($idSession, substr($sPrompt, 0, 20), 0, 1)."'");}
	
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
	my ($idSession) = @_;
	$aSessions[$idSession]->{lowercase_lock} = 1;
    UI_updateStatus();
    return '';
}

sub lc_shift_unlock {
	my ($idSession) = @_;
	$aSessions[$idSession]->{lowercase_lock} = 0;
    UI_updateStatus();
}


# NOTE: $DEL $ABORT $CANCEL were implemented differently directly with a regexp in command_input()


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
	$sLine =~ s/ +/ /gs;      # Make all whitespace a single space character
	
	return $sLine;
}

sub HTTP_get{
	my ($sUrl) = @_;
	
	if ($Configs{Debug} > 1){ logDebug("\nHTTP_get $sUrl ");}
	
	if (!$Modules{'LWP::UserAgent'}->{loaded}){
		if ($Configs{Debug} > 1){ logDebug("ERROR Missing perl module LWP-UserAgent\n");}
		return undef;
	}
	my $oUA = LWP::UserAgent->new();
	$oUA->timeout(10);
	
	$oUA->add_handler(response_header => sub { return HTTP_progress('HEAD', @_);});
	$oUA->add_handler(response_data   => sub { return HTTP_progress('DATA', @_);});
	$oUA->add_handler(response_done   => sub { return HTTP_progress('DONE', @_);});

	my $oResponse = $oUA->get($sUrl);
	
	if ($oResponse->is_success()) {
		my $sContents = $oResponse->decoded_content();
		if ($Configs{Debug} > 1){ logDebug('OK '.length($sContents)."bytes\n");}
		return $sContents;
	}
	else {
		if ($Configs{Debug} > 1){ logDebug('ERROR '.$oResponse->status_line()."\n");}
	 	return undef;
	}
}

sub HTTP_progress{
	my($sEvent, $oResponse, $oUA, $rHash, $sData) = @_;
	if ($sEvent eq 'DATA'){
		UI_showProgress(length($oResponse->{_content}), $oResponse->{_headers}->{'content-length'}, 1);
	}
	elsif($sEvent eq 'HEAD'){
		UI_showProgress(1, $oResponse->{_headers}->{'content-length'}, 1);
	}
	elsif($sEvent eq 'DONE'){
		UI_showProgress(0, undef, 1);
	}
	return 1;
}


sub DOM_process{
	my ($sUrl, $rContainer, $rTitle, $rCleanup, $bShowLinks) = @_;
	
	my $sError = '', my $rDom, my $oTitle, my $oArticle, my $sText, my $sSelector;
	
	if (!$Modules{'HTML::TreeBuilder'}->{loaded}){ 
		$sError = '-- ERROR: This feature requires the HTML-TreeBuilder perl module to be installed.'; 
	}
	
	if (ref($sUrl)){
		$rDom = $sUrl;
	}
	else{
		if ($sUrl =~ /^\d+$/){
			if (defined $Global{Links}->[int($sUrl)]){
				$sUrl = $Global{Links}->[int($sUrl)];
			}
			else{
				$sError = '-- ERROR: Unknown link id';
			}
		}
		
		if (!$sError){
			$rDom = DOM_create($sUrl);
			if (!$rDom){ $sError = '-- ERROR: Could not retrieve page'; }
		}
	}
	
	if (!$sError){
		# Try several locations
		if ($rContainer){
			if (!ref($rContainer)){
				$rContainer = [$rContainer];
			}
		}
		else{
			$rContainer = ['body'];
			#$sError = '-- ERROR: Missing container settings';
		}
		
		if (!$sError){
			foreach $sSelector (@$rContainer){
				$oArticle = DOM_selector($rDom, $sSelector);
				if ($oArticle){ last; }
			}
			if (!$oArticle){ $sError = '-- ERROR: The article does not have suitable text contents';}
		}
		
		if (!$sError){
			if ($rTitle){
				if (!ref($rContainer)){
					$rContainer = [$rContainer];
				}
			}
			else{
				$rTitle = [];
			}
			
			foreach $sSelector (@$rTitle){
				$oTitle = DOM_selector($rDom, $sSelector);
				if ($oTitle){ last; }
			}
			if (!$oTitle){ $oTitle = DOM_selector($oArticle, 'h1'); }
			if (!$oTitle){ $oTitle = DOM_selector($rDom, 'h1'); }
			if (!$oTitle){ $oTitle = DOM_selector($rDom, 'title'); }
			
			if ($oTitle){
				$oArticle->unshift_content(['h1', $oTitle->as_text()]);
				$oTitle->delete();
			}

			if (!defined $rCleanup || ref($rCleanup) != 'ARRAY'){
				$rCleanup = [];
			}
			DOM_cleanup($oArticle, @$rCleanup);
			$sText = DOM_text($oArticle, $bShowLinks, $sUrl);
		}
		
		$rDom->delete();
	}
	
	return wantarray ? ($sText, $sError, $rDom) : ($sError || $sText);
}

sub DOM_create{
	my ($sUrl) = @_;
	
	my $sContents = HTTP_get($sUrl);
	
	if (!$sContents){
		return undef;
	}
	
	my $DOM = HTML::TreeBuilder->new();
	$DOM->no_expand_entities(1);
	$DOM->parse_content($sContents);
	$DOM->elementify();
	
	return $DOM;
}

sub DOM_cleanup{
	my $rDom = shift(@_);
	
	my @aTagCleanup;
	
	push(@aTagCleanup, $rDom->look_down("_tag" => "script"));
	push(@aTagCleanup, $rDom->look_down("_tag" => "object"));
	push(@aTagCleanup, $rDom->look_down("_tag" => "noscript"));
	push(@aTagCleanup, $rDom->look_down("_tag" => "img"));
	
	foreach my $sSelector (@_){
		push(@aTagCleanup, DOM_selector($rDom, $sSelector));
	}
	
	for my $rTag (@aTagCleanup){
		if (defined $rTag){
			$rTag->delete();
		}
	}
}

sub DOM_selector{
	my ($rDom, $sSelector) = @_;
	
	my @aLevels   = split(/\s+/, $sSelector);
	my $bDirect   = 0;

	my @aElements = ref($rDom) eq 'ARRAY' ? @$rDom : ($rDom);
	
	foreach my $sLevel (@aLevels){
		if ($sLevel =~ /^(\w+)?(\#([\w-]+))?(\.(\S+))?(\[(\S+)(=|=~)(\S+)\])?$/){
			my @aParams;

			if (defined $3){ push(@aParams, 'id',    $3);   }			
			if (defined $1){ push(@aParams, '_tag',  $1); }
			if (defined $5){ push(@aParams, 'class', qr/\b$5\b/);}
			if (defined $7 && defined $9){ 
				if ($8 eq '='){
					push(@aParams, $7, $9);
				}
				elsif($8 eq '=~'){
					push(@aParams, $7, qr/$9/);
				}
			}
			
			my @aFound;
			if (@aParams < 2){
				return wantarray ? @aFound : undef;
			}
			
			foreach my $rEl (@aElements){
				if ($rEl){
					if ($bDirect){
						# Direct children only
						push(@aFound, $rEl->look_down(@aParams, '_parent', $rEl));
					}
					else{
						push(@aFound, $rEl->look_down(@aParams));
					}
				}
			}
			
			if (@aFound == 0){
				return wantarray ? @aFound : undef;
			}
			@aElements = @aFound;
			
			$bDirect = 0;
		}
		elsif($sLevel eq '>'){
			$bDirect = 1;
		}
	}
	return wantarray ? @aElements : $aElements[0];
}

sub DOM_selector_simple{
	my ($rDom, $sSelector) = @_;
	
	$sSelector =~ /^\s*(\w+)?(\#([\w-]+))?(\.(\S+))?\s*$/;
	my @aParams;
	
	if (defined $1){ push(@aParams, '_tag', $1); }
	if (defined $3){ push(@aParams, 'id', $3);   }
	if (defined $5){ push(@aParams, 'class', qr/$5/);}
	
	if (@aParams < 2){
		return undef;
	}
	
	return $rDom->look_down(@aParams);
}

sub DOM_text{
	my ($rDom, $bShowLinks, $sBaseUrl) = @_;
	
	my $sText = $rDom->as_HTML(undef, '', {});
	
	$sText =~ s/\s+//s;
	$sText =~ s/\s+$//s;
	$sText =~ s/\s+/ /gs;      # Make all whitespace a single space character
	
	# Special cases (we want to avoid double LF)
	$sText =~ s/<\/p>\s*<p>/\n/gi;
	# Open tags
	$sText =~ s/<title[^>]*>/\n\n--- /gi;
	$sText =~ s/<h1[^>]*>/\n\n--- /gi;
	$sText =~ s/<h2[^>]*>/\n-- /gi;
	$sText =~ s/<h3[^>]*>/\n- /gi;
	$sText =~ s/<tr[^>]*>/\n/gi;
	$sText =~ s/<td[^>]*>/&nbsp;/gi;
	$sText =~ s/<hr[^>]*>/\n------------------------------------------------------------\n/gi;
	$sText =~ s/<(br|p)(\s[^>]*)?>/\n/gi;
	if ($bShowLinks){
		$sText =~ s/<a\s[^>]*href=(['"])([^"]+)\1[^>]*>/&link_get($2, $sBaseUrl, 1)/egi; #'
	}
	
	# Closing tags
	$sText =~ s/<\/h1[^>]*>/ ---\n\n/gi;
	$sText =~ s/<\/title[^>]*>/ ---\n\n/gi;
	$sText =~ s/<\/(p|h2|h3)(\s[^>]*)?>/\n/gi;
	
	$sText =~ s/<[^>]*>//gs;   # Clean HTML tags
	$sText =~ s/&nbsp;/ /gs;   # Convert spaces
	if ($Modules{'HTML::Entities'}->{loaded}){
		$sText = decode_entities($sText);
	}
	else{
		$sText =~ s/&#[0-7]*;//gs; # Clean escaped characters
	}
	return $sText;
}


# Note, this is for XML::DOM not for HTML DOM it is used in METAR XML
# I wonder WHY THE FUCK XML::DOM doesn't have an easy way to do this!
sub DOM_value{
	my ($rNode, $sChild, $sFormat, $sDefault) = @_;
	
	if ($rNode){
		my $rNodes = $rNode->getElementsByTagName($sChild, 0);
		if ($rNodes->getLength() > 0){
			if ($sFormat){
				return sprintf($sFormat, $rNodes->item(0)->getFirstChild()->getNodeValue()); 
			}
			else{
				return $rNodes->item(0)->getFirstChild()->getNodeValue(); 
			}
		}
		return $sDefault;
	}
	return $sDefault;
}

# Obsolete, replaced by DOM based HTML handling
sub html_get_chunk{
	my ($sUrl, $sTagStart, $sTagStop, $rCleanup) = @_;
	
	my $sOut = '';
	my $sContents = HTTP_get($sUrl);
	my $sText    = '';
	my $bCapture = 0;
	foreach my $sLine(split(/\n/, $sContents)) {
		if (!$bCapture && $sLine =~ /$sTagStart/){
			$bCapture = 1;
			$sText .= $sLine;
		}
		elsif($bCapture && $sLine =~ /$sTagStop/){
			$bCapture = 0;
		}
		elsif($bCapture){
			$sText .= $sLine;
		}
	}
	
	my @aCleanup = ('<script(.|\s)+?</script>', '<noscript(.|\s)+?</noscript>','<object(.|\s)+?</object>');
	foreach (@aCleanup){
		$sText =~ s/$_//;
	}
	
	if ($rCleanup){
		foreach (@$rCleanup){
			$sText =~ s/$_//;
		}
	}
	
	$sText = html_decode($sText);
	
	return $sText;
}
# Obsolete, used by html_chunk
sub html_decode{
	my ($sText) = @_;
	$sText =~ s/^\s+//;
	$sText =~ s/\s+$//;
	$sText =~ s/\s+/ /gs;      # Make all whitespace a single space character
	$sText =~ s/<h1[^>]*>/$lf--- /gi;
	$sText =~ s/<\/h1[^>]*>/ ---$lf/gi;
	$sText =~ s/<(br|p|div)(\s[^>]*)?>/$lf/gi;
	$sText =~ s/<[^>]*>//gs;   # Clean HTML tags
	$sText =~ s/&nbsp;/ /gs;   # Convert spaces
	if ($Modules{'HTML::Entities'}->{loaded}){
		$sText = decode_entities($sText);
	}
	else{
		$sText =~ s/&#[0-7]*;//gs; # Clean escaped characters
	}
	return $sText;
}


sub link_get{
	my ($sLink, $sBaseUrl, $bShowLink) = @_;
	if ($sLink =~ /^javascript:/){
		return '';
	}
	elsif ($sLink =~ /^\/\//){
		$sLink = 'http:'.$sLink;
	}
	elsif ($sLink =~ /^\//){
		$sBaseUrl =~ s/^(http:\/\/[^\/]+).*$/$1/;
		$sLink = $sBaseUrl.'/'.$sLink;
	}
	elsif ($sLink =~ /^https?:\/\//){
		# Do nothing, it already is absolute
	}
	else{
		$sBaseUrl =~ s/^(http:\/\/.+\/)[^\/]*$/$1/;
		$sLink = $sBaseUrl.$sLink;
	}
	
	my $nId = array_pos($Global{Links}, $sLink);
	if ($nId > -1){
		return $nId;
	}
	else{
		$nId = scalar @{$Global{Links}};
		$Global{Links}->[$nId] = $sLink;
	}
	return $bShowLink ? " (LNK:$nId)" : $nId;
}


#---------------------------------------------------------------------------
# News
#---------------------------------------------------------------------------

# This sub selects which supported news is used
sub news_article{
	my ($sUrl, $bIsSupported) = @_;
	
	# $bIsSupported is used to know if the URL is supported or not only, without retrieving the page nor doing anything
	
	# REUTERS
	if ($sUrl =~ /^http\:\/\/\w+.reuters.com\//){
		if ($sUrl =~ /-id([A-Z0-9]+)$/){
			if ($bIsSupported){ return 1; }
			return DOM_process("http://www.reuters.com/assets/print?aid=".$1, ['div.printarticle'], [], []);
		}
		else{
			return "-- ERROR: Unrecognized Reuters ID";
		}
	}
	# BBC
	elsif ($sUrl =~ /^http\:\/\/\w+.bbc.co.uk\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl.'?print=true', ['div.story-body', 'div.storybody', 'div#meta-information.emp-decription'], ['h1.story-header'], ['div.share-help', 'div.story-feature','div.videoInStory']);
	}
	# TELAM
	elsif ($sUrl =~ /^http\:\/\/\w+.telam.com.ar\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['div#DetalleNota'], [], ['div.compartir_nota']);
	}
	# AP
	elsif ($sUrl =~ /^http\:\/\/hosted\.ap\.org\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['body'], ['span#entry-content','p.body'], ['table.ap-mediabox-table', 'p.ap-story-p']);
	}
	# SPIEGEL
	elsif ($sUrl =~ /^http\:\/\/\w+\.spiegel\.de\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['div#spArticleColumn'], ['h2'], ['div#spArticleFunctions', 'div#spArticleTopAsset', 'div#spFbTwitterBarStd','div#spArticleFunctionsBottom','div#spSocialBookmark','div.spArticleBottomBox','div.spArticleNewsfeedBox','br.spBreakNoHeight','div.spArticleCredit']);
	}
	# RIA
	elsif ($sUrl =~ /^http\:\/\/\w+\.ria\.ru\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['div#article'], ['h1'], []);
	}
	# TASS
	elsif ($sUrl =~ /^http\:\/\/\w+\.itar-tass\.com\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['div#hypercontext'], ['h3'], []);
	}
	# INTERPRESS
	elsif ($sUrl =~ /^http\:\/\/(\w+\.)?ipsnews\.net\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['span.texto1'], ['span.marron_titulo_big'], []);
	}
	# ANSA
	elsif ($sUrl =~ /^http\:\/\/(\w+\.)?ansa\.it\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['div#content-corpo'], ['div.header-content > h1'], []);
	}
	# UPI
	elsif ($sUrl =~ /^http\:\/\/(\w+\.)?upi\.com\//){
		if ($bIsSupported){ return 1; }
		return DOM_process($sUrl, ['div#sv'], ['div#sv > div.h1'], ['div#sv_tool']);
	}
	# TXT content
	elsif ($sUrl =~ /\.txt$/){
		if ($bIsSupported){ return 1; }
		return HTTP_get($sUrl);
	}
	else{
		if ($bIsSupported){ return 0; }
		return ("-- ERROR: Full news is only supported for AP, Reuters, BBC, TELAM, RIA, Spiegel, INTERPRESS", 1);
	}
}






#---------------------------------------------------------------------------
# Action Commands
#---------------------------------------------------------------------------



# Abort current commands and output
sub do_abort {
	my ($idSession, $sArgs, $bShowAborted) = @_;
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
				if ($thisSession->{PORT}) {
					$thisSession->{PORT}->purge_all();
				}
			}
			
			$sOut = "-- ABORTED session ".$nId." by $idSession";
			if (($bShowAborted || $idSession != $nId) && $thisSession->{status}){
				$thisSession->{OUT} = "$lf-- ABORTED by session $idSession$lf";
				if ($thisSession->{prompt}){
					$thisSession->{OUT} .= "$cr$lf$Configs{SystemPrompt}";
				}
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
			do_abort($idSession, $thisSession->{id}, $bShowAborted);
			if ($thisSession->{status}){
				$nCount++;
			}
		}
		$sOut = "-- ABORTED $nCount sessions";
	}
	elsif ($aArgs[0] =~ /^TTY$/i){
		my $nCount = 0;
		foreach my $thisSession (@aSessions){
			if ($thisSession->{type} eq 'TTY'){
				do_abort($idSession, $thisSession->{id}, $bShowAborted);
				if ($thisSession->{status}){
					$nCount++;
				}
			}
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
	
	if ($Configs{Debug} > 1){ logDebug("\ndo_art $idSession: $sArgs");}

	my $sUrlArgs = $sUrl;
	
	return do_url($idSession, $sUrlArgs, 1);
}


# Get the wheater forecaste for a US city
sub do_weather {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd   = 'WEATHER';
	my @aArgs  = split(/\s+/, $sArgs);
	my $sOut   = '';
	my $bError = 0;
	
	command_start($idSession, $sCmd, 'WEATHER REPORT');

	my $sSourceFeed = $sArgs;
	
	# Get the CITY
	my $sSource = command_input($idSession, 'weather_source', 'LINE', $aArgs[0], '', "Source or Country\a: ", $sCmd);
	if ($sSource eq ''){ return ('', 1); }

	$sSource = uc($sSource);
	
	my $sSourceFeed = $sArgs ? uc($sArgs) : $sSource;
	
	if ($sSourceFeed =~ s/^(\w\w)\s+(\w\w)\s+(\w.+)$/$1.$2.$3/){ # We replace ONLY the first and second space into a dot
		$sSourceFeed =~ s/\s+//g; # We remove subsequent spaces
	}
	elsif ($sSourceFeed =~ s/^(\w\w)\s+(\w.+)$/$1.$2/){ # We replace ONLY the first space into a dot
		$sSourceFeed =~ s/\s+//g; # We remove subsequent spaces
	}
	
	
	if($Configs{'RSS.Feed.WEATHER.'.$sSourceFeed}){
		return do_news($idSession, "WEATHER $sSourceFeed");
	}
	elsif($Configs{'RSS.Feed.WEATHER.'.$sSource}){
		return do_news($idSession, "WEATHER $sSource");
	}
	else{
		if ($sSource =~ /^NOAA|METAR|WWO|GOOGLE|METARLEGACY$/i){
			$sArgs =~ s/^\S+\s+//;
		}
		else{
			$sSource = $Configs{WeatherDefaultSource};
		}
		
		if ($sSource eq 'NOAA' ){
			return do_weather_noaa($idSession, $sArgs);
		}
		elsif ($sSource eq 'METAR'){
			return do_weather_metar($idSession, $sArgs);
		}
		elsif ($sSource eq 'METARLEGACY'){
			return do_weather_metar_legacy($idSession, $sArgs);
		}
		elsif ($sSource eq 'WWO'){
			return do_weather_wwo($idSession, $sArgs);
		}
		elsif ($sSource eq 'GOOGLE'){
			return do_weather_google($idSession, $sArgs);
		}
		else{
			$bError = 1;
			$sOut = '-- ERROR: Unsupported source';
		}
	}

	command_done($idSession, '', '^weather_');
	
	return ($sOut, 0, $bError);
}

sub do_weather_wwo{
	my ($idSession, $sArgs) = @_;
	
	my $sCmd   = 'WEATHER';
	my @aArgs  = split(/\s+/, $sArgs);
	my $sOut   = '';
	my $bError = 0;

	if (!$Modules{'JSON'}->{loaded}){
		return "-- ERROR: perl module JSON missing";
	}
	
	# Please do not steal this free key, you can get your own at their website!
	my $sUrl  = 'http://free.worldweatheronline.com/feed/weather.ashx?q='.URI::Escape::uri_escape($sArgs).'&format=json&num_of_days=5&key=fad451e34f025626121103';

	my $sJSON = HTTP_get($sUrl);
	if (!$sJSON){
		return "-- ERROR: Could not retrieve data from WWO";
	}
	
	my $oReport    = decode_json($sJSON);
	my $rNow       = $oReport->{data}->{current_condition}->[0];
	my $bUseArrows = ($idSession == 0 && $Configs{CopyHostOutput} eq 'OFF') ? 1 : 0;
	my $bCelsius   = 1;
	
	
	$sOut .= sprintf("Current weather for %s: %s\n",      $oReport->{data}->{request}->[0]->{type}, $oReport->{data}->{request}->[0]->{query});
	$sOut .= sprintf(" Time:          %-10s Temp:     %s\n",    $rNow->{observation_time}, $bCelsius ? $rNow->{temp_C}.'C' : $rNow->{temp_F}.'F');
	$sOut .= sprintf(" Humidity:      %-10s Pressure: %s\n", ,  $rNow->{humidity}.'%', $rNow->{pressure}.'mb');
	$sOut .= sprintf(" Precipitation: %-10s Wind:     %s %s %s\n", $rNow->{precipMM}.'mm', $rNow->{winddir16Point}, weather_arrow($rNow->{winddir16Point}, $bUseArrows), $bCelsius ? $rNow->{windspeedKmph}.'Kmph' : $rNow->{windspeedMph}.'Mph');
	$sOut .= sprintf(" Conditions: %s\n",    $rNow->{weatherDesc}->[0]->{value});
	$sOut .= "Forecasts:\n";
	foreach my $rForecast (@{$oReport->{data}->{weather}}){
		$sOut .= sprintf(" %s Low: %-4s High: %-4s Wind: %3s %1s %7s - %s\n",  
			$rForecast->{date},
			$bCelsius  ? $rForecast->{tempMinC}.'C' : $rForecast->{tempMinF}.'F',
			$bCelsius  ? $rForecast->{tempMaxC}.'C' : $rForecast->{tempMaxF}.'F',
			$rForecast->{winddir16Point},
			weather_arrow($rForecast->{winddir16Point}),
			$bCelsius ? $rForecast->{windspeedKmph}.'Kmph' : $rForecast->{windspeedMph}.'Mph ',
			$rForecast->{weatherDesc}->[0]->{value});
	}
	$sOut .= "Source: WWO\n";
	$sOut .= "-- End of WEATHER REPORT --";
	
	command_done($idSession, '', '^weather_');
	return $sOut;
}



sub do_weather_google{
	my ($idSession, $sArgs) = @_;
	
	my $sCmd   = 'WEATHER';
	my @aArgs  = split(/\s+/, $sArgs);
	my $sOut   = '';
	my $bError = 0;

	if (!$Modules{'Weather::Google'}->{loaded}){
		return "-- ERROR: perl module Weather-Google missing";
	}
	
	my $oSvc = new Weather::Google;
	$oSvc->city($sArgs);
	my $rCurrent   = $oSvc->current();
	my @aForecasts;
	$aForecasts[0] = $oSvc->forecast(0);
	$aForecasts[1] = $oSvc->forecast(1);
	$aForecasts[2] = $oSvc->forecast(2);
	$aForecasts[3] = $oSvc->forecast(3);

	my $sUnits    = $oSvc->forecast_information('unit_system') eq 'US' ? 'F' : 'C';
	my $sTemp     = $sUnits eq 'F' ? $rCurrent->{temp_f}.'F' : $rCurrent->{temp_c}.'C';
	my $sHumidity = $rCurrent->{humidity};
	my $sWind     = $rCurrent->{wind_condition};
	
	$sOut = sprintf("Current weather for %s\n Temp: %s\n %s\n %s\n %s\nForecasts:\n", $oSvc->info('city'), $sTemp, $sHumidity, $sWind, $rCurrent->{condition});
	foreach my $rForecast (@aForecasts){
		$sOut .= sprintf(" %s Low: %d%s High: %d%s - %s\n", $rForecast->{day_of_week}, $rForecast->{low}, $sUnits, $rForecast->{high},$sUnits, $rForecast->{condition});
	}
	$sOut .= "Source: GOOGLE\n";
	$sOut .= "-- End of WEATHER REPORT --";
	
	command_done($idSession, '', '^weather_');
	return $sOut;
}


sub weather_wind{
	my ($nDegrees, $bUseArrows) = @_;
	
	my $sWind = $nDegrees;
	if ($nDegrees =~ /^\d{1,3}$/i){
		$nDegrees = int($nDegrees);
		if    ($nDegrees < 15)  { $sWind = "N";  }
		elsif ($nDegrees < 30)  { $sWind = "NNE";}
		elsif ($nDegrees < 60)  { $sWind = "NE"; }
		elsif ($nDegrees < 75)  { $sWind = "ENE";}
		elsif ($nDegrees < 105) { $sWind = "E";  }
		elsif ($nDegrees < 120) { $sWind = "ESE";}
		elsif ($nDegrees < 150) { $sWind = "SE"; }
		elsif ($nDegrees < 165) { $sWind = "SSE";}
		elsif ($nDegrees < 195) { $sWind = "S";  }
		elsif ($nDegrees < 210) { $sWind = "SSW";}
		elsif ($nDegrees < 240) { $sWind = "SW"; }
		elsif ($nDegrees < 265) { $sWind = "WSW";}
		elsif ($nDegrees < 285) { $sWind = "W";  }
		elsif ($nDegrees < 300) { $sWind = "WNW";}
		elsif ($nDegrees < 330) { $sWind = "NW"; }
		elsif ($nDegrees < 345) { $sWind = "NNW";}
		else                    { $sWind = "N";  }
	}
	
	if ($bUseArrows){
		if (defined $aEscapeCharsDecodeASCII{"ARROW$sWind"}){
			return $aEscapeCharsDecodeASCII{"ARROW$sWind"};
		}
		if (defined $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 0, 2)}){
			return $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 0, 2)};
		}
		if (defined $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 1, 2)}){
			return $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 1, 2)};
		}
	}
	
	return $sWind;
}

sub weather_arrow{
	my ($sWind, $bUseArrows) = @_;
	if (defined $bUseArrows && !$bUseArrows){
		return '';
	}
	if (defined $aEscapeCharsDecodeASCII{"ARROW$sWind"}){
		return $aEscapeCharsDecodeASCII{"ARROW$sWind"};
	}
	if (defined $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 0, 2)}){
		return $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 0, 2)};
	}
	if (defined $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 1, 2)}){
		return $aEscapeCharsDecodeASCII{'ARROW'.substr($sWind, 1, 2)};
	}
	return '';
}


sub weather_metar_getStation{
	my ($sStation) = @_;
	
	my $sFile = './tmp/icao-stations.txt';
	
	$sStation = uc($sStation);
	
	if (!defined $Global{'ICAO-STATION'}){
		$Global{'ICAO-STATION'} = {};
	}

	if (defined $Global{'ICAO-STATION'}->{$sStation}){
		return @{$Global{'ICAO-STATION'}->{$sStation}};
	}
	
	if (!(-e $sFile)){
		return '';
	}
	
	# Make the search
	if (open(my $rFile, '<', $sFile)){
		my $sLine;
		while (!eof($rFile)){
			$sLine = <$rFile>;
			if (substr($sLine, 0, 4) eq $sStation){
				chomp($sLine);
				my @aLine = split(';', $sLine);
				close($rFile);
				$Global{'ICAO-STATION'}->{$aLine[0]} = \@aLine;
				return @aLine;
			}
		}
		close($rFile);
	}
	return '';
}

sub weather_metar_convertToHistoric{
	my ($sMetar) = @_;
		
	if (!$Modules{'Geo::METAR'}->{loaded}){
		return '-- ERROR: Perl module Geo-METAR is required for this feature'; 
	}

	my %aClouds = (
		CAVOK => $aEscapeCharsDecodeASCII{WXCLR},
		SKC => $aEscapeCharsDecodeASCII{WXCLR},
		CLR => $aEscapeCharsDecodeASCII{WXCLR},
		SCT => $aEscapeCharsDecodeASCII{WXSCT},
		BKN => $aEscapeCharsDecodeASCII{WXBKN},
		FEW => "-$aEscapeCharsDecodeASCII{WXSCT}",
		OVC => $aEscapeCharsDecodeASCII{WXOVC},
		NSC => $aEscapeCharsDecodeASCII{WXCLR},
		NCD => $aEscapeCharsDecodeASCII{WXCLR}
	);
	my %aWeather = (
		MI => '',   #'shallow',
		PI => '',   #'partial',
		BC => '',   #'patches',
		DR => 'L',  #'drizzle',
		BL => '',   #'blowing',
		SH => 'RW', #'shower(s)',
		TS => 'T',  #'thunderstorm',
		FZ => 'ZL', #'freezing',
		DZ => 'L',  #'drizzle',
		RA => 'R',  #'rain',
		SN => 'S',  #'snow',
		SG => 'SG', #'snow grains',
		IC => 'IC', #'ice crystals',
		PE => 'SP', #'ice pellets',
		GR => 'A',  #'hail',
		GS => 'AP', #'small hail/snow pellets',
		UP => '',   #'unknown precip',
		BR => '',   #'mist',
		FG => 'F',  #'fog',
		PRFG=> 'GF',#'fog banks',  # officially PR is a modifier of FG
		FU => 'K',  #'smoke',
		VA => 'DV', #volcanic ash',
		DU => 'D',  #dust',
		SA => 'BN', #'sand',
		HZ => 'H',  #'haze',
		PY => '',   #'spray',
		PO => 'BD', #'dust/sand whirls',
		SQ => '',   #'squalls',
		FC => 'TORNADO', #'funnel cloud(tornado/waterspout)',
		SS => 'BN', #sand storm',
		DS => 'BD', #dust storm',
		TSRA => 'TR'
	);
	
	my $sOut = '';
	
	my $m = new Geo::METAR();
	#$m->debug(1);
	$m->metar($sMetar);


	my @aOld;
	
	# Station
	push(@aOld, substr($m->{SITE}, 0, 1) eq 'K' ? substr($m->{SITE}, 1) : $m->{SITE});
	
	# Special
	if ($m->{type} eq 'SPECI'){ push(@aOld, 'S1');}
	
	
	push(@aOld, substr($m->{date_time},2,4).'Z');
	
	# Cloud layers and ceiling
	my $sClouds  = '';
	my $sCeiling = '';
	foreach (@{$m->{sky}}){
		if (/^([A-Z]+)(\d*)/){
			my $nFeet = int($2);
			$sClouds .= ($nFeet > 0? $nFeet : '').(defined($aClouds{$1}) ? $aClouds{$1}: $1);
			if (!$sCeiling && ($sCeiling eq 'BKN' || $sCeiling eq 'OVC')){
				$sCeiling = 'M'.int($2).$aClouds{$1};
			}
		}
		else{
			$sClouds .= $_;
		}
	}
	push(@aOld, $sClouds);
	if ($sCeiling){
		push(@aOld, $sCeiling);
	}

	# Visibility
	my $sVisibility = $m->{visibility};
	$sVisibility =~ s/SM$//;
	push(@aOld, $sVisibility);

	# Obstruction to vision
	my $sObstruction = '';
	foreach (@{$m->{weather}}){
		if (substr($_, 0, 1) eq '+' || substr($_, 0, 1) eq '-'){
			$sObstruction .= substr($_, 0, 1, '');
		}
		if (defined $aWeather{$_}){
			$sObstruction .= $aWeather{$_};
		}
		else{
			$sObstruction .= $_;
		}
	}
	if ($sObstruction){
		push(@aOld, $sObstruction);
	}

	# Several parts are not space separated, they come in a chunk
	my $sChunk ='';
	
	# SLP
	my $sPart = $m->{slp};
	$sPart =~ s/^SLP0*//;
	$sChunk .= $sPart.'/';
	# Temp
	$sChunk .= int($m->{TEMP_F}).'/';
	# Dew Point
	$sChunk .= int($m->{DEW_F});
	# Wind
	$sChunk .= weather_arrow($m->{WIND_DIR_ABB}, 1);
	$sChunk .= int($m->{WIND_KTS}).'/';
	# Altimeter
	$sPart = $m->{ALT};
	$sPart =~ s/^[23](\d)\.(\d\d).*$/$1$2/;
	$sChunk .= $sPart;
	
	push(@aOld, $sChunk);
	# End of chunk
	
	if ($m->{REMARKS}){
		my $sRemarks = '';
		foreach (@{$m->{REMARKS}}){
			if (!(/^A0\d\w?$/)){
				$sRemarks .= $sRemarks ? ' '.$_: $_;
			}
		}
		push(@aOld, $sRemarks);
	}
	
	$sOut .= join(' ', @aOld);
	return $sOut;

}

sub do_weather_metar{
	my ($idSession, $sArgs) = @_;
	
	my $sCmd   = 'METAR';
	my @aArgs  = split(/\s+/, $sArgs);
	my $sOut   = '';
	my $bError = 0;
	
	command_start($idSession, $sCmd, 'WEATHER METAR REPORT');
	
	my $nArgs = scalar(@aArgs);
	
	my $sOutput = lc($aArgs[0]);
	if ($sOutput =~ /^standard|readable|translated|detailed|historic|station|search|state|country$/i){
		$sArgs =~ s/^\S+\s*//;
		shift(@aArgs);
	}
	else{
		$sOutput = 'readable';
	}
	
	# Station DB handling commands
	if ($sOutput =~ /^station|search|state|country$/){
		my $sContents;

		my $sTarget = './tmp/icao-stations.txt';
		
		# Download the list
		if (!(-e $sTarget)){
			$sContents = HTTP_get('http://weather.noaa.gov/data/nsd_cccc.txt');
			if ($sContents){
				open(my $rFile, '>', $sTarget);
				print $rFile $sContents;
				close($rFile); 
			}
			else{
				return "-- ERROR: Could not retrieve list of ICAO stations";
			}
		}
		# Make the search
		if (-e $sTarget){
			if (open(my $rFile, '<', $sTarget)){
				my $sLine;
				$sOut = "Searching stations: $sArgs\n\n";
				$sArgs = uc($sArgs);
				my $nResults = 0;
				while (!eof($rFile)){
					$sLine = <$rFile>;
					chomp($sLine);
					my @aLine = split(';', $sLine);
					if (!$sArgs){
						$sOut .= "$aLine[0] $aLine[6] $aLine[5], ".($aLine[4] ? "$aLine[4], " : '')."$aLine[3]\n";
						$nResults++;
					}
					elsif($sOutput eq 'search' && $aLine[3] =~ /$sArgs/i){
						$sOut .= "$aLine[0] $aLine[6] $aLine[5], ".($aLine[4] ? "$aLine[4], " : '')."$aLine[3]\n";
						$nResults++;
					}
					elsif($sOutput eq 'state' && $aLine[4] eq $sArgs){
						$sOut .= "$aLine[0] $aLine[6] $aLine[5], ".($aLine[4] ? "$aLine[4], " : '')."$aLine[3]\n";
						$nResults++;
					}
					elsif($sOutput eq 'country' && $aLine[5] =~ /$sArgs/i){
						$sOut .= "$aLine[0] $aLine[6] $aLine[5], ".($aLine[4] ? "$aLine[4], " : '')."$aLine[3]\n";
						$nResults++;
					}
					elsif($sOutput eq 'station' && $aLine[0] =~ /$sArgs/i){
						$sOut .= "$aLine[0] (WMO:$aLine[1].$aLine[2]) $aLine[6] $aLine[5], ".($aLine[4] ? "$aLine[4], " : '')."$aLine[3]\n";
						$sOut .= "     Lat/Long/Elev: $aLine[7] $aLine[8] $aLine[11] Up Air: $aLine[9] $aLine[10] $aLine[11]\n";
						$nResults++;
					}
				}
				close($rFile);
				$sOut .= "-- DONE: $nResults results\n";
			}
		}
		else{
			return "-- ERROR: Could not retrieve list of ICAO stations";
		}
		return $sOut;
	}
	
	
	my $nHours = 6;
	if ($aArgs[0] =~ /^\d+$/){
		$nHours = int($aArgs[0]);
		$sArgs =~ s/^\S+\s*//;
		shift(@aArgs);
	}
	
	if ($sArgs !~ /^(\w\w\w\w|\w+\*)(\s\w\w\w\w|\s\w+\*)*$/){
		return "-- ERROR: Invalid ICAO station(s)";
	}
	
	my $sEncodedStations = URI::Escape::uri_escape($sArgs);
	
	if ($sOutput eq 'translated'){
		$sOut = "-- WARNING: TRANSLATED mode renamed to DETAILED.\n";
		$sOutput = 'detailed';
	}
	
	if ($sOutput eq 'detailed'){
		# This URL produces lots of output
		my $sUrl = "http://www.aviationweather.gov/adds/metars/?station_ids=$sEncodedStations&std_trans=translated&chk_metars=on&hoursStr=past+$nHours+hours&chk_tafs=on&submitmet=Submit";
		$sOut .= DOM_process($sUrl, ['body'], ['h2']);
		return $sOut;
	}


	if ($sOutput eq 'standard' || $sOutput eq 'readable' || $sOutput eq 'historic'){
		if (!$Modules{'XML::DOM'}->{loaded}){
			return '-- ERROR: Perl module XML-DOM is required for this feature'; 
		}
		
		my $sUrl = "http://weather.aero/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&hoursBeforeNow=$nHours&stationString=$sEncodedStations";
		my $sContents = HTTP_get($sUrl);
		
		$sOut    = "--- METAR provided by ADDS - Aviation Digital Data Service\n\n";
		my $oParser = new XML::DOM::Parser;
		my $oXml    = $oParser->parse($sContents);
		
		my $rNode = $oXml->getFirstChild()->getElementsByTagName('errors', 0)->item(0);
		my @aErrors   = $rNode ? $rNode->getElementsByTagName('error', 0) : ();
		foreach $rNode (@aErrors){
			$sOut .= "-- ERROR: ".$rNode->getFirstChild()->getNodeValue()."\n";
		}
		
		my $rNode = $oXml->getFirstChild()->getElementsByTagName('warnings', 0)->item(0);
		my @aWarnings  = $rNode ? $rNode->getElementsByTagName('warning', 0) : ();
		foreach $rNode (@aWarnings){
			$sOut .= "-- WARNING: ".$rNode->getFirstChild()->getNodeValue()."\n";
		}
		if (@aErrors > 0 || @aWarnings > 0){
			$sOut .= "\n";
		}
		
		my $rData = $oXml->getFirstChild()->getElementsByTagName('data', 0)->item(0);
		
		$sOut .= "Results: ".$rData->getAttributeNode('num_results')->getValue()."\n\n";
		
		my @aMetars = $rData->getElementsByTagName('METAR');
		
		# STANDARD
		if ($sOutput eq 'standard'){
			for my $rMetar (@aMetars){
				$sOut .= $rMetar->getElementsByTagName('raw_text', 0)->item(0)->getFirstChild()->getNodeValue()."\n";
			}
		}
		# HISTORIC
		elsif($sOutput eq 'historic'){
			if (!$Modules{'Geo::METAR'}->{loaded}){
				return '-- ERROR: Perl module Geo-METAR is required for this feature'; 
			}
			for my $rMetar (@aMetars){
				$sOut .= weather_metar_convertToHistoric($rMetar->getElementsByTagName('raw_text', 0)->item(0)->getFirstChild()->getNodeValue())."\n";
			}
		}
		# READABLE
		else{
			for my $rMetar (@aMetars){
				$sOut .= "- METAR ".DOM_value($rMetar, 'raw_text')."\n";
				$sOut .= sprintf(" Station %s %s at %s%s\n", DOM_value($rMetar, 'station_id'), (weather_metar_getStation(DOM_value($rMetar, 'station_id')))[3], DOM_value($rMetar, 'observation_time'), (DOM_value($rMetar, 'metar_type') eq 'SPECI' ? '  SPECIAL' : ''));
				$sOut .= sprintf(" Temp: % 2dC DewPoint: % 2dC Wind: % 3dKT %3s%s\n", DOM_value($rMetar, 'temp_c'), DOM_value($rMetar, 'dewpoint_c'), DOM_value($rMetar, 'wind_speed_kt'), weather_wind(DOM_value($rMetar, 'wind_dir_degrees')), weather_wind(DOM_value($rMetar, 'wind_dir_degrees'), 1));
				$sOut .= sprintf(" Visibility: % 2dSM          Altimeter: %2.3finHG %s\n", DOM_value($rMetar, 'visibility_statute_mi'), DOM_value($rMetar, 'altim_in_hg'), DOM_value($rMetar, 'sea_level_pressure_mb', 'SLP: %smb'));
				$sOut .= " Sky: ";
				my $nCond = 0;
				for my $rCond ($rMetar->getElementsByTagName('sky_condition')){
					my $sBase = $rCond->getAttributeNode('cloud_base_ft_agl');
					$sBase = $sBase ? $sBase->getValue() : '';
					$sOut .= ($nCond ? '      ' : '').$rCond->getAttributeNode('sky_cover')->getValue().($sBase ? " at $sBase ft" : '')."\n";
					$nCond++;
				}
				$sOut .= DOM_value($rMetar, 'wx_string', " Conditions: %s\n");
				$sOut .= "\n";
			}
		}
		return $sOut;
	}

	return "-- ERROR: Invalid output specified";
}


sub do_weather_metar_legacy{
	my ($idSession, $sArgs) = @_;
	
	my $sCmd   = 'METAR';
	my @aArgs  = split(/\s+/, $sArgs);
	my $sOut   = '';
	my $bError = 0;
	
	command_start($idSession, $sCmd, 'WEATHER METAR REPORT');
	
	my $nArgs = scalar(@aArgs);
	
	my $sOutput = lc($aArgs[0]);
	if ($sOutput eq 'standard' || $sOutput eq 'translated' || $sOutput eq 'station' || $sOutput eq 'search'){
		$sArgs =~ s/^\S+\s*//;
	}
	else{
		$sOutput = 'translated';
	}
	
	if ($sOutput eq 'station' || $sOutput eq 'search'){
		my $sContents;
		my $sTarget = './tmp/metar-stations.txt';
		# Download the list
		if (!(-e $sTarget)){
			$sContents = HTTP_get('http://www.aviationweather.gov/static/adds/metars/stations.txt');
			if ($sContents){
				open(my $rFile, '>', $sTarget);
				print $rFile $sContents;
				close($rFile); 
			}
			else{
				return "-- ERROR: Could not retrieve list of ICAO stations";
			}
		}
		# Make the search
		if (-e $sTarget){
			if (open(my $rFile, '<', $sTarget)){
				my $sLine;
				$sOut = "Searching stations: $sArgs\n\n";
				$sArgs = uc($sArgs);
				while (!eof($rFile)){
					$sLine = <$rFile>;
					chomp($sLine);
					if (!$sArgs || ($sOutput eq 'search' && (substr($sLine, 0, 1) eq '!') || $sLine =~ /$sArgs/) || ($sOutput eq 'station' && substr($sLine, 20, 4) eq $sArgs)){
						$sOut .= "$sLine\n";
					}
				}
				close($rFile);
			}
		}
		else{
			return "-- ERROR: Could not retrieve list of ICAO stations";
		}
		return $sOut;
	}
	
	my $nHours = 6;
	if ($aArgs[1] =~ /^\d+$/){
		$nHours = int($aArgs[1]);
		$sArgs =~ s/^\S+\s*//;
	}
	
	if ($sArgs !~ /^(\w\w\w\w|\w+\*)(\s\w\w\w\w|\s\w+\*)*$/){
		return "-- ERROR: (LEGACY COMMAND) Invalid ICAO station(s)";
	}
	
	my $sEncodedStations = URI::Escape::uri_escape($sArgs);
	
	

	if ($sOutput eq 'standard' || $sOutput eq 'translated'){
		my $sUrl = "http://www.aviationweather.gov/adds/metars/?station_ids=$sEncodedStations&std_trans=$sOutput&chk_metars=on&hoursStr=past+$nHours+hours&chk_tafs=on&submitmet=Submit";
		return DOM_process($sUrl, ['body'], ['h2'], []);
	}
	
	return "-- ERROR: (LEGACY COMMAND) Invalid output specified";
}

# Get the wheater forecaste for a US city
sub do_weather_noaa {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'NOAA';

	command_start($idSession, $sCmd, 'WEATHER NOAA REPORT');
	
	# Get the CITY
	my $sCity = command_input($idSession, 'weather_city', 'LINE', $sArgs, '', "State and City\a: ", $sCmd);
	if ($sCity eq ''){ return ('', 1); }
	
	my $bIsClimate = 0;
	if ($sCity =~ /^CLIMATE\s/i){
		$bIsClimate = 1;
		$sCity =~ s/^\w+\s+//;
	}
	
	if ($sCity !~ /^\w\w(\s|\/)\w/){
		return ("-- ERROR: NOAA requires the following: SC City name", 0, 1);
	}

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
	
	my $sUrlArgs = ($bIsClimate ? $Configs{WeatherNoaaClimateBase} : $Configs{WeatherNoaaForecastBase}).$sCity;
	
	return do_ftp($idSession, $sUrlArgs, 1);
}

sub do_web {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'WEB';

	my @aArgs = split(/\s+/, $sArgs);
	
	command_start($idSession, $sCmd, 'WEB');

	# Get the URL
	my $sUrl = command_input($idSession, 'web_url', 'LINE', $aArgs[0], '', "\aURL: ", $sCmd);
	if ($sUrl eq ''){ return ('', 1); }
	
	if ($sUrl =~ /^\d+$/){
		if (defined $Global{Links}->[int($sUrl)]){
			$sUrl = $Global{Links}->[int($sUrl)];
		}
		else{
			return ("-- ERROR: That link id is not in the detected links", 0, 1);
		}
	}
	
	if ($sUrl !~ /^\w+\:\/\//){
		$sUrl = 'http://'.$sUrl;
	}

	my ($sContents, $sError, $rDom) = DOM_process($sUrl, ['body'], ['title'], [], 1);

	if ($sError){
		return ($sError, 0, 1);
	}
	else{
		command_done($idSession, '', '^web_');
		return ($sContents."\n-- DONE --", 0, 0);
	}
}

# Get a URL and show its contents, also used as a utility function
sub do_url {
	my ($idSession, $sArgs, $bNoTitle) = @_;
	my $sCmd = 'URL';

	my @aArgs = split(/\s+/, $sArgs);
	
	if ($Configs{Debug} > 1){ logDebug("\ndo_url $idSession: $sArgs");}
	
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
	
	if ($sUrl =~ /^\d+$/){
		if (defined $Global{Links}->[int($sUrl)]){
			$sUrl = $Global{Links}->[int($sUrl)];
		}
		else{
			return ("-- ERROR: That link id is not in the detected links", 0, 1);
		}
	}
	
	if (!$bNoTitle && !$sTarget){
		# Make sure the OUT buffer is empty before proceeding
		my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Loading...\n\n", $sCmd);
		if ($bReady eq ''){ return ('', 1); }
	}
	
	if ($sUrl !~ /^\w+\:\/\//){
		$sUrl = 'http://'.$sUrl;
	}

	my $sContents = HTTP_get($sUrl);
	
	if ($sContents) {
		$aSessions[$idSession]->{VARS}->{'url'}   = '';
		$aSessions[$idSession]->{VARS}->{'ready'} = '';
		
		command_done($idSession);
	
		if ($sTarget){
			if ($sTarget =~ /^FILE:/i){
				$sTarget =~ s/^FILE://i;
				if ($Configs{Debug} > 1){ logDebug("\nSaving to file $sTarget from $sUrl");}
				open(my $rFile, '>', $sTarget);
				print $rFile $sContents;
				close($rFile); 
				return ("-- DONE: File Saved ".length($sContents)." bytes", 0, 0);
			}
			else{
				message_send('SYS', $sTarget, $sContents);
			}
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


# Get a File by FTP and show its contents, also used as a utility function
sub do_ftp {
	my ($idSession, $sArgs, $bNoTitle) = @_;
	my $sCmd = 'FTP';

	my @aArgs = split(/\s+/, $sArgs);
	
	if ($Configs{Debug} > 1){ logDebug("\ndo_ftp $idSession: $sArgs");}
	
	$bNoTitle = defined($bNoTitle) ? int($bNoTitle) : (defined($aArgs[2]) ? int($aArgs[2]) : 0);

	my $sUrl    = defined($aArgs[0]) ? $aArgs[0] : '';
	my $sTarget = defined($aArgs[1]) ? $aArgs[1] : ''; # Target Session

	my $sOut    = '';
	my $sContents = '';
	
	if ($bNoTitle){
		$aSessions[$idSession]->{command_calls}++;
	}
	else{
		command_start($idSession, $sCmd, 'RETRIEVE FTP FILE');
	}

	# Get the URL
	my $sUrl = command_input($idSession, 'url', 'LINE', $sUrl, '', "\aSERVER: ", $sCmd);
	if ($sUrl eq ''){ return ('', 1); }

	if ($sUrl =~ /^ftp:\/\/(.+?)\/(.+\/)(.*)$/i){
		
		if (!$bNoTitle){
			# Make sure the OUT buffer is empty before proceeding
			my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Loading...\n\n", $sCmd);
			if ($bReady eq ''){ return ('', 1); }
		}

		
		my $sServer   = $1;
		my $sDir      = $2;
		my $sFile     = $3;
		my $sTmpFile  = time();
		
    my $oFTP = Net::FTP->new($sServer, Debug => 0);
    if (!$oFTP){
    	$sOut = "-- ERROR: Cannot connect to FTP: ".$sServer;
    }
    elsif (!$oFTP->login("anonymous",'anonymous@example.com')){
    	$sOut = "-- ERROR: Cannot login to FTP: ".$oFTP->message;
    }
    elsif ($sDir && !$oFTP->cwd('/'.$sDir)){
    	$sOut = "-- ERROR: Cannot change FTP directory: ".$oFTP->message;
    }
		elsif(!$oFTP->pasv()){    
    	$sOut = "-- ERROR: Cannot switch to PASV: ".$oFTP->message;
		}
		else{
			if ($sFile eq '' || $sFile eq '*'){
				my @aFiles = $oFTP->ls($sFile ? $sFile : '*');
				$sContents = join("", @aFiles);
			}
			else{
				if(!$oFTP->get($sFile, $sTmpFile)){
	    		$sOut = "-- ERROR: Cannot download file: ".$oFTP->message;
				}
				elsif (!open(my $TMPFILE, '<', $sTmpFile)) {
					$sOut = "-- ERROR: Could not open temporary file $sTmpFile";
				}
				else {
					$sContents = join("", <$TMPFILE>);
					close($TMPFILE);
					unlink($sTmpFile);
				}
			}
		}
    $oFTP->quit();
	}
	else{
		$sOut = "-- ERROR: Invalid FTP format $sUrl";
	}


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
	
		command_done($idSession);
	
		if (!$sOut){
			$sOut = "-- ERROR: Cannot download FTP URL --";
		}
	
		return ($sOut, 0, 1);
	}
}

# EVAL a perl sentence
sub do_eval {
	my ($idSession, $sArgs, $sArgsOriginal) = @_;
	
	my $sCmd = 'EVAL';
	
	my $sOut = '';
	if ($sArgs ne ''){
		$sOut = eval($sArgs);
		if ($@){
			$sOut .= "-- ERROR:\n$@\n";
		}
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
					$sOut .= sprintf(" %15s: (%d) %s\n", $sKey, length($aSessions[$idSessCheck]->{$sKey}), debug_chars($idSessCheck, substr($aSessions[$idSessCheck]->{$sKey}, 0, 20), 0, 1));
				}
				elsif ($sKey eq 'RAW_IN' || $sKey eq 'RAW_OUT' || $sKey eq 'eol'){
					$sOut .= sprintf(" %15s: (%d) %s\n", $sKey, length($aSessions[$idSessCheck]->{$sKey}), debug_chars($idSessCheck, substr($aSessions[$idSessCheck]->{$sKey}, 0, 20), 1, 1));
				}
				elsif ($sKey eq 'VARS'){
					foreach my $sVar (sort keys %{$aSessions[$idSessCheck]->{VARS}}){
						$sOut .= sprintf(" %15s: HASH %d\n", $sKey, %{$aSessions[$idSessCheck]->{$sKey}});
						if ($aSessions[$idSessCheck]->{VARS}->{$sVar} ne ''){
							$sOut .= sprintf(" %20s: %s\n", 'VARS.'.$sVar, substr($aSessions[$idSessCheck]->{VARS}->{$sVar}, 0, 30));
						}
					}
				}
				elsif ($sKey eq 'commands'){
					foreach my $sVar (sort keys %{$aSessions[$idSessCheck]->{VARS}}){
						$sOut .= sprintf(" %15s: HASH %d\n", $sKey, %{$aSessions[$idSessCheck]->{$sKey}});
						if ($aSessions[$idSessCheck]->{VARS}->{$sVar} ne ''){
							$sOut .= sprintf(" %20s: %s\n", 'VARS.'.$sVar, substr($aSessions[$idSessCheck]->{VARS}->{$sVar}, 0, 30));
						}
					}
				}
				elsif ($sKey eq 'rx_last' || $sKey eq 'time_start'){
					my $nVal = $aSessions[$idSessCheck]->{$sKey};
					if ($nVal > 0){
						$sOut .= sprintf(" %15s: %d (%s - %d ago)\n", $sKey, $nVal, get_datetime($nVal), time() - $nVal);
					}
					else{
						$sOut .= sprintf(" %15s: %d (never)\n", $sKey, $nVal);
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


sub do_suppress{
	my ($idSession, $sArgs) = @_;
	my $sCmd     = 'SUPPRESS';
	my @aArgs    = split(/\s+/, $sArgs);
	my $sOut     = '';
	my $thisSession = $aSessions[$idSession];
	if ($thisSession->{type} ne 'TTY'){
		$sOut = '-- ERROR: The command is only valid for TTY sessions';
	}
	elsif (!defined $aArgs[0]){
		$sOut = "TTY.$idSession.LoopSuppress: ".($Configs{"TTY.$idSession.LoopSuppress"} ? 'ON' : 'OFF');
	}
	elsif ($aArgs[0] !~ /^(0|1|ON|OFF)$/i){
		$sOut = '-- ERROR: You must specify ON or OFF';
	}
	elsif (defined $aArgs[2] && (!defined $thisSession->{VARS}->{echo_test_key} || $thisSession->{VARS}->{echo_test_key} ne $aArgs[2])){
		# Don't do anything, keep silent, the command was really intended for another host
		$sOut = '';
	}
	else{
		config_set("TTY.$idSession.LoopSuppress", ($aArgs[0] eq '1' || uc($aArgs[0]) eq 'ON') ? 1 : 0);
		
		$sOut = "TTY.$idSession.LoopSuppress: ".($Configs{"TTY.$idSession.LoopSuppress"} ? 'ON' : 'OFF');
		
		$thisSession->{VARS}->{echo_test_key} = undef;
		
		if (defined $aArgs[1] && $aArgs[1] =~ /^\d+$/){
			if ($aSessions[int($aArgs[1])]->{VARS}->{'echo_test_target'} eq $idSession){
				# Notify the given session
				message_deliver('SYS', $aArgs[1], "-- Session $idSession has enabled Loop Echo Suppression", 0, 1, 0);
				$aSessions[int($aArgs[1])]->{VARS}->{'echo_test_target'} = undef;
			}
		}
		
		if (defined $thisSession->{VARS}->{echo_test_runinprotect}){
			config_set("RunInProtect", $thisSession->{VARS}->{echo_test_runinprotect});
			delete $thisSession->{VARS}->{echo_test_runinprotect};
		}
		if (defined $thisSession->{VARS}->{echo_test_prompt}){
			config_set("TTY.$idSession.Prompt", $thisSession->{VARS}->{echo_test_prompt});
			delete $thisSession->{VARS}->{echo_test_prompt};
		}
		if (defined $thisSession->{VARS}->{echo_test_label}){
			config_set("TTY.$idSession.Label", $thisSession->{VARS}->{echo_test_label});
			delete $thisSession->{VARS}->{echo_test_label};
		}
		
	}
	return $sOut;
}

# Send a message and see if it replies back
sub do_echotest{
	my ($idSession, $sArgs) = @_;
	my $sCmd     = 'ECHOTEST';
	my @aArgs    = split(/\s+/, $sArgs);
	my $sOut     = '';
	
	my $idTarget = defined $aArgs[0] && $aArgs[0] =~ /^\d+$/ ? int($aArgs[0]) : 0;
	
	if (!$idTarget){
		$sOut = '-- ERROR: You must provide the numeric id of the target session to be tested';
	}
	elsif(!$aSessions[$idTarget]->{status}){
		$sOut = "-- ERROR: Session $idTarget is disconnected";
	}
	else{
		my $targetSession = $aSessions[$idTarget];
		# We disable the interfase suppress
		if ($targetSession->{type} eq 'TTY'){
			config_set("TTY.$idTarget.LoopSuppress", 0);
			config_set("TTY.$idTarget.Echo", 0);
			$targetSession->{VARS}->{echo_test_runinprotect} =  $Configs{RunInProtect};
			config_set("RunInProtect", 0);
			$targetSession->{VARS}->{echo_test_prompt} =  $Configs{"TTY.$idTarget.Prompt"};
			config_set("TTY.$idTarget.Prompt", 0);
			$targetSession->{VARS}->{echo_test_label} =  $Configs{"TTY.$idTarget.Label"};
			config_set("TTY.$idTarget.Label", 0);
		}
		else{
			session_set($idTarget, 'echo_input', 0);
		}
		
		$aSessions[$idSession]->{VARS}->{echo_test_target} =  $idTarget;
		$targetSession->{VARS}->{echo_test_key}     =  time();
		
		$targetSession->{VARS}->{OUT} =  '';
		$targetSession->{VARS}->{RAW_OUT} =  '';
		
		if ($targetSession->{type} eq 'TTY' && $targetSession->{PORT} && serial_wait($targetSession->{PORT})){
			$targetSession->{PORT}->write($targetSession->{eol});
			sleep(1);
		}
		message_deliver('SYS', $idTarget, $Configs{EscapeChar}."SUPPRESS ON $idSession ".$targetSession->{VARS}->{'echo_test_key'}, 0, 1, 1);
		
		$sOut = 'Testing... If it does not reply there is no echo in the loop.';
		
	}
	
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

		if (substr($sMsg, 0, 1) eq $Configs{EscapeChar}){
			# Remote command (Line starts with $$)
			if (substr($sMsg, 1, 1) eq $Configs{EscapeChar}){
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
		elsif($rv == -1){
			$sOut = "-- ERROR: Target's source filtering does not allow message"; 
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
sub UI_do_sendfile{
	my $sFile = Tkx::tk___getOpenFile();
	if ($sFile){
		host_add_text('SENDFILE 1 '.$sFile);
	}
}

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

	if (!open(my $FH, '<', $sFile)) {
		$sOut = "-- ERROR: Could not open file $sFile";
	}
	else {
		my $sMsg = join("",<$FH>);
		close($FH);
		
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
		my $sVar   = $aArgs[0];
		
		my $bAllowNew = 0;
		my $bFound    = 0;
		
		if (substr($sVar, 0, 1) eq '+'){
			$bAllowNew = 1;
			$sVar = substr($sVar, 1);
		}
		$sVar      =~ s/\-/_/g;
		
		my $sValue = $sArgs;
		$sValue    =~ s/^[\w\-\.]+\s+//;
		
		my $sVarUC = uc($sVar);
		foreach my $sKey (keys %Configs){
			if ($sVarUC eq uc($sKey)){
				config_set($sKey, $sValue);
				$bFound = 1;
				last;
			}
		}
		
		if (!$bFound && $bAllowNew){
			config_set($sVar, $sValue);
			$bFound = 1;
		}
		
		if (!$bNoOutput){
			if ($bFound){
				$sOut = '-- DONE --';
			}
			else{
				$sOut = '-- ERROR: Setting not found';
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
	foreach my $sKey (sort keys %Configs){
		if ($sSearch eq '' || $sKey =~ /^$sSearch/i){
			if ($sSearch eq '' && length($Configs{$sKey}) > 38){
				$sOut .= sprintf(" %18s: %s... (%d)\n", $sKey, substr($Configs{$sKey}, 0, 38), length($Configs{$sKey}));
			}
			else{
				$sOut .= sprintf(" %18s: %s\n", $sKey, $Configs{$sKey});
			}
		}
	}
	$sOut .= "-- DONE --";
	
	return $sOut;
}

# Change configs for serial port
sub do_port{
	my ($idSession, $sArgs, $bNoOutput) = @_;
	my $sCmd = 'PORT';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (!defined($aArgs[0]) || !defined($aArgs[1]) || !defined($aArgs[2])){
		return '-- ERROR: Usage: PORT PORTNUM BAUD WordParityStop CODE (optional)';	
	}
	
	$aArgs[1] = uc($aArgs[1]); # Baud
	$aArgs[2] = uc($aArgs[2]); # Word
	
	if (!defined($aBaudRates{$aArgs[1]}) && !defined($aBaudRates{'BAUD'.$aArgs[1]})){
		return '-- ERROR: Unknown Baud Rate';	
	}

	if($aArgs[2] !~ /^[5678][NOE][12]$/){
		return '-- ERROR: Unknown word parameters, use (5,6,7,8)(N,E,O)(1,2)';	
	}

	if(defined($aArgs[3]) && !defined($CODES{uc($aArgs[3])})){
		return '-- ERROR: Unknown CODE';
	}

	if (!defined($aBaudRates{$aArgs[1]}) && defined($aBaudRates{'BAUD'.$aArgs[1]})){
		$aArgs[1] = 'BAUD'.$aArgs[1];
	}
	
	if (defined($aBaudRates{$aArgs[1]})){
		config_set('TTY.1.BaudRate', $aArgs[1], 0, 1);
		config_set('TTY.1.Divisor',  $aBaudRates{$aArgs[1]}->{divisor}, 0, 1);
	}
	elsif($aArgs[1] =~ /^\d+$/){
		config_set('TTY.1.BaudRate', '', 0, 1);
		config_set('TTY.1.Divisor', int($aArgs[1]), 0, 1);
	}
	else{
		return '-- ERROR: Unsupported BaudRate';	
	}
	
	config_set('TTY.1.Divisor', defined($aBaudRates{$aArgs[1]}) ? $aBaudRates{$aArgs[1]}->{divisor} : $aBaudRates{'BAUD'.$aArgs[1]}->{divisor}, 0, 1);
	config_set('TTY.1.Port',    $bWindows ? 'COM'.int($aArgs[0]).':' : '/dev/ttyS'.int($aArgs[0]), 0, 1);
		
	$aArgs[2] =~ /^([5678])([NOE])([12])$/;
	config_set('TTY.1.DataBits', int($1), 0, 1);
	config_set('TTY.1.Parity',   $2 eq 'N' ? 'none' : ($2 eq 'E' ? 'even' : 'odd'), 0, 1);
	config_set('TTY.1.StopBits', int($3), 0, 1);

	if (defined($aArgs[3])){
		config_set('TTY.1.Code', uc($aArgs[3]), 0, 1);
	}
	
	serial_init(1);
	
	return "-- OK: Changed to port $Configs{'TTY.1.Port'} Div:$Configs{'TTY.1.Divisor'} $aArgs[2] $Configs{'TTY.1.Code'}";
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
		elsif($sPass ne $Configs{SystemPassword} && $sPass ne $Configs{GuestPassword}){
			$sOut = '-- Invalid username or password';
		}
		else{
			if (!defined $idSession){
				# We use this value as a flag
				$sOut = 'OK';
			}
			else{
				$aSessions[$idSession]->{auth} = $sPass eq $Configs{SystemPassword} ? 3 : 2;
				$aSessions[$idSession]->{user} = $sUser;
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

sub do_about {
	my ($idSession, $sArgs) = @_;

	if ($idSession == 0){
		Tkx::tk___messageBox(
			-parent => $oTkMainWindow,
			-title => "About HeavyMetal",
			-type => "ok",
			-icon => "info",
			-message => $sAboutMessage
		);
		return "";
	}
	else{
		return wrap("", "", $sAboutMessage);
	}
}

# Tell me a joke
sub do_joke{
	my ($idSession, $sArgs) = @_;
	$nCurrentJoke = (($nCurrentJoke + 1) >= scalar @aJokes) ? 0 : $nCurrentJoke + 1;
	return wrap("", "", '- '.$aJokes[$nCurrentJoke]);
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


	if (!$Modules{'MSN'}->{loaded} || !$Modules{'Crypt::SSLeay'}->{loaded}){
		return ('-- ERROR: MSN perl module or dependencies not loaded', 0, 1);
	}
	
	my $sMsg;
	
	# STATUS?
	if (!defined($aArgs[0])){
		if (!$Configs{MsnEnabled}){
			$sOut  = '-- MSN is Disabled';
		}
		elsif (!$MsnConnected){
			$sOut  = '-- MSN is not connected';
		}
		elsif($aSessions[$idSession]->{target} =~ /^MSN:/){
			$sOut  = '-- MSN is connected as '.$Configs{MsnUsername}.' in chat with '.substr($aSessions[$idSession]->{target}, 4);
		}
		else{
			$sOut  = '-- MSN is connected as '.$Configs{MsnUsername};
		}
	}
	# ON|OFF
	elsif ($aArgs[0] =~ /^(ON|OFF|0|1)$/i){
		my $bEnable = ($aArgs[0] =~ /^(ON|1)$/i) ? 1 : 0;
		$MsnConnectBy = $idSession;
		$sOut = msn_toggle($bEnable);
	}
	elsif (!$Configs{MsnEnabled}){
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
				if ($oMSN->{Notification}->{Lists}->{FL}->{$_}->{Status} eq 'OFF'){
					$sOut = "-- User $_ is offline";
				}
				else{
					($sOut) = do_target($idSession, 'MSN:'.$_);
				}
				last;
			}
		}
		if (!$sOut){
			$sOut = '-- Contact not found in your contacts list. Use $MSN LIST';
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
		config_set('Debug', ($aArgs[0] =~ /^(ON)$/i) ? 1 : 0);
		$sOut = "-- Debug: $Configs{Debug}";
	}
	elsif (defined($aArgs[0])  && $aArgs[0] =~ /^(0|1|2|3)$/i){
		config_set('Debug', int($aArgs[0]));
		$sOut = "-- Debug: $Configs{Debug}";
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
		$sOut .= sprintf("-- Debug: %d File: %s Socket: %s", $Configs{Debug}, $sDebugFile, ($rDebugSocket ? 'Yes' : 'No'));
	}

	return $sOut;
}

# Switch prompt ON and OFF
sub do_prompt {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'PROMPT';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (defined($aArgs[0]) && $aArgs[0] =~ /^(ON|OFF|0|1)$/i){
		$aSessions[$idSession]->{'prompt'} = ($aArgs[0] =~ /^(ON|1)$/i) ? 1 : 0;
		$sOut = "-- New Prompt: ".($aSessions[$idSession]->{'prompt'} ? 'ON' : 'OFF');
	}
	else{
		$sOut = "-- Prompt: ".($aSessions[$idSession]->{'prompt'} ? 'ON' : 'OFF').($aArgs[0] ne '' ? ' (Unrecognized new value)' : '');
	}
	return $sOut;
}


# Switch echo ON and OFF
sub do_echo {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'ECHO';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';
	
	if (defined($aArgs[0]) && $aArgs[0] =~ /^(ON|OFF|0|1)$/i){
		$aSessions[$idSession]->{'echo_input'} = ($aArgs[0] =~ /^(ON|1)$/i) ? 1 : 0;
		$sOut = "-- New Echo: ".($aSessions[$idSession]->{'echo_input'} ? 'ON' : 'OFF');
	}
	else{
		$sOut = "-- Echo: ".($aSessions[$idSession]->{'echo_input'} ? 'ON' : 'OFF').($aArgs[0] ne '' ? ' (Unrecognized new value)' : '');
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
		$sOut  = '-- Your current Source is: '.$aSessions[$idSession]->{source}.$lf;
		$sOut .= '-- Your current Target is: '.$aSessions[$idSession]->{target}.$lf;
	}			
	elsif($aArgs[0] =~ /^ALL$/i){
		# Restore back to ALL
		my $sOutTarget = '';
		my $sOutSource = '';

		($sOutTarget) = do_target($idSession, $aArgs[0]);
		($sOutSource) = do_source($idSession, $aArgs[0]);
		
		$sOut .= $sOutSource.$lf.$sOutTarget;
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
				my $sMsg = sprintf('-- User %s from session %d wants to chat. Use %sCHAT %d', $idSession, $aSessions[$idSession]->{user}, $Configs{EscapeChar}, $idSession);
				message_send('SYS', $aArgs[0], $sMsg);
				$sOut = $sOutSource.$lf.$sOutTarget;
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
	my $sOut  = "-- PIPE READY: $Configs{SystemName} --";

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

				$aSessions[$xTarget]->{auth}   = 1;
				$aSessions[$xTarget]->{source} = 'ALL';
				$aSessions[$xTarget]->{target} = 'ALL';
				$aSessions[$xTarget]->{label}  = 1;
				
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

sub do_invert {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'INVERT';
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut = '';

	if (defined($aArgs[0]) && $aArgs[0] =~ /^\d+$/){
		my $xTarget    = int($aArgs[0]);
		my $sDirection = defined($aArgs[1]) ? uc($aArgs[1]) : '';
		my $nVal    = session_get($xTarget, 'direction');
		if (defined $nVal){
			if ($sDirection eq ''){
				# Invert direction
				$aSessions[$xTarget]->{direction} = $aSessions[$xTarget]->{direction} ? 0 : 1;
				# AUTH, for outbound = 0 / for inbound = 3
				$aSessions[$xTarget]->{auth}      = $aSessions[$xTarget]->{direction} ? 0 : 3;
				$sOut = '-- Session $xTarget is now '. ($aSessions[$xTarget]->{direction} ? 'OUTBOUND' : 'INBOUND');
			}
			elsif($sDirection eq 'IN'){
				# Inbound
				$aSessions[$xTarget]->{direction} = 0;
				$aSessions[$xTarget]->{auth}      = 3;
				$sOut = '-- Session $xTarget is now '. ($aSessions[$xTarget]->{direction} ? 'OUTBOUND' : 'INBOUND');
			}
			elsif($sDirection eq 'OUT'){
				# Outbound
				$aSessions[$xTarget]->{direction} = 1;
				$aSessions[$xTarget]->{auth}      = 0;
				$sOut = '-- Session $xTarget is now '. ($aSessions[$xTarget]->{direction} ? 'OUTBOUND' : 'INBOUND');
			}
			else{
				$sOut = '-- Unknown direction, use IN or OUT. Leave empty to invert';
			}
		}
		else{
			$sOut = '-- Session not found. Check with command LIST';
		}
	}
	else{
		$sOut = '-- Missing session ID. Usage: INVERT ID (IN,OUT)';
	}
	return $sOut;
}

sub do_logout{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'LOGOUT';
	
	if ($aSessions[$idSession]->{type} eq 'TELNET'){
		# Make sure the OUT buffer is empty before proceeding
		my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "Bye Bye!\n", $sCmd);
		if ($bReady eq ''){ return ('', 1); }
	
		telnet_close($aSessions[$idSession]->{SOCKET}, "CMD exit");
		
		return '';
	}
	else{
		return '-- ERROR: This command is for TELNET sessions only';
	}
}



sub do_twitter {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);

	my $sCmd = 'TWITTER';
	command_start($idSession, $sCmd, 'TWITTER');
	
	if (!$Modules{'XML::RSS::Parser'}->{loaded}){
		return ("-- ERROR: Perl module XML-RSS-Parser is missing", 0, 1);
	}

	# Get the feed
	my $sAccount = command_input($idSession, 'news_account', 'LINE', $aArgs[0], '^\w+$', "\aAccount: ", $sCmd, 1);
	if ($sAccount eq ''){ return ('', 1); }


	return do_news($idSession, "TITLES http://api.twitter.com/1/statuses/user_timeline.rss?screen_name=$sAccount", 1, 1);
}


# !!! This commands should be made asynch so host can continue operations while retrieving msgs
sub do_news {
	my ($idSession, $sArgs, $bNoTitle, $bNoLinks) = @_;
	my @aArgs = split(/\s+/, $sArgs);

	my $sCmd = 'NEWS';
	command_start($idSession, $sCmd, 'NEWS');
	
	if (!$Modules{'XML::RSS::Parser'}->{loaded}){
		return ("-- ERROR: Perl module XML-RSS-Parser is missing", 0, 1);
	}

	if (defined $bNoTitle){
		$aSessions[$idSession]->{VARS}->{news_notitle} = $bNoTitle;
	}

	my $sOutput;
	my $sFeed;
	my $sUrl;
	
	# If the case is simple directly route to SUMMARY
	if (@aArgs == 1 && exists $Configs{'RSS.Feed.'.uc($aArgs[0])}){
		$sOutput = 'SUMMARY';
		$sFeed   = $aArgs[0];
	}
	else{
		$sOutput = $aArgs[0];
		$sFeed   = $aArgs[1];
	}
	
	$sOutput = command_input($idSession, 'news_output', 'LINE', $sOutput, '^(\d+|ITEM|LIST|FULL|SUMMARY|TITLES|SEARCH|WEATHER)$', "\aOption (LIST,TITLES,SUMMARY,FULL,ITEM,SEARCH): ", $sCmd, 1);
	if ($sOutput eq ''){ return ('', 1); }

	# LIST Feeds
	if ($sOutput eq 'LIST'){
		return do_news_list($idSession, '');
	}

	# ITEM (ARTICLE)
	if ($sOutput =~ /^\d+$/){
		return do_news_item($idSession, $sOutput);
	}
	if ($sOutput eq 'ITEM'){
		my $sId = command_input($idSession, 'news_item', 'LINE', $aArgs[1], '^\d+$', "\aLink ID: ", $sCmd);
		if ($sId eq ''){ return ('', 1); }
		
		return do_news_item($idSession, $sId);
	}
	
	# Get the feed
	$sFeed = command_input($idSession, 'news_feed', 'LINE', $sFeed, '^([\w\.-]+$|http:\/\/)', "\aRSS Feed Name or URL: ", $sCmd);
	if ($sFeed eq ''){ return ('', 1); }
	
	if ($sOutput eq 'WEATHER'){
		$sFeed = 'WEATHER.'.$sFeed;
	}
	
	if ($sFeed =~ /^[\w\.-]+$/){
		$sFeed = uc($sFeed);
		if (exists $Configs{"RSS.Feed.$sFeed"}){
			$sUrl = $Configs{"RSS.Feed.$sFeed"};
		}
		else{
			return ("-- ERROR: RSS Feed $sFeed not configured", 0, 1);
		}
	}
	else{
		$sUrl = $sFeed;
	}
	
	my $sSearch= '';
	if ($sOutput eq 'SEARCH'){
		$sSearch = command_input($idSession, 'news_search', 'LINE', $aArgs[2], '.', "\aSearch term: ", $sCmd);
		if ($sSearch eq ''){ return ('', 1); }
	}
	
	
	my $sLoadingText = $sOutput eq 'FULL' ? "-- Loading, this will take some time...$lf$lf" : "-- Loading...$lf$lf";
	
	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', $sLoadingText, $sCmd);
	if ($bReady eq ''){ return ('', 1); }
	
	my $sOut = '';

	UI_showProgress(1);

	my $oParser = XML::RSS::Parser->new();
	my $oFeed = $oParser->parse_uri($sUrl);
	
	if (!$oFeed){
		$sOut .= "$lf-- ERROR: Unsupported RSS Feed$lf";
	}
	else{
		UI_showProgress(0);
	
		my $oFeedTitle = $oFeed->query('/channel/title');
		my $sFeedTitle = $oFeedTitle ? $oFeedTitle->text_content() : 'Missing feed title';
		my $nTotal     = $oFeed->item_count();
		
		if ($Modules{'HTML::Entities'}->{loaded}){
			$sFeedTitle = decode_entities($sFeedTitle);
		}
		
		my $bShowLinks = $Configs{'RSS.ShowLinkIds'};
		
		if (!$aSessions[$idSession]->{VARS}->{news_notitle} && $sOutput ne 'WEATHER'){
			$sOut = "--- NEWS FEED: $sFeedTitle ($nTotal news) ---$lf";
		}
		
		if ($sSearch){
			 $sOut   .= "Searching: $sSearch$lf";
			 $sOutput = 'SUMMARY';
			 
			 $sSearch = lc($sSearch); # We want a case insensitive search
			 $bShowLinks = 1;
		}
		if ($sFeed eq 'HISTORY'){
			$bShowLinks = 1;
		}
		
		if ($bNoLinks){
			$bShowLinks = 0;
		}
		
		$sOut .= "$lf";
		 
		my $nCount   = 0;
		my $nResults = 0;
		my $nTotal   = $oFeed->item_count();
		foreach my $oItem ($oFeed->query('//item')){
			$nCount++;
			
			my $oTitle = $oItem->query('title');
			my $oDesc  = $oItem->query('description');
			my $sTitle = $oTitle ? clean_html($oTitle->text_content()) : 'Missing title in RSS Feed';
			my $sDesc  = $oDesc ? clean_html($oDesc->text_content()) : '';
			my $sLink  = $oItem->query('link')->text_content();
			my $nLink  = link_get($sLink);
	
			if ($Modules{'HTML::Entities'}->{loaded}){
				$sTitle = decode_entities($sTitle);
				$sDesc = decode_entities($sDesc);
			}
		
			if (!$aSessions[$idSession]->{command}){
				# The command was aborted
				UI_showProgress(0);
				return ('-- ABORTED --', 0, 1);
			}
			UI_showProgress($nCount, $nTotal);
			
			if ($sSearch && index(lc($sDesc), $sSearch) < 0 && index(lc($sTitle), $sSearch) < 0){
				next;
			}
			
			$nResults++;
			
			if ($sOutput eq 'TITLES'){
				$sOut .= "- $sTitle (LNK:$nLink)$lf";
			}
			elsif($sOutput eq 'SUMMARY' || $sOutput eq 'WEATHER'){
				$sOut .= "$lf--- $sTitle".($bShowLinks ? " (LNK:$nLink)$lf" : $lf);
				$sOut .= wrap("", "", $sDesc). $lf;
			}
			elsif($sOutput eq 'FULL'){
				UI_updateStatus("-- CMD: $sCmd --\n$nResults of $nTotal\n".substr($sTitle, 0, 40).(length($sTitle) > 40 ? '...' : ''));
				my $sText = '';
				
				my ($sText, $bUnsupported) = news_article($sLink);
				
				if ($bUnsupported){
					$sOut .= "$lf--- $sTitle ---$lf";
					$sOut = wrap("", "", $sDesc). $lf;
					$sOut .= "-- WARNING: FULL only works for selected news sources.";
				}
				elsif ($sText){
					$sOut .= $sText.$lf.$lf;
				}
				else{
					$sOut .= "$lf--- $sTitle ---$lf";
					$sOut .= wrap("", "", $sDesc). $lf;
					$sOut .= "-- WARNING: Only summary available for this news.$lf$lf";
				}
			}
		}
	
		if ($sSearch && !$nResults){
			$sOut .= 'No results found for that search';
		}
		
		if ($sOut eq ''){
			$sOut = 'Sorry, news are unavailable now';
		}
		else{
			$sOut .= "$lf-- End of NEWS $sOutput --$lf";
		}
	}

	UI_updateStatus('', 0);
	
	command_done($idSession, '', '^news_');

	return ($sOut, 0, 0);
}


sub do_news_item{
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';

	my $sId = $aArgs[0];

	if ($sId !~ /^\d+$/){
		return ("-- ERROR: Missing link-id. Usage is $Configs{EscapeChar}NEWS lnk-id", 0, 1);
	}
	
	if (!defined $Global{Links}->[$sId]){
		return ("-- ERROR: That link id is not in the detected links", 0, 1);
	}
	
	my $sLink = $Global{Links}->[$sId];

	my ($sText, $bUnsupported) = news_article($sLink);
	
	if ($bUnsupported){
		return ($sText, 0, 1);
	}
	elsif (!$sText){
		return ("-- ERROR: Cannot retrieve the news.", 0, 1);
	}
	
	$sOut .= $sText.$lf.$lf."-- DONE --";

	command_done($idSession, '', '^news_');
	
	return $sOut;
}



sub do_news_list{
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = 'List of News RSS Feeds:'.$lf;

	for my $sKey (sort keys %Configs){
		if ($sKey =~ /^RSS.Feed\.([\w\.]+)$/){
			$sOut .= uc($1).$lf;
		}
	}

	$sOut  .= '-- DONE --';
	
	command_done($idSession, '', '^news_');
	
	return $sOut;
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
	
	my $sContents = HTTP_get($sUrl);
	
	foreach my $sLine(split(/\n/, $sContents)) {
		if ($sLine =~ /class="topheadline"/){
			$sLine = clean_html($sLine);
			if (length($sLine) > 0){
				$sOut .= "\n--- ".$sLine . $lf;
			}
		}
		elsif ($sLine =~ /class="topheadlinebody"/){
			$sLine = clean_html($sLine);
			if (length($sLine) > 0){
				$sOut .= wrap("", "", $sLine). $lf;
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

	UI_updateStatus();
	
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

	my $sContents = HTTP_get($sUrl);

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
					$sOut .= $sLine . $lf;
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

	UI_updateStatus();
	
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
	    $s .=  "=================================================================\n";
	    $s .=  "Usage: perl heavymetal.pl [-configs=values] [--commands=params]\n";
	    $s .=  "  Example: perl heavymetal.pl -config1=\"value1\" --command=\"params\"\n";
	    $s .=  "=================================================================\n";
	    $s .=  "\n";
	    
		if (!defined $aArgs[0] || lc($aArgs[0]) eq 'settings'){
		    $s .=  "-- Configuration settings:\n";
		    $s .=  "\n";
		    foreach my $sKey (sort(keys(%aConfigDefinitions))) { 
				$s .= sprintf(" %14s: %s -Def: %s\n", $sKey, $aConfigDefinitions{$sKey}->{help}, $aConfigDefinitions{$sKey}->{default});
		    }
		    $s .=  "-------------------------------------------------------------\n";
		    $s .=  "\n";
		}
		if (!defined $aArgs[0] || lc($aArgs[0]) eq 'commands'){
		    $s .=  "-- Commands:\n";
		    $s .=  "\n";
		    foreach my $sKey (sort(keys(%aActionCommands))) { 
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
		    $s .=  "-- Escaped characters (use $Configs{EscapeChar}):\n";
		    $s .=  "\n";
		    $s .=  "ASCII:";
		    foreach my $sKey (sort(keys(%aEscapeCharsDecodeASCII))) { 
				$s .= " $sKey";
		    }
		    $s .=  "\nITA2:";
		    foreach my $sKey (sort(keys(%aEscapeCharsDecodeITA))) { 
				$s .= " $sKey";
		    }
		    $s .=  "\n";
		}
	    $s .=  "=============================================================\n";
	    $s .=  "\n\n";
    }
	return $s;
}

	
sub do_hmnet {
	my ($idSession, $sArgs) = @_;
	my $sCmd  = 'HMNET';
	
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';
	
	my $bUpdate = 0;
	
	if (!defined $idSession){
		$idSession = 0;
	}

	# Dump the configs
	if (scalar(@aArgs) == 0 || $aArgs[0] =~ /^configs$/i){
		$sOut  = "-- HM Net Configs:\n";
		foreach my $sKey (sort keys %Configs){
			if ($sKey eq 'HMNetEnabled'){
				$sOut .= sprintf(" %12s: %s\n", $sKey, $Configs{$sKey} ? 'ON' : 'OFF');
			}
			elsif ($sKey =~ /^HMNet/i && $sKey ne 'HMNetUrl'){
				$sOut .= sprintf(" %12s: %s\n", $sKey, $Configs{$sKey});
			}
		}
	}
	# Handle ON and OFF
	elsif ($aArgs[0] =~ /^(ON|OFF|0|1)$/i){
		if ($Configs{HMNetEnabled}){
			$bUpdate = 1;
		}
		$Configs{HMNetEnabled} = ($aArgs[0] =~ /^(ON|1)$/i) ? 1 : 0;
		if ($Configs{HMNetEnabled}){
			$bUpdate = 1;
		}
	}
	# Handle configs
	elsif ($aArgs[0] =~ /^(Enabled|Name|Pass|Owner|Email|Url)$/i){
		if (uc($aArgs[0]) eq 'ENABLED'){
			if ($Configs{HMNetEnabled}){
				$bUpdate = 1;
			}
			$aArgs[1] = ($aArgs[1] =~ /^(ON|1)$/i) ? 1 : 0;
			if ($aArgs[1]){
				$bUpdate = 1;
			}
		}
		
		$Configs{'HMNet' . ucfirst($aArgs[0])} = $aArgs[1];
		$sOut .= '-- HMNet New config ' . ucfirst($aArgs[0]).' = '.$aArgs[1];
	}
	elsif ($aArgs[0] =~ /^list$/i){
		$sOut .= "-- HMNet\n";
		$sOut .= HTTP_get($Configs{HMNetUrl}."?action=list&width=$Configs{Columns}&version=$sGlobalVersion&sysname=$Configs{SystemName}");
	}
	
	if ($bUpdate){
		if (!$Configs{HMNetUrl}){
			$sOut .= "-- HMNet Update\n-- ERROR: Missing URL in config\n";
		}
		elsif (!$Configs{HMNetName}){
			$sOut .= "-- HMNet Update\n-- ERROR: Missing Station Name in config\n";
		}
		elsif (!$Configs{HMNetPass}){
			$sOut .= "-- HMNet Update\n-- ERROR: Missing Station Pass in config\n";
		}
		elsif (!$Configs{HMNetOwner}){
			$sOut .= "-- HMNet Update\n-- ERROR: Missing Owner in config\n";
		}
		elsif (!$Configs{HMNetEmail}){
			$sOut .= "-- HMNet Update\n-- ERROR: Missing Email in config\n";
		}
		elsif (!$Configs{TelnetEnabled}){
			$sOut .= "-- HMNet Update\n-- ERROR: You don't have TELNET listening in your station\n";
		}
		else{
			my $sUrl = $Configs{HMNetUrl} . '?action='. ($Configs{HMNetEnabled} ? 'update' : 'delete');
			$sUrl .= '&name='    . URI::Escape::uri_escape($Configs{HMNetName});
			$sUrl .= '&password='. URI::Escape::uri_escape($Configs{HMNetPass});
			$sUrl .= '&owner='   . URI::Escape::uri_escape($Configs{HMNetOwner});
			$sUrl .= '&email='   . URI::Escape::uri_escape($Configs{HMNetEmail});
			$sUrl .= '&port='    . URI::Escape::uri_escape($Configs{TelnetPort});
			$sUrl .= '&version=' . URI::Escape::uri_escape($sGlobalVersion);
			$sUrl .= '&sysname=' . URI::Escape::uri_escape($Configs{SystemName});
			
			$sOut .= "-- HMNet Update: ";
			$sOut .= HTTP_get($sUrl);
		}
	}
	
	
	return $sOut;
}

sub do_version {
	my ($idSession, $sArgs) = @_;
	my $sCmd  = 'VERSION';
	
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';
	
	if (!defined $idSession){
		$idSession = 0;
	}
	
	command_start($idSession, $sCmd, $sCmd);
	
	my $sSubCmd = uc($aArgs[0]);
	# rest of the commands if they apply
	$sArgs =~ s/^\S+\s*//;
	$sOut = $Configs{SystemName}.' is using HeavyMetal v'.$sGlobalVersion.' release '.$sGlobalRelease.$lf;
	
	if ($sSubCmd eq 'CHECK'){
		$sOut .= do_version_check($idSession, $sArgs);
	}
	elsif ($sSubCmd eq 'UPDATE'){
		$sOut .= do_version_update($idSession, $sArgs);
	}

	command_done($idSession);
		
	return ($sOut, 0, 0);
}

sub do_version_update {
	my ($idSession, $sArgs) = @_;
	my $sCmd  = 'VERSION';
	
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';
	
	if (!defined $idSession){
		$idSession = 0;
	}
	
	my $sNewBuild = uc($aArgs[0]);

	if (scalar(keys(%{$Global{VersionsAvailable}})) == 0){
		$sOut = do_version_check($idSession, '', 1);
	}
	
	if (!$sNewBuild){
		if (!$sGlobalAvailableBuildReleased){
			$sOut .= '-- You are already using the latest RELEASED build for your version';
			return $sOut;
		}
		else{
			$sNewBuild = $sGlobalAvailableBuildReleased;
		}
	}
	elsif ($sNewBuild eq 'BETA'){
		if (!$sGlobalAvailableBuildBeta){
			$sOut .= '-- You are already using the latest RELEASED or BETA build for your version';
			return $sOut;
		}
		else{
			$sNewBuild = $sGlobalAvailableBuildBeta;
		}
	}
	else{
		if (!$sGlobalAvailableBuildReleased){
			$sOut .= '-- You are already using the latest RELEASED build for your version';
		}
	}
	
	$sOut .= "-- Updating to build $sNewBuild$lf";
	
	if (!$Modules{'File::Copy'}->{loaded} && !($aArgs[1] eq 'NOBACKUP')){
		$sOut .= '-- ERROR: Cannot download without making a backup, File::Copy perl module needed for that';
	}
	elsif (!exists($Global{VersionsAvailable}->{$sNewBuild})){
		$sOut .= '-- ERROR: That update is not available';
	}
	elsif(!$Global{VersionsAvailable}->{$sNewBuild}->{PL}){
		$sOut .= '-- ERROR: That update is not available as PL file';
	}
	elsif($Global{VersionsAvailable}->{$sNewBuild}->{status} ne 'RELEASED' && uc($aArgs[0]) ne $Global{VersionsAvailable}->{$sNewBuild}->{status} && uc($aArgs[1]) ne $Global{VersionsAvailable}->{$sNewBuild}->{status}){
		$sOut .= "-- ERROR: As that build is in ".$Global{VersionsAvailable}->{$sNewBuild}->{status}." status, you must$lf specifically allow it by using command:$lf";
		$sOut .= "$Configs{EscapeChar}VERSION UPDATE $sNewBuild $Global{VersionsAvailable}->{$sNewBuild}->{status}";
	}
	else{
		my $sUrl      = $Global{VersionsAvailable}->{$sNewBuild}->{PL};
		my $sTarget   = 'heavymetal.pl';
		my $sBackup   = 'tmp/'.$sTarget.'.'.time().'.bak';

		my $sContents = HTTP_get($sUrl);
		
		if (!$sContents) {
			$sOut .= '-- ERROR: Cannot download file!';
		}
		else{
			# Make the backup
			if ($Modules{'File::Copy'}->{loaded}){
				copy($sTarget, $sBackup);
			}
			
			# Autoupdate the initial line accordingly (only cares in linux)
			if (!$bWindows){
				if ($sContents =~ /^(#\!.+)/){
					my $sDefaultLine = $1;
					if (open (my $INPUT, '<', $sTarget)){
						my $sFirstLine = (<$INPUT>);
						close($INPUT);
						chomp($sFirstLine);
						if ($sFirstLine =~ /^#\!/ && $sFirstLine ne $sDefaultLine){
							$sContents =~ s/^$sDefaultLine/$sFirstLine/;
						}
					}
				}
			}
			
			# Save the file
			if ($Configs{Debug} > 1){ logDebug("\nSaving to file $sTarget from $sUrl");}
			open(my $rFile, '>', $sTarget);
			print $rFile $sContents;
			close($rFile); 
			
			$sOut .= "-- New version downloaded (".length($sContents)." bytes)\n-- Backup file: $sBackup\n-- You now must restart heavymetal...\n-- DONE";
		}

	}
	return $sOut;
}

sub do_version_check {
	my ($idSession, $sArgs, $bNoSuggestion) = @_;
	my $sCmd  = 'VERSION';
	
	my @aArgs = split(/\s+/, $sArgs);
	my $sOut  = '';
	
	if (!defined $idSession){
		$idSession = 0;
	}

	$sOut .= "-- Available versions at HMNet:\n";
	my $sContents .= HTTP_get($Configs{HMNetUrl}."?action=getVersions&width=$Configs{Columns}&version=$sGlobalVersion&sysname=$Configs{SystemName}");
	
	$sOut .= $sContents;
	my @aLines = split(/\n/, $sContents);
	my $sBuild;
	my $n = 0;
	foreach my $sLine (@aLines){
		chomp($sLine);
		if (substr($sLine, 0, 1) ne " "){
			if ($sLine =~ /^((\d+\.\d+)\.\d+)\s+(\d\d\d\d-\d\d-\d\d)\s(\w+)$/){
				$sBuild    = $1;
				$Global{VersionsAvailable}->{$sBuild} = {version => $2, build => $sBuild, released => $3, status => $4};
			}
			else{
				$sBuild = '';
			}
		}
		else{
			if ($sBuild){
				my ($sDist, $sUrl) = split('=', $sLine, 2);
				$sDist =~ s/\s//;
				if ($sDist && $sUrl){
					$Global{VersionsAvailable}->{$sBuild}->{$sDist} = $sUrl;
				}
			}
		}
	}
	
	my $sMyVersion = $sGlobalVersion;
	$sMyVersion =~ s/^(\d+\.\d+).+/$1/;
	
	$sGlobalAvailableBuildReleased = '';
	my $bUpdatableBeta     = 0;
	my $bUpdatableReleased = 0;
	foreach $sBuild (sort keys %{$Global{VersionsAvailable}}){
		if ($Global{VersionsAvailable}->{$sBuild}->{version} eq $sMyVersion){
			if ( ($sBuild cmp $sGlobalVersion) > 0){
				$sOut .= "-- Update $sBuild ".$Global{VersionsAvailable}->{$sBuild}->{status}." is available for your version.$lf";

				if ($Global{VersionsAvailable}->{$sBuild}->{status} eq 'RELEASED'){
					if (!$bNoSuggestion){
						$sOut .= "-- Use command $Configs{EscapeChar}VERSION UPDATE $sBuild$lf";
					}
					$sGlobalAvailableBuildReleased = $sBuild;
					$bUpdatableReleased = 1;
				}
				if ($Global{VersionsAvailable}->{$sBuild}->{status} eq 'BETA'){
					$sGlobalAvailableBuildBeta = $sBuild;
					$bUpdatableBeta     = 1;
				}
			}
		}
	}
	
	if (!$bNoSuggestion && !$bUpdatableReleased && !$bUpdatableBeta){
		$sOut .= '-- You are already using the latest build for your version'.$lf;
	}
	
	return $sOut;
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


sub do_telnet_reverse {
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'TELNETREVERSE';
	my @aArgs = split(/\s+/, $sArgs);
	
	if (!defined $idSession){
		$idSession = 0;
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

	
	my $idNewSession = telnet_connect($sHost, $nPort, $idSession);
	
	if ($idNewSession > 0){
		$aSessions[$idNewSession]->{'direction'}   = 0; 
		$aSessions[$idNewSession]->{'auth'}        = 3;
		$aSessions[$idNewSession]->{'user'}        = 'REMOTE';
		$aSessions[$idNewSession]->{'source'}      = 'OFF';
		$aSessions[$idNewSession]->{'echo_input'}  = 0;
		
		message_send('SYS', $idSession, "-- DONE: Telnet reverse connection OK. The remote peer now has access.");
	}
	
	$aSessions[$idSession]->{VARS}->{'telnet_host'} = '';
	
	
	do_target($idSession, 'ALL');
	
	command_done($idSession);

	return '';
}

sub do_list{
	my ($idSession, $sArgs) = @_;
	my $sOut = '';

	$sOut  = "-- $Configs{SystemName} Sessions:\r\n";
	$sOut .= "ID -TYPE- -USER------ I/O LVL -TARGET---- SRC -ADDRESS------ STATUS\r\n";
	foreach my $thisSession (@aSessions){
		if (!defined $thisSession->{type}){
			next;
		}
		$sOut .= sprintf("%2d %-6s %-11.11s %-3s  %d  %-11.11s %3.3s %-14.14s %-6.6s\r\n", 
			$thisSession->{id}, 
			$thisSession->{type}, 
			$thisSession->{user}, 
			$thisSession->{direction} ? 'Out' : 'In', 
			$thisSession->{auth}, 
			$thisSession->{target}, 
			$thisSession->{source}, 
			$thisSession->{address}, 
			$thisSession->{status} ? 'Conn' : 'Disc');
	}
	
	UI_updateSessionsList();

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

	if (!$Modules{'Text::Banner'}->{loaded}){
		return ('-- ERROR: Perl module Text-Banner not found.', 0, 1);
	}

	# Get the TEXT
	my $sText = command_input($idSession, 'banner_text', 'LINE', $sArgs, '', "Text\a: ", $sCmd);
	if ($sText eq ''){ return ('', 1); }

	
	if ($sText =~ /^=\S\S?\S?\s/){
		if ($sText =~ /^=([12345])([HVhv])?([\x20-\x7f])?\s/){
			my ($nSize, $sDir, $sFill) = (int($1), $2, $3);
			$sText =~ s/^\S+\s//;
			return banner_create($sText, $nSize, $sDir, $sFill);
		}
		else{
			return '-- ERROR: Usage is BANNER =(1-5)(H,V)(fill char) Text';
		}
	}
	return banner_create($sText);
}

sub banner_create{
	my ($sText, $nSize, $sOrientation, $sFill) = @_;
	
	# This lousy module does not work if you create more than once, so we have to keep it as a global singleton
	if (!defined $oGlobalBanner){
		$oGlobalBanner = Text::Banner->new();
	}

	$oGlobalBanner->{SIZE}         = $nSize ? $nSize : 1;
	$oGlobalBanner->{ORIENTATION}  = lc($sOrientation) eq 'v' ? 'v' : 'h';
	$oGlobalBanner->{FILL}         = $sFill ? $sFill : '*';
	
	
	if ($oGlobalBanner->{ORIENTATION} eq 'h'){
		my $sOut = '';
		while (length($sText) > 0){
			$oGlobalBanner->set(substr($sText, 0, int(8/$oGlobalBanner->{SIZE}), ''));
			if ($sOut){
				$sOut .= "\n\n";
			}
			$sOut .= $oGlobalBanner->get();
		}
		return $sOut;
	}
	else{
		$oGlobalBanner->set($sText);
		return $oGlobalBanner->get();
	}
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

	return $Configs{TestQBF}.$EOL.$Configs{TestQBF}.$EOL.$Configs{TestQBF};
}


sub generate_test{
	my ($idSession, $sCmd, $sTitle, $sString, $nLines, $bNumbers) = @_;

	if (length($sString) < 1){
		return '';
	}

	command_start($idSession, $sCmd, $sTitle);
	
	my $nColumns = $aSessions[$idSession]->{type} eq 'TTY' ? $Configs{"TTY.$idSession.Columns"} : $Configs{Columns};
	
	my $sTestLine = substr($sString x int($nColumns / length($sString)), 0, $nColumns - 1);
	my $sOut      = '';
	
	if ($nLines > 1 && $nLines <= 100){
		$sTestLine = substr($sTestLine, 0, $nColumns - 5);
		for (my $n = 1; $n <= $nLines; $n++){
			if ($bNumbers){
				$sOut .= sprintf('%03d ', $n);
			}
			$sOut .= $sTestLine.$lf;
		}
	}
	else{
		$sOut = $sTestLine.$lf;
	}
	
	command_done($idSession);
	return $sOut;
}


sub do_ryry {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	
	return generate_test($idSession, 'RYRY', 'RYRY TEST', 'RY', int($aArgs[0]), (uc($aArgs[1]) eq 'OFF' ? 0 : 1));
}

sub do_r6r6 {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	
	return generate_test($idSession, 'R6R6', 'R6R6 TEST', 'R6', int($aArgs[0]), (uc($aArgs[1]) eq 'OFF' ? 0 : 1));
}

sub do_rrrr {
	my ($idSession, $sArgs) = @_;
	my @aArgs = split(/\s+/, $sArgs);
	
	return generate_test($idSession, 'RRRR', 'RRRR TEST', 'R', int($aArgs[0]), (uc($aArgs[1]) eq 'OFF' ? 0 : 1));
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

	my $sServer  = $Configs{EmailSMTP};
	my $sAccount = $Configs{EmailAccount};
	my $sPass    = $Configs{EmailPassword};
	my $sFrom    = $Configs{EmailFrom};
	
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

	my $sServer  = (exists $aArgs[1] && $aArgs[1] ne '') ? $aArgs[1] : $Configs{EmailPOP};
	my $sAccount = (exists $aArgs[2] && $aArgs[2] ne '') ? $aArgs[2] : $Configs{EmailAccount};
	my $sPass    = (exists $aArgs[3] && $aArgs[3] ne '') ? $aArgs[3] : $Configs{EmailPassword};

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
	$sAction  = command_input($idSession, 'email_action', 'LINE', '', '\S', "Action\a: ", $sCmd);
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

	if ($sAction =~ /^\d+$/){
		$nMsgId  = $sAction;
		$sAction = 'ALL';
	}

	my $sSearch = '';
	if ($sAction ne 'ALL' && $sAction ne 'HEADERS'){
		$sSearch = $sAction;
		$sAction = 'HEADERS';
	}


	if ($sServer eq '' || $sAccount eq '' || $sPass eq '') {
		return "-- ERROR: Missing POP configuration. See README about heavymetal.cfg";
	}

	# Make sure the OUT buffer is empty before proceeding
	my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', ($sSearch ? "Searching subject: $sSearch\n-- Fetching...\n\n" : "-- Fetching...\n\n"), $sCmd);
	if ($bReady eq ''){ return ('', 1); }

	
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

		UI_updateStatus($sOut);
		
		my $nCount = 0;
		my $nResults = 0;
		
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
		
		foreach my $idMsg (@aList) {
			$nCount++;
			
			if (!$aSessions[$idSession]->{command}){
				# The command was aborted
				UI_showProgress(0);
				return ('-- ABORTED --', 0, 1);
			}
			
			UI_updateStatus("Fetching message $nCount of $nMessages\n".($sSearch ? "Results: $nResults - " : '').length($sOut).' bytes', $nCount, $nMessages);
			
			my $sMessage = $oPOP->get($idMsg);
			if (defined $sMessage) {
				my $sLine;
				my $sHeader = "";
				my $sBody   = "";
				my $bBody   = 0;
				my $bShowHeader = 1;
				my $bShowBody   = ($sAction eq "ALL") ? 1 : 0;

				foreach my $sLine (@$sMessage) {
					if ($bBody){
						if ($bShowBody) {
							$sBody .= $sLine;
						}
					}
					elsif($bShowHeader){
						chomp($sLine);
						if ($sLine =~ /^Subject:/i) {
							$sHeader .= $sLine.$lf;
							if ($sSearch) {
								if ($sLine =~ /$sSearch/i) {
									$bShowBody = 1;
									$nResults++;
								}
								else {
									$bShowHeader = 0;
								}
							}
						}
						elsif ($sLine =~ /^To:/i) {
							$sHeader .= $sLine.$lf;;
						}
						elsif ($sLine =~ /^From:/i) {
							$sHeader .= $sLine.$lf;;
						}
						elsif ($sLine =~ /^Date:/i) {
							$sHeader .= $sLine.$lf;;
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
					$sOut .= $sHeader.$lf;
					if ($bShowBody){
						$sOut .= $sBody.$lf;
					}
				}
			} 
			else {
				$sOut .= sprintf("---- Msg: %3d -- ID: %3d - Error: %s\n", $nCount, $idMsg, $!);
			}
		}
	};
	if ($@) {
		UI_showProgress(0);
		command_done($idSession);
		return ("-- ERROR: Failed to complete email command: $@", 0, 1);
	}

	$sOut .= "\n-- DONE --";
	
	$aSessions[$idSession]->{VARS}->{'email_action'} = '';
	$aSessions[$idSession]->{VARS}->{'ready'} = '';
	
	UI_showProgress(0);
	UI_updateStatus();
	
	command_done($idSession);
	
	return ($sOut, 0, 0);
}


sub do_quote_portfolio {
	my ($idSession, $sArgs) = @_;
	
	my $sCmd = 'QUOTE';
	
	command_start($idSession, $sCmd, 'STOCK PORTFOLIO');
	
	return do_quote($idSession, $Configs{StockPortfolio});
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


# -------------------------------------------------------
# Helper functions
# -------------------------------------------------------

# TRY CATCH functions to emulate standard Usage
# Explained: http://www.perlmonks.org/?node_id=384038
sub try (&$) {
   my($try, $catch) = @_;
   eval { $try };
   if ($@) {
      local $_ = $@;
      &$catch;
   }
}
sub catch (&) { $_[0] }

# Quicky in_array
sub in_array {
	my ($arr,$search_for) = @_;
	my %items = map {$_ => 1} @$arr; # create a hash out of the array values
	return (exists($items{$search_for}))?1:0;
}

sub array_pos {
	my ($rArr, $sSearch) = @_;
	my $n = 0;
	for (@$rArr){
		if ($_ eq $sSearch){
			return $n;
		}
		$n++;
	}
	return -1;
}




sub ftp_list {
	my ($sUrl) = @_;
	
	if ($sUrl eq ''){ return '-- ERROR: Missing FTP URL'; }

	my $sOut = '';
	
	if ($sUrl =~ /^ftp:\/\/(.+?)\/(.+\/)(.*)$/i){
		my $sServer   = $1;
		my $sDir      = $2;
		my $sSearch   = $3;
		
		my $oFTP = Net::FTP->new($sServer, Debug => 0);
		if (!$oFTP){
			$sOut = "-- ERROR: Cannot connect to FTP: ".$sServer;
		}
		elsif (!$oFTP->login("anonymous",'anonymous@example.com')){
			$sOut = "-- ERROR: Cannot login to FTP: ".$oFTP->message;
			$oFTP->quit();
		}
		elsif ($sDir && !$oFTP->cwd('/'.$sDir)){
			$sOut = "-- ERROR: Cannot change FTP directory: ".$oFTP->message;
			$oFTP->quit();
		}
		elsif(!$oFTP->pasv()){    
			$sOut = "-- ERROR: Cannot switch to PASV: ".$oFTP->message;
			$oFTP->quit();
		}
		else{
				my @aFiles = $oFTP->ls($sSearch ? $sSearch : '*');
				$oFTP->quit();
				return @aFiles;
		}
	}
	else{
		$sOut = "-- ERROR: Invalid FTP format $sUrl";
	}
	return $sOut;
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
    Time::HiRes::sleep(0.1); # How long??


        # Turn the device on
    $oSerialPort->dtr_active(1);
    $oSerialPort->rts_active(1);
    Time::HiRes::sleep(0.2); # How long??

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
    Time::HiRes::sleep(0.15);

    print " done\n" if $X10_DEBUG;

        # Turn the device off
    $oSerialPort->dtr_active(0);
    $oSerialPort->rts_active(0);

}



#------------------------------------------------------------------------
# - - - - - - - - - - - - - - TELNET SUBS - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------

sub telnet_init{
	
	$sckTelnetListener = IO::Socket::INET->new(
		LocalAddr => '0.0.0.0', 
		LocalPort => int($Configs{TelnetPort}),
		Listen => 10, 
		Reuse=>1
	);
	
	if (!defined($sckTelnetListener) || !$sckTelnetListener){
		if ($Configs{Debug}){ logDebug("ERROR: Could not initiate listener socket: $@\n"); }
		$Configs{TelnetEnabled} = 0;
		return 0;
	}
 
	# Do I need to do this?
	$sckTelnetListener->autoflush(1);
	
	# IO Select Sets for main thread
	if (!defined $oTelnetReadSet)      { $oTelnetReadSet      = new IO::Select(); }
	if (!defined $oTelnetWriteSet)     { $oTelnetWriteSet     = new IO::Select(); }
	if (!defined $oTelnetExceptionSet) { $oTelnetExceptionSet = new IO::Select(); }

	$oTelnetReadSet->add($sckTelnetListener);
	$oTelnetExceptionSet->add($sckTelnetListener);
	$nTelnetSockets++;
	
	if ($Configs{Debug}){ logDebug("\nTelnet server listening at port $Configs{TelnetPort}");}


	return 1;
}


sub telnet_toggle{
	my ($bEnable) = @_;
	if (defined $bEnable){
		$Configs{TelnetEnabled} = $bEnable;
	}
	
	my $sOut = '';
	if ($Configs{TelnetEnabled}){
		if ($Configs{Debug}){ logDebug("\nEnabled Telnet\n"); }
		telnet_init();
		$sOut = '-- Telnet Enabled';
	}
	else{
		if ($Configs{Debug} > 0){ logDebug("\nDisabled Telnet\n"); }
		my $nCount = telnet_close('IN', 'Telnet Disabled');
		$sOut = '-- Telnet Disabled: '.$nCount.' socket(s) disconnected';
	}
	
	UI_updateStatus();
	return $sOut;
}


sub telnet_connect{
	(my $sHost, my $nPort, my $xTarget) = @_;
	
	$nPort = int($nPort);
	
	my $sckClient = new IO::Socket::INET(
		Proto    => 'tcp',
		PeerHost => $sHost,
		PeerPort => $nPort, 
		Timeout  => 5
	);

	if (!$sckClient){
		if (defined $xTarget){
			message_send('SYS', $xTarget, "Could not connect to $sHost:$nPort");
		}
		if ($Configs{Debug}){ logDebug("\nCould not connect to $sHost $nPort\n");}
		return '';
	}


	my $xSource = defined($xTarget) && $xTarget =~ /^\d+$/ ? $xTarget : 'ALL';
	$xTarget = defined($xTarget) ? $xTarget : 'IN';

	my $sRemoteIP   = $sckClient->peerhost();
	my $nRemotePort = $sckClient->peerport();
	my $sLocalIP    = $sckClient->sockhost();
	my $nLocalPort  = $sckClient->sockport();
	
	# IO Select Sets for main thread (if Telnet listener is disabled, then we might need to initiate these)
	if (!defined $oTelnetReadSet)      { $oTelnetReadSet      = new IO::Select(); }
	if (!defined $oTelnetWriteSet)     { $oTelnetWriteSet     = new IO::Select(); }
	if (!defined $oTelnetExceptionSet) { $oTelnetExceptionSet = new IO::Select(); }
	
	$oTelnetReadSet->add($sckClient);
	$oTelnetWriteSet->add($sckClient);
	$oTelnetExceptionSet->add($sckClient);
	
	my $idSession  = session_new_telnet({
		'SOCKET'      => $sckClient,
		'direction'   => 1, 
		'auth'        => 0, 
		'target'      => $xTarget, 
		'source'      => $xSource,
		'remote_ip'   => $sRemoteIP,
		'remote_port' => $nRemotePort,
		'negotiate'   => $Configs{TelnetNegotiate},
		'address'     => $sRemoteIP
	});
	
	if (defined $xTarget){
		message_send($idSession, $xTarget, "Connected exclusively to session $idSession to $sHost:$nPort\r\n");
	}

	$aTelnetSockets{"$sckClient"} = $idSession;
	$nTelnetSockets++;
	
	if (exists $aSessions[$xTarget]){
		$aSessions[$xTarget]->{target} = $idSession;
	}
	if ($Configs{Debug}){ logDebug("\nNew server ($idSession) $sRemoteIP\n");}
	
	UI_updateStatus();
	
	return $idSession;
}


sub telnet_close{
	(my $sckSocket, my $sReason) = @_;
	
	# We kill all inbound connections and the main listener. We do not touch outbound connections.
	if ($sckSocket eq 'IN'){
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
	$nTelnetSockets--;
	
	# Close the socket
	$sckSocket->close();
	
	$nSessionsCount--;
	
	my $idSession = defined($aTelnetSockets{"$sckSocket"}) ? $aTelnetSockets{"$sckSocket"} : 0;
	my $sIP       = 'unknown';
	
	if ($idSession){
		$aSessions[$idSession]->{'status'} = 0;
		$sIP = $aSessions[$idSession]->{'remote_ip'};
	}
	
	if ($Configs{Debug}){ logDebug("\nTelnet connection $idSession from $sIP closed: $sReason\n");}

	return 1;
}



sub telnet_io{
	
	my $sckWrite;
	
	my $n;
	
	my ($aReadyRead, $aReadyWrite, $aReadyException) = IO::Select->select($oTelnetReadSet, $oTelnetWriteSet, $oTelnetExceptionSet, 0.001);

	# Loop all exceptions in connections
	foreach my $sckRead (@$aReadyException){
		telnet_close($sckRead, "Socket Exception");
	}
	
	
	# Loop all read connections
	if (defined($aReadyRead)){
		foreach my $sckRead (@$aReadyRead){

			
				
			if ($sckRead eq $sckTelnetListener){
				# NEW CONNECTION
				if ($Configs{TelnetEnabled}){
					
					my $sckClient  = $sckRead->accept();
								
					my $remoteip   = $sckClient->peerhost();
					my $remoteport = $sckClient->peerport();
					my $localip    = $sckClient->sockhost();
					my $localport  = $sckClient->sockport();
					
					$oTelnetReadSet->add($sckClient);
					$oTelnetWriteSet->add($sckClient);
					$oTelnetExceptionSet->add($sckClient);
					
					my $idSession  = session_new_telnet({
						'SOCKET'      => $sckClient,
						'direction'   => 0, 
						'auth'        => 0, 
						'remote_ip'   => $remoteip,
						'remote_port' => $remoteport,
						'xlate_cr'    => 1,
						'negotiate'   => $Configs{TelnetNegotiate},
						'prompt'      => 1,
						'address'     => $remoteip,
						'clean_line'  => 1,
						'label'       => 1
					});
					
					
					$aTelnetSockets{"$sckClient"} = $idSession;
					$nTelnetSockets++;
						
					if ($aSessions[$idSession]->{negotiate}){
						# IAC WILL ECHO
						$aSessions[$idSession]->{OUT} = chr(255).chr(251).chr(1);
					}

					$aSessions[$idSession]->{OUT} .= "\r\n$Configs{TelnetWelcome}\n$Configs{SystemPrompt}";
					
					
					if ($Configs{Debug}){ logDebug("\nNew client ($idSession) from $remoteip\n");}
				}
				else{
					my $sckClient = $sckRead->accept();         
					my $remoteip  = $sckClient->peerhost();
					$sckClient->close();
					
					# Note: As we were not really connected yet we don't increment/decrement the telnet counter
					
					if ($Configs{Debug}){ logDebug("\nNew client from $remoteip rejected\n");}
				}
			}
			else{
				# CLIENT->SERVER
				
				my $idSession = $aTelnetSockets{"$sckRead"};
				
				my $sChunk;
				my $nBytes = $sckRead->sysread($sChunk, 4096); #sysread
				
				# We have incomming data
				if(defined($nBytes) && $nBytes > 0){
					
					# Fix issue with backspace not deleting character
					$sChunk =~ s/$bs/$bs $bs/g;
					
					if ($aSessions[$idSession]->{negotiate}){
						# Clear telnet simple negotiations (they start with IAC)
						$sChunk =~ s/\xFF[^\xFF].//g;
						$sChunk =~ s/\xFF\xFF/\xFF/g;
					}
					
					$aSessions[$idSession]->{IN} .= $sChunk;
					
					my $nPosChunk;
					my $sChrChunk = "\n";
					
					# INBOUND
					if ($aSessions[$idSession]->{'direction'} == 0){
						
						
						my $nPos  = index($aSessions[$idSession]->{IN}, "\n");
						
						if ($aSessions[$idSession]->{xlate_cr} && $nPos >= 0){
							$aSessions[$idSession]->{xlate_cr} = 0;
						}
						
						if ($aSessions[$idSession]->{xlate_cr}){
							my $nPos2 = index($aSessions[$idSession]->{IN}, "\r");
							if ($nPos2 >= 0){
								$nPos = $nPos2;
								$sChrChunk = "\r";
							}
						}
						
						if ($nPos >= 0){
							
							# Echo the first part of the chunk up to the \n including it
							my $nLinesCount = 0;
							if ($aSessions[$idSession]->{echo_input}){
								$aSessions[$idSession]->{OUT} .= substr($sChunk, 0, index($sChunk, $sChrChunk) + 1, '');
							}

							while($nPos >= 0){
								
								if ($nLinesCount > 0){
									if ($aSessions[$idSession]->{echo_input}){
										$aSessions[$idSession]->{OUT} .= substr($sChunk, 0, index($sChunk, $sChrChunk) + 1, '');
									}
								}

								# Get the complete line and clean the \r\n
								my $sLine = substr($aSessions[$idSession]->{IN}, 0, $nPos + 1, '');
								$sLine =~ s/[\r\n]+$//g;
								
								# Decode escape sequences TO ASCII
								if ($sLine && $Configs{EscapeEnabled} && index($sLine, $Configs{EscapeChar}) >= 0){
									$sLine = escape_to_ascii($idSession, $sLine);
								}
								
								# Process backspaces
								if ($sLine){
									while (($n = index($sLine, $bs)) >= 0){
										if ($n > 0){
											substr($sLine, $n - 1, 2, '');
										}
										else{
											substr($sLine, 0, 1, '');
										}
									}
								}
								
								# AUTHENTICATED SESSION
								if ($aSessions[$idSession]->{auth}){
									# Detect and execute commands or send message
									process_line($idSession, $sLine);
									
									if ($aSessions[$idSession]->{input_type} eq '' && $aSessions[$idSession]->{prompt}){
										#$aSessions[$idSession]->{OUT} .= "\r\n$Configs{SystemPrompt}";
									}
									
								}
								# UNAUTHENTICATED SESSION
								else{
									# Catchall for unauthenticated sessions
									my $sResult = '';
									my $bShowPrompt = 1;
									if (substr($sLine, 0, 1) eq $Configs{EscapeChar}){
										# PING		
										if( $sLine =~ /^.ping\s*$/i ){
											$sResult = 'PONG!';
										}
										elsif( $sLine =~ /^.(exit|quit|logout)\s*$/i ){
											do_logout($idSession);
											$sResult = "";
											$bShowPrompt = 0;
										}
										# LOGIN
										elsif( $sLine =~ /^.login(\s+(\S.*))?$/i ){
											$sResult = do_login($idSession, $2);
										}
										else{
											my $sResult = "-- Unauthenticated user";
										}
									}
									elsif ($sLine ne '' && !$aSessions[$idSession]->{warning_unauth}){
										$sResult = "-- Unauthenticated user";
										$aSessions[$idSession]->{warning_unauth} = 1;
									}
										
									$aSessions[$idSession]->{OUT} .= $sResult."\r\n" . ($bShowPrompt ? $Configs{SystemPrompt} : '');
	
								}
								
								$nLinesCount++;
								$nPos = index($aSessions[$idSession]->{IN}, $sChrChunk);
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
					telnet_close($sckRead, "Connection Closed (R)");
				}
				
				
			}
		}
	}
	
	
	# Loop all write connections
	if (defined($aReadyWrite)){
		# SERVER->CLIENT
		foreach my $sckWrite (@$aReadyWrite){
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
	
					eval {
						$sckWrite->send($sBuffer);
					};
					if($@){
						telnet_close($sckWrite, "Connection Closed (W)");
					}
				}
			}
		}
	}

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
		return;
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
		return;
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
		return;
	}
	
	foreach my $thisSession (@aSessions){
		if ($thisSession->{'status'}){
			if (!$sField || ($nEq == 0 && lc($thisSession->{$sField}) eq $sTarget) || ($nEq == 1 && $thisSession->{$sField} == $sTarget)){
				return $thisSession->{$sVar};
			}
		}
	}
	
	return;
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
		
		if (!$Configs{MsnEnabled}){
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
		return;
	}
	
	my $nCount = 0;
	foreach my $thisSession (@aSessions){
		if ($thisSession->{'status'} && $thisSession->{auth} > 0){
			if ($nSendType == 1 
				|| ($nSendType == 2 && $thisSession->{type} eq $xTarget) 
				|| ($nSendType == 3 && $thisSession->{user} eq $xTarget) 
				|| ($nSendType == 4 && $thisSession->{direction} == 1) 
				|| ($nSendType == 5 && $thisSession->{direction} == 0))
			{
				
				if ($idSource != $thisSession->{'id'} || $thisSession->{echo_msg}){
					if ($Configs{Debug} > 1){ logDebug(sprintf("\nSend %d bytes type %d from %d to %d", length($sText), $nSendType, $idSource, $thisSession->{'id'}));}
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
		if ($Configs{Debug} > 1){ logDebug("\nNot delivered $idSession: Invalid");}
		return 0;
	}
	
	my $thisSession = $aSessions[$idSession];

	if (!$thisSession->{'status'}){
		if ($Configs{Debug} > 1){ logDebug("\nNot delivered $idSession: Disconnected");}
		return 0;
	}
	
	if ($idSource ne 'SYS' && $thisSession->{'source'} ne 'ALL' && $thisSession->{'source'} ne $idSource){
		if ($Configs{Debug} > 1){ logDebug("\nNot delivered $idSession: Source does not match");}
		return -1;
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
	if ($thisSession->{'label'} && $sSource ne '' && (!$thisSession->{'direction'} || substr($sText, 0 ,1) ne $Configs{EscapeChar})){
		$sOutText = "$sSource: $sText";
	}

	# Deal according to session type
	if ($thisSession->{'type'} eq 'HOST'){
		if (!$bNoCr){
			if ($thisSession->{column} > 0){
				$sPad     = ($thisSession->{column} > length($sOutText)) ? " " x ($thisSession->{column} - length($sOutText)) : '';
				$sOutText =  "\r$sOutText$sPad";
			}
			$sOutText .= $lf;
		}
	}
	elsif ($thisSession->{'type'} eq 'TTY'){
		if ($thisSession->{column} > 0){
			# Prepend a new line
			$sOutText = $lf.$sOutText;
		}
		if (!$bNoCr){
			$sOutText .= $lf;
		}
	}
	elsif ($thisSession->{'type'} eq 'MSN'){

	}
	elsif ($thisSession->{'type'} eq 'TELNET'){

		# Outbound
		if ($thisSession->{'direction'}){
			if (!$bNoCr){
				$sOutText .= $lf;
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
				$sOutText .= $lf;
			}
		}
	}

	# Only for inbound
	if ($thisSession->{'direction'} == 0){
		# Deal with System Prompt
		if ($thisSession->{input_type} eq ''){
			if ($thisSession->{'prompt'} && !$bNoPrompt){
				$sOutText .= $Configs{SystemPrompt};
			}
			if ($thisSession->{echo_input} && length($thisSession->{IN}) > 0 && index($thisSession->{IN}, $lf) < 0){
				$sOutText .= $thisSession->{IN};
			}
		}
		# Deal with Input Prompt
		else{
			if ($thisSession->{'input_prompt'} ne ''){
				$sOutText .= $thisSession->{'input_prompt'};
			}
			if ($thisSession->{echo_input} && length($thisSession->{IN}) > 0 && index($thisSession->{IN}, $lf) < 0){
				$sOutText .= $thisSession->{IN};
			}
		}
	}
	
	# Append to buffer
	$thisSession->{OUT} .= $sOutText;
	
	if ($Configs{Debug} > 1){ logDebug(sprintf("\nDelivered %d (%d): %s%s", $idSession, length($sOutText), debug_chars($idSession, substr($sOutText, 0, 40), 0, 1), (length($sOutText) > 30 ? '...' : '')));}

	return 1;
}


#------------------------------------------------------------------------
# - - - - - - - - - - - - - - COMMANDS  - - - - - - - - - - - - - - - - -
#------------------------------------------------------------------------


sub process_line{
	(my $idSession, my $sLine) = @_;

	if ($Configs{Debug} > 1){ logDebug(sprintf("\nLine %d (%d): %s%s", $idSession, length($sLine), debug_chars($idSession, substr($sLine, 0, 40), 0, 1), (length($sLine) > 30 ? '...' : '')));}

	my $thisSession = $aSessions[$idSession];
	
	# Detect and execute commands
	if ($thisSession->{input_type} eq ''){
		if (substr($sLine, 0, 1) eq $Configs{EscapeChar}){
			my $sResult    = '';
			# REMOTE COMMAND (Line starts with $$)
			if (substr($sLine, 1, 1) eq $Configs{EscapeChar}){
				my $nCount = session_set($thisSession->{target});
				if ($nCount > 1){
					$sResult = '-- ERROR: You can only send remote commands to single targets';
				}
				elsif ($nCount < 1){
					$sResult = '-- ERROR: Invalid target';
				}
				elsif(session_get($thisSession->{target}, 'status') == 0){
					$sResult = '-- ERROR: Disconnected target';
				}
				elsif(session_get($thisSession->{target}, 'direction') == 0){
					$sResult = '-- ERROR: You can only send commands to outbound connections';
				}
				else{
					# Send the command
					message_send($idSession, $thisSession->{target}, substr($sLine, 1), 0, 1, 1);
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

				my $sArgsOriginal = $sArgs;
				my $bContinued = 0;
				my $bError     = 0;
				
				# Custom commands
				if (!exists($aActionCommands{$sCmd}) && exists($Configs{"CommandCustom.$sCmd"})){
					my $sNewCmdLine = $Configs{"CommandCustom.$sCmd"};
					
					if (substr($sNewCmdLine, 0, 1) eq $Configs{EscapeChar}){
						$nPos = index($sNewCmdLine, ' ');
						$sCmd = uc($nPos >= 0 ? substr($sNewCmdLine, 1, $nPos - 1)  : substr($sNewCmdLine, 1));
						
						$sArgs = ($sCmd eq 'EVAL') ? $sNewCmdLine : $sNewCmdLine;
						$sArgs =~ s/^\S+\s*//;
						$sArgs =~ s/\s+$//;
					}
					else{
						$sResult = $sNewCmdLine .' '. $sArgs;
						$bContinued = 0;
						$bError     = 0;
					}
				}
				
				# Action commands
				if (exists $aActionCommands{$sCmd}){
					if ($aActionCommands{$sCmd}->{auth} <= $thisSession->{auth}){
						if ($Configs{Debug}) { logDebug("\nAction: '$sCmd' Args: '$sArgs'\n"); }
						## REPEAT command is catched at another point not here
						if ($sCmd ne 'REPEAT'){
							$thisSession->{command_num}  = -1;
							if (!defined $thisSession->{COMMANDS}->[0] || $sLine ne $thisSession->{COMMANDS}->[0]){
								unshift(@{$thisSession->{COMMANDS}}, $sLine);
								if (scalar @{$thisSession->{COMMANDS}} > $Configs{CommandsMaxHistory}){
									pop(@{$thisSession->{COMMANDS}});
								}
							}
						}
						$thisSession->{command_calls} = 0;
						
						if ($sCmd eq 'EVAL'){
							# By passing the original args as well, we allow the eval to execute nice custom commands
							($sResult, $bContinued, $bError) = &{$aActionCommands{$sCmd}->{command}}($idSession, $sArgs, $sArgsOriginal);
						}
						else{
							($sResult, $bContinued, $bError) = &{$aActionCommands{$sCmd}->{command}}($idSession, $sArgs);
						}
						
						
					}
					else{
						$sResult = "-- ERROR: Not enough permissions to execute \"$sCmd\"";	
						$bError  = 1;
					}
				}
				elsif($sResult eq ''){
					$sResult = sprintf('-- ERROR: Unknown command "%s%s"', substr($sCmd, 0, 10), length($sCmd) > 10 ? '...':'');
					$bError  = 1;
				}

				if ($sResult ne ''){
					$bContinued = $bContinued == 1 ? 1 : 0;
					message_deliver('SYS', $idSession, $sResult, $bContinued, $bContinued, $bContinued);
				}

				# Copy output
				if (!$bError){
					if ($idSession == 0 && $sCmd ne 'SEND' && $Configs{CopyHostOutput} ne '' && $Configs{CopyHostOutput} ne 'OFF' && $Configs{CopyHostOutput} ne $idSession && $Configs{CopyHostOutput} ne 'HOST' && !$thisSession->{'command_target'}){
						$thisSession->{'command_target'} = $Configs{CopyHostOutput};
					}
					if (!$bContinued && $thisSession->{'command_target'}){
						message_send($idSession, $thisSession->{'command_target'}, $sResult, 0, 1, 0);
						$thisSession->{'command_target'} = '';
					}
				}
				return 1;
			}
		}
		else{
			message_deliver('SYS', $idSession, '', 1);
			message_send($idSession, $thisSession->{target}, $sLine);
			return 0;
		}
	}
	else {
		# AWAITING INPUT: LINE
		if ($thisSession->{input_type} eq 'LINE'){
			if ($thisSession->{'input_var'} ne ''){
				$sLine =~ s/\s+$//;
				$thisSession->{'VARS'}->{$thisSession->{'input_var'}} = $sLine;
			}
			$thisSession->{input_type} = '';
		}
		# AWAITING INPUT: BLOCK
		elsif ($thisSession->{input_type} eq 'BLOCK'){
			if ($sLine !~ /^NNNN\s*$/i){
				if ($thisSession->{'input_var'} ne ''){
					$thisSession->{'VARS'}->{$thisSession->{'input_var'}} .= $sLine.$lf;
				}
			}
			else{
				$thisSession->{input_type} = '';
			}
		}
		# AWAITING INPUT: OUT-EMPTY
		if ($thisSession->{input_type} eq 'OUT-EMPTY'){
			if ($thisSession->{'input_var'} ne ''){
				$thisSession->{'VARS'}->{$thisSession->{'input_var'}} = 1;
			}
			$thisSession->{input_type} = '';
		}

		
		# NEXT COMMAND
		if ($thisSession->{input_type} eq ''){




#!!! This should be changed, no need to redo all the code from above....
			if ($thisSession->{command}){
				
				my $sCmdRef = $thisSession->{command};
				
				my $sResult    = '';
				my $bContinued = 0;
				my $bError     = 0;
				
				$thisSession->{command} = '';
				
				if (exists($aActionCommands{$sCmdRef})){
					if ($aActionCommands{$sCmdRef}->{auth} <= $thisSession->{auth}){
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
					
					# Copy output
					if (!$bError && !$bContinued && $thisSession->{'command_target'}){
						message_send($idSession, $thisSession->{'command_target'}, $sResult, 0, 1, 0);
						$thisSession->{'command_target'} = '';
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
		$Configs{MsnEnabled} = 0;
		
		if ($Configs{Debug}){ logDebug("\nMSN disabled due to dependencies not fulfilled\n");}
		
		return 0;
	}
	
	
	if ($Configs{MsnEnabled}){
		
		if ($Configs{MsnDebug} == 1){
			# create an MSN object showing all server errors and other errors
			$oMSN = new MSN('Handle' => $Configs{MsnUsername}, 'Password' => $Configs{MsnPassword});
		}
		elsif ($Configs{MsnDebug} == 2){
			# OR create an MSN object with full debugging info
			$oMSN = new MSN('Handle' => $Configs{MsnUsername}, 'Password' => $Configs{MsnPassword}, 'AutoloadError' => 1, 'Debug' => 1, 'ShowTX' => 1, 'ShowRX' => 1 );
		}
		else{
			# OR create an MSN object with all error messages turned off
			$oMSN = new MSN('Handle' => $Configs{MsnUsername}, 'Password' => $Configs{MsnPassword}, 'ServerError' => 0, 'Error' => 0 );
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
		$Configs{MsnEnabled} = $bEnable;
	}
	
	my $sOut = '';
	if ($Configs{MsnEnabled}){
		if ($Configs{MsnUsername} ne ''){
			if ($Configs{Debug}){ logDebug("\nEnabled MSN: $Configs{MsnUsername}\n"); }
			
			UI_updateStatus("Connecting to MSN...\nWindow may freeze for a few seconds!");
			
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
			$Configs{MsnEnabled} = 0;
		}
	}
	else{
		if ($Configs{Debug} > 0){ logDebug("\nDisabled MSN\n"); }
		if (defined $oMSN){
			# connect to the server
			$oMSN->disconnect();
		}
		UI_updateStatus();
		$sOut = '-- MSN Disconnected';
	}
	return $sOut;
}



sub msn_io{
	if ($Configs{MsnEnabled} && defined $oMSN){
		
		foreach my $thisSession (@aSessions){
			if ($thisSession->{'status'} && $thisSession->{'type'} eq 'MSN'){
				if ($thisSession->{'direction'} == 0){
					if (length($thisSession->{OUT}) > 0){
						
						my $sMsg = '';
						# Decently cut long messages by lines
						if (length($thisSession->{OUT}) < 1400 || index($thisSession->{OUT}, $lf) < 0){
							$sMsg = $thisSession->{OUT};
							$thisSession->{OUT} = '';
						}
						else{
							# Get the initial line
							my $nPos = index($thisSession->{OUT}, $lf);
							$sMsg .= substr($thisSession->{OUT}, 0, $nPos + 1, '');
							
							$nPos = index($thisSession->{OUT}, $lf);
							while(length($thisSession->{OUT}) > 0 && $nPos >= 0 && (length($sMsg) + $nPos) < 1300){
								# Add as many lines as possible before reaching the limit or reaching the last line
								$sMsg .= substr($thisSession->{OUT}, 0, $nPos + 1, '');
								$nPos  = index($thisSession->{OUT}, $lf);
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

	if ($Configs{Debug} > 0){ logDebug("\nMSN Connected as $Configs{MsnUsername}\n" ); }

	$MsnConnected = 1;

	UI_updateStatus();
	message_send('SYS', $MsnConnectBy, "-- MSN Connected as $Configs{MsnUsername}");
	
	#$oMSN->{Notification}->send( 'LST', 'FL');

	# example of a call with style and P4 name
	#$msn->call( $admin, "I am connected!", 'Effect' => 'BI', 'Color' => '00FF00', 'Name' => 'TTY' );
}

sub msn_statusDisconnected{
	my $self = shift;

	if ($Configs{Debug} > 0){ logDebug("MSN $Configs{MsnUsername} Disconnected\n" );  }
	
	$MsnConnected = 0;
	
	UI_updateStatus();
	message_send('SYS', $MsnConnectBy, "-- MSN $Configs{MsnUsername} Disconnected");
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
			
			if ($Configs{Debug} > 1){ logDebug("\nMSN Decoded: $sSourceEmail"); }
		}
		
		$sMessage =~ s/<msnobj.+?>//i;
	}


	if ($Configs{Debug} > 0){ logDebug("\nMSN $sAddress: $sMessage"); }

	my $idSession = session_get("address=$sAddress", 'id');

	if (!defined $idSession){
		# UNAUTHENTICATED
		if (substr($sMessage, 0, 1) eq $Configs{EscapeChar}){
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
						'COMMANDS'    => [],
						'command_num' => -1,
						'input_type'  => '', 
						'input_var'   => '', 
						'input_prompt'=> '',
						'echo_input'  => 1,
						'echo_msg'    => 0, 
						'command'     => '',
						'label'       => 1
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
		elsif($Configs{MsnListen}){
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
	my($idSession, $sIn) = @_;
	my $sOut = '';
	my $n;
	
	for ($n = 0; $n < length($sIn); $n++){
		$sOut .= debug_char($idSession, substr($sIn, $n, 1));
	}
	return $sOut;
}

sub debug_char{
	my($idSession, $c) = @_;
	my $thisSession = $aSessions[$idSession];
	my $sCode = $Configs{"TTY.$idSession.Code"};
	my $o;
	
	if ($sCode && $sCode ne 'ASCII'){
		if (exists $aEscapeCharsDebugITA2{$c}){
			return '<'.$aEscapeCharsDebugITA2{$c}.'>';
		}
		
		$o  = $CODES{$sCode}->{'FROM-LTRS'}->{$c};
		$c  = $CODES{$sCode}->{'FROM-FIGS'}->{$c};
		$o .= '|'.(exists $aEscapeCharsDebugASCII{$c}) ? '<'.$aEscapeCharsDebugASCII{$c}.'>' : $c;
		return $o;
	}
	else{
		if (exists $aEscapeCharsDebugASCII{$c}){
			return '<'.$aEscapeCharsDebugASCII{$c}.'>';
		}
		else{
			return $c;
		}
	}
	return '<?>';
}


sub logDebug{
	my($sLine) = @_;

	if ($Configs{Debug} > 0 && $Configs{DebugFile} ne ''){
		if (!defined $rDebugHandle){
			
			$sDebugFile = $Configs{DebugFile};
			
			my $sNow = get_datetime();
			
			my $sDatetime = $sNow;
			$sDatetime    =~ s/\D//g;
			my $sDate     = substr($sDatetime, 0, 10);
			
			# Note: Very primitive way to replace datetime and date in file
			$sDebugFile   =~ s/\$DATETIME/$sDatetime/;
			$sDebugFile   =~ s/\$DATE/$sDate/;
			
			open($rDebugHandle, '>>', $sDebugFile);
			
			
			if ($rDebugHandle){
				print "\n-- HeavyMetal v$sGlobalVersion ($sGlobalRelease) - Debug $Configs{Debug} - $sNow --\n";
				
				print $rDebugHandle "-- HeavyMetal v$sGlobalVersion ($sGlobalRelease) - Debug $Configs{Debug} - $sNow --\n";
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
	if ($Configs{EscapeEnabled} && index($sLine, $Configs{EscapeChar}) >= 0){
		for ($n = 0; $n < length($sLine); $n++){
			$c = substr($sLine, $n, 1);	
			if ($sEscape eq ''){
				if ($c eq $Configs{EscapeChar}){	
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
						$d = $aEscapeCharsDecodeASCII{$sCode};
					}
					elsif (exists $aEscapeCommands{$sCode}){
						# An escape immediate action
						$d = &{$aEscapeCommands{$sCode}}($idSession);
					}
					else{
						# Not an escape sequence at all
						$sLine2 .= $sEscape;
						$d = undef;
					}
					
					if ($c eq $Configs{EscapeChar}){
						# New escape start detected
						$sEscape = $c;
					}
					elsif ($c eq ' ' && defined $d){
						# Space after successful escape sequence is ignored
						$sEscape = '';
						$sLine2 .= $d;
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
		}
	}
	else{
		return $sLine;
	}
	
	return $sLine2;
}







sub transcode_to_loop{
	my($idSession, $sLine) = @_;
	my $thisSession = $aSessions[$idSession];
	my $n;
	my $c;
	my $d;
	my $sOut         = '';
	my $sStatusShift = $ltrs;
	my $sCode = $Configs{"TTY.$idSession.Code"};
	
	for ($n = 0; $n < length($sLine); $n++){
		$c = substr($sLine, $n, 1);

		# PROCESS ASCII->ASCII LOOP
		if ($sCode eq "ASCII" ) {
			if ($c eq $lf && $Configs{"TTY.$idSession.TranslateLF"}){
				$d = $EOL;
			}
			elsif ($c eq $cr && $Configs{"TTY.$idSession.TranslateCR"}) {
				$d = $EOL;
			}
			else {
				$d = $c;
			}
		}
		# PROCESS OTHER->ASCII LOOP
		else {

			if ($CODES{$sCode}->{upshift}){
				$c = uc($c);
			}
		
			if ($c eq $lf){
				$d = $aSessions[$idSession]->{eol};
				$sStatusShift = $ltrs;
			}
			elsif (exists($CODES{$sCode}->{'TO-LTRS'}->{$c})){
				if ($sStatusShift eq $figs) {
					$sOut        .= $ltrs;
					$sStatusShift = $ltrs;
				}
				$d = $CODES{$sCode}->{'TO-LTRS'}->{$c}
			}
			elsif (exists($CODES{$sCode}->{'TO-FIGS'}->{$c})){
				if ($sStatusShift eq $ltrs) {
					$sOut        .= $figs;
					$sStatusShift = $figs;
				}
				$d = $CODES{$sCode}->{'TO-FIGS'}->{$c}
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
sub UI_weather_FTP_init{
	my($sMenu, $sWhat, $sState) = @_;
	
	if (!defined $sState || $sWhat ne 'climate' && $sWhat ne 'forecast'){
		return;
	}
	
	if (length $sState == 2){
		my @aFiles = ftp_list(($sWhat eq 'climate' ? $Configs{WeatherNoaaClimateBase} : $Configs{WeatherNoaaForecastBase}) . lc($sState) . '/*');
		if (scalar @aFiles != 1 || $aFiles[0] !~ /^-- ERROR/){
			$oTkMenues{$sMenu}->delete(0, 'last');
		}
		
		if (scalar @aFiles > 0){
 			my $rCities = [];
			foreach my $sCity (sort @aFiles){
				$sCity =~ s/\.txt$//;
				$sCity =~ tr/_/ /;
				if ($sCity =~ /^-- ERROR/){
					$oTkMenues{$sMenu}->add_command(-label => $sCity);
				}
				else{
					$oTkMenues{$sMenu}->add_command(-label => $sCity, -command  => [\&host_add_text, "$Configs{EscapeChar}WEATHER NOAA ".($sWhat eq 'climate' ? 'CLIMATE ' : '')."$sState $sCity\n"]);
					push(@$rCities, $sCity);
				}
			}
			if (!defined($Global{'NoaaFtpTree'}->{$sWhat})){
				$Global{'NoaaFtpTree'}->{$sWhat} = {};
			}
			$Global{'NoaaFtpTree'}->{$sWhat}->{$sState} = $rCities;
		
			if ($Modules{JSON}->{loaded}){
				if (open(my $FH, '>', 'tmp/noaa-ftp.json')){
					print $FH encode_json($Global{'NoaaFtpTree'});
					close($FH);
				}
			}
		}
		
	}
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
		#"- LU8AJA Tests -" => {'LNET' => 'http://lucille/'},
	);
	
	# Prepend the base url to everything
	
	my $sSubCat;
	my $sLabel;
	my $sCategory;
	my $sBase;

	$sCategory = '- Special Events -';
	$sBase     = 'http://www.buzbee.net/heavymetal/asciiart/';
	foreach my $sSubCat (keys %{$rtty_art{$sCategory}}){
		foreach my $sLabel (keys %{$rtty_art{$sCategory}->{$sSubCat}}){
			$rtty_art{$sCategory}->{$sSubCat}->{$sLabel} = $sBase.$rtty_art{$sCategory}->{$sSubCat}->{$sLabel};
		}
	}

	$sCategory = '- Links to Royer Pavilion @ RTTY.COM -';
	$sBase     = 'http://www.rtty.com/gallery/';
	foreach my $sSubCat (keys %{$rtty_art{$sCategory}}){
		foreach my $sLabel (keys %{$rtty_art{$sCategory}->{$sSubCat}}){
			$rtty_art{$sCategory}->{$sSubCat}->{$sLabel} = $sBase.$rtty_art{$sCategory}->{$sSubCat}->{$sLabel};
		}
	}
	
	return %rtty_art;
}


