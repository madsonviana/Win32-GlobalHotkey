package Win32::GlobalHotkey;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Cancel;
use Carp;

=head1 NAME

Win32::GlobalHotkey - Use System-wide Hotkeys independently

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( 'Win32::GlobalHotkey', $VERSION );


# Look at (msdn RegisterHotkey)
# http://msdn.microsoft.com/en-us/library/windows/desktop/ms646309%28v=vs.85%29.aspx
use constant {
	MOD_ALT      => 0x0001,
	MOD_CONTROL  => 0x0002,
	MOD_NOREPEAT => 0x4000, # only OS-version >= 6.1 (Win7)
	MOD_SHIFT    => 0x0004,
	MOD_WIN      => 0x0008,


	# KEYS
	KEY_LBUTTON => 0x01,
	KEY_RBUTTON => 0x02,
	KEY_CANCEL => 0x03,
	KEY_MBUTTON => 0x04,
	KEY_XBUTTON1 => 0x05,
	KEY_XBUTTON2 => 0x06,
	KEY_MINUS => 0x07,
	KEY_BACK => 0x08,
	KEY_TAB => 0x09,
	KEY_CLEAR => 0x0C,
	KEY_RETURN => 0x0D,
	KEY_SHIFT => 0x10,
	KEY_CONTROL => 0x11,
	KEY_MENU => 0x12,
	KEY_PAUSE => 0x13,
	KEY_CAPITAL => 0x14,
	KEY_KANA => 0x15,
	KEY_HANGUEL => 0x15,
	KEY_HANGUL => 0x15,
	KEY_JUNJA => 0x17,
	KEY_FINAL => 0x18,
	KEY_HANJA => 0x19,
	KEY_KANJI => 0x19,
	KEY_ESCAPE => 0x1B,
	KEY_CONVERT => 0x1C,
	KEY_NONCONVERT => 0x1D,
	KEY_ACCEPT => 0x1E,
	KEY_MODECHANGE => 0x1F,
	KEY_SPACE => 0x20,
	KEY_PRIOR => 0x21,
	KEY_NEXT => 0x22,
	KEY_END => 0x23,
	KEY_HOME => 0x24,
	KEY_LEFT => 0x25,
	KEY_UP => 0x26,
	KEY_RIGHT => 0x27,
	KEY_DOWN => 0x28,
	KEY_SELECT => 0x29,
	KEY_PRINT => 0x2A,
	KEY_EXECUTE => 0x2B,
	KEY_SNAPSHOT => 0x2C,
	KEY_INSERT => 0x2D,
	KEY_DELETE => 0x2E,
	KEY_HELP => 0x2F,
	KEY_0 => 0x30,
	KEY_1 => 0x31,
	KEY_2 => 0x32,
	KEY_3 => 0x33,
	KEY_4 => 0x34,
	KEY_5 => 0x35,
	KEY_6 => 0x36,
	KEY_7 => 0x37,
	KEY_8 => 0x38,
	KEY_9 => 0x39,
	KEY_A => 0x41,
	KEY_B => 0x42,
	KEY_C => 0x43,
	KEY_D => 0x44,
	KEY_E => 0x45,
	KEY_F => 0x46,
	KEY_G => 0x47,
	KEY_H => 0x48,
	KEY_I => 0x49,
	KEY_J => 0x4A,
	KEY_K => 0x4B,
	KEY_L => 0x4C,
	KEY_M => 0x4D,
	KEY_N => 0x4E,
	KEY_O => 0x4F,
	KEY_P => 0x50,
	KEY_Q => 0x51,
	KEY_R => 0x52,
	KEY_S => 0x53,
	KEY_T => 0x54,
	KEY_U => 0x55,
	KEY_V => 0x56,
	KEY_W => 0x57,
	KEY_X => 0x58,
	KEY_Y => 0x59,
	KEY_Z => 0x5A,
	KEY_LWIN => 0x5B,
	KEY_RWIN => 0x5C,
	KEY_APPS => 0x5D,
	KEY_SLEEP => 0x5F,
	KEY_NUMPAD0 => 0x60,
	KEY_NUMPAD1 => 0x61,
	KEY_NUMPAD2 => 0x62,
	KEY_NUMPAD3 => 0x63,
	KEY_NUMPAD4 => 0x64,
	KEY_NUMPAD5 => 0x65,
	KEY_NUMPAD6 => 0x66,
	KEY_NUMPAD7 => 0x67,
	KEY_NUMPAD8 => 0x68,
	KEY_NUMPAD9 => 0x69,
	KEY_MULTIPLY => 0x6A,
	KEY_ADD => 0x6B,
	KEY_SEPARATOR => 0x6C,
	KEY_SUBTRACT => 0x6D,
	KEY_DECIMAL => 0x6E,
	KEY_DIVIDE => 0x6F,
	KEY_F1 => 0x70,
	KEY_F2 => 0x71,
	KEY_F3 => 0x72,
	KEY_F4 => 0x73,
	KEY_F5 => 0x74,
	KEY_F6 => 0x75,
	KEY_F7 => 0x76,
	KEY_F8 => 0x77,
	KEY_F9 => 0x78,
	KEY_F10 => 0x79,
	KEY_F11 => 0x7A,
	KEY_F12 => 0x7B,
	KEY_F13 => 0x7C,
	KEY_F14 => 0x7D,
	KEY_F15 => 0x7E,
	KEY_F16 => 0x7F,
	KEY_F17 => 0x80,
	KEY_F18 => 0x81,
	KEY_F19 => 0x82,
	KEY_F20 => 0x83,
	KEY_F21 => 0x84,
	KEY_F22 => 0x85,
	KEY_F23 => 0x86,
	KEY_F24 => 0x87,
	KEY_NUMLOCK => 0x90,
	KEY_SCROLL => 0x91,
	KEY_NUMLOCK => 0x90,
	KEY_SCROLL => 0x91,
	KEY_LSHIFT => 0xA0,
	KEY_RSHIFT => 0xA1,
	KEY_LCONTROL => 0xA2,
	KEY_RCONTROL => 0xA3,
	KEY_LMENU => 0xA4,
	KEY_RMENU => 0xA5,
	KEY_BROWSER_BACK => 0xA6,
	KEY_BROWSER_FORWARD => 0xA7,
	KEY_BROWSER_REFRESH => 0xA8,
	KEY_BROWSER_STOP => 0xA9,
	KEY_BROWSER_SEARCH => 0xAA,
	KEY_BROWSER_FAVORITES => 0xAB,
	KEY_BROWSER_HOME => 0xAC,
	KEY_VOLUME_MUTE => 0xAD,
	KEY_VOLUME_DOWN => 0xAE,
	KEY_VOLUME_UP => 0xAF,
	KEY_MEDIA_NEXT_TRACK => 0xB0,
	KEY_MEDIA_PREV_TRACK => 0xB1,
	KEY_MEDIA_STOP => 0xB2,
	KEY_MEDIA_PLAY_PAUSE => 0xB3,
	KEY_LAUNCH_MAIL => 0xB4,
	KEY_LAUNCH_MEDIA_SELECT => 0xB5,
	KEY_LAUNCH_APP1 => 0xB6,
	KEY_LAUNCH_APP2 => 0xB7,
	KEY_OEM_1 => 0xBA,
	KEY_OEM_PLUS => 0xBB,
	KEY_OEM_COMMA => 0xBC,
	KEY_OEM_MINUS => 0xBD,
	KEY_OEM_PERIOD => 0xBE,
	KEY_OEM_2 => 0xBF,
	KEY_OEM_3 => 0xC0,
	KEY_OEM_4 => 0xDB,
	KEY_OEM_5 => 0xDC,
	KEY_OEM_6 => 0xDD,
	KEY_OEM_7 => 0xDE,
	KEY_OEM_8 => 0xDF,
	KEY_OEM_102 => 0xE2,
	KEY_PROCESSKEY => 0xE5,
	KEY_ATTN => 0xF6,
	KEY_CRSEL => 0xF7,
	KEY_EXSEL => 0xF8,
	KEY_EREOF => 0xF9,
	KEY_PLAY => 0xFA,
	KEY_ZOOM => 0xFB,
	KEY_NONAME => 0xFC,
	KEY_PA1 => 0xFD,
	KEY_OEM_CLEAR => 0xFE
};

