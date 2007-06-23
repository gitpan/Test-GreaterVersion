use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Test::GreaterVersion',
	VERSION_FROM => 'lib/Test/GreaterVersion.pm',
	AUTHOR       => 'Gregor Goldbach <goldbach@dfn-cert.de>',
	PREREQ_PM    =>
	  { Test::Builder => 0, CPAN => 0, File::Spec => 0 }    
	,
	PREREQ_FATAL => 1
);
