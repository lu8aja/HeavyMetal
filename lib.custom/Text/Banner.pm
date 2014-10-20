#
# $Id: Banner.pm,v 1.2 1999/12/19 18:28:23 stuart Exp $
#
# Copyright (c) 1999 Stuart Lory, Z�rich Switzerland. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Text::Banner;
use strict(qw(refs vars subs));

BEGIN {
   *Banner::VERSION=*Banner::version=\'$Revision: 1.2 $';
   *Banner::ID=*Banner::id=\'$Id: Banner.pm,v 1.2 1999/12/19 18:28:23 stuart Exp $';
}
sub new {
   my $proto=shift; my $class=ref($proto)||$proto;
   my $self={}; my $save=$/; undef $/; my ($byte,$var,$num,$pic);
   foreach $byte (split //,unpack("u*",<DATA>)) {
      $var=ord $byte;
      foreach $num (128,64,32,16,8,4,2,1) {
	 if (($var&$num)==$num) { $pic .=1; } else { $pic .=0; }
      }
   }
   $self->{XL}=$pic; $self->{ORIENTATION}="H"; $self->{SIZE}=1; $/=$save;
   return bless $self,$class;
}
sub rotate {
   my $self=shift;
   return $self->{ORIENTATION} unless @_;
   my $direction=shift;
   return undef unless ($direction=~/^h|v/i);
   if ($direction=~/h/i) {
      $self->{ORIENTATION}="H";
   } else {
      $self->{ORIENTATION}="V";
   }
   return $self->{ORIENTATION};
}
sub size {
   my $self=shift;
   return $self->{SIZE} unless @_;
   my $size=shift;
   # Allow up to 5x blowup. After that its too grainy to be of decent use.
   return undef unless ($size > 0 && $size <6);
   $self->{SIZE}=$size;
   return $size;
}
sub fill {
   my $self=shift;
   return $self->{FILL} unless @_;
   my $char=shift;
   if ($char=~/reset/i) {
   	undef $self->{FILL};
	$self->_CHANGE;
	return undef;
   }
   $char=substr($char,0,1);	# only one character allowed for fill value.
   $char=~s/[^\x20-\x7f]+//g;
   $self->{FILL}=$char if $char;
   $self->_CHANGE;
   return $self->{FILL};
}
sub _CHANGE {
   my $self=shift; my $char;
   foreach $char (@{$self->{STRING}}) {
      foreach (@{$self->{PIC}->{$char}}) {
	 s/0/ /g;
	 if ($self->{FILL}) { s/[^\s]|1/$self->{FILL}/g; } else { s/[^\s]/$char/g; }
      }
   }
}
sub version { return $Banner::VERSION; }  # since global vars, don't need $self
sub set {
   my $self=shift; my $string=shift; my ($char,$var,$pos,$temp,%map);
   return undef unless $string;
   undef @{$self->{STRING}};
   undef $self->{PIC};
   $string=~s/[^\x20-\x7f]+//g; # We only print ASCII characters 32 to 126. Strip out anything else.
   @{$self->{STRING}}=split'',$string;
   foreach (@{$self->{STRING}}) { $map{$_}=1 };
   foreach $char (keys %map) {
      $var=ord $char; $var-=32; $pos=$var*49;
      $temp=substr($self->{XL},$pos,49);
      foreach (0,7,14,21,28,35,42,49) { push @{$self->{PIC}->{$char}}, substr($temp,$_,7); }
      push @{$self->{PIC}->{$char}},"0000000"; # this is spacing between lines
   }
   $self->_CHANGE if $self->{FILL};
   return undef;
}
sub _BLOWUP {
   my $self=shift; my ($dynamic,$creation,$output,$temp);
   $dynamic='$self->{CURRENT_LINE}=~s/(.)/'.'$1' x $self->{SIZE}.'/mg;';
   eval $dynamic;
   if ($self->{ORIENTATION}=~/H/i) {
      $temp=$self->{CURRENT_LINE};
      $dynamic='$output .="'. '$temp\n' x $self->{SIZE}.'";';
      eval $dynamic;
   } else {
      foreach (split /\n/,$self->{CURRENT_LINE}) {
	 $dynamic='$output .= "'.'$_\n' x $self->{SIZE}.'";';
	 eval $dynamic;
      }
   }
   return $output;
}
sub get {
   my $self=shift; my ($creation,$num,$char,$line,$pos,$temp);
   if ($self->{ORIENTATION}=~/h/i) {
      foreach $num (0..7) {
	 undef $self->{CURRENT_LINE};
         foreach (@{$self->{STRING}}) { $self->{CURRENT_LINE} .=${$self->{PIC}->{$_}}[$num]." "; }
         if (($self->{SIZE}>1)&&($self->{SIZE}<6)) {
            $creation .=$self->_BLOWUP;
         } else { 
            $creation .=$self->{CURRENT_LINE}."\n";
         }
      }
   } else {
      foreach $char (@{$self->{STRING}}) {
	 my @array=@{$self->{PIC}->{$char}};
	 undef $self->{CURRENT_LINE};
	 foreach $pos (0..6) {
	    foreach $line (6,5,4,3,2,1,0) { $self->{CURRENT_LINE}.=substr($array[$line],$pos,1); }
	    $self->{CURRENT_LINE}.="\n";
	 }
	 $creation .=$self->{CURRENT_LINE};
      }
      if (($self->{SIZE}>1)&&($self->{SIZE}<6)) {
         $self->{CURRENT_LINE}=$creation;
         $creation=$self->_BLOWUP;
      }
   }
   return $creation;
}

