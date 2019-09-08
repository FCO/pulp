subset Dir  of IO::Path where :d;
subset Sta  of Str      where .contains: "*";
subset Staa of Str      where .contains: "**";

sub test-glob(Sta $pattern, Str $str) {
    my $copy = $str;
    for $pattern.split: "*", :skip-empty {
        return False without my $i = $copy.index: $_;
        $copy .= substr: $i + .chars
    }
    $copy.ends-with("*") || $copy.chars == 0
}

proto glob(|) is export                               { * }
multi glob(Str $path,            IO::Path $_ = $*CWD) { glob $*SPEC.splitdir($path), $_ }
multi glob([],                   IO::Path $_ = $*CWD) { $_ }
multi glob(["*"],                IO::Path $_ = $*CWD) { $_ }
multi glob(["**"],               IO::Path $_ = $*CWD) { $_ }
multi glob(["*", *@rest],        Dir $_      = $*CWD) { |.dir.map: { glob @rest, $_ } }
multi glob(["**", *@rest],       Dir $_      = $*CWD) { |.dir.flatmap: { |glob(("**", |@rest), $_), |glob @rest, $_ } }
multi glob(["*", *@],            IO::Path    = $*CWD) { Empty }
multi glob(["**", *@rest],       IO::Path    = $*CWD) { Empty }
multi glob([Staa $next, *@rest], Dir $_      = $*CWD) { |glob(( $next.subst(/"**"/, "*", :g), |@rest ), $_), |.dir.map: { |glob ( $next, |@rest ), $_ } }
multi glob([Staa $next, *@rest], IO::Path $_ = $*CWD) { |glob ( $next.subst(/"**"/, "*", :g), |@rest ), $_ }
multi glob([Sta $next, *@rest],  Dir $_      = $*CWD) { |.dir.map: { test-glob($next, .basename) ?? |glob @rest,$_ !! Empty } }
multi glob([Str $next, *@rest],  Dir $_      = $*CWD) { do given .add: $next { .e ?? |glob @rest, $_ !! Empty } }
multi glob([Str $next, *@rest],  IO::Path    = $*CWD) { Empty }


