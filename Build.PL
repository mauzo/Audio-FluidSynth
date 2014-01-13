use Module::Build;

Module::Build->new(
    module_name		=> "Audio::FluidSynth",
    license		=> "bsd",
    configure_requires	=> {
	"Module::Build"	    => "0.38",
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
