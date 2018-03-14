#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <fluidsynth.h>

typedef fluid_settings_t        *Settings;
typedef fluid_synth_t           *Synth;
typedef fluid_audio_driver_t    *Driver;

#define FS_MOD "Audio::FluidSynth"

#define FS_Settings_CLASS   FS_MOD "::Settings"
#define FS_Synth_CLASS      FS_MOD
#define FS_Driver_CLASS     FS_MOD "::Driver"

#define FS_CLASS(typ)   FS_ ## typ ## _CLASS

#define fs_ck_nn(ptr, typ) \
    STMT_START { \
        if (!ptr) \
            Perl_croak(aTHX_ "Failed to create %s object", \
                FS_CLASS(typ)); \
    } STMT_END

static void
FS_fs_ck_obj (pTHX_ SV *sv, const char *cls, CV *cv)
{
    GV *gv;
    HV *st;

    if (sv_isobject(sv) && sv_derived_from(sv, cls))
        return;

    gv = CvGV(cv);
    if (!gv) gv = gv_fetchpvs(FS_MOD "::__ANON__", GV_ADD, SVt_PVCV);
    st = GvSTASH(gv);
    if (!st) gv_stashpvs(FS_MOD "::__ANON__::", GV_ADD);

    Perl_croak(aTHX_ "%s->%s: '%s' is not an %s",
        HvNAME(st), GvNAME(gv), SvPV_nolen(sv), cls);
}

#define fs_ck_obj(sv, typ) \
    FS_fs_ck_obj(aTHX_ sv, FS_CLASS(typ), cv)

#define FS_MKOBJ(sv, typ) \
    sv_bless(newRV_noinc((SV*)sv), gv_stashpvs(FS_CLASS(typ), GV_ADD))

#define FS_PTROBJ(var, arg, typ) \
    STMT_START { \
        SV *sv; \
        fs_ck_obj(arg, typ); \
        sv = SvRV(arg); \
        var = INT2PTR(typ, SvIV(sv)); \
    } STMT_END

#define FS_AVOBJ(var, arg, typ) \
    STMT_START { \
        AV *av; SV **sv; \
        fs_ck_obj(arg, typ); \
        av = (AV*)SvRV(arg); \
        sv = av_fetch(av, 0, 0); \
        if (!sv) Perl_croak(aTHX_ "%s: panic: no pointer element", FS_MOD); \
        var = INT2PTR(typ, SvIV(*sv)); \
    } STMT_END

static void
FS_fs_ck_phase (pTHX_ void *obj, const char *type)
{
    if (PL_phase == PERL_PHASE_DESTRUCT)
        Perl_warn(aTHX_ 
            "%s object 0x%"UVxf" reached final phase of global destruction\n",
            type, PTR2UV(obj));
}

#define fs_ck_phase(o, typ) FS_fs_ck_phase(aTHX_ (o), FS_CLASS(typ))

MODULE = Audio::FluidSynth  PACKAGE = Audio::FluidSynth::Settings  PREFIX = fluid_settings_

Settings
new (class)
        const char *class;
    CODE:
        RETVAL = new_fluid_settings();
    OUTPUT:
        RETVAL

void
DESTROY (fls)
        Settings    fls;
    CODE:
        /* Settings doesn't keep any refs, so it doesn't matter if it
         * reaches global destruction */
        delete_fluid_settings(fls);

void
set (set, name, val)
        Settings    set;
        const char  *name;
        SV          *val;
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
        Settings    set;
        const char  *name;
    PREINIT:
        int         type;
        int         ok;
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

SV *
new (class, flssv)
        const char  *class;
        SV          *flssv;
    PREINIT:
        Settings    fls;
        Synth       syn;
        AV          *obj;
        SV          *flsobj;
    CODE:
        FS_PTROBJ(fls, flssv, Settings);
        syn = new_fluid_synth(fls);
        fs_ck_nn(syn, Synth);

        obj = newAV();
        av_extend(obj, 1);
        av_store(obj, 0, newSViv(PTR2IV(syn)));
        av_store(obj, 1, newRV_inc(SvRV(flssv)));

        RETVAL = FS_MKOBJ(obj, Synth);
    OUTPUT:
        RETVAL

void
DESTROY (syn)
        Synth   syn;
    CODE:
        fs_ck_phase(syn, Synth);
        delete_fluid_synth(syn);

int
fluid_synth_sfload (synth, filename, reset)
        Synth       synth;
        const char  *filename;
        bool        reset;
    POSTCALL:
        if (RETVAL == FLUID_FAILED)
            Perl_croak(aTHX_ "Failed to load SoundFont '%s'", filename);

NO_OUTPUT int 
fluid_synth_noteon (synth, chan, key, vel)
        Synth   synth;
        int     chan;
        int     key;
        int     vel;
    POSTCALL:
        if (RETVAL != FLUID_OK)
            Perl_croak(aTHX_ "noteon failed");

NO_OUTPUT int
fluid_synth_noteoff (synth, chan, key)
        Synth   synth;
        int     chan;
        int     key;
    POSTCALL:
        if (RETVAL != FLUID_OK)
            Perl_croak(aTHX_ "noteoff failed");

NO_OUTPUT int
fluid_synth_program_change (synth, chan, prognum)
        Synth   synth;
        int     chan;
        int     prognum;
    POSTCALL:
        if (RETVAL != FLUID_OK)
            Perl_croak(aTHX_ "program_change failed");

NO_OUTPUT int
fluid_synth_bank_select (synth, chan, bank)
        Synth           synth;
        int             chan;
        unsigned int    bank;
    POSTCALL:
        if (RETVAL != FLUID_OK)
            Perl_croak(aTHX_ "bank_select failed");

NO_OUTPUT int
fluid_synth_program_select (synth, chan, sfont, bank, preset)
        Synth           synth;
        int             chan;
        unsigned int    sfont;
        unsigned int    bank;
        unsigned int    preset;
    POSTCALL:
        if (RETVAL != FLUID_OK)
            Perl_croak(aTHX_ "program_select failed");

NO_OUTPUT int
fluid_synth_cc (synth, chan, num, val)
        Synth   synth;
        int     chan;
        int     num;
        int     val;
    POSTCALL:
        if (RETVAL != FLUID_OK)
            Perl_croak(aTHX_ "cc failed");


MODULE = Audio::FluidSynth  PACKAGE = Audio::FluidSynth::Driver

SV *
new (class, setsv, synsv)
        const char  *class;
        SV          *setsv;
        SV          *synsv;
    PREINIT:
        Settings    set;
        Synth       syn;
        Driver      drv;
        AV          *obj;
    CODE:
        FS_PTROBJ(set, setsv, Settings);
        FS_AVOBJ(syn, synsv, Synth);
        drv = new_fluid_audio_driver(set, syn);
        fs_ck_nn(drv, Driver);

        obj = newAV();
        av_extend(obj, 2);
        av_store(obj, 0, newSViv(PTR2IV(drv)));
        av_store(obj, 1, newRV_inc(SvRV(setsv)));
        av_store(obj, 2, newRV_inc(SvRV(synsv)));

        RETVAL = FS_MKOBJ(obj, Driver);
    OUTPUT:
        RETVAL

void
DESTROY (drv)
        Driver  drv;
    CODE:
        fs_ck_phase(drv, Driver);
        delete_fluid_audio_driver(drv);
