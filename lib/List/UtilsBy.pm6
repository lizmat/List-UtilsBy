use v6.c;

class List::UtilsBy:ver<0.0.1>:auth<cpan:ELIZABETH> {
    our sub max_by(&code, @values, :$scalar) is export(:all) {
        my $max = -Inf;
        my @max-value is default(Nil);
        for @values -> $value {
            with code($value) {
                if $_ > $max {
                    $max = $_;
                    @max-value = $value;
                }
                elsif $_ == $max {
                    @max-value.push($value);
                }
            }
        }
        $scalar ?? @max-value[0] !! @max-value;
    }
    our constant &nmax_by is export(:all) = &max_by;

    our sub min_by(&code, @values, :$scalar) is export(:all) {
        my $min = Inf;
        my @min-value is default(Nil);
        for @values -> $value {
            with code($value) {
                if $_ < $min {
                    $min = $_;
                    @min-value = $value;
                }
                elsif $_ == $min {
                    @min-value.push($value);
                }
            }
        }
        $scalar ?? @min-value[0] !! @min-value;
    }
    our constant &nmin_by is export(:all) = &min_by;

    our sub minmax_by(&code, @values) is export(:all) {
        my $max = -Inf;
        my $min = Inf;
        my $max-value is default(Nil);
        my $min-value is default(Nil);
        for @values -> $value {
            with code($value) {
                if $_ < $min {
                    $min = $_;
                    $min-value = $value;
                }
                elsif $_ > $max {
                    $max = $_;
                    $max-value = $value;
                }
            }
        }
        ($min-value,$max-value)
    }
    our constant &nminmax_by is export(:all) = &minmax_by;

    our sub rev_nsort_by(&code, @values) is export(:all) {
        # Please note that reversing the result of the sort just means that
        # it uses an iterator that walks back from the end of the reified
        # list, rather than creating a reversed copy of the List.
        @values.sort( { +code($_) } ).reverse.List
    }

    our sub rev_sort_by(&code, @values) is export(:all) {
        @values.sort( { ~code($_) } ).reverse.List
    }

    our sub sort_by(&code, @values) is export(:all) {
        @values.sort( { ~code($_) } ).List
    }

    our sub nsort_by(&code, @values) is export(:all) {
        @values.sort( { +code($_) } ).List
    }

    our sub uniq_by(&code, @values) is export(:all) {
        @values.unique( { ~code($_) } ).List
    }

    our sub partition_by(&code, @values) is export(:all) {
        @values.classify( { ~code($_) }, :into(my %) )
    }

    our sub count_by(&code, @values) is export(:all) {
        my %count_by;
        ++%count_by{ code($_) } for @values;
        %count_by
    }

    our sub zip_by(&code, **@arrays) is export(:all) {
        my @iterators = @arrays.map: *.iterator;
        my $nr_values = +@iterators;
        my @zip_by;

        loop {
            my $seen = $nr_values;
            my @values = @iterators.map: {
                my $pulled := .pull-one;
                if $pulled =:= IterationEnd {
                    --$seen;
                    Nil
                }
                else {
                    $pulled
                }
            }
            last unless $seen;
            @zip_by.append( code(|@values).Slip )
        }
        @zip_by
    }

    our sub unzip_by(&code, @values) is export(:all) {
        my @unzip_by;
        for @values.kv -> $result, $_ {
            for code($_).kv -> $index, \value {
                @unzip_by[$index][$result] = value
            }
        }
        @unzip_by
    }

    our sub extract_by(&code, @values) is export(:all) {
        my @extract_by;
        @extract_by.prepend( @values.splice($_,1) ) if code(@values[$_])
          for (^@values).reverse;
        @extract_by
    }

    our sub extract_first_by(&code, @values) is export(:all) {
        with @values.first(&code, :k) {
            @values.splice($_,1).head
        }
        else {
            ()
        }
    }

    our sub weighted_shuffly_by(&code, @values) is export(:all) {
        my @weighted_shuffle_by;
        my $mix = MixHash.new( @values.map( { $_ => code($_) } ) );
        while $mix {
            @weighted_shuffle_by.push( $mix{$mix.pick}:delete )
        }
        @weighted_shuffle_by
    }

