# HeavyMetal TTY Control Program

HeavyMetal is a perl based software with a Tk/Tcl based GUI, which allows your PC (be it Windows or Linux) to interact with a teleprinter (TTY) over the good old RS-232 serial port.

The software allows you to access different internet services, as well as be accessed by different types of clients. We could describe HeavyMetal as a kind of chat/messaging server, with support for many protocols, and above all the ability to interact with these old steel monsters we lovely call TTYs. One basic problem we face with TTYs is the need to feed them with suitable data, as well as the need to impress those who come home showing the top tech from the early XXth century still interacting with all the top tech of the XXIst century...

HeavyMetal was developed by Bill Buzbee from 2001 to 2006. You can access his webpage here, where you can get version 1.27

Between May and November 2010, I took the task of entirely rewriting the code into a more expandable codebase, while adding support for sessions and many new cool features. At the same time I kept the GUI more or less as it was.

Project homepage: http://www.albinarrate.com/heavymetal.html

##Version History

###HeavyMetal v3.0
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