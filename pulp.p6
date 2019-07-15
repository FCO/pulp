#!env perl6
use lib ".";
use Pulp;
use Pulp::Plugin::Subst;
use Pulp::Plugin::Rename;
use Pulp::Plugin::JSMinify;

sub copy-dest1-dest2 is task {
    src("src/*").map(dest("dest1", "dest2"))
}

sub copy-dest3 is task {
    src("src/*").map(rename(* * 2)).map(dest("dest3"))
}

sub test-replace is task {
    src("src/*").map(subst(/\d+/, *², :g)).map(dest("dest4"))
}

sub test-parallel is parallel-task {
    "copy-dest1-dest2", "copy-dest3"
}

sub test-serial is serial-task {
    "copy-dest1-dest2", "copy-dest3"
}

sub default is task { say "DEFAULT" }

sub watch is task {
    watch-path "src/*", :task<copy-dest3>
}

sub minify is task {
    src("js/*.js").map(js-minify()).map(dest("js.min"))
}
