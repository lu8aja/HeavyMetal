
#================================================
package MSN::P2P;
#================================================

#=============================================================================
# P2P.PM for MSN.PM 2.0 to cleanup P2P and add functions
#    By Matt Austin 12/13/04
#
# ACTIONS:
#  1) arrange p2p to make more sence and allow for recieveing  Done: 12/15/04
#  2) Remove p2p_transfers from SB , and break into functions  Done: 01/01/05
#  3) add new File sending methods                             ToDo
#  4) add recieveing methods                                   Working
#
#=============================================================================


=head1 MSN::P2P

=cut
use strict;
use warnings;

use URI::Escape;

# For DP
use MIME::Base64;
use Data::Dumper;

# For errors
use MSN::Util;

sub checksum { my $o = tell(DATA); seek DATA,0,0; local $/; my $t = unpack("%32C*",<DATA>) % 65535;seek DATA,$o,0; return $t;};


=head2 Methods

=item
new

Creats new P2P obj (with every SB obj)

=cut
sub new
{
        my $class = shift;
        my ($sb) = @_;
        my $self  =
        {
                Type     => 'P2P',
                SB       => $sb
        };
        bless( $self, $class );
        return $self;
}

sub debug
{
        my $self = shift;

        return $self->{SB}->{Msn}->debug( @_ );
}

sub error
{
        my $self = shift;

        return $self->{SB}->{Msn}->error( @_ );
}

sub p2p_transfer
{
        my $self = shift;
        my $user = shift;
        my $data = shift;

        # get p2p header and footer info.
        my $header = substr($data, 0, 48);
        my $p2pdata = substr($data, 48, -4);
        my $footer = substr($data, -4);
        my %fields;
        my $P2PHeader = {
                    Sesid   => GetDWord(substr($header, 0, 4)),
                    Baseid  => GetDWord(substr($header, 4, 4)),
                    Offset  => GetDWord(substr($header, 8, 4)),
                    TotSize => GetDWord(substr($header, 16, 4)),
                    Size    => GetDWord(substr($header, 24, 4)),
                    Flag    => GetDWord(substr($header, 28, 4)),
                    PrevBID => GetDWord(substr($header, 32, 4)),
                    AckBid  => GetDWord(substr($header, 36, 4)),
                    AckSize => GetDWord(substr($header, 40, 4)),
                    Footer  => GetDWord($footer,1),
                    User    => $user,
        };
        $self->{$P2PHeader->{Sesid}}->{Data} .= $p2pdata; #append data bad for big files..?
        if(($P2PHeader->{Size} + $P2PHeader->{Offset} + $P2PHeader->{AckSize} == $P2PHeader->{TotSize})){# got all p2p

        $self->{$P2PHeader->{Sesid}}->{Type} = "" if(!$self->{$P2PHeader->{Sesid}}->{Type}); #bad workaround for "eq" error :/

        $self->{$P2PHeader->{Sesid}}->{Headers} = $P2PHeader;
        $data = $self->{$P2PHeader->{Sesid}}->{Data};

        if($P2PHeader->{Flag} == 2){ #got p2p ack
                if($P2PHeader->{AckBid} == 100){
                 $self->sendDataPrep($P2PHeader);
                }
                elsif(($P2PHeader->{AckBid} == 101)&&($self->{$P2PHeader->{Sesid}}->{Type} eq "CEDP")){
                 $self->sendDPData($P2PHeader);
                 delete $self->{P2PTransfers}->{$P2PHeader->{PrevBID}};
                }
        }
        else{
                if($data =~ m/INVITE MSNMSGR/gs){ #got invite
                    $self->GotInvite($P2PHeader->{Sesid});
                }
                elsif(index($data, "200 OK") > 0){
                my $params;
                foreach my $line ( split("\r\n", $data) ) {
                next unless length $line;
                my ($key, $value) = split(' ', $line, 2);
                $params->{$key} = $value;
                }
                                 my $file = $self->{FT}->{$params->{'SessionID:'}};
                                 $self->SendACK($P2PHeader);
                                 my $FileD = '';
                                 open( FILE, $file ) || return $self->{SB}->error( "Could not find the file '$file'" );
                                 binmode(FILE);
                                 while( <FILE> ) { $FileD .= $_; }
                                 close(FILE);

                                 my $FileL   = length($FileD);
                                 my $session = $params->{'SessionID:'};

                                 for (my $offset = 0; $offset < $FileL; $offset += 1352) {
                                 my $TFileD = substr($FileD, $offset, 1352);
                                 $self->_sendp2p( { Name       => $user,
                                               SessionID  => $session,
                                               BaseID     => $P2PHeader->{PrevBID} - 1,
                                               Offset     => $offset,
                                               TotalSize  => $FileL,
                                               Flag       => 16777264,
                                               PrevBaseID => 102,
                                               Footer     => 2,
                                               Data       => $TFileD,});

                                 }

                }
                elsif($P2PHeader->{Sesid} == 64){ #got ink
                       $data =~ s/\0//gs;
                       $data =~ s/^.*?base64://gs;
                       $self->{SB}->{Msn}->call_event($self->{SB}, "Ink", $data);
                       $self->SendACK($P2PHeader);
                }
                elsif(($self->{$P2PHeader->{Sesid}}->{Type} eq "File")){ #got file data
                     $self->SendACK($P2PHeader);
                     if(ref($self->{$P2PHeader->{Sesid}}->{FileReply}) eq "CODE"){
                      #run the sub if code refrence
                      &{$self->{$P2PHeader->{Sesid}}->{FileReply}}($self->{SB}, $self->{$P2PHeader->{Sesid}}->{Data});
                     }
                     else{
                      #otherwise write it to a file
                         open (FILE, ">$self->{$P2PHeader->{Sesid}}->{FileReply}");
                         binmode(FILE);
                         print FILE $self->{$P2PHeader->{Sesid}}->{Data};
                         close(FILE);
                     }
                    # print Dumper($self->{$P2PHeader->{Sesid}});

                }
                else{
                #print "$data\n";
                     if($data =~ m/BYE MSNMSGR/){
                         # print Dumper($self->{$P2PHeader->{Sesid}});
                     }
                }
                delete $self->{$P2PHeader->{Sesid}};
        }
                #$self->{data}->{$P2PHeader->{Sesid}} = "";#done with data
                #delete $self->{$P2PHeader->{Sesid}};
        }

}


