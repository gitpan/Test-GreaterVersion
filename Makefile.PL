use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Test::GreaterVersion',
	VERSION_FROM => 'lib/Test/GreaterVersion.pm',
	AUTHOR       => 'Gregor Goldbach <glauschwuffel@nomaden.org>',
	PREREQ_PM    => {
		Test::Builder => 0,
		CPAN          => 0,
		File::Spec    => 0,    
		CPAN::Version => 0
	},
	LICENSE      => 'perl',
	PREREQ_FATAL => 1
);
