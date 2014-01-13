#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <fluidsynth.h>

typedef fluid_settings_t        *Audio_FluidSynth_Settings;
typedef fluid_synth_t           *Audio_FluidSynth;
typedef fluid_audio_driver_t    *Audio_FluidSynth_Driver;


MODULE = Audio::FluidSynth  PACKAGE = Audio::FluidSynth::Settings  PREFIX = fluid_settings_

Audio_FluidSynth_Settings
new (class)
        const char *class;
    CODE:
        RETVAL = new_fluid_settings();
    OUTPUT:
        RETVAL

void
DESTROY (fls)
        Audio_FluidSynth_Settings   fls;
    CODE:
        delete_fluid_settings(fls);

void
set (set, name, val)
        Audio_FluidSynth_Settings   set;
        const char                  *name;
        SV                          *val;
    PREINIT:
        int                         type;
        int                         ok;
    CODE:
        type = fluid_settings_get_type(set, name);
        switch (type) {
            case FLUID_NUM_TYPE: {
                NV nv = SvNV(val);
                ok = fluid_settings_setnum(set, name, (double)nv);
                break;
            }
            case FLUID_INT_TYPE: {
                IV iv = SvIV(val);
                ok = fluid_settings_setint(set, name, (int)iv);
                break;
            }
            case FLUID_STR_TYPE: {
                char *pv = SvPV_nolen(val);
                ok = fluid_settings_setstr(set, name, pv);
                break;
            }
            default:
                Perl_croak(aTHX_ "Unknown FluidSynth setting '%s'", name);
        }
        if (!ok)
            Perl_croak(aTHX_ "Can't set FluidSynth setting '%s'", name);

SV *
get (set, name)
        Audio_FluidSynth_Settings   set;
        const char                  *name;
    PREINIT:
        int                         type;
        int                         ok;
    CODE:
        type = fluid_settings_get_type(set, name);
        switch (type) {
            case FLUID_NUM_TYPE: {
                double val;
                ok = fluid_settings_getnum(set, name, &val);
                if (ok) RETVAL = newSVnv((NV)val);
                break;
            }
            case FLUID_INT_TYPE: {
                int val;
                ok = fluid_settings_getint(set, name, &val);
                if (ok) RETVAL = newSViv((IV)val);
                break;
            }
            case FLUID_STR_TYPE: {
                char    *val;
                ok = fluid_settings_dupstr(set, name, &val);
                if (ok) {
                    RETVAL = newSVpv(val, 0);
                    free(val);
                }
                break;
            }
            default:
                Perl_croak(aTHX_ "Unknown FluidSynth setting '%s'", name);
        }
        if (!ok)
            Perl_croak(aTHX_ "Can't get FluidSynth setting '%s'", name);
    OUTPUT:
        RETVAL


MODULE = Audio::FluidSynth  PACKAGE = Audio::FluidSynth  PREFIX = fluid_synth_

Audio_FluidSynth
new (class, fls)
        const char                  *class;
        Audio_FluidSynth_Settings   fls;
    CODE:
        RETVAL = new_fluid_synth(fls);
    OUTPUT:
        RETVAL

void
DESTROY (syn)
        Audio_FluidSynth    syn;
    CODE:
        delete_fluid_synth(syn);


MODULE = Audio::FluidSynth  PACKAGE = Audio::FluidSynth::Driver

Audio_FluidSynth_Driver
new (set, syn)
        Audio_FluidSynth_Settings   set;
        Audio_FluidSynth            syn;
    CODE:
        RETVAL = new_fluid_audio_driver(set, syn);
    OUTPUT:
        RETVAL