sub GotInvite{
    my( $self, $sid) = @_;
    my $bid = $self->MakeBID();
    my $data = $self->{$sid}->{Data};
    my $header = $self->{$sid}->{Headers};

    #build param hash
    my $params;
    foreach my $line ( split("\r\n", $data) ) {
        next unless length $line;
        my ($key, $value) = split(' ', $line, 2);
        $params->{$key} = $value;
    }
    $params->{'Context:'} = decode_base64($params->{'Context:'} || '');
    $self->{$sid}->{Params} = $params;
    $self->{$sid}->{Params}->{Bid} = $bid;

    if($params->{'EUF-GUID:'}){

        # Send BaseID message
        $self->_sendp2p({ Name          => $header->{User},
                          BaseID        => $bid,
                          TotalSize     => $header->{TotSize},
                          AckSize       => $header->{TotSize},
                          Flag          => 2,
                          PrevBaseID    => $header->{Baseid},
                          AckPrevBaseID => $header->{PrevBID},
        } );

        if ($params->{'EUF-GUID:'} eq '{A4268EEC-FEC5-49E5-95C3-F126696BDBF6}'){
                # got CE, DP, Wink invite
                $self->{$params->{'SessionID:'}}->{Type} = "CEDP";
                $self->Send200OK($sid);
        }

        elsif($params->{'EUF-GUID:'} eq '{5D3E02AB-6190-11D3-BBBB-00C04F795683}'){
                # ToDo: FTP
                $self->{$params->{'SessionID:'}}->{Type} = "File";
                $self->{$params->{'SessionID:'}}->{FileName} = substr($params->{'Context:'}, 20, 550);
                $self->{$params->{'SessionID:'}}->{FileName} =~ s/\0//g;
                $self->{$params->{'SessionID:'}}->{FileSize} = GetDWord(substr($params->{'Context:'}, 8, 4));
                $self->{$params->{'SessionID:'}}->{FileReply} = $self->{SB}->{Msn}->call_event($self->{SB}, "FileReceve", $self->{$params->{'SessionID:'}}->{FileName}, $self->{$params->{'SessionID:'}}->{FileSize}, $params);
                if($self->{$params->{'SessionID:'}}->{FileReply}){$self->Send200OK($sid);}
                else{$self->Send603Decline($sid);}
                #if(ref($FileReply) eq "CODE"){

        }
        else{
                $self->Send603Decline($sid);
        }
    }

}