=head1 SYNOPSIS

    use Win32::GlobalHotkey;

    my $hk = Win32::GlobalHotkey->new;
    
    $hk->PrepareHotkey( 
        vkey     => Win32::GlobalHotkey.KEY_B, 
        modifier => Win32::GlobalHotkey::MOD_ALT, 
        cb => sub { print "Hotkey pressed!\n" }, # Beware! - You are in another thread.
     );
    
    $hk->StartEventLoop;
    
    #...
    
    $hk->StopEventLoop;

=head1 DESCRIPTION

This module let you create system wide hotkeys. Prepare your Hotkeys with the C<PrepareHotkey> method.
C<StartEventLoop> will initialize a new thread, register all hotkeys and start the Message Loop for event receiving. 

B<The stored callback is executed in the context of the thread.>

=head1 METHODS

=head2 new

Constructs a new object.

You can pass a parameter C<warn> with your own callback method to the constuctor. Defaults to:

    Win32::GlobalHotkey->new( 
        warn => sub {
            carp $_[0];
        }
    );

B<Beware!> The callback is executed in thread context at the time the EventLoop is running.

=cut


sub new {
	my ( $class, %p ) = @_;
	
	my $this = bless {}, $class;
	
	$this->{warn} = $p{warn} // sub { carp $_[0] };
	
	$this->{Hotkey}    = {};
	$this->{EventLoop} = undef;
	
	return $this;
}