    our sub bundle_by(&code, $number, @values) is export(:all) {
        @values.map(&code).batch($number).List
    }
}

sub EXPORT(*@args, *%_) {

    if @args {
        my $imports := Map.new( |(EXPORT::all::{ @args.map: '&' ~ * }:p) );
        if $imports != @args {
            die "List::UtilsBy doesn't know how to export: "
              ~ @args.grep( { !$imports{$_} } ).join(', ')
        }
        $imports
    }
    else {
        Map.new
    }
}

=begin pod

=head1 NAME

List::UtilsBy - Port of Perl 5's List::UtilsBy 0.11

=head1 SYNOPSIS

    use List::UtilsBy <nsort_by min_by>;

    my @files_by_age = nsort_by { .IO.modified }, @files;

    my $shortest_name = min_by { .chars }, @names;

=head1 DESCRIPTION

List::UtilsBy provides some trivial but commonly needed functionality on
lists which is not going to go into C<List::Util>.

=head1 Porting Caveats

Perl 6 does not have the concept of C<scalar> and C<list> context.  Usually,
the effect of a scalar context can be achieved by prefixing C<+> to the
result, which would effectively return the number of elements in the result,
which usually is the same as the scalar context of Perl 5 of these functions.

Many functions take a C<&code> parameter of a C<Block> to be called by the
function.  Many of these assume B<$_> will be set.  In Perl 6, this happens
automagically if you create a block without a definite or implicit signature:

  say { $_ == 4 }.signature;   # (;; $_? is raw)

which indicates the Block takes an optional parameter that will be aliased
as C<$_> inside the Block.  If you want to be able to change C<$_> inside
the block B<without> changing the source array, you can use the C<is copy>
trait thus:

  -> $_ is copy { ... code changing $_ ... }

Perl 6 also doesn't have a single C<undef> value, but instead has
C<Type Objects>, which could be considered undef values, but with a type
annotation.  In this module, C<Nil> (a special value denoting the absence
of a value where there should have been one) is used instead of C<undef>.

Also note there are no special parsing rules with regards to blocks in Perl 6.
So a comma is B<always> required after having specified a block.

Some functions return something different in scalar context than in list
context.  Perl 6 doesn't have those concepts.  Functions that are supposed
to return something different in scalar context also accept a C<:scalar>
named parameter to indicate a scalar context result is required.  This will
be noted with the function in question if that feature is available.

=head1 FUNCTIONS

=head2 sort_by BLOCK, LIST

Returns the list of values sorted according to the string values returned by
the BLOCK. A typical use of this may be to sort objects according to the
string value of some accessor, such as:

    my @sorted = sort_by { .name }, @people;

The key function is being passed each value in turn, The values are then
sorted according to string comparisons on the values returned.
This is equivalent to:

    my @sorted = sort -> $a, $b { $a.name cmp $b.name }, @people;

except that it guarantees the C<name> accessor will be executed only once
per value.  One interesting use-case is to sort strings which may have numbers
embedded in them "naturally", rather than lexically:

    my @sorted = sort_by { S:g/ (\d+) / { sprintf "%09d", $0 } / }, @strings;

This sorts strings by generating sort keys which zero-pad the embedded numbers
to some level (9 digits in this case), helping to ensure the lexical sort puts
them in the correct order.

=head3 Idiomatic Perl 6 ways

    my @sorted = @people.sort: *.name;

=head2 nsort_by BLOCK, LIST

Similar to C</sort_by> but compares its key values numerically.

=head3 Idiomatic Perl 6 ways

    my @sorted = <10 1 20 42>.sort: +*;

=head2 rev_sort_by BLOCK, LIST

=head2 rev_nsort_by BLOCK, LIST

    my @sorted = rev_sort_by { KEYFUNC }, @vals;

    my @sorted = rev_nsort_by { KEYFUNC }, @vals;

    Similar to L<sort_by> and L<nsort_by> but returns the list in the reversei
    order.

=head2 max_by BLOCK, LIST

    my @optimal = max_by { KEYFUNC }, @vals;

    my $optimal = max_by { KEYFUNC }, @vals, :scalar;

