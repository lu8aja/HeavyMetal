# HeavyMetal TTY Control Program

HeavyMetal is a perl based software with a Tk/Tcl based GUI, which allows your PC (be it Windows or Linux) to interact with a teleprinter (TTY) over the good old RS-232 serial port.

The software allows you to access different internet services, as well as be accessed by different types of clients. We could describe HeavyMetal as a kind of chat/messaging server, with support for many protocols, and above all the ability to interact with these old steel monsters we lovely call TTYs. One basic problem we face with TTYs is the need to feed them with suitable data, as well as the need to impress those who come home showing the top tech from the early XXth century still interacting with all the top tech of the XXIst century...

HeavyMetal was developed by Bill Buzbee from 2001 to 2006. You can access his webpage here, where you can get version 1.27

Between May and November 2010, I took the task of entirely rewriting the code into a more expandable codebase, while adding support for sessions and many new cool features. At the same time I kept the GUI more or less as it was.

In 2012 I was forced to give another jump into v3.1 due to changes in the ActivePerl distribution (they dropped the Tk extension I was using), so as I had to rewrite pretty much the whole GUI into a new module (Tkx). I obviously took the chance to make many changes that were in the ToDo list.

Project homepage: http://www.albinarrate.com/heavymetal.html

## HeavyMetal v3.1 in Linux

The following is a step by step list to get heavyMetal working on linux.
You may need to adapt some steps to best fit your needs.

1- Get the Fedora installed (Using VMWare image in my case)
	In your case you almost surely will not need to do this ;)

2- Allow root acces by modifying pam
	Files: /etc/pam.d/gdm and /etc/pam.d/gdm-password
	Comment out line: auth required pam_succeed_if.so user != root quiet
	Instructions: http://fedoraproject.org/wiki/Enabling_Root_User_For_GNOME_Display_Manager
	In your case you almost surely will not need to do this ;)

3- Login as root

4- Download and install latest ActivePerl community edition as a package
	http://www.activestate.com/activeperl/downloads
	In my case ActivePerl-5.14.2.1402-i686-linux-glibc-2.3.6-295342.tar.gz
	
5- Extract it with the archive manager

6- Follow instructions in readme.txt from the extracted folder:
	Open terminal
	cd into the extracted dir
	Then run: sh install.sh
	Install it into the default /opt/ActivePerl-blah
	
7- Edit /home/root/.bash_profile
	Added the following lines:
		export PATH=$HOME/bin:/opt/ActivePerl-5.14/bin:$PATH
		export PERL5LIB=/opt/ActivePerl-5.14/lib:/opt/ActivePerl-5.14/site/lib
	Logout and login again (apparently this was needed to reload the ENV vars?!)
	
8- Install the following packages with the OS packages tool (System Tools / Add/Remove Software):
	X.Org X11 libXss runtime library
	command line clipboard grabber (xclip)
	
9- With the Activeperl ppm, install the packages
	cd /opt/ActivePerl-5.14/bin
	ppm-shell 
		install Device-SerialPort
		install Clipboard
		install Crypt-SSLeay
		install Finance-YahooQuote
		install XML-RSS-Parser
		
	Or equivalent actions with the GUI based ppm
	
10- DONE! Go to the heavymetal dir, and do:
	perl heavymetal.pl
	
	According to your setup, you might need to provide an absolute path to perl, or to edit the first line of heavymetal.pl to indicate to the shell, where is perl.

## HeavyMetal v3.1 in Windows

The following is a step by step list to get heavyMetal working on Windows.
You may need to adapt some steps to best fit your needs.
Please note that is you are using an HeavyMetal version with ActivePerl 
already packaged, you do not need to follow these instructions. 

1- Download and install latest ActivePerl community edition 32 bits x86 
	Do not use 64 bits!
	http://www.activestate.com/activeperl/downloads
	In my case ActivePerl-5.14.2.1402-MSWin32-x86-295342.msi
	
2- Once installed, execute the Perl Package Manager you can find in the 
   Start menu or use the ppm-shell command

3- Install the following components:
	Tkx
	Tkx-Scrolled
	Win32-API
	Clipboard
	Crypt-SSLeay
	Finance-YahooQuote
	HTML-TreeBuilder
	Weather-Google
	XML-RSS-Parser

	Remember that some of these may already be installed in your perl 
	setup while some other module not mentioned here may be missing 
	in your setup.
	
	During HM initialization, you will see a list of perl modules being
	loaded. If some one fails it will be notified there. Also keep in 
	mind that most modules are optional and they are reported as 
	OPTIONAL. Hence if a module does not load, HM will initialize 
	properly, but the features that require the failed module will 
	simply not work.
	
4- DONE! Go to the heavymetal dir, and do:
	perl heavymetal.pl
	
	You may need to add the perl/bin folder to your path environment 
	variable.
	On initialization the list of modules will come up and if there 
	is any error it will be mentioned. You might need to install more
	packages according to your environment.
	Most modules are optional, and if they do not load, whatever feature
	that relies on them will be disabled.
	That means that even with some modules missing, you may get the GUI working.


##Version History

### HeavyMetal v3.0 (2010-06-25)
* Session based with independent buffers
* Support for Telnet clients and servers
* Ability to pipe a telnet connection between two HMs so you can chat TTY-to-TTY over Internet
* MSN client allows to send and receive messages and commands via MSN
* Eyeball labels in punched tape
* Expandable support for different encodings
* Whole new way to setup configurations, easily expandable
* Reorganized commands so new commands can be easily added
* Fixed AP News & Today in History
* Fixed SMTP Auth
* Fixed NOAA FTP url used for Weather forecasts

### HeavyMetal v3.1.000 (2012-02-28)
* Rewrote the GUI, now uses tabs and configs are available right at the GUI. You even have icons!
* Support for ConsoleOnly mode. With it you can run HM as a daemon and access it via Telnet.
* Support for multiple serial ports (max 2 for now, but easily expandable) with totally independent configurations.
* RSS News feeds now allow to add any source for the news summary
* Full news supported for selected sources. Right now Reuters and BBC. We can easily add more on demand.
* Custom commands, now you can write your own command, and configure it right from the GUI
* Loop echo detection (it automatically checks for echo and enables loop echo suppression with just one click)
* Favorites for everything, now you can easily setup at the GUI your favorite Weather cities, telnet hosts, news feeds, etc. They will simply show up in the menu.
* A system to autoupdate the software with a single click
* Fix to the weather FTP from NOAA, now the cities are dynamically loaded instead of having a static list (which was outdated)
* A plethora of bugfixes. Now it has been tested in Linux (Fedora using ActivePerl)

### HeavyMetal v3.1.001 (2012-03-10)
* New RSS tab to handle many many RSS feeds
* Many Favorites added to menus
* Main weather provider switched to WWO
* Added special RSS feed for historic cables
* Added WEATHER METAR support in various formats and with subcommand
* Added a progress bar for measuring the buffer in a nice graphical way

### HeavyMetal v3.1.002 (2012-03-25)
* New built-in CRON for scheduled tasks
* Twitter feeds support via RSS
* METAR HISTORIC format, just like the weather teletypes from the 1940s
* NOAA CLIMATE access added
* NOAA menues are now cached
* Double click on a feed in the RSS tab now shows a summary for that feed.
* $WEB command for very basic HTML text-browsing
* New built-in BANNER command, in replacement of the external command used in previous versions