=head2 PrepareHotkey( parameter => value, ... )

Prepares the registration of an hotkey. Can be called multiple times (with different values). Can not be called after C<StartEventLoop>.

The following parameters are required:

=over 4

=item C<vkey>

The pressed key.

=item C<Win32::GlobalHotkey::KEY_LBUTTON>
=item C<Win32::GlobalHotkey::KEY_RBUTTON>
=item C<Win32::GlobalHotkey::KEY_CANCEL>
=item C<Win32::GlobalHotkey::KEY_MBUTTON>
=item C<Win32::GlobalHotkey::KEY_XBUTTON1>
=item C<Win32::GlobalHotkey::KEY_XBUTTON2>
=item C<Win32::GlobalHotkey::KEY_MINUS>
=item C<Win32::GlobalHotkey::KEY_BACK>
=item C<Win32::GlobalHotkey::KEY_TAB>
=item C<Win32::GlobalHotkey::KEY_CLEAR>
=item C<Win32::GlobalHotkey::KEY_RETURN>
=item C<Win32::GlobalHotkey::KEY_SHIFT>
=item C<Win32::GlobalHotkey::KEY_CONTROL>
=item C<Win32::GlobalHotkey::KEY_MENU>
=item C<Win32::GlobalHotkey::KEY_PAUSE>
=item C<Win32::GlobalHotkey::KEY_CAPITAL>
=item C<Win32::GlobalHotkey::KEY_KANA>
=item C<Win32::GlobalHotkey::KEY_HANGUEL>
=item C<Win32::GlobalHotkey::KEY_HANGUL>
=item C<Win32::GlobalHotkey::KEY_JUNJA>
=item C<Win32::GlobalHotkey::KEY_FINAL>
=item C<Win32::GlobalHotkey::KEY_HANJA>
=item C<Win32::GlobalHotkey::KEY_KANJI>
=item C<Win32::GlobalHotkey::KEY_ESCAPE>
=item C<Win32::GlobalHotkey::KEY_CONVERT>
=item C<Win32::GlobalHotkey::KEY_NONCONVERT>
=item C<Win32::GlobalHotkey::KEY_ACCEPT>
=item C<Win32::GlobalHotkey::KEY_MODECHANGE>
=item C<Win32::GlobalHotkey::KEY_SPACE>
=item C<Win32::GlobalHotkey::KEY_PRIOR>
=item C<Win32::GlobalHotkey::KEY_NEXT>
=item C<Win32::GlobalHotkey::KEY_END>
=item C<Win32::GlobalHotkey::KEY_HOME>
=item C<Win32::GlobalHotkey::KEY_LEFT>
=item C<Win32::GlobalHotkey::KEY_UP>
=item C<Win32::GlobalHotkey::KEY_RIGHT>
=item C<Win32::GlobalHotkey::KEY_DOWN>
=item C<Win32::GlobalHotkey::KEY_SELECT>
=item C<Win32::GlobalHotkey::KEY_PRINT>
=item C<Win32::GlobalHotkey::KEY_EXECUTE>
=item C<Win32::GlobalHotkey::KEY_SNAPSHOT>
=item C<Win32::GlobalHotkey::KEY_INSERT>
=item C<Win32::GlobalHotkey::KEY_DELETE>
=item C<Win32::GlobalHotkey::KEY_HELP>
=item C<Win32::GlobalHotkey::KEY_0>
=item C<Win32::GlobalHotkey::KEY_1>
=item C<Win32::GlobalHotkey::KEY_2>
=item C<Win32::GlobalHotkey::KEY_3>
=item C<Win32::GlobalHotkey::KEY_4>
=item C<Win32::GlobalHotkey::KEY_5>
=item C<Win32::GlobalHotkey::KEY_6>
=item C<Win32::GlobalHotkey::KEY_7>
=item C<Win32::GlobalHotkey::KEY_8>
=item C<Win32::GlobalHotkey::KEY_9>
=item C<Win32::GlobalHotkey::KEY_A>
=item C<Win32::GlobalHotkey::KEY_B>
=item C<Win32::GlobalHotkey::KEY_C>
=item C<Win32::GlobalHotkey::KEY_D>
=item C<Win32::GlobalHotkey::KEY_E>
=item C<Win32::GlobalHotkey::KEY_F>
=item C<Win32::GlobalHotkey::KEY_G>
=item C<Win32::GlobalHotkey::KEY_H>
=item C<Win32::GlobalHotkey::KEY_I>
=item C<Win32::GlobalHotkey::KEY_J>
=item C<Win32::GlobalHotkey::KEY_K>
=item C<Win32::GlobalHotkey::KEY_L>
=item C<Win32::GlobalHotkey::KEY_M>
=item C<Win32::GlobalHotkey::KEY_N>
=item C<Win32::GlobalHotkey::KEY_O>
=item C<Win32::GlobalHotkey::KEY_P>
=item C<Win32::GlobalHotkey::KEY_Q>
=item C<Win32::GlobalHotkey::KEY_R>
=item C<Win32::GlobalHotkey::KEY_S>
=item C<Win32::GlobalHotkey::KEY_T>
=item C<Win32::GlobalHotkey::KEY_U>
=item C<Win32::GlobalHotkey::KEY_V>
=item C<Win32::GlobalHotkey::KEY_W>
=item C<Win32::GlobalHotkey::KEY_X>
=item C<Win32::GlobalHotkey::KEY_Y>
=item C<Win32::GlobalHotkey::KEY_Z>
=item C<Win32::GlobalHotkey::KEY_LWIN>
=item C<Win32::GlobalHotkey::KEY_RWIN>
=item C<Win32::GlobalHotkey::KEY_APPS>
=item C<Win32::GlobalHotkey::KEY_SLEEP>
=item C<Win32::GlobalHotkey::KEY_NUMPAD0>
=item C<Win32::GlobalHotkey::KEY_NUMPAD1>
=item C<Win32::GlobalHotkey::KEY_NUMPAD2>
=item C<Win32::GlobalHotkey::KEY_NUMPAD3>
=item C<Win32::GlobalHotkey::KEY_NUMPAD4>
=item C<Win32::GlobalHotkey::KEY_NUMPAD5>
=item C<Win32::GlobalHotkey::KEY_NUMPAD6>
=item C<Win32::GlobalHotkey::KEY_NUMPAD7>
=item C<Win32::GlobalHotkey::KEY_NUMPAD8>
=item C<Win32::GlobalHotkey::KEY_NUMPAD9>
=item C<Win32::GlobalHotkey::KEY_MULTIPLY>
=item C<Win32::GlobalHotkey::KEY_ADD>
=item C<Win32::GlobalHotkey::KEY_SEPARATOR>
=item C<Win32::GlobalHotkey::KEY_SUBTRACT>
=item C<Win32::GlobalHotkey::KEY_DECIMAL>
=item C<Win32::GlobalHotkey::KEY_DIVIDE>
=item C<Win32::GlobalHotkey::KEY_F1>
=item C<Win32::GlobalHotkey::KEY_F2>
=item C<Win32::GlobalHotkey::KEY_F3>
=item C<Win32::GlobalHotkey::KEY_F4>
=item C<Win32::GlobalHotkey::KEY_F5>
=item C<Win32::GlobalHotkey::KEY_F6>
=item C<Win32::GlobalHotkey::KEY_F7>
=item C<Win32::GlobalHotkey::KEY_F8>
=item C<Win32::GlobalHotkey::KEY_F9>
=item C<Win32::GlobalHotkey::KEY_F10>
=item C<Win32::GlobalHotkey::KEY_F11>
=item C<Win32::GlobalHotkey::KEY_F12>
=item C<Win32::GlobalHotkey::KEY_F13>
=item C<Win32::GlobalHotkey::KEY_F14>
=item C<Win32::GlobalHotkey::KEY_F15>
=item C<Win32::GlobalHotkey::KEY_F16>
=item C<Win32::GlobalHotkey::KEY_F17>
=item C<Win32::GlobalHotkey::KEY_F18>
=item C<Win32::GlobalHotkey::KEY_F19>
=item C<Win32::GlobalHotkey::KEY_F20>
=item C<Win32::GlobalHotkey::KEY_F21>
=item C<Win32::GlobalHotkey::KEY_F22>
=item C<Win32::GlobalHotkey::KEY_F23>
=item C<Win32::GlobalHotkey::KEY_F24>
=item C<Win32::GlobalHotkey::KEY_NUMLOCK>
=item C<Win32::GlobalHotkey::KEY_SCROLL>
=item C<Win32::GlobalHotkey::KEY_NUMLOCK>
=item C<Win32::GlobalHotkey::KEY_SCROLL>
=item C<Win32::GlobalHotkey::KEY_LSHIFT>
=item C<Win32::GlobalHotkey::KEY_RSHIFT>
=item C<Win32::GlobalHotkey::KEY_LCONTROL>
=item C<Win32::GlobalHotkey::KEY_RCONTROL>
=item C<Win32::GlobalHotkey::KEY_LMENU>
=item C<Win32::GlobalHotkey::KEY_RMENU>
=item C<Win32::GlobalHotkey::KEY_BROWSER_BACK>
=item C<Win32::GlobalHotkey::KEY_BROWSER_FORWARD>
=item C<Win32::GlobalHotkey::KEY_BROWSER_REFRESH>
=item C<Win32::GlobalHotkey::KEY_BROWSER_STOP>
=item C<Win32::GlobalHotkey::KEY_BROWSER_SEARCH>
=item C<Win32::GlobalHotkey::KEY_BROWSER_FAVORITES>
=item C<Win32::GlobalHotkey::KEY_BROWSER_HOME>
=item C<Win32::GlobalHotkey::KEY_VOLUME_MUTE>
=item C<Win32::GlobalHotkey::KEY_VOLUME_DOWN>
=item C<Win32::GlobalHotkey::KEY_VOLUME_UP>
=item C<Win32::GlobalHotkey::KEY_MEDIA_NEXT_TRACK>
=item C<Win32::GlobalHotkey::KEY_MEDIA_PREV_TRACK>
=item C<Win32::GlobalHotkey::KEY_MEDIA_STOP>
=item C<Win32::GlobalHotkey::KEY_MEDIA_PLAY_PAUSE>
=item C<Win32::GlobalHotkey::KEY_LAUNCH_MAIL>
=item C<Win32::GlobalHotkey::KEY_LAUNCH_MEDIA_SELECT>
=item C<Win32::GlobalHotkey::KEY_LAUNCH_APP1>
=item C<Win32::GlobalHotkey::KEY_LAUNCH_APP2>
=item C<Win32::GlobalHotkey::KEY_OEM_1>
=item C<Win32::GlobalHotkey::KEY_OEM_PLUS>
=item C<Win32::GlobalHotkey::KEY_OEM_COMMA>
=item C<Win32::GlobalHotkey::KEY_OEM_MINUS>
=item C<Win32::GlobalHotkey::KEY_OEM_PERIOD>
=item C<Win32::GlobalHotkey::KEY_OEM_2>
=item C<Win32::GlobalHotkey::KEY_OEM_3>
=item C<Win32::GlobalHotkey::KEY_OEM_4>
=item C<Win32::GlobalHotkey::KEY_OEM_5>
=item C<Win32::GlobalHotkey::KEY_OEM_6>
=item C<Win32::GlobalHotkey::KEY_OEM_7>
=item C<Win32::GlobalHotkey::KEY_OEM_8>
=item C<Win32::GlobalHotkey::KEY_OEM_102>
=item C<Win32::GlobalHotkey::KEY_PROCESSKEY>
=item C<Win32::GlobalHotkey::KEY_ATTN>
=item C<Win32::GlobalHotkey::KEY_CRSEL>
=item C<Win32::GlobalHotkey::KEY_EXSEL>
=item C<Win32::GlobalHotkey::KEY_EREOF>
=item C<Win32::GlobalHotkey::KEY_PLAY>
=item C<Win32::GlobalHotkey::KEY_ZOOM>
=item C<Win32::GlobalHotkey::KEY_NONAME>
=item C<Win32::GlobalHotkey::KEY_PA1>
=item C<Win32::GlobalHotkey::KEY_OEM_CLEAR>

