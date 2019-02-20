

sub load_custom_commands{
	my ($pCommands, $pConfigs, $pModules) = @_;
	# The scope of this file is isolated except for the functions, so we must use a function, and there configure the system to run our command
	
	
	# Definition of the command, this causes the command to become available, uncomment the following lines
	$pCommands->{'WHATEVER'} = {
		command => \&do_custom_whatever, 
		auth => 2, 
		help => 'Cmd description', 
		args => 'list possible args'
	};
	
	# pConfigs and pModules can be acessed in the same way to add newer configs, or require certain modules
	# You may have many commands defined in this function, here only one is given as example
	
}


# Remember to change WHATEVER everywhere to the name of your command
# Always name your custom command function name with "do_custom_" followed by your command name in lowercase
sub do_custom_whatever{
	my ($idSession, $sArgs) = @_;
	my $sCmd = 'WHATEVER'; #Change to the name of your custom command
	
	# This array will hold you arguments by position, a simple space based split
	my @aArgs = split(/\s+/, $sArgs);
	# The prefix to identify which variables within the session are related to your command, normally the command in lowercase
	my $sVarPrefix = lc($sCmd)."_";

	# Setup your vars if needed, if not delete
	my $sServer  = $Configs{EmailSMTP};    
	my $sTo      = '';
	my $sSubject = '';
	my $sMessage = '';
	
	command_start($idSession, $sCmd, 'NICE TITLE GOES HERE');  # Init the command
	
	# START: Arguments by position (separated by spaces)
		# Try to get TO directly from the command line, 
		$sTo = (exists($aArgs[0]) && $aArgs[0] ne '') ? $aArgs[0] : '';
		
	# END: Arguments by position
	
	
	# START: Arguments "rest of the line"
		# Try to get SUBJECT from the command line (i.e. the rest of the command line)
		if ($sArgs ne ''){
			$sSubject = $sArgs;
			# The PCRE is used to remove the initial word(s) from the line, repeat the line according to how many arguments by position you have, before your "rest of the line"
			$sSubject =~ s/^\S+\s+//; 
			
			
			# You could instead glue the args array, but you could not be preserving the correct whitespaces
		}
	# START: Arguments "rest of the line"
	

	# START: Interactive section. 
		# There are several ways to obtain the interactive inputs, the 3rd parameter determines that.
		# Every time there is a new line, we execute the whole command again and again, the difference is that we advance further and further into the command
		# And in every step we store the new input in the corresponding variable which is also saved in its session
		# Once we are done asking things, we use the OUT-EMPTY, this is not really to retrieve data from the stream, but instead to wait the 
		# out buffer to be emptied  hence having shown everything to the user
		# If you don't what the interactive section, simply directly use the arguments from $aArgs and delete the interactive section
		
			
		# Get the TO (LINE input with PCRE validation)
		$sTo = command_input($idSession, $sVarPrefix.'to', 'LINE', $sTo, '^[\w\-\.]+[\@\:\$][\w\-\.]+\.\w+$', "\aTo: ", $sCmd);
		if ($sTo      eq ''){ return ('', 1); }
	
		# Get the SUBJECT (LINE input without validation, any nonempty will do)
		$sSubject = command_input($idSession, $sVarPrefix.'subject', 'LINE', $sSubject, '', "\aSubject: ", $sCmd);
		if ($sSubject eq ''){ return ('', 1); }
		
		# Get the MESSAGE (BLOCK multiline input without validation)
		$sMessage = command_input($idSession, $sVarPrefix.'message', 'BLOCK', $sMessage, '', "\aMessage: ", $sCmd);
		if ($sMessage eq ''){ return ('', 1); }
		
		# Make sure the OUT buffer is empty before proceeding
		my $bReady = command_input($idSession, 'ready', 'OUT-EMPTY', '', '', "-- Sending...\n\n", $sCmd);
		if ($bReady eq ''){ return ('', 1); }

	# END: Interactive section

	eval {
		# At this point we do all of our stuff
		
		# YOUR CODE LOGIC GOES HERE
		
		
		# It is VERY important to clear everything once done, the 3rd param is the PCRE used to identify the variables which must be cleared when done
		command_done($idSession, '', '^'.$sVarPrefix);
		# Change this end result to whatever you wish, try to keep the format
		return ('-- WHATEVER EXECUTED --');
		
	};
	if ($@) {
		# It is important here that we are flaging this as an error and we are not clearing the variables with command done, so if we want to retry the var are already set.
		command_done($idSession);
		return ("-- ERROR: Failed to complete WHATEVER command: $@", 0, 1);
	}

}

# This last 1 is fundamental so perl can include the file, otherwise you will get an error
1;