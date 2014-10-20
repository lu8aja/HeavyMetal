#================================================
package MSN::SwitchBoard;
#================================================

use strict;
use warnings;

use URI::Escape;

# For DP
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);
use MIME::Base64;
use Data::Dumper;

use POSIX;

# For errors
use MSN::Util;
use MSN::P2P;

sub checksum { my $o = tell(DATA); seek DATA,0,0; local $/; my $t = unpack("%32C*",<DATA>) % 65535;seek DATA,$o,0; return $t;};


sub new
{
        my $class = shift;
        my ($msn, $host, $port) = @_;

        my $self  =
        {
                Msn            => $msn,
                Host           => $host,
                Port           => $port,
                Socket         => undef,
                Members        => {},
                Call           => {},
                p2pQue         => [],
                Type           => 'SB',
                MessageStyle   => $msn->getMessageStyle(),
        };

        bless( $self, $class );
        $self->{P2P} = new MSN::P2P($self);
        return $self;
}

sub DESTROY
{
        my $self = shift;

        # placeholder for possible destructor code
}

sub AUTOLOAD
{
        my $self = shift;

        my $method = $MSN::SwitchBoard::AUTOLOAD;

        if( $method =~ /CMD_(.*)$/ )
        {
                $self->cmdError( "$1 not handled in MSN::SwitchBoard" );
        }
        else
        {
                $self->error( "method $method not defined" ) if( $self->{Msn}->{AutoloadError} );
        }
}

sub debug
{
        my $self = shift;

        return $self->{Msn}->debug( @_ );
}

sub error
{
        my $self = shift;

        return $self->{Msn}->error( @_ );
}

sub serverError
{
        my $self = shift;

        return $self->{Msn}->serverError( @_ );
}

sub cmdError
{
        my $self = shift;

        return $self->{Msn}->cmdError( @_ );
}

#================================================
# Methods to connect from a RNG or XFR
#================================================

sub connectRNG
{
        my $self = shift;
        my ($key, $sid) = @_;

        $self->debug( "Connecting to SwitchBoard at $self->{Host}:$self->{Port}" );

        $self->{Socket} = new IO::Socket::INET(
                                                                  PeerAddr => $self->{Host},
                                                                  PeerPort => $self->{Port},
                                                                  Proto          => 'tcp',
                                                                  Timeout  => 60
                                                                ) or return $self->error( "$!" );

        $self->{Msn}->{Select}->add( $self->{Socket} );
        $self->{Msn}->{Connections}->{ $self->{Socket}->fileno } = $self;
        $self->send( 'ANS', "$self->{Msn}->{Handle} $key $sid" );
}

sub connectXFR
{
        my $self = shift;
        my ($key, $handle, $message, $style) = @_;

        # store the call handle and message for later delivery
        $self->{Call}->{Handle} = $handle;
        $self->{Call}->{Message} = $message;
        $self->{Call}->{Style} = $style;

        $self->debug( "Connecting to SwitchBoard at $self->{Host}:$self->{Port}" );

        $self->{Socket} = new IO::Socket::INET(
                                                                  PeerAddr => $self->{Host},
                                                                  PeerPort => $self->{Port},
                                                                  Proto          => 'tcp'
                                                                ) or return $self->error( "$!" );

        $self->{Msn}->{Select}->add( $self->{Socket} );
        $self->{Msn}->{Connections}->{ $self->{Socket}->fileno } = $self;
        $self->send( 'USR', "$self->{Msn}->{Handle} $key" );
}

#================================================
# Main public methods to set message style,
# send messages and invite contacts into the convo
#================================================

sub setMessageStyle
{
        my $self = shift;

        $self->{MessageStyle} = { (%{$self->{MessageStyle}}), @_ };
}

sub getMessageStyle
{
        my $self = shift;

        return $self->{MessageStyle};
}

sub getMembers
{
        my $self = shift;

        return $self->{Members};
}

sub getID
{
        my $self = shift;

        return $self->{Socket}->fileno;
}

sub getType
{
        my $self = shift;

        return 'SB';
}

sub leave
{
        my $self = shift;

        $self->debug( "Leaving SwitchBoard " . $self->{Socket}->fileno );

        return $self->_send( "OUT\r\n" );
}

