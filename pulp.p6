#!env perl6
use lib ".";
use Pulp;

sub copy-dest1-dest2 is task {
    src("src/*").map(dest("dest1", "dest2"))
}

sub copy-dest3 is task {
    src("src/*").map(rename(* * 2)).map(dest("dest3"))
}
