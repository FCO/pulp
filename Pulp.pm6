#!env perl6
use IO::Glob;

class File {
    has IO::Path $.path;
    has Supply   $.content;
}

sub src(*@paths) is export {
    gather for @paths -> $p {
        for glob($p) {
            next if .d;
            my $CWD = $p.IO.dirname;
            my $path = .relative($CWD).IO.clone(:$CWD);
            take File.new:
                :$path,
                :content(.open.Supply)
        }
    }
}

sub mkdir-p(IO::Path $_) {
    my $parent = .parent;
    mkdir-p $parent unless $parent.d;
    .mkdir unless .d
}

sub dest(*@paths) is export {
    -> File $file {
        my $supply = $file.content;
        for @paths -> $CWD {
            my $path = $file.path.clone(:$CWD).IO;
            my $dir  = $path.absolute.IO.relative($*CWD).IO.dirname;
            mkdir-p $dir.IO unless $dir.IO.d;
            my $fd   = $path.open: :w;
            $supply .= do: -> $content { $fd.print: $content }
        }
        $supply
    }
}

sub rename(&trans) is export {
    -> File $file {
        $file.clone: :path($file.path.clone: :path("{ $file.path.dirname }/{ trans $file.path.basename }"))
    }
}

my %tasks;

multi trait_mod:<is>(Sub $r, Bool :$task! where * === True) is export {
    %tasks{ $r.name } = $r
}

multi MAIN(Bool :tasks(:$T)!) is export {
    say "Tasks:";
    for %tasks.keys -> $task {
        say " - $task"
    }
}

multi MAIN(Str $task where %tasks.keys.any) is export {
    with %tasks{ $task }.() {
        .map: {
            #note "file saved";
            .tap#: :done{ say "file copied" }
        }
    }
}