sub sendInk
{
                  my $self = shift;
                  my $data = shift;

                  my $inkheader = "MIME-Version: 1.0\r\nContent-Type: application/x-ms-ink\r\n";

                  if($data =~ m/\.isf/){
                       open( INK, $data ) or return $self->error( "Could not find the file '$data'" );
                       binmode(INK);
                       $data = '';
                       while( <INK> ) { $data .= $_; }
                       close(INK);
                       $data = encode_base64($data);
                       $data =~ s/\n//gs;
                  }
                  #check num of users
                  if(scalar(keys %{$self->getMembers})==1){
                   $self->{P2P}->sendInk_P2P($data);
                  }
                  else {
                  #do normal ink
                       my $chunks = ceil(length( $data ) / 1202);
                       if($chunks > 1){
                            for (my $chunk = 0; $chunk < $chunks; $chunk++) {
                               my $ink_data = $inkheader . "Message-ID: {CDB7FFFF-C94B-9CC9-5C09-4BFFE25FFFFF}\r\n";
                               $ink_data .= ($chunk) ? "Chunk: $chunk\r\n\r\n" : "Chunks: $chunks\r\n\r\nbase64:";
                               $ink_data .= substr($data, $chunk * 1202, 1202) . "\r\n";
                               $self->sendraw('MSG', 'N '.length($ink_data). "\r\n" . $ink_data);
                            };
                       }
                       else {
                            my $ink_data = $inkheader . "\r\nbase64:$data\r\n";
                            $self->sendraw('MSG', 'N '.length($ink_data). "\r\n" . $ink_data);
                       }
                  }
}

sub sendmsg
{
        my $self = shift;

        # DEPRECATED METHOD
        # USE sendMessage instead

        # tell the caller
        print( "!! DEPRECATED METHOD       !!\n!! USE sendMessage INSTEAD !!\n" );

        # route to our new method
        $self->sendMessage( @_ );
}

sub sendMessage
{
	my $self = shift;
	my $response = shift;

	if( !defined $response )	{ return $self->error( "You must pass the message you want to send" ); }

	# pull in the default style and overwrite with optionally passed in style
	# encode the Font name, which should only really encode spaces (maybe change this to substitute spaces with %20)
	my $style = { (%{$self->{MessageStyle}}), @_ };
	$style->{Font} = uri_escape( $style->{Font} );

	while( $response =~ /(.{1,1400})/gs )
	{
		my $message = $1;
		if( length $message )
		{
			my $objects = $self->{Msn}->{Notification}->{Objects};
			my @emotes = keys(%{$objects});
			@emotes = grep { index($message, $_) > -1 } @emotes;

			# only five allowed per message
			my $count = scalar (@emotes) < 6 ? scalar(@emotes) - 1 : 5;
			my $emomsg = join "", map {"$_\t". $objects->{$_}->{Object}."\t"} @emotes[0 .. $count] ;

			# Check
			if( $emomsg )
			{
				 my $emoheader = "MIME-Version: 1.0\r\nContent-Type: text/x-mms-emoticon\r\n\r\n$emomsg";
				 $self->sendraw("MSG", "N ".length($emoheader)."\r\n$emoheader");
			}


			my $sStyleFont         = defined $style->{Font}        ? $style->{Font}        : '';
			my $sStyleEffect       = defined $style->{Effect}      ? $style->{Effect}      : '';
			my $sStyleColor        = defined $style->{Color}       ? $style->{Color}       : '';
			my $sStyleCharacterSet = defined $style->{CharacterSet}? $style->{CharacterSet}: '';
			my $sStylePitchFamily  = defined $style->{PitchFamily} ? $style->{PitchFamily} : '';
							 
			my $header = qq{MIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\n} .
							 qq{X-MMS-IM-Format: FN=$sStyleFont; EF=$sStyleEffect; }.
							 qq{CO=$sStyleColor; CS=$sStyleCharacterSet; } .
							 qq{PF=$sStylePitchFamily\n};

			$header .= "P4-Context: " . $style->{Name} . "\n" if( exists $style->{Name} );
			$header .= "\n" . $message;
			$header =~ tr/\r//;
			$header =~ s/\n/\r\n/g;
			$self->sendraw( 'MSG', 'U ' . length($header) . "\r\n" . $header );
	  }
	}
}

sub sendTyping
{
        my $self = shift;

        my $header = qq{MIME-Version: 1.0\nContent-Type: text/x-msmsgscontrol\nTypingUser: } . $self->{Msn}->{Handle} . qq{\n\n\n};
        $header =~ s/\n/\r\n/gs;
        $self->sendraw( 'MSG', 'N ' . length($header) . "\r\n" . $header);
}

sub sendClientCaps
{
        my $self = shift;

        return if( scalar keys %{$self->{Msn}->{ClientCaps}} == 0 );

        my $caps = '';
        foreach my $key (keys %{$self->{Msn}->{ClientCaps}})
        {
                $caps .= $key . ": " . $self->{Msn}->{ClientCaps}->{$key} . "\n";
        }

        my $header = qq{MIME-Version: 1.0\nContent-Type: text/x-clientcaps\n\n} . $caps . qq{\n\n\n};
        $header =~ s/\n/\r\n/gs;
        $self->sendraw( 'MSG', 'N ' . length($header) . "\r\n" . $header);
}

