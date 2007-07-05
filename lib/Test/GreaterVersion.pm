package Test::GreaterVersion;

=head1 NAME

Test::GreaterVersion -- Test if you incremented VERSION

=head1 SYNOPSIS

  has_greater_version('My::Module');

  has_greater_version_than_cpan('My::Module');
  
=head1 DESCRIPTION

There are two functions which are supposed to be used
in your test suites to assure that you incremented your
version before your install the module or upload it to CPAN.

C<has_greater_version> checks if your module source has a greater
VERSION number than the version installed in the system.

C<has_greater_version_than_cpan> checks if your module source has
a greater VERSION number than the version found on CPAN.

The version is checked by looking for the VERSION scalar in the
module. The names of these two functions are always exported.

The two test functions expect your module files layed out in
the standard way, i.e. tests are called in the top directory and
module if found in the C<lib> directory:

  Module Path
    doc
    examples
    lib
    t

The version of My::Module is therefore expected in the file
C<lib/My/Module.pm>. There's currently no way to alter that
location. (The file name is OS independent via the magic of
L<File::Spec>.)

The version information is actually parsed by
L<ExtUtils::MakeMaker>.

The version numbers are compared calling
C<CPAN::Version::vgt()>. See L<CPAN::Version> or L<version>
for version number syntax. (Short: Both 1.00203 and v1.2.30 work.)  

Please note that these test functions should not be put in normal
test script below C<t/>. They will break the tests. These functions
are to be put in some install script to check the versions
automatically.

=cut

use strict;
use warnings;

use ExtUtils::MakeMaker;
use CPAN;
use CPAN::Version;
use Cwd;
use File::Spec;
use Test::Builder;

use base qw(Exporter);
our @EXPORT = qw(has_greater_version
  has_greater_version_than_cpan);

our $VERSION = 0.009;

our $Test = Test::Builder->new;

sub import {
	my ($self) = shift;
	my $pack = caller;

	$Test->exported_to($pack);
	$Test->plan(@_);

	$self->export_to_level( 1, $self, 'has_greater_version' );
	$self->export_to_level( 1, $self, 'has_greater_version_than_cpan' );
}

=head2 has_greater_version ($module)

Returns 1 if the version of your module in 'lib/' is greater
than the version of the installed module, 0 otherwise.

=cut

sub has_greater_version {
	my ($module) = @_;

	unless ($module) {
		return $Test->diag("You didn't specify a module name");
	}

	my $version_installed = _get_installed_version($module);
	unless ($version_installed) {
		return $Test->diag('Getting version of installed module failed');
	}

	my $version_from_lib = _get_version_from_lib($module);
	unless ($version_from_lib) {
		return $Test->diag('Getting version of module in lib failed');
	}

	$Test->ok( CPAN::Version->vgt( $version_from_lib, $version_installed ),
		"$module has greater version" );
}

=head2 has_greater_version_than_cpan ($module)

Returns 1 if the version of your module in 'lib/' is greater
than the version on CPAN, 0 otherwise.

Due to the interface of the CPAN module there's currently
no way to tell if the module is not on CPAN or if there
has been an error in getting the module information from CPAN.
As a result this function should only be called if you are
sure that there's a version of the module on CPAN.

Depending on the configuration of your CPAN shell the first
call of this function may seem to block the test. When
you notice this behaviour it's likely that the CPAN shell is
trying to get the latest module index which may take some time.

=cut

sub has_greater_version_than_cpan {
	my ($module) = @_;

	unless ($module) {
		return $Test->diag('You didn\'t specify a module name');
	}

	my $version_on_cpan = _get_version_from_cpan($module);
	unless ($version_on_cpan) {
		return $Test->diag("Getting version of '$module' on CPAN failed");
	}

	my $version_from_lib = _get_version_from_lib($module);
	unless ($version_from_lib) {
		return $Test->diag("Getting version of '$module' in lib failed");
	}

	$Test->ok( CPAN::Version->vgt( $version_from_lib, $version_on_cpan ),
		"$module has greater version than on CPAN" );
}

=head2 _get_installed_version ($module)

Gets the version of the installed module. The version
information is found with the help of the CPAN module.

Returns 0 if CPAN cannot find the module or it has no
VERSION. Returns the version otherwise.

We don't use CPAN::Shell::inst_version() since it doesn't
remove blib before searching for the version and
we want to have a diag() output in the test. And because
the manpage doesn't list the function in the stable
interface.

=cut

sub _get_installed_version {
	my ($module) = @_;

	# Strip blib from @INC so the CPAN::Shell
	# won't find the module even if it's there.
	# (Tests add blib to @INC).
	# Localize @INC so we won't affect others
	local @INC = grep { $_ !~ /blib/ } @INC;

	my $file = _module_to_file($module);

	my $bestv;
	for my $incdir (@INC) {
		my $bfile = File::Spec->catfile( $incdir, $file );

		# skip if it's not a file
		next unless -f $bfile;

		# get the version
		my $foundv = MM->parse_version($bfile);

		# remember which version is greatest
		if ( !$bestv || CPAN::Version->vgt( $foundv, $bestv ) ) {
			$bestv = $foundv;
		}
	}

	return $bestv;
}

=head2 _get_version_from_lib ($module)

Gets the version of the module found in 'lib/'.
Transforms the module name into a filename which points
to a file found under 'lib/'.

C<MM->parse_version()> tries to find the version.

Returns 0 if the module could not be loaded or has no
VERSION. Returns the version otherwise.

=cut

sub _get_version_from_lib {
	my $module = shift;

	my $file = _module_to_file($module);

	return $Test->diag("file '$file' doesn't exist")
	  unless -f $file;

	# try to get the version
	my $code = sub { MM->parse_version($file) };    
	my ( $version, $error ) = $Test->_try($code);

	# fail on errors
	return $Test->diag("parse_version had errors: $@")
	  if $error;

	return $version;

}

# convert module name to file under lib (OS-independent)
sub _module_to_file {
	my ($module) = @_;

	# get list of components
	my @components = split( /::/, $module );

	# cwd/lib/a/b.pm under UNI*
	my $cwd = getcwd();
	my $file = File::Spec->catfile( $cwd, 'lib', @components );
	$file .= '.pm';

	return $file;
}

=head2 _get_version_from_cpan ($module)

Gets the module's version as found on CPAN. The version
information is found with the help of the CPAN module.

Returns 0 if the module is not on CPAN or the CPAN module
failed somehow. Returns the version otherwise.

=cut

sub _get_version_from_cpan {
	my ($module) = @_;

	# Turn off coloured output of the CPAN shell.
	# This breaks the test/Harness/whatever.
	CPAN::HandleConfig->load();
	$CPAN::Config->{colorize_output}=0;

	# taken from CPAN manpage
	my $m = CPAN::Shell->expand( 'Module', $module );
	
	# the module is not on CPAN or something broke
	return $Test->diag("CPAN-version of '$module' not available")
	  unless $m;

	# there is a version on CPAN
	return $m->cpan_version();
}

=head2 NOTES

This module was inspired by brian d foy's talk
'Managing Complexity with Module::Release' at the Nordic Perl
Workshop in 2006.

=head2 AUTHOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=head2 SIMILAR MODULES

L<Test::Version> tests if there is a VERSION defined.

L<Test::HasVersion> does it, too, but has the ability to
check all Perl modules in C<lib>.

Neither of these compare versions.

=head2 COPYRIGHT

Copyright (c) 2007 by Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