=item
sendFile (to do)

Send a file to the SB user.

     sendFile('path/to/file/file.ext', 'file.ext');

     ** optional pass file handle in?
     ** add msnftp later

=cut

sub sendFile{
 my( $self, $file, $name) = @_;
    my ($filepath, $filename ) = $file =~ m!(^.*[\\|/])([^\\|/]*)$!;
    my @members = keys %{$self->{SB}->getMembers};
    my $user = $members[0];
    my $handle = $self->{SB}->{Msn}->{Handle};
    my $size = -s $file;
    my $sessid = int(rand(100000000)) + 1000;
    $self->{FT}->{$sessid} = $file;

    my $utf_file = pack("S*", unpack("C*", $file), 0);

    my $msnobj = encode_base64(MakeDWord(574).MakeDWord(2).MakeQWord($size).MakeDWord(1).$utf_file.(chr(0) x (550 - length($utf_file))).(chr(255) x 4),"");
    my $rdata = "EUF-GUID: {5D3E02AB-6190-11D3-BBBB-00C04F795683}\r\n" .
                "SessionID: $sessid\r\nAppID: 2\r\nContext: ".$msnobj."\r\n\r\n\0";

    my $FileD = "INVITE MSNMSGR:$user MSNSLP/1.0\r\nTo: <msnmsgr:$user>\r\n" .
                  "From: <msnmsgr:" . $handle . ">\r\n" .
                  "Via: MSNSLP/1.0/TLP ;branch=".CreateGUID()."\r\nCSeq: 0 \r\n" .
                  "Call-ID: ".CreateGUID()."\r\nMax-Forwards: 0\r\nContent-Type: application/x-msnmsgr-sessionreqbody\r\n" .
                  "Content-Length: ".length($rdata)."\r\n\r\n".$rdata;

    my $bid = $self->MakeBID();
    my $FileL        = length($FileD);
    my $session = $self->{SB}->{P2PTransfers}->{$bid}->{SessionID};

    for (my $offset = 0; $offset < $FileL; $offset += 1202) {
        my $TFileD = substr($FileD, $offset, 1202);
        $self->_sendp2p( {
                Name       => $user,
                BaseID     => $bid,
                Offset     => $offset,
                TotalSize  => $FileL,
                Flag       => 0,
                PrevBaseID => 0,
                Footer     => 0,
                Data       => $TFileD,
        },1);
    }
}

sub sendInk_P2P{
        my( $self, $data) = @_;
        my $bid = $self->MakeBID();
        my @members = keys %{$self->{SB}->getMembers};
        my $ink_data = "MIME-Version: 1.0\r\n".
                       "Content-Type: application/x-ms-ink\r\n".
                       "\r\n\0base64:$data";
        $ink_data = pack("S*", unpack("C*", $ink_data), 0); # UTF-16 the Data
        my $ink_len  = length($ink_data);
        for (my $offset  = 0; $offset < $ink_len;$offset += 1202 ){
             my $data = substr($ink_data, $offset, 1202);
             $self->_sendp2p({Name      => $members[0],
                              SessionID => 64,
                              BaseID    => $bid,
                              Offset    => $offset,
                              TotalSize => $ink_len,
                              Size      => length($data),
                              Data      => $data,
                              Footer    => 3,
                              });
             };
}



