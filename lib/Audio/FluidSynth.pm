package Audio::FluidSynth;

=head1 NAME

Audio::FluidSynth - Bind the fluidsynth MIDI library

=cut

use 5.010;
use warnings;
use strict;

our $VERSION = "1";

use XSLoader;

XSLoader::load __PACKAGE__, $VERSION;

1;

=head1 BUGS

Please report to <L<bug-Audio-FluidSynth@rt.cpan.org>>.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 COPYRIGHT

Copyright 2014 Ben Morrow.

Released under the 2-clause BSD licence.

