package Audio::FluidSynth;

use 5.010;
use warnings;
use strict;

our $VERSION = "0";

use XSLoader;

XSLoader::load __PACKAGE__, $VERSION;

1;
