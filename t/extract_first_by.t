use v6.*;
use Test;
use List::UtilsBy <extract_first_by>;
%*ENV<RAKUDO_NO_DEPRECATIONS> = True;

plan 7;

# We'll need a real array to work on
my @words = <here are some words>;

is extract_first_by( { .chars == 4 }, @words), "here",
  'extract first finds an element';
is-deeply @words, [<are some words>],
  'extract first leaves other matching elements';

is-deeply extract_first_by( { .chars == 6 }, @words), (),
  'extract first returns empty list on no match';
is-deeply @words, [<are some words>], 'and leaves array unchanged';

is-deeply extract_first_by( Scalar, { .chars == 6 }, @words), Nil,
  'extract first returns Nil on no match with Scalar';
is-deeply extract_first_by( { .chars == 6 }, @words, :scalar), Nil,
  'extract first returns Nil on no match with :scalar';
is-deeply @words, [<are some words>], 'and still leaves array unchanged';

# vim: expandtab shiftwidth=4
