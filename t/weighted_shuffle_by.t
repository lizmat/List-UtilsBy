use v6.*;
use Test;
use List::UtilsBy <weighted_shuffle_by>;

plan 3;

is-deeply weighted_shuffle_by( { $_ } ), (), 'empty list';

is-deeply weighted_shuffle_by( { 1 }, "a"), ["a"], 'unit list';

my @vals = weighted_shuffle_by( { 1 }, "a", "b", "c" );
is-deeply @vals.sort, <a b c>, 'set of return values';

# vim: expandtab shiftwidth=4
