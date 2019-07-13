#!env perl6
use lib ".";
use Pulp;

sub copy-dest1-dest2 is task {
    src("src/*").map(dest("dest1", "dest2"))
}

sub copy-dest3 is task {
    src("src/*").map(rename(* * 2)).map(dest("dest3"))
}

sub test-parallel is parallel-task {
    "copy-dest1-dest2", "copy-dest3"
}

sub test-serial is serial-task {
    "copy-dest1-dest2", "copy-dest3"
}