1;

__DATA__
M````````'#AP0`.'._=$````!0I_*?RA1])D/A,E]QI=!!=+',)##B+"<G#@
M@@```!A!`@0$!A@("!`@A@`B*?RB(``$"'P@0````!PX((```!\````````.
M'#@$$$$$$$`XB@P8*(X(,*!`@0^?00+Z!`_OH(%\!@OH$*%"_@@7^!`_`8+Y
M]!@?H,%]_A!!!`@0?08+Z#!?/H,%^!@OA!P0`$'!!PX`.'!!`(((("`@(``/
M@#X``("`@((((/H($<(`"'T&[=O0'P@HB@_X,']!@_H,'\^@P($""^_08,&#
M!_?X$#Y`@?_\"!\@0(#Z#`GP8+Z#!@_X,&"<$"!`@0<`@0(&#!?0HDCA(B0H
M$"!`@0/\''5DP8,&#AHR8L.#_@P8,&#__08/Z!`@/H,&#%A/?T&#^B0H+Z#`
M?`8+[^($"!`@1!@P8,&"^@P8,%$4$09,F3)DMH*(H(*(H,%$4$"!`C^"""""
M#^^0($"!`^@("`@("`O@0($"!/A!1$```````````'\X<$!`````&$D+]"A`
M/D+Y"A?`#R%`@0G@#Y"A0H7P!^@?($#\`_0/D"!``/(4"=">`(4+]"A0@`@0
M($"!``$"!`H3P!"B>)$2$`@0($"!^`0LUJ%"A`(6*E*C0@#R%"A0G@#Y"A?(
M$``\A0I41T`^0H7R)"`/(#P%">`'P@0($"`$*%"A0G@"%"A0DA@!"A0K6:$`
JA)#!A)"`(B@@0($`/P0000?G$"#`@0'!`@0`$"!!P$"!@@1QA)#`````

__END__

=head1 NAME

Text::Banner - create text resembling Unix 'banner' command

=head1 SYNOPSIS

   use Text::Banner;
   $a = Text::Banner->new;
   $a->set('MYTEXT');
   $a->size(3);
   $a->fill('*');
   $a->rotate('h');
   print $a->get;


=head1 DESCRIPTION

The B<Text::Banner> creates a large ascii-representation of a defined string, like
the 'banner' command available in Unix. A string is passed to the module and the
equivalent banner string is generated and returned for use. The string can be
scaled (blown up) from 100 to 500% of the base size. The characters used to
generate the banner image can be any character defined by the user (within a
limited range) or they can be the made up from whatever the current character
being generated happens to be. The banner can be created either vertically or
horizontally.

An object reference is created with the B<new> method. The reference is then used
to define the string to create and for manipulation of the object. No specific order
is required for object manipulation, with the exception of the 'get' operation which
will return the string based upon the current object definitions.

The 'set' operation allows the user to specify the string to be generated.
There is no limit on the length of the string, however, generated strings that
are longer than the display output will continue onto the next line and
interlace with the first character that was generated - resulting in a messy,
difficult-to-read output. Some experimentation may be required to find the
ideal maximum length depending upon the environment you are using.

The 'size' operation provides functionality for blowing up the size of the
generated string from 100 to 500 percent of normal size. '1' is 100%, '2' is
200% and so on. The larger the defined size, the more grainier the output
string becomes. When an object is first created the size defaults to '1'.
Calling the 'size' method without any parameters will return the current
size definition.

The 'rotate' method allows switching between horizontal and vertical output.
Objects are created by default in horizontal mode. Calling the method
without any arguments will return the current output mode - otherwise specify
either 'h' for horizontal or 'v' for vertical output.

The 'fill' operation defines how the returned string should be created. By
default, newly created objects will use the current ascii character of the
character being generated. For example, creating the string 'Hello' without
changing the fill character will cause a string to be created where the 'H'
is made up of the letter 'H', the 'e' from the letter 'e', 'l' from 'l' and so
on. This can be changed if desired by calling the 'fill' operation with the
ASCII character you wish all characters of the string to be created from.
Once defined, the fill character remains constant until changed again. Calling
the fill operation with no parameters will return the currently defined fill
character. Calling the fill operation with the command 'reset' will remove the
fill character, and default back to the original behaviour as outlined above.

The 'get' operation is what causes the string to be generated based upon the
current object definitions. The object is generated and passed directly back
from the method, therefore it can either be printed directly or saved to a
variable for later use.

=head1 EXAMPLES

   # Example 1:

   use Text:Banner;
   $h=Text::Banner->new;
   $h->set('MYTEXT');
   $h->fill('*');
   foreach $num (1..5) {
      $h->size($num);
      print $h->get;
      $h->rotate;
      print $h->get;
   }
   exit 0;
	
	
   # Example 2:

   use Text:Banner;
   $a=Text::Banner->new;
   $a->set('MYtext');
   print $a->get;
   $a->fill('/');
   print $a->get;
   exit 0;

Example 2 would generate the following output:

=begin text

M     M Y     Y                                 
MM   MM  Y   Y    ttttt  eeeeee  x    x   ttttt 
M M M M   Y Y       t    e        x  x      t   
M  M  M    Y        t    eeeee     xx       t   
M     M    Y        t    e         xx       t   
M     M    Y        t    e        x  x      t   
M     M    Y        t    eeeeee  x    x     t   
      
/     / /     /                                 
//   //  /   /    /////  //////  /    /   ///// 
/ / / /   / /       /    /        /  /      /   
/  /  /    /        /    /////     //       /   
/     /    /        /    /         //       /   
/     /    /        /    /        /  /      /   
/     /    /        /    //////  /    /     /   

=end text

Consult the horizontal.txt and vertical.txt files that come with the
module for examples of what different sizes look like.


=head1 NOTES

Multiple objects can of course be generated, however, it should be kept in
mind that the object is not static and changing the defined string output
could be used as an alternative to multiple object creation as each created
object chews up about 4k of memory.

Generated ASCII characters are restricted to those between 32 (space) and
126 (~). Those outside of these values are removed and the resulting 
generated string will not include them. The same restriction applies to the
fill character used for defining character generation.


=head1 AUTHOR

Text::Banner was written November, 1999 by Stuart Lory (stuart@onyx.ch). The
module has been tested in both a Unix and PC environment without any known
problems. If you find a bug, please advise.

=cut
