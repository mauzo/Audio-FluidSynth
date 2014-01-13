use Module::Build;

unless (eval "require ExtUtils::PkgConfig; 1") {
    print "This module requires ExtUtils::PkgConfig.\n";
    exit 0;
}

my %pc = ExtUtils::PkgConfig->find("fluidsynth");
print "Using FluidSynth version $pc{modversion}.\n";

Module::Build->new(
    module_name		=> "Audio::FluidSynth",
    license		=> "bsd",

    dynamic_config          => 1,
    extra_compiler_flags    => $pc{cflags},
    extra_linker_flags      => $pc{libs},

    configure_requires	=> {
        "ExtUtils::PkgConfig"   => "0",
	"Module::Build"	        => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
    },
    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/Audio-FluidSynth",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=Audio-FluidSynth",
	},
    },
)->create_build_script;
