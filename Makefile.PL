use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Goto::Cached',
    VERSION_FROM      => 'lib/Goto/Cached.pm', # finds $VERSION
    PREREQ_PM         => {
		'XSLoader'		=> 0,
		'Scope::Guard'	=> 0,
		'Test::More'	=> 0,
	}, # e.g., Module::Name => 1.1
	AUTHOR			  => 'chocolateboy <chocolate.boy@email.com>',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    # OPTIMIZE		  => '-pg -g3 -Wall', # e.g., '-DHAVE_SOMETHING'
    OPTIMIZE		  => '-g3 -Wall',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
