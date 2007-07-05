#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

my $module='Test::GreaterVersion';

use_ok($module) or exit;
can_ok($module, 'has_greater_version');

# no module name
{
    my $expected=0;
    my $got=has_greater_version();
    is($got, $expected,'no module name');
}

# name of non-existent module
{
    my $expected=0;
    my $got=has_greater_version("I don't exist XX");
    is($got, $expected, 'name of non-existent module');
}

# name of module not in lib
{
    my $expected=0;
    my $got=has_greater_version('Test::More');
    is($got, $expected, 'name of module not in lib');
}

=head2 AUTOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=cut