sub sendDPData{
  my( $self, $header) = @_;
  my $bid = $header->{PrevBID};
  my $notification = $self->{SB}->{Msn}->{Notification};
  $bid+=2;
  my $location = $self->{P2PTransfers}->{$bid}->{Location};
  my $FileD        = $notification->{Objects}->{$location}->{Data};
  my $FileL        = length($FileD);
  my $session = $self->{P2PTransfers}->{$bid}->{SessionID};

  for (my $offset = 0; $offset < $FileL; $offset += 1202) {
  my $TFileD = substr($FileD, $offset, 1202);
  $self->_sendp2p( { Name       => $header->{User},
                     SessionID  => $session,
                     BaseID     => $bid - 1,
                     Offset     => $offset,
                     TotalSize  => $FileL,
                     Flag       => 32,
                     PrevBaseID => 102,
                     Footer     => 4,
                     Data       => $TFileD,
                   });
  }
}

#================================================
# ACKS OK's Declines and DataPrep Functions
#================================================

sub Send200OK{
my( $self, $sid) = @_;

my $data = $self->{$sid}->{Data};
my $header = $self->{$sid}->{Headers};
my $params = $self->{$sid}->{Params};
my $bid = $self->{$sid}->{Params}->{Bid};

$self->{P2PTransfers}->{$bid}->{SessionID} = $params->{'SessionID:'};
($self->{P2PTransfers}->{$bid}->{Location}) = $params->{'Context:'} =~ /Location="(.*?)"/;

my $okdata = "SessionID: " . $params->{'SessionID:'} . "\r\n\0";

$okdata = "MSNSLP/1.0 200 OK" . "\r\n" .
          "To: <msnmsgr:"     . $header->{User} . ">\r\n" .
          "From: <msnmsgr:"   . $self->{SB}->{Msn}->{Handle} . ">\r\n" .
          "Via: "             . $params->{'Via:'} . "\r\n" .
          "CSeq: "            . '1 ' . "\r\n" .
          "Call-ID: "         . $params->{'Call-ID:'} . "\r\n" .
          "Max-Forwards: "    . '0'. "\r\n" .
          "Content-Type: "    . "application/x-msnmsgr-sessionreqbody" . "\r\n" .
          "Content-Length: "  . length($okdata). "\r\n" ."\r\n" .$okdata;

$self->_sendp2p({ Name       => $header->{User},
                  BaseID     => $bid - 3,
                  TotalSize  => length($okdata),
                  PrevBaseID => 100,
                  Data       => $okdata,
});
}

sub Send603Decline{

my( $self, $sid) = @_;

    my $data = $self->{$sid}->{Data};
    my $header = $self->{$sid}->{Headers};
    my $params = $self->{$sid}->{Params};
    my $bid = $self->{$sid}->{Params}->{Bid};
    my $okdata = "SessionID: " . $params->{'SessionID:'} . "\r\n\0";

    $okdata = "MSNSLP/1.0 603 Decline" . "\r\n" .
               "To: <msnmsgr:"         . $header->{User} . ">\r\n" .
               "From: <msnmsgr:"       . $self->{SB}->{Msn}->{Handle} . ">\r\n" .
               "Via: "                 . $params->{'Via:'} . "\r\n" .
               "CSeq: "                . '1 ' . "\r\n" .
               "Call-ID: "             . $params->{'Call-ID:'} . "\r\n" .
               "Max-Forwards: "        . '0' . "\r\n" .
               "Content-Type: "        . "application/x-msnmsgr-sessionreqbody" . "\r\n" .
               "Content-Length: "      . length($okdata) . "\r\n" .
               "\r\n" .
               $okdata;

    $self->_sendp2p({ Name       => $header->{User},
                      BaseID     => $bid - 3,
                      TotalSize  => length($okdata),
                      PrevBaseID => 100,
                      Data       => $okdata,});
}

 sub SendACK{
    my $self = shift;
    my $P2PHeader = shift;

    $self->_sendp2p({ SessionID     => $P2PHeader->{Sesid},
                      Name          => $P2PHeader->{User},
                      BaseID        => $self->MakeBID(),
                      TotalSize     => $P2PHeader->{TotSize},
                      AckSize       => $P2PHeader->{TotSize},
                      Flag          => 2,
                      PrevBaseID    => $P2PHeader->{BaseID},
                      #AckPrevBaseID => $P2PHeader->{PrevBaseID},
                   });

}

