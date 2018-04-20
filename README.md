NAME
====

List::UtilsBy - Port of Perl 5's List::UtilsBy 0.11

SYNOPSIS
========

    use List::UtilsBy <nsort_by min_by>;
     
    my @files_by_age = nsort_by { .IO.modified }, @files;
     
    my $shortest_name = min_by { .chars }, @names;

DESCRIPTION
===========

List::UtilsBy provides some trivial but commonly needed functionality on lists which is not going to go into `List::Util`.

Porting Caveats
===============

Perl 6 does not have the concept of `scalar` and `list` context. Usually, the effect of a scalar context can be achieved by prefixing `+` to the result, which would effectively return the number of elements in the result, which usually is the same as the scalar context of Perl 5 of these functions.

Perl 6 does not have a magic `$a` and `$b`. But they can be made to exist by specifying the correct signature to blocks, specifically "-> $a, $b". These have been used in all examples that needed them. Just using the signature auto-generating `$^a` and `$^b` would be more Perl 6 like. But since we want to keep the documentation as close to the original as possible, it was decided to specifically specify the "-> $a, $b" signatures.

Many functions take a `&code` parameter of a `Block` to be called by the function. Many of these assume **$_** will be set. In Perl 6, this happens automagically if you create a block without a definite or implicit signature:

    say { $_ == 4 }.signature;   # (;; $_? is raw)

which indicates the Block takes an optional parameter that will be aliased as `$_` inside the Block.

Perl 6 also doesn't have a single `undef` value, but instead has `Type Objects`, which could be considered undef values, but with a type annotation. In this module, `Nil` (a special value denoting the absence of a value where there should have been one) is used instead of `undef`.

Also note there are no special parsing rules with regards to blocks in Perl 6. So a comma is **always** required after having specified a block.

The following functions are actually built-ins in Perl 6.

    any all none minmax uniq zip

They mostly provide the same or similar semantics, but there may be subtle differences, so it was decided to not just use the built-ins. If these functions are imported from this library in a scope, they will used instead of the Perl 6 builtins. The easiest way to use both the functions of this library and the Perl 6 builtins in the same scope, is to use the method syntax for the Perl 6 versions.

    my @a = 42,5,2,98792,88;
    {  # Note: imports in Perl 6 are always lexically scoped
        use List::Util <minmax>;
        say minmax @a;  # Ported Perl 5 version
        say @a.minmax;  # Perl 6 version
    }
    say minmax @a;  # Perl 6 version again

Many functions returns either `True` or `False`. These are `Bool`ean objects in Perl 6, rather than just `0` or `1`. However, if you use a Boolean value in a numeric context, they are silently coerced to 0 and 1. So you can still use them in numeric calculations as if they are 0 and 1.

Some functions return something different in scalar context than in list context. Perl 6 doesn't have those concepts. Functions that are supposed to return something different in scalar context also accept a `:scalar` named parameter to indicate a scalar context result is required. This will be noted with the function in question if that feature is available.

FUNCTIONS
=========

sort_by BLOCK, LIST
-------------------

Returns the list of values sorted according to the string values returned by the BLOCK. A typical use of this may be to sort objects according to the string value of some accessor, such as:

    my @sorted = sort_by { .name }, @people;

The key function is being passed each value in turn, The values are then sorted according to string comparisons on the values returned. This is equivalent to:

    my @sorted = sort -> $a, $b { $a.name cmp $b.name }, @people;

except that it guarantees the `name` accessor will be executed only once per value. One interesting use-case is to sort strings which may have numbers embedded in them "naturally", rather than lexically:

    my @sorted = sort_by { S:g/ (\d+) / { sprintf "%09d", $0 } / }, @strings;

This sorts strings by generating sort keys which zero-pad the embedded numbers to some level (9 digits in this case), helping to ensure the lexical sort puts them in the correct order.

### Idiomatic Perl 6 ways

    my @sorted = @people.sort: *.name;

nsort_by BLOCK, LIST
--------------------

Similar to `sort_by` but compares its key values numerically.

### Idiomatic Perl 6 ways

    my @sorted = <10 1 20 42>.sort: +*;

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/List-UtilsBy . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Re-imagined from the Perl 5 version as part of the CPAN Butterfly Plan. Perl 5 version developed by Paul Evans.