sub invite
{
        my $self = shift;
        my $handle = shift || return $self->error( "Need a handle to invite" );

        $self->send( 'CAL',  $handle );
        return 1;
}

#================================================
# Internal methods to send data to the server
#================================================

sub _send
{
        my $self = shift;
        my $msg = shift || return $self->error( "No message specified" );

        # Send the data to the socket.
        $self->{Socket}->print( $msg );
        my $fn = $self->{Socket}->fileno;
        if( $msg eq "OUT\r\n" || $msg eq "BYE\r\n" )
        {
                $self->{Msn}->{Select}->remove( $fn );
                delete $self->{Msn}->{Connections}->{ $fn };
                undef $self->{Socket};
        }
        chomp($msg);

        print( "($fn $self->{Type}) TX: $msg\n" ) if( $self->{Msn}->{ShowTX} );
	#$self->{Msn}->call_event( $self, "RX", "TX - $msg" );

        return length($msg);
}

sub send
{
        my $self = shift;
        my $cmd  = shift || return $self->error( "No command specified to send" );
        my $data = shift;

        # Generate TrID using global TrID value...
        my $datagram = $cmd . ' ' . $self->{Msn}->{Notification}->{TrID}++ . ' ' . $data . "\r\n";
        return $self->_send( $datagram );
}

sub sendraw
{
        my $self = shift;
        my $cmd = shift || return $self->error( "No command specified to send" );
        my $data  = shift;
        # same as send without the "\r\n"

        my $datagram = $cmd . ' ' . $self->{Msn}->{Notification}->{TrID}++ . ' ' . $data;
        return $self->_send( $datagram );
}

sub sendrawnoid
{
        my $self = shift;
        my $cmd = shift || return $self->error( "No command specified to send" );
        my $data  = shift;

        my $datagram = $cmd . ' ' . $data;
        return $self->_send( $datagram );
	print( "RAWNOID SENDING $datagram\n\n" );
}

sub isOnline
{
        my $self = shift;
        my $handle = shift || return $self->error( "Need to send the handle of the person you want to check" );

        # try to get a new switchboard
        $self->send( 'CAL', $handle );

        # store the handle and message of this call for use after we have a switchboard (why subtract 1 here??)
#        my $TrID = $self->{TrID} - 1;
}

#================================================
# Method to dispatch server messages to the right handlers
#================================================

sub dispatch
{
        my $self = shift;
        my $incomingdata = shift || '';

        my ($cmd, @data) = split( / /, $incomingdata );

        if( !defined $cmd )
        {
                return $self->serverError( "Empty event received from server : '" . $incomingdata . "'" );
        }
        elsif( $cmd =~ /[0-9]+/ )
        {
                return $self->serverError( MSN::Util::convertError( $cmd ) . " : " . @data );
        }
        else
        {
                my $c = "CMD_" . $cmd;

                no strict 'refs';
                &{$c}($self,@data);
        }
}

#================================================
# MSN Server messages handled by SwitchBoard
#================================================

sub CMD_JOI
{
        my $self = shift;
        my ($user, $friendly) = @_;

        if( $self->{Call}->{Message} )
        {
                $self->sendMessage( $self->{Call}->{Message}, %{$self->{Call}->{Style}} );
                delete $self->{Call}->{Message};
                delete $self->{Call}->{Style};
        }

        $self->{Members}->{$user} = $friendly;
        $self->{Msn}->call_event( $self, "MemberJoined", $user, uri_unescape($friendly) );

        $self->sendClientCaps();
}

sub CMD_IRO
{
        my $self = shift;
        my (undef, $current, $total, $user, $friendly) = @_;

        if( $current == 1 )
        {
                $self->{Msn}->call_event( $self, "RoomOpened" );
        }

        $self->{Members}->{$user} = $friendly;
        $self->{Msn}->call_event( $self, "MemberHere", $user, uri_unescape($friendly) );

        if ($current == $total)
        {
                $self->{Msn}->call_event( $self, "RoomUpdated" );
                $self->sendClientCaps();
        }
}

sub CMD_ANS
{
        my $self = shift;
        my ($response) = @_;

        $self->{Msn}->call_event( $self, "Answer" );
}

sub CMD_CAL
{
        my $self = shift;
        my @data = @_;

}

sub CMD_BYE
{
        my $self = shift;
        my ($user) = @_;

        delete $self->{Members}->{$user} if $self->{Members}->{$user};
        $self->{Msn}->call_event( $self, "MemberLeft", $user );

        if( scalar keys %{$self->{Members}} == 0 )
        {
                $self->{Msn}->call_event( $self, "RoomClosed" );
                $self->{Msn}->{Select}->remove( $self->{Socket}->fileno() );
                delete $self->{Msn}->{Connections}->{ $self->{Socket}->fileno() };
#                undef $self;
        }
}

