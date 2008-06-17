use 5.006;

use ExtUtils::MakeMaker;
use Config;

my $optimize;

if ($Config{gccversion}) {
    $optimize = '-O3 -Wall';
} elsif ($Config{osname} eq 'MSWin32') {
    $optimize = '-O2 -W4';
} else {
    $optimize = $Config{optimize};
}

WriteMakefile(
    NAME         => 'Goto::Cached',
    VERSION_FROM => 'lib/Goto/Cached.pm',
    PREREQ_PM    => {
        'Devel::Hints::Lexical' => '0.03',
        'Scope::Guard'          => '0.03',
        'Test::More'            => '0',
    },
    AUTHOR   => 'chocolateboy <chocolate.boy@email.com>',
    LIBS     => [''],
    DEFINE   => '',
    OPTIMIZE => $optimize,
    INC      => '-I.',
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
);
