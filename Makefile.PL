use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Goto::Cached',
    VERSION_FROM => 'lib/Goto/Cached.pm',
    PREREQ_PM    => {
        'Scope::Guard' => 0,
        'Test::More'   => 0,
    },
    AUTHOR   => 'chocolateboy <chocolate.boy@email.com>',
    LIBS     => [''],
    DEFINE   => '',
    OPTIMIZE => '-O3 -Wall',
    INC      => '-I.',
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
);
