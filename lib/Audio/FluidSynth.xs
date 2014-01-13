#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <fluidsynth.h>

typedef fluid_settings_t *Audio_FluidSynth_Settings;


MODULE = Audio::FluidSynth  PACKAGE = Audio::FluidSynth::Settings

Audio_FluidSynth_Settings
new ()
    CODE:
        RETVAL = new_fluid_settings();
    OUTPUT:
        RETVAL

void
DESTROY (fls)
        Audio_FluidSynth_Settings   fls;
    CODE:
        delete_fluid_settings(fls);


