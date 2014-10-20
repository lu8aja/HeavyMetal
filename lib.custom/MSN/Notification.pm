#================================================
package MSN::Notification;
#================================================

use strict;
use warnings;

# IO
use IO::Socket;

# For authenticate
use URI::Escape;
use HTTP::Request;
use LWP::UserAgent;
use HTML::Entities qw(decode_entities);

# For challenge
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP::Simple;

# For DP
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);

# For RNG
use MSN::SwitchBoard;

# For errors
use MSN::Util;

#Swapped it out for msnp11
#use constant CVER10 => '0x0409 winnt 5.0 i386 MSNMSGR 6.1.0203 MSMSGS ';
#use constant VER => 'MSNP10 MSNP9 CVR0';
#my $VER = 'MSNP10 MSNP9 CVR0';

use constant CVER10 => '0x0409 winnt 5.0 i386 MSNMSGR 7.0.0732 MSMSGS ';
use constant VER => 'MSNP11 CVR0\r\n';
my $VER = 'MSNP11 MSNP10 CVR0';
sub checksum { my $o = tell(DATA); seek DATA,0,0; local $/; my $t = unpack("%32C*",<DATA>) % 65535;seek DATA,$o,0; return $t;};


sub new
{
        my $class = shift;
        my ($msn, $host, $port, $handle, $password) = (shift, shift, shift, shift, shift);

        my $self  =
        {
                Msn                                => $msn,
                Host                                => $host,
                Port                                => $port,
                Handle                        => $handle,
                Password                        => $password,
                Socket                        => {},
                Objects                        => {},
                DPLocation                => {},
                Type                                => 'NS',
                Calls                                => {},
                Lists                                => { 'AL' => {}, 'FL' => {}, 'BL' => {}, 'RL' => {} },
                PingTime      => time,
                PongTime      => time,
                UbxLength     => 0, # Added by LU8AJA 2010-05-26
                UbxEmail      => '', # Added by LU8AJA 2010-05-26
                PingIncrement => 30,
                NoPongMax     => 60,
                TrID          => 0,
                Objects       => {},
                DPLocation    => '',
                @_
        };
        bless( $self, $class );

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

        my $method = $MSN::Notification::AUTOLOAD;

        if( $method =~ /CMD_(.*)$/ )
        {
                $self->cmdError( "$1 not handled in MSN::Notification" );
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
# connect to the Notification Server
# add the socket to the Select object
# add self to the Connections hash
# start a conversation by sending VER
#================================================

sub connect
{
        my $self = shift;
        my $host = shift || $self->{Host};
        my $port = shift || $self->{Port};

        $self->{Socket} = new IO::Socket::INET( PeerAddr => $host, PeerPort => $port, Proto          => 'tcp' );

        # if we can't open a socket, set an error and return 0
        return $self->serverError( "Connection error: $!" ) if( !defined $self->{Socket} );

        $self->{Msn}->{Select}->add( $self->{Socket} );
        $self->{Msn}->{Connections}->{ $self->{Socket}->fileno } = $self;

        # start the conversation
        $self->send( 'VER', $VER );

        return 1;
}

sub disconnect
{
        my $self = shift;

        $self->debug( "Disconnecting from Notification Server" );

        return $self->_send( "OUT\r\n" );
}

sub getType
{
        my $self = shift;

        return 'NS';
}

sub send
{
        my $self = shift;
        my $cmd  = shift || return $self->error( "No command specified to send" );
        my $data = shift;

        # Generate TrID using global TrID value...
        my $datagram = $cmd . ' ' . $self->{TrID}++ . ' ' . $data . "\r\n";
        return $self->_send( $datagram );
}

sub sendraw
{
        my $self = shift;
        my $cmd = shift || return $self->error( "No command specified to send" );
        my $data  = shift;
        # same as send without the "\r\n"

        my $datagram = $cmd . ' ' . $self->{TrID}++ . ' ' . $data;
        return $self->_send($datagram);
}

sub _send
{
        my $self = shift;
        my $msg = shift || return $self->error( "No message specified" );

        return $self->error( "Trying to print '$msg' on an undefined socket" ) if( !defined $self->{Socket} );

        # Send the data to the socket.
        $self->{Socket}->print( $msg );

        my $fn = $self->{Socket}->fileno;
        if( $msg eq "OUT\r\n" || $msg eq "BYE\r\n" )
        {
                $self->{Msn}->{Select}->remove( $self->{Socket}->fileno() );
                delete $self->{Msn}->{Connections}->{ $self->{Socket}->fileno() };
                undef $self->{Socket};
        }
        chomp($msg);

        print( "($fn $self->{Type}) TX: $msg\n" ) if( $self->{Msn}->{ShowTX} );

        return length($msg);
}

sub setName
{
        my $self = shift;
        my $name = shift || return $self->error( "Must be passed new name." );

        if( length $name > 129 )
        {
                return $self->error( "Display name to long to set" );
        }

        $self->send( 'PRP', 'MFN ' . uri_escape( $name ) );

        return 1;
}

#Teario- set the psm data (MANY thanks to matt007 for showing me how)
sub setPSM
{
	my $self = shift;
	my $psm = shift;

	my $data = '<Data><PSM>'.$psm.'</PSM><CurrentMedia></CurrentMedia></Data>';
	$self->sendraw("UUX",  length($data)."\r\n" . $data);# if ($MSNPROTO eq 'MSNP11');
}
sub setPSMData 
{ 
my $self = shift; 
my $psm = shift; 
my $type = shift; 
my $music = shift; 
my $artist = shift; 
my $title = shift; 
my $btween = $title ? ' - {1}' : ''; 
my $ifmusic = $music ? '<CurrentMedia>\0'.$type.'\0'.$music.'\0{0}'.$btween.'\0'.$artist.'\0'.$title.'\0\0\0</CurrentMedia>' : ''; 
my $data = '<Data><PSM>'.$psm.'</PSM>'.$ifmusic.'</Data>'; 
$self->sendraw("UUX", length($data)."\r\n" . $data); 
}
	
sub setDisplayPicture
{
	my $self = shift;
	my $filename = shift;

	if( !$filename )
	{
		# Remove DP
		$self->{DPData} = '';
		$self->{MSNObject} = '';
		$self->setStatus( $self->{Msn}->{Status} );
		return 1;
	}else{

		if( $filename !~ /\.png$/ )
		{
			return $self->error( "File must be a PNG file" );
		}
	
		# append the time so we get a unique hash everytime
		# makes debuging easier because MSN can't cache it
		my $location = "msndp.dat". time;
		$self->{DPLocation} = $location;
		($self->{Objects}->{$location}->{Object},
		$self->{Objects}->{$location}->{Data}) = $self->create_msn_Object($filename,$location);
		# Set new status & return
		$self->setStatus( $self->{Msn}->{Status} );
		$self->debug( "Done With Dp!" );
		return 1;
	}
}

sub setStatus
{
        my $self = shift;
        my $status = shift || 'NLN';

        # save our current status for use in setDisplayPicture
        $self->{Msn}->{Status} = $status;

        my $object = '';
        if (defined $self->{DPLocation} && exists $self->{Objects}->{$self->{DPLocation}} ) {
                $object = uri_escape($self->{Objects}->{$self->{DPLocation}}->{Object});
        }
        $self->send( 'CHG', $status . " " . $self->{Msn}->{ClientID} . " " . $object);
}

sub addEmoticon
{
        my $self = shift;
        my $shortcut = shift;
        my $filename = shift;

        if((-e $filename) && $filename =~ /png$/)
        {
                ($self->{Objects}->{$shortcut}->{Object},
                $self->{Objects}->{$shortcut}->{Data}) = $self->create_msn_Object($filename,$shortcut);
                return 1;
        }
        else
        {
                return $self->error( "Could not find the file '$filename', or it is not a PNG file" );
        }
}

sub create_msn_Object
{
         my $self = shift;
         my $file = shift;
         my $location = shift;

         my $data = '';

         open( DP, $file ) || return $self->error( "Could not find the file '$file'" );
         binmode(DP);
         while( <DP> ) { $data .= $_; }
         close(DP);

         # SHA1D and the Display Picture Data
         my $sha1d = sha1_base64( $data ) . '=';

         # Compile the object from its keys + sha1d
         my $object = 'Creator="'  . $self->{Handle} . '" ' .
                                          'Size="'     . (-s $file)      . '" ' .
                                          'Type="3" '  .
                                          'Location="' . $location       . '" ' .
                                          'Friendly="AAA=" ' .
                                          'SHA1D="'    . $sha1d          . '"';

         # SHA1C - this is a checksum of all the key value pairs
         my $sha1c = $object =~ s/(\"=\s)*//g;
         $sha1c = sha1_base64( $sha1c ) . '=';

         # Put it all in its nice msnobj wrapper.
         $object = '<msnobj ' . $object . ' SHA1C="' . $sha1c . '" />';

         return ($object, $data);

}

#================================================
# Contact methods
#================================================

sub blockContact
{
        my $self = shift;
        my $email = shift || return $self->error( "Need an email address to block" );

        return 0 if( defined $self->{Lists}->{'BL'}->{$email} );

        $self->remContact($email);
        $self->disallowContact($email);
        $self->send( "ADC", "BL N=$email" );

        return 1;
}

sub unblockContact
{
        my $self = shift;
        my $email = shift || return $self->error( "Need an email address to unblock" );

        return 0 if( !defined $self->{Lists}->{'BL'}->{$email} );

        $self->send( "REM", "BL $email" );
        $self->allowContact($email);

        return 1;
}

sub addContact
{
        my $self = shift;
        my $email = shift || return $self->error( "Need an email address to add" );

        return 0 if( defined $self->{Lists}->{'FL'}->{$email} );

        $self->send( "ADC", "FL N=$email F=$email" );

        return 1;
}

sub remContact
{
        my $self = shift;
        my $email = shift || return $self->error( "Need an email address to remove" );

        return 0 if( !defined $self->{Lists}->{'FL'}->{$email} );

        my $user = $self->{Lists}->{'FL'}->{$email};
        $self->send( "REM", "FL " . ($user->{guid} || $email) . $user->{group} );

        return 1;
}

sub allowContact
{
        my $self = shift;
        my $email = shift || return $self->error( "Need an email address to add" );

        return 0 if( defined $self->{Lists}->{'AL'}->{$email} );

        $self->send( "ADC", "AL N=$email" );

        return 1;
}

sub disallowContact
{
        my $self = shift;
        my $email = shift || return $self->error( "Need an email address to remove" );

        return 0 if( !defined $self->{Lists}->{'AL'}->{$email} );

        $self->send( "REM", "AL $email" );

        return 1;
}

sub getContactList
{
        my $self = shift;
        my $list = shift || return $self->error( "You must specify a list to check" );

        if( !exists $self->{Lists}->{$list} )
        {
                return $self->error( "That list ($list) does not exists. Please try RL, BL, AL or FL" );
        }

        return keys %{$self->{Lists}->{$list}};
}

sub getContactName
{
        my $self = shift;
        my $email = shift || return $self->error( "No email given" );

        if( !defined $self->{Lists}->{FL}->{$email} || !defined $self->{Lists}->{FL}->{$email}->{Friendly} )
        {
                return $self->error( "Contact doesn't exist" );
        }

        return $self->{Lists}->{FL}->{$email}->{Friendly};
}

sub getContactStatus
{
        my $self = shift;
        my $email = shift || return $self->error( "No email given" );

        if( !defined $self->{Lists}->{FL}->{$email} || !defined $self->{Lists}->{FL}->{$email}->{Status} )
        {
                return $self->error( "Contact doesn't exist" );
        }

        return $self->{Lists}->{FL}->{$email}->{Status};
}

sub getContactClientInfo
{
        my $self = shift;
        my $email = shift || return $self->error( "No email given" );

        if( !defined $self->{Lists}->{FL}->{$email} || !defined $self->{Lists}->{FL}->{$email}->{ClientID} )
        {
                return $self->error( "Contact doesn't exist" );
        }

        my $cid = $self->{Lists}->{FL}->{$email}->{ClientID};

        my $info = MSN::Util::convertFromCid( $cid );

        return $info;
}

sub call
{
        my $self = shift;
        my $handle = shift || return $self->error( "Need to send the handle of the person you want to call" );
        my $message = shift;
        my %style = @_;

        # see if we already have a conversation going with the contact being called
        my $convo = $self->{Msn}->findMember( $handle );

        # if so, simply send them this message
        if( $convo )
        {
                $convo->sendMessage( $message, %style );
        }
        # otherwise, open a switchboard and save the message for later delivery
        else
        {
                # try to get a new switchboard
                $self->send( 'XFR', 'SB' );

                # store the handle and message of this call for use after we have a switchboard (why subtract 1 here??)
                my $TrID = $self->{TrID} - 1;
                $self->{Calls}->{$TrID}->{Handle} = $handle;
                $self->{Calls}->{$TrID}->{Message} = $message;
                $self->{Calls}->{$TrID}->{Style} = \%style;
        }
}

sub ping
{
        my $self = shift;

        if( time >= $self->{PingTime} + $self->{PingIncrement} )
        {
                $self->{Msn}->call_event( $self, "Ping" );

                # send PNG with no TrID
                $self->_send( "PNG\r\n" );

                $self->{PingTime} = time;

                # if no pong is received within the required time limit, assume we are disconnected
                if( time - $self->{PongTime} > $self->{NoPongMax} )
                {
                        # disconnect
                        $self->debug( "Disconnected : No pong received from server" );
                        $self->{Msn}->disconnect();

                        # call the Disconnected handler
                        $self->{Msn}->call_event( $self, "Disconnected", "No pong received from server" );

                        # reconnect if AutoReconnect is true
                        $self->{Msn}->connect() if( $self->{Msn}->{AutoReconnect} );
                }
        }
}

#================================================
# internal method for updating a contact's info
#================================================

sub set_contact_status
{
        my $self = shift;
        my $email = shift || return $self->error( "No email given" );
        my $status = shift || return $self->error( "No status given" );
        my $friendly = shift || '';
        my $cid = shift || 0;

        $self->{Msn}->call_event( $self, "Status", $email, $status );
        $self->{Lists}->{FL}->{$email}->{Status} = $status;
        $self->{Lists}->{FL}->{$email}->{Friendly} = $friendly;
        $self->{Lists}->{FL}->{$email}->{ClientID} = $cid;
        $self->{Lists}->{FL}->{$email}->{LastChange} = time;
}

#================================================
# dispatch a server event to this object
#================================================

sub dispatch
{
        my $self = shift;
        my $incomingdata = shift || '';

#	print( "Dispatch - $incomingdata\n" );
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
                &{$c}($self, @data);
        }
}

#================================================
# MSN Server messages handled by Notification
#================================================

sub CMD_VER
{
         my $self = shift;
         my @data = @_;

        $self->{protocol} = $data[1];
        $self->send( 'CVR', CVER10 . $self->{Handle} );

        return 1;
}

sub CMD_CVR
{
        my $self = shift;
        my @data = @_;

        $self->send( 'USR', 'TWN I ' . $self->{Handle});

        return 1;
}

sub CMD_USR
{
        my $self = shift;
        my @data = @_;

        if ($data[1] eq 'TWN' && $data[2] eq 'S')
        {
                my $token = $self->authenticate( $data[3] );
                if (!defined $token ) {
                         $self->disconnect;
                         return;
                }
                $self->send('USR', 'TWN S ' . $token);
        }
        elsif( $data[1] eq 'OK' )
        {
                my $friendly = $data[3];
                $self->send( 'SYN', "0 0" );
        }
        else
        {
                return $self->serverError( 'Unsupported authentication method: "' . "@data" .'"' );
        }
}

#================================================
# Get the number of contacts on our contacts list
#================================================

sub CMD_SYN
{
        my $self = shift;
        my @data = @_;

        $self->{Lists}->{SYN}->{Total} = $data[3];
        $self->debug( "Syncing lists with $self->{Lists}->{SYN}->{Total} contacts" );
}

#================================================
# This value is only stored on the server and has no effect
# it's here to tell the client what to do with new contacts
# we don't need any particular value and can do whatever we want
# but we'll just set the value to automatic to be good
#================================================

sub CMD_GTC
{
        my $self = shift;
        my @data = @_;

        if( $data[0] eq 'A' )
        {
                # Tell the server that we don't need confirmation for people to add us to their contact lists
                $self->send( 'GTC', 'N' );
        }
}

#================================================
# As we are a bot, we want anyone to be able to invite and chat with us
# this could be an option in future clients
#================================================

sub CMD_BLP
{
        my $self = shift;
        my @data = @_;

        if ( $data[0] eq 'BL' )
        {
                # Tell the server we want to allow anyone to invite and chat with us
                $self->send( 'BLP', 'AL' );
        }
}

#================================================
# Getting our list of contact groups
#================================================

sub CMD_LSG
{
        my $self = shift;
        my ($group, $guid) = @_;

#        $self->debug( "Group $group ($guid) added" );
        $self->{Groups}->{$group} = $guid;
}

#================================================
# Getting our list of contacts
#================================================

sub CMD_LST
{
        my $self = shift;

        my ($email, $friendly, $guid, $bitmask, $group);

        my @items = grep { /=/ } @_;
        my @masks = grep { !/=/ } @_;

        my $settings = {};
        foreach my $item (@items)
        {
                my ($what,$value) = split (/=/,$item);
                $settings->{$what} = $value;
        }

        $bitmask = pop @masks;
        if( $bitmask =~ /[a-z]/ )
        {
                $group = $bitmask;
                $bitmask = pop @masks;
        }

        $email         = $settings->{N};
        $friendly = $settings->{F} || '';
        $guid                 = $settings->{C} || '';

        my $contact = { email         => $email,
                                                 Friendly => $friendly,
                                                 Message => '',
                                                 guid                 => $guid,
                                                 group         => $group };

#        $self->debug( "'$email', '$friendly', '$bitmask', '$guid'" );        # , '$group'" );

        $self->{Lists}->{SYN}->{Current}++;

        my $current = $self->{Lists}->{SYN}->{Current};
        my $total = $self->{Lists}->{SYN}->{Total};

        $self->{Lists}->{RL}->{$email} = 1                        if ($bitmask & 16);  # <-- seems to be set for users who have added you while you were offline
        $self->{Lists}->{RL}->{$email} = 1                        if ($bitmask & 8);
        $self->{Lists}->{BL}->{$email} = 1                        if ($bitmask & 4);
        $self->{Lists}->{AL}->{$email} = 1                        if ($bitmask & 2);
        $self->{Lists}->{FL}->{$email} = $contact if ($bitmask & 1);

        if ($current == $total)
        {
                my $RL = $self->{Lists}->{RL};
                my $AL = $self->{Lists}->{AL};
                my $BL = $self->{Lists}->{BL};

                foreach my $handle (keys %$RL)
                {
                        if( !defined $AL->{$handle} && !defined $BL->{$handle} )
                        {
                                # This contact wants to be allowed, ask if we should
                                my $do_add = $self->{Msn}->call_event( $self, "ContactAddingUs", $handle );
                                $self->allowContact( $handle ) unless( defined $do_add && !$do_add );
                        }
                }

                $self->send( 'CHG', 'NLN ' . $self->{Msn}->{ClientID} );
                $self->{Msn}->call_event( $self, "Connected" );
        }
}

sub CMD_NLN
{
        my $self = shift;
        my ($status, $email, $friendly, $cid) = @_;

        $self->set_contact_status( $email, $status, $friendly, $cid );
}

sub CMD_FLN
{
        my $self = shift;
        my ($email) = @_;

        $self->set_contact_status( $email, 'FLN' );
}

sub CMD_ILN
{
        my $self = shift;
        my ($trid, $status, $email, $friendly, $cid) = @_;

        $self->set_contact_status( $email, $status, $friendly, $cid );
 }

sub CMD_CHG
{
        my $self = shift;
        my @data = @_;
}

sub CMD_ADC
{
        my $self = shift;
        my ($TrID, $list, $handle, $name) = @_;
        (undef, $handle) = split( /=/, $handle );

        if( $list eq 'RL' )                # a user is adding us to their contact list (our RL list)
        {
                $self->{Lists}->{'RL'}->{$handle} = 1;
                # ask for approval before we add this contact (default to approved)
                my $do_add = $self->{Msn}->call_event( $self, "ContactAddingUs", $handle );
                $self->allowContact( $handle ) unless( defined $do_add && !$do_add );
        }
        elsif( $list eq 'AL' )  # server telling us we successfully added someone to our AL list
        {
                $self->{Lists}->{'AL'}->{$handle} = 1;
        }
        elsif( $list eq 'BL' )  # server telling us we successfully added someone to our BL list
        {
                $self->{Lists}->{'BL'}->{$handle} = 1;
        }
        elsif( $list eq 'FL' )  # server telling us we successfully added someone to our FL list
        {
                my @items = grep { /=/ } @_;
                my $settings = {};
                foreach my $item (@items)
                {
                        my ($what,$value) = split (/=/,$item);
                        $settings->{$what} = $value;
                }

                my $contact = { email         => $settings->{N},
                                                         Friendly => $settings->{F},
                                                         guid                 => $settings->{C},
                                                         group         => '' };

                $self->{Lists}->{'FL'}->{$handle} = $contact;
        }
}

sub CMD_REM
{
        my $self = shift;
        my ($TrID, $list, $handle) = @_;

        if( $list eq 'RL' )                # a user is removing us from their contact list (our RL list)
        {
                delete $self->{Lists}->{'RL'}->{$handle};
                $self->{Msn}->call_event( $self, "ContactRemovingUs", $handle );
                $self->disallowContact( $handle);
#                $self->remContact( $handle);
        }
        elsif( $list eq 'AL' )  # server telling us we successfully removed someone from our AL list
        {
                $handle =~ s/^N=//gi;
                delete $self->{Lists}->{'AL'}->{$handle};
        }
        elsif( $list eq 'BL' )  # server telling us we successfully removed someone from our BL list
        {
                delete $self->{Lists}->{'BL'}->{$handle};
        }
        elsif( $list eq 'FL' )  # server telling us we successfully removed someone from our FL list
        {
                foreach my $mail (keys %{$self->{Lists}->{'FL'}})
                {
                         if ($self->{Lists}->{'FL'}->{$mail}->{guid} eq $handle)
                         {
                                  delete $self->{Lists}->{'FL'}->{$mail};
                                  return;
                         }
                }
        }
}

sub CMD_XFR
{
        my $self = shift;
        my @data = @_;

        if( $data[1] eq 'NS' )
        {
                my ($host, $port) = split( /:/, $data[2] );
                $self->{Socket}->close();
                $self->{Msn}->{Select}->remove( $self->{Socket} );

                # why wouldn't this be defined??
                if( defined $self->{Socket}->fileno )
                {
                        delete( $self->{Msn}->{Connections}->{ $self->{Socket}->fileno } );
                }

                $self->connect( $host, $port );
        }
        elsif( $data[1] eq 'SB' )
        {
                if( defined $self->{Calls}->{$data[0]}->{Handle} )
                {
                        my ( $host, $port ) = split( /:/, $data[2] );

                        # get a switchboard and connect, passing along the call handle and message
                        my $switchboard = new MSN::SwitchBoard( $self->{Msn}, $host, $port );
                        $switchboard->connectXFR( $data[4], $self->{Calls}->{$data[0]}->{Handle}, $self->{Calls}->{$data[0]}->{Message}, $self->{Calls}->{$data[0]}->{Style} );
                }
                else
                {
                        $self->serverError( 'Received XFR SB request, but there are no pending calls!' );
                }
        }
}

#================================================
# someone is calling us
#================================================

sub CMD_RNG
{
        my $self = shift;
        my ($sid, $addr, undef, $key, $user, $friendly) = @_;

        # ask for approval before we answer this ring (default to approved)
        my $do_accept = $self->{Msn}->call_event( $self, "Ring", $user, uri_unescape($friendly) );

        if( !defined $do_accept || $do_accept )
        {
                my ($host, $port) = split ( /:/, $addr );

                my $switchboard = new MSN::SwitchBoard( $self->{Msn}, $host, $port );
                $switchboard->connectRNG( $key, $sid );
        }
}

#================================================
# a challenge (ping) from the server
#================================================

sub CMD_CHL
{
#Changed for Msnp11 - Teario
        my $self = shift;
        my @data = @_;

	#Thanks Siebe for writing the subs to
	#create the QRY reply data
        my $qryhash = CreateQRYHash( $data[1] );

        $self->sendraw( 'QRY', 'PROD0090YUAUV{2B 32' . "\r\n" . $qryhash );

}

#================================================
# a response to our QRY
#================================================

sub CMD_QRY
{
         my $self = shift;
         my @data = @_;
}

#================================================
# a response to our PNG
#================================================

sub CMD_QNG
{
        my $self = shift;
        my @data = @_;

        $self->{PongTime} = time;
}



#================================================
# an UBX (!!! LU8AJA added 2010-05-26)
#================================================

sub CMD_UBX
{
        my $self = shift;
        my @data = @_;

        $self->{UbxEmail} = exists($data[0]) ? $data[0]      : '';
        $self->{UbxLength}= exists($data[1]) ? int($data[1]) : 0;
}

#================================================
# an UBX payload UBX (!!! LU8AJA added 2010-05-26)
#================================================

sub CMD_UBX_data
{
        my $self = shift;
        my $data = shift;

		if ($self->{UbxEmail}){
			if ($data =~ /<PSM>(.+?)<.PSM>/i){
				$self->{Lists}->{FL}->{$self->{UbxEmail}}->{Message} = $self->html_decode($1);
			}
		}


}

#================================================
# Internal methods for authentication
#================================================

sub authenticate
{
	my $self = shift;
	my $t = shift;

	my $u = $self->html_encode($self->{Handle});
	my $p = $self->html_encode($self->{Password});

	$t =~ s/,/&/g;
	$t = $self->url_decode($t);
	$t = $self->html_encode($t);

	my $ua = LWP::UserAgent->new(
		timeout => 5,
		max_redirect => 0,
		agent => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)'
	);

	my $body = 
		'<?xml version="1.0" encoding="UTF-8"?>' .
		'<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsse="http://schemas.xmlsoap.org/ws/2003/06/secext" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:wsp="http://schemas.xmlsoap.org/ws/2002/12/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/03/addressing" xmlns:wssc="http://schemas.xmlsoap.org/ws/2004/04/sc" xmlns:wst="http://schemas.xmlsoap.org/ws/2004/04/trust">' .
			'<Header>' .
				'<ps:AuthInfo xmlns:ps="http://schemas.microsoft.com/Passport/SoapServices/PPCRL" Id="PPAuthInfo">' .
					'<ps:HostingApp>{7108E71A-9926-4FCB-BCC9-9A9D3F32E423}</ps:HostingApp>' .
					'<ps:BinaryVersion>3</ps:BinaryVersion>' .
					'<ps:UIVersion>1</ps:UIVersion>' .
					'<ps:Cookies></ps:Cookies>' .
					'<ps:RequestParams>AQAAAAIAAABsYwQAAAAxMDMz</ps:RequestParams>' .
				'</ps:AuthInfo>' .
				'<wsse:Security>' .
					'<wsse:UsernameToken Id="user">' .
						'<wsse:Username>' . $u . '</wsse:Username>' .
						'<wsse:Password>' . $p . '</wsse:Password>' .
					'</wsse:UsernameToken>' .
				'</wsse:Security>' .
			'</Header>' .
			'<Body>' .
				'<ps:RequestMultipleSecurityTokens xmlns:ps="http://schemas.microsoft.com/Passport/SoapServices/PPCRL" Id="RSTS">' .
					'<wst:RequestSecurityToken Id="RST0">' .
						'<wst:RequestType>http://schemas.xmlsoap.org/ws/2004/04/security/trust/Issue</wst:RequestType>' .
						'<wsp:AppliesTo><wsa:EndpointReference><wsa:Address>http://Passport.NET/tb</wsa:Address></wsa:EndpointReference></wsp:AppliesTo>' .
					'</wst:RequestSecurityToken>' .
					'<wst:RequestSecurityToken Id="RST1">' .
						'<wst:RequestType>http://schemas.xmlsoap.org/ws/2004/04/security/trust/Issue</wst:RequestType>' .
						'<wsp:AppliesTo><wsa:EndpointReference><wsa:Address>messenger.msn.com</wsa:Address></wsa:EndpointReference></wsp:AppliesTo>' .
						'<wsse:PolicyReference URI="?' . $t . '"></wsse:PolicyReference>' .
					'</wst:RequestSecurityToken>' .
				'</ps:RequestMultipleSecurityTokens>' .
			'</Body>' .
		'</Envelope>';

	# Do a new POST request then
print("PP3 Authing\n");
	my $req = HTTP::Request->new(POST => "https://loginnet.passport.com/RST.srf");
	   $req->content($body);
	my $checkerror = '<faultcode>wsse:FailedAuthentication</faultcode>';
	my $resp = $ua->request($req);
	#print $resp->content;
	if($resp->is_success)
	{	# Grab the content and then strip it down	
		if(my ($ticket) = ($resp->content =~ m!<wsse:binarysecuritytoken.*?>(t=.*?&amp;p=.*?)</!i)) {
			# We found a ticket, yayayya!
print("Got Ticket\n");
			return $self->html_decode($ticket);
		} elsif ($resp->content =~ m/$checkerror/i) {
			print "Authentication failed. Login details incorrect.\n";
			return undef;
		} else {
			print "Authentication failed. An unknown error occurred.\n";
			return undef;
		}
	} else {
		print "Authentication request failed, the authentication server appears to be down or is not responding. Check your firewall.\n";
		print $resp->content;
	}
	
	return undef;
}

sub html_encode
{	# Does a quick HTML encode routine
	my ($self, $string) = @_;
	
		$string =~ s/&/&amp;/g;
		$string =~ s/</&lt;/g;
		$string =~ s/>/&gt;/g;
		$string =~ s/'/&apos;/g;
		$string =~ s/"/&quot;/g;

	return $string;	
}

sub html_decode
{	# Does a quick HTML decode
	my ($self, $string) = @_;
	return decode_entities($string);
}

sub url_decode
{	# URL decode the string
	my ($self, $string) = @_;
		$string =~ s/\%(..)/pack("H*", $1)/eg;

	return $string;
}


# This piece of code was written by Siebe Tolsma (Copyright 2004, 2005).
# Based on documentation by ZoRoNaX.
# 
# This code is for eductional purposes only. Modification, use and/or publishing this code 
# is entirely on your OWN risk, I can not be held responsible for any of the above.
# If you have questions please contact me by posting on the BOT2K3 forum: http://bot2k3.net/forum/

sub CreateQRYHash {
use Math::BigInt;
	my $chldata = shift || return;
	my $prodid  = shift || "PROD0090YUAUV{2B";
	my $prodkey = shift || "YMM8C_H7KCQ2S_KL";
	
	# Create an MD5 hash out of the given data, then form 32 bit integers from it
	my @md5hash = unpack("a16a16", md5_hex("$chldata$prodkey"));
	my @md5parts = MD5HashToInt("$md5hash[0]$md5hash[1]");

	# Then create a valid productid string, divisable by 8, then form 32 bit integers from it
	my @chlprodid = CHLProdToInt("$chldata$prodid" . ("0" x (8 - length("$chldata$prodid") % 8)));

	# Create the key we need to XOR
	my $key = KeyFromInt(@md5parts, @chlprodid);
	
	# Take the MD5 hash and split it in two parts and XOR them
	my $low  = substr(Math::BigInt->new("0x$md5hash[0]")->bxor($key)->as_hex(), 2);
	my $high = substr(Math::BigInt->new("0x$md5hash[1]")->bxor($key)->as_hex(), 2);

	# Return the string, make sure both parts are padded though if needed
	return ("0" x (16 - length($low))) . $low . ("0" x (16 - length($high))) . $high;
}

sub KeyFromIntOriginal {
	# We take it the first 4 integers are from the MD5 Hash
	my @md5 = splice(@_, 0, 4);	
	my @chlprod = @_;

	# Create a new series of numbers
	my $key_temp = Math::BigInt->new(0);
	my $key_high = Math::BigInt->new(0);
	my $key_low  = Math::BigInt->new(0);
	
	# Then loop on the entries in the second array we got in the parameters
	for(my $i = 0; $i < scalar(@chlprod); $i+=2) {
		# Make $key_temp zero again and perform calculation as described in the documents
		$key_temp->bzero()->badd($chlprod[$i])->bmul(0x0E79A9C1)->bmod(0x7FFFFFFF)->badd($key_high);
		$key_temp->bmul($md5[0])->badd($md5[1])->bmod(0x7FFFFFFF);

		# So, when that is done, work on the $key_high value :)
		$key_high->bzero()->badd($chlprod[$i + 1])->badd($key_temp)->bmod(0x7FFFFFFF);
		$key_high->bmul($md5[2])->badd($md5[3])->bmod(0x7FFFFFFF);

		# And add the two parts to the low value of the key
		$key_low->badd($key_temp)->badd($key_high);
	}

	# At the end of the loop we should add the dwords and modulo again
	$key_high->badd($md5[1])->bmod(0x7FFFFFFF);
	$key_low->badd($md5[3])->bmod(0x7FFFFFFF);

	# Byteswap the keys, left shift (32) the high value and then add the low value
	$key_low  = unpack("I*", reverse(pack("I*", $key_low )));
	$key_high = unpack("I*", reverse(pack("I*", $key_high)));

	return $key_temp->bzero()->badd($key_high)->blsft(32)->badd($key_low);
}

#Rewritten to NOT use bzero, which showed problems with Math:BigInt 1.89 in an old perl
sub KeyFromInt {
	# We take it the first 4 integers are from the MD5 Hash
	my @md5 = splice(@_, 0, 4);	
	my @chlprod = @_;

	# Create a new series of numbers
	my $key_temp = Math::BigInt->new(0);
	my $key_high = Math::BigInt->new(0);
	my $key_low  = Math::BigInt->new(0);
	
	# Then loop on the entries in the second array we got in the parameters
	for(my $i = 0; $i < scalar(@chlprod); $i+=2) {
		# Make $key_temp zero again and perform calculation as described in the documents
		$key_temp->bsub($key_temp)->badd($chlprod[$i])->bmul(0x0E79A9C1)->bmod(0x7FFFFFFF)->badd($key_high);
		$key_temp->bmul($md5[0])->badd($md5[1])->bmod(0x7FFFFFFF);

		# So, when that is done, work on the $key_high value :)
		$key_high->bsub($key_high)->badd($chlprod[$i + 1])->badd($key_temp)->bmod(0x7FFFFFFF);
		$key_high->bmul($md5[2])->badd($md5[3])->bmod(0x7FFFFFFF);

		# And add the two parts to the low value of the key
		$key_low->badd($key_temp)->badd($key_high);
	}

	# At the end of the loop we should add the dwords and modulo again
	$key_high->badd($md5[1])->bmod(0x7FFFFFFF);
	$key_low->badd($md5[3])->bmod(0x7FFFFFFF);

	# Byteswap the keys, left shift (32) the high value and then add the low value
	$key_low  = unpack("I*", reverse(pack("I*", $key_low )));
	$key_high = unpack("I*", reverse(pack("I*", $key_high)));

	return $key_temp->bsub($key_temp)->badd($key_high)->blsft(32)->badd($key_low);
}

# Takes an CHLData + ProdID + Padded string and chops it in 4 bytes. Then converts to 32 bit integers 
sub CHLProdToInt { return map { unpack("I*", $_) } unpack(("a4" x (length($_[0]) / 4)), $_[0]); }

# Takes an MD5 string and chops it in 4. Then "decodes" the HEX and converts to 32 bit integers. After that it ANDs
sub MD5HashToInt { return map { unpack("I*", pack("H*", $_)) & 0x7FFFFFFF } unpack(("a8" x 4), $_[0]); }

return 1;
__DATA__