sub CMD_USR
{
        my $self = shift;
        my @data = @_;
#print( "\n\n" );
#foreach my $line( @data )
#{
#	print( "DATA - $line\n" );
#}
#print( "\n\n" );
        if( $data[1] eq 'OK' )
        {
                if( defined $self->{Call}->{Handle} )
                {
                        $self->send( 'CAL',  $self->{Call}->{Handle} );
                }
                else
                {
                        return $self->error( "Missing a call handle?\n" );
                }
        }
        else
        {
                return $self->error( 'Unsupported authentication method: "' . "@data" .'"' );
        }
}

sub CMD_MSG
{
        my $self = shift;
        my ($user, $friendly, $length) = @_;

        # we don't have the full message yet, so store it and return
        if( length( $self->{buf} ) < $length )
        {
                $self->{buf} = $self->{line} . $self->{buf};
                return "wait";
        }

        # get the message and split into header and msg content
        my ( $header, $msg ) = ( '', substr( $self->{buf}, 0, $length, "" ) );
        ($header, $msg) = _strip_header($msg);

	#print( "\n\nCT TYPE".$header->{'Content-Type'}."\n\n" );
        # determine message type
        if( $header->{'Content-Type'} =~ /text\/x-msmsgscontrol/ )
        {
                $self->{Msn}->call_event( $self, "Typing", $user, uri_unescape($friendly) );
        }
        elsif( $header->{'Content-Type'} =~ /text\/x-msmsgsinvite/ )
        {
                my $settings = { map { split(/\: /,$_) } split (/\r\n/, $msg) };
                if( $settings->{'Invitation-Command'} eq "INVITE" && $settings->{'Application-Name'} eq "File Transfer" )
                {
                         $self->{Msn}->call_event( $self, "FileReceiveInvitation",
                                                                                $user, uri_unescape($friendly),
                                                                                $settings->{'Invitation-Cookie'},
                                                                                $settings->{'Application-File'},
                                                                                $settings->{'Application-FileSize'} );
                }
                elsif ($settings->{'Invitation-Command'} eq "ACCEPT")
                {
                }
                elsif ($settings->{'Invitation-Command'} eq "CANCEL")
                {
                }
                # other....
        }
         elsif( $header->{'Content-Type'} =~ /text\/x-mms-emoticon/ )
         {
	          # emoticon objects being sent
         }
         elsif( $header->{'Content-Type'} =~ /application\/x-ms-ink/ )
         {
                  # normal ink message being sent
         }
        elsif( $header->{'Content-Type'} =~ /application\/x-msnmsgrp2p/ )
        {
                $self->{P2P}->p2p_transfer($user, $msg);
                #$self->p2p_transfer($user, $msg);
        }
        elsif( $header->{'Content-Type'} =~ /text\/x-clientcaps/ )
        {
                my $client_caps = { map { split(/\: /,$_) } split (/\r\n/, $msg) };

                $self->{Msn}->call_event( $self, "ClientCaps", $user, %$client_caps );
        }
        elsif( $header->{'Content-Type'} =~ /application\/x-msnmsgr-sessionreqbody/ )        {}
        elsif( $msg =~ /INVITE\s+MSNMSGR/g || $msg =~ /BYE\s+MSNMSGR/g )                                        {}
        else
        {         # regular hopefully
                my $format_info = defined $header->{'X-MMS-IM-Format'} ? $header->{'X-MMS-IM-Format'} : '';
                $format_info =~ /FN=(.*?);\s+EF=(.*?);\s+CO=(.*?);\s+CS=(.*?);\s+PF=(.*?)/;
                my %style = ( Font => $1, Effect => $2, Color => $3, CharacterSet => $4, PitchFamily => $5 );

                $self->{Msn}->call_event( $self, "Message", $user, uri_unescape($friendly), $msg, %style );
        }
}






#================================================
# Utility function for removing header from a message
#================================================

sub _strip_header
{
        my $msg = shift;

         if ($msg =~ /^(.*?)\r\n\r\n(.*?)$/s)
        {
                my ($head, $msg) = ($1,$2);
                my @temp = split (/\r\n/, $head);
                my $header = {};
                foreach my $item (@temp)
                {
                        my ($key,$value) = split(/:\s*/,$item);
                        $header->{$key} = $value || "";
                }

                return $header,$msg;
        }
        return {}, $msg;
}

#For Nudges (by mattaustin)
sub nudge{
my $self = shift;
my $nudge = "MIME-Version: 1.0\r\n".
          "Content-Type: text/x-msnmsgr-datacast\r\n".
          "\r\n".
          "ID: 1\r\n".
          "\r\n";
$self->sendraw("MSG", "N ".length($nudge)."\r\n$nudge");
}

return 1;
__DATA__