Returns the (first) value(s) from C<@vals> that give the numerically largest
result from the key function.

    my $tallest = max_by { $_->height }, @people, :scalar;

    my $newest = max_by { .IO.modified }, @files, :scalar;

If the C<:scalar> named parameter is specified, then only the first maximal
value is returned. Otherwise a list of all the maximal values is returned.
This may be used to obtain positions other than the first, if order is
significant.

If called on an empty list, an empty list is returned.

For symmetry with the L</nsort_by> function, this is also provided under the
name C<nmax_by> since it behaves numerically.

=head2 min_by BLOCK, LIST

    my @optimal = min_by { KEYFUNC }, @vals;

    my $optimal = min_by { KEYFUNC }, @vals, :scalar;

Similar to L</max_by> but returns values which give the numerically smallest
result from the key function. Also provided as C<nmin_by>

=head2 minmax_by

    my ($minimal, $maximal) = minmax_by { KEYFUNC }, @vals

Similar to calling both L</min_by> and L</max_by> with the same key function
on the same list. This version is more efficient than calling the two other
functions individually, as it has less work to perform overall. Also provided
as C<nminmax_by>.

=head2 uniq_by BLOCK, LIST

    my @unique = uniq_by { KEYFUNC }, @vals;

Returns a list of the subset of values for which the key function block
returns unique values. The first value yielding a particular key is chosen,
subsequent values are rejected.

    my @some_fruit = uniq_by { $_->colour }, @fruit;

To select instead the last value per key, reverse the input list. If the order
of the results is significant, don't forget to reverse the result as well:

    my @some_fruit = reverse uniq_by { $_->colour }, reverse @fruit;

Because the values returned by the key function are used as hash keys, they
ought to either be strings, or at least stringify in an identifying manner.

=head2 partition_by BLOCK, LIST

    my %parts = partition_by { KEYFUNC }, @vals;

Returns a Hash of Arrays containing all the original values distributed
according to the result of the key function block. Each value will be an
Array containing all the values which returned the string from the
key function, in their original order.

   my %balls_by_colour = partition_by { $_->colour }, @balls;

Because the values returned by the key function are used as hash keys, they
ought to either be strings, or at least stringify in an identifying manner.

=head2 count_by BLOCK, LIST

    my %counts = count_by { KEYFUNC }, @vals;

Returns a Hash giving the number of times the key function block returned
the key, for each value in the list.

   my %count_of_balls = count_by { $_->colour }, @balls;

Because the values returned by the key function are used as hash keys, they
ought to either be strings, or at least stringify in an identifying manner.

=head2 zip_by BLOCK, ARRAYS

    my @vals = zip_by { ITEMFUNC }, @arr0, @arr1, @arr2, ... ;

Returns a list of each of the values returned by the function block, when
invoked with values from across each each of the given Arrays. Each value
in the returned list will be the result of the function having been
invoked with arguments at that position, from across each of the arrays given.

   my @transposition = zip_by { [ @_ ] }, @matrix;

   my @names = zip_by { "$_[1], $_[0]" }, @firstnames, @surnames;

   print zip_by { "$_[0] => $_[1]\n" }, %hash.keys, %hash.values;

If some of the arrays are shorter than others, the function will behave as if
they had C<Any> in the trailing positions. The following two lines are
equivalent:

   zip_by { f(@_) }, [ 1, 2, 3 ], [ "a", "b" ];
   f( 1, "a" ), f( 2, "b" ), f( 3, Any );

If the item function returns a list, and you want to have the separate entries
of that list to be included in the result, you need to return that slip that
list.. This can be useful for example, for generating a hash from two separate
lists of keys and values:

    my %nums = zip_by { |@_ }, <one two three>, (1, 2, 3);
    # %nums = ( one => 1, two => 2, three => 3 )

(A function having this behaviour is sometimes called C<zipWith>, e.g. in
Haskell, but that name would not fit the naming scheme used by this module).

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/List-UtilsBy . Comments
and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

Re-imagined from the Perl 5 version as part of the CPAN Butterfly Plan. Perl 5
version developed by Paul Evans.

=end pod

# vim: ft=perl6 expandtab sw=4
