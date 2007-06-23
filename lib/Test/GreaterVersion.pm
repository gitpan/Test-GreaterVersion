package Test::GreaterVersion;

=head1 NAME

Test::GreaterVersion -- Did you update the VERSION?

=head1 SYNOPSIS

  has_greater_version('My::Module');

  has_greater_version_than_cpan('My::Module');
  
=head1 DESCRIPTION

You might have forgotten to update the version of your module.
This module provides two tests to check that.

C<has_greater_version> checks if your module source has a greater
VERSION number than the version installed in the system.

C<has_greater_version_than_cpan> checks if your module source has
a greater VERSION number than the version found on CPAN.

The version is checked by looking for the VERSION scalar in the
module. The names of these two functions are always exported.

=cut

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Test::Builder;
use CPAN;
use File::Spec;
use Cwd;

use base qw(Exporter);
our @EXPORT = qw(has_greater_version
  has_greater_version_than_cpan);

our $VERSION = 0.003;

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
		return $Test->diag('Getting version from installed module failed');
	}

	my $version_from_lib = _get_version_from_lib($module);
	unless ($version_from_lib) {
		return $Test->diag('Getting version from module in lib failed');
	}

	$Test->ok(
		$version_from_lib > $version_installed,
		"$module has greater version"
	);
}

=head2 has_greater_version_than_cpan ($module)

Returns 1 if the version of your module in 'lib/' is greater
than the version on CPAN, 0 otherwise.

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

	$Test->ok(
		$version_from_lib > $version_on_cpan,
		"$module has greater version than on CPAN"
	);
}

=head2 _get_installed_version ($module)

Gets the version of the installed module. Just calls eval()
and tries to find the version afterwards.

Returns 0 if C<use> cannot find the module or it has no
VERSION. Returns the version otherwise.

=cut

sub _get_installed_version {
	my ($module) = @_;

	# strip blib from @INC
	# localize @INC so we won't affect others
	local @INC = grep { $_ !~ /blib/ } @INC;

	# load module at runtime
	eval "use $module";

	# fail on errors
	return $Test->diag("Eval had errors: $@") if $@;

	# turn of warnings
	no strict 'refs';

	# fail if there's no version defined
	unless ( defined ${"$module\::VERSION"} ) {
		return $Test->diag('Scalar VERSION not found');
	}

	# get the version
	return ${"$module\::VERSION"};

	# turn on warnings again
	use strict 'refs';
}

=head2 _get_version_from_lib ($module)

Gets the version of the module found in 'lib/'.
Transforms the module name into a filename which points
to a file found under 'lib/'.

Returns 0 if the module could not be loaded or has no
VERSION. Returns the version otherwise.

=cut

sub _get_version_from_lib {
	my $module = shift;

	my $file = _module_to_file($module);

	# try to get the version
	my $version;
	eval { $version = MM->parse_version($file); };

	# fail on errors
	return $Test->diag("parse_version had errors: $@") if $@;

	return $version;

}

# convert module name to file under lib (OS-independent)
sub _module_to_file {
	my ($module) = @_;

	# get list of components
	my @components = split( /::/, $module );

	# cwd/lib/a/b.pm under UNI*X
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

	# taken from CPAN manpage
	my $m = CPAN::Shell->expand( 'Module', $module );

	# the module is not on CPAN or something broke
	return $Test->diag("CPAN-version of '$module' not available")
	  unless $m;

	# there is a version on CPAN
	return $m->cpan_version();
}

=head2 BUGS

The double-colons are replaced by with slashes.
This works only on UNI*-like systems.

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

Neiter of these compare versions.

=head2 COPYRIGHT

Copyright (c) 2007 by Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