=item C<modifier>

=over 8

The Keyboard modifier (ALT, CTRL, SHIFT, WINDOWS). Use the following. Can be combinated with a Bitwise OR ("|").

=item C<Win32::GlobalHotkey::MOD_ALT>

=item C<Win32::GlobalHotkey::MOD_CONTROL>

=item C<Win32::GlobalHotkey::MOD_SHIFT>

=item C<Win32::GlobalHotkey::MOD_WIN>

=back

=item C<cb>

A subroutine reference which is called if the hotkey is pressed.

=back

=cut

# Hotkey Hash Format:
# vkey     => the virtuell (normal) key like a 'b'
# modifier => one of the modifiers above
# cb       => sub { ... }
# keycode  => ord uc vkey => the ascii (ansi?) keycode
#
# saved in the Hash Hotkey as keycode . modifier 

sub PrepareHotkey {
	my ( $this, %p ) = @_;
	
	if ( $this->{EventLoop} && $this->{EventLoop}->is_running ) {
		$this->{warn}->( 'EventLoop already running. Stop it to register another Hotkey' );
		return 0;
	}

	if ( exists $this->{Hotkey}{ $p{vkey} . $p{modifier} } ) {
		$this->{warn}->( 'Hotkey already prepared for registering' );
		return 0;
	}

	$this->{Hotkey}{ $p{vkey} . $p{modifier} } = 
		{ keycode => $p{vkey}, vkey => $p{vkey}, modifier => $p{modifier}, cb => $p{cb} };
	
	return 1;
}

