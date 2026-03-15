use strict;
use warnings;
use Test::More tests => 2;
use lib 'lib';
use Syntax::Feature::With qw(with);

my $data = { foo => 'bar', num => 42 };
my ($foo, $num);

with($data, sub {
    my %f = @_;
    $foo = $f{foo};
    $num = $f{num};
});

is($foo, 'bar', 'foo field correct');
is($num, 42, 'num field correct');