sub sendDataPrep{
  my( $self, $header) = @_;
  my $bid = $header->{PrevBID};
  $bid+=3;
  my $session = $self->{P2PTransfers}->{$bid}->{SessionID};
  $self->debug( "Sending Ack" );
  $self->_sendp2p({ Name       => $header->{User},
                    SessionID  => $session,
                    BaseID     => $bid - 2,
                    TotalSize  => 4,
                    PrevBaseID => 101,
                    Footer     => 4,
                    Data       => MakeDWord(0),
             });
}

#================================================
# p2p Queing and sending functions
#================================================

sub _sendp2p {
         my $self = shift;
         my $args = shift;

         my $head = "MIME-Version: 1.0\r\n" .
                    "Content-Type: application/x-msnmsgrp2p\r\n".
                    "P2P-Dest: " . $args->{Name} . "\r\n" .
                    "\r\n";


         my $bin = MakeDWord($args->{SessionID}     || 0) .  #1
                   MakeDWord($args->{BaseID}        || 0) .  #2
                   MakeDWord($args->{Offset}        || 0) . MakeDWord(0)  . #3  (faked QWord)
                   MakeDWord($args->{TotalSize}     || 0) . MakeDWord(0)  . #4  (faked QWord)
                   MakeDWord($args->{Size}          || length($args->{Data} || '')) . #5
                   MakeDWord($args->{Flag}          || 0) .  #6
                   MakeDWord($args->{PrevBaseID}    || 0) .  #7
                   MakeDWord($args->{AckPrevBaseID} || 0) .  #8
                   MakeDWord($args->{AckSize}       || 0) . MakeDWord(0)  . #9  (faked QWord)
                   ($args->{Data}                   || '' ).
                   MakeDWord($args->{Footer}        || 0, 1);

         my $msg = $head . $bin;
         my $sid = $args->{SessionID} || 0;
         push(@{$self->{p2pQue}->{$sid}}, $msg);
         # push @{$self->{p2pQue}}, $msg;
         # $self->{SB}->sendraw("MSG", "D " . length($msg) . "\r\n" . $msg );
};

sub p2pWaiting {
         my $self = shift;
         return scalar keys %{$self->{p2pQue}};
}

sub p2pSendOne {
         my $self = shift;
         foreach my $sid (keys %{$self->{p2pQue}}){
                  my $msg = shift @{$self->{p2pQue}->{$sid}};
                  if ($msg) {
                  #print "msg: $msg\n";
                           $self->{SB}->sendraw("MSG", "D " . length($msg) . "\r\n" . $msg );
                  }
          delete $self->{p2pQue}->{$sid} unless @{$self->{p2pQue}->{$sid}};
         }

}
#================================================
# Utility functions for p2p
#================================================

sub MakeBID{
  my $self = shift;
  my $bid;
  do { $bid = 1000 + int(rand(10000000));} while( exists $self->{P2PTransfers}->{$bid});
  return $bid;
}


sub MakeDWord
{
  my ($word,$little) = @_;
  return $little ? pack("N", $word) : pack("V", $word);
}

sub MakeQWord {
  return MakeDWord(shift,shift) . (chr(0)x4);
}

sub GetDWord
{
  my ($word,$little) = @_;
  return $little ? unpack("N", $word) : unpack("V", $word);
}
sub CreateGUID{
  #{DWORD-WORD-WORD-WORD-WORD.DWORD}
  return sprintf("{%08X-%04X-%04X-%04X-%04X%08X}",
  rand(2294967295),rand(32767),rand(32767),rand(32767),rand(32767),rand(2294967295));
}

return 1;
__DATA__