=head2 StartEventLoop

This method starts the MessageLoop for the (new) hotkey thread. You must stop it to change registered hotkeys
    
=cut

sub StartEventLoop {
	my $this = shift;
	
		
	$this->{EventLoop} = threads->create(  
		sub {
			
			my %atoms;
			
			for my $hotkey ( values %{ $this->{Hotkey} } ) {
				my $atom = XSRegisterHotkey( 
					$hotkey->{modifier}, 
					$hotkey->{keycode}, 
					'perl_Win32_GlobalHotkey_' . $hotkey->{vkey} . '_' . $hotkey->{modifier} 
				);

				if ( not $atom  ) {
					$this->{warn}->( "can not register Hotkey - already registered?" );
				} else {
					$atoms{ $atom } = $hotkey->{cb};
				}
			}
									
			while ( my $atom = XSGetMessage( ) ) {
				&{ $atoms{ $atom } };
			}
		}
	);
}

=head2 StopEventLoop

Stops the MessageLoop. Currently, it only detachs and kill the hotkey thread.

=cut

sub StopEventLoop {
	my $this = shift;
	
	#TODO: Unregister / Delete / correct join
	
	#sleep 2;
	$this->{EventLoop}->cancel;
	#$this->{EventLoop}->kill('KILL');
	#$this->{EventLoop}->join;
	#sleep 1;
	
	
	
#	$this->{EventLoop}->join;
}

=head2 GetConstant( name )

Static utility method to return the appropriate constant value for the given string.

=cut

sub GetConstant {
	no strict 'refs';
	return &{ $_[1] };	
}

=head1 AUTHOR

Tarek Unger, C<< <tu2 at gmx.net> >>

=head1 BUGS

Sure.

Please report any bugs or feature requests to C<bug-win32-globalhotkey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-GlobalHotkey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::GlobalHotkey

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-GlobalHotkey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-GlobalHotkey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-GlobalHotkey>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-GlobalHotkey/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Tarek Unger.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

