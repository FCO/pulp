use Pulp::Glob;
use Pulp::Run;
use Pulp::File;

#| Create a new Seq of virtual files from the paths
sub src(*@paths) is export {
    gather for @paths -> $p {
        for glob($p) {
            next if .d;
            my $CWD = $p.IO.dirname;
            my $path = .relative($CWD).IO.clone(:$CWD);
            take Pulp::File.new:
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

#| Set where to save the transformed files
sub dest(*@paths) is export {
    -> Pulp::File $file {
        my Supply $stream = $file.content;
        my @ret = do for @paths -> $CWD {
            my $path    = $file.path.clone(:$CWD).IO;
            my $dir     = $path.absolute.IO.relative($*CWD).IO.dirname;
            mkdir-p $dir.IO unless $dir.IO.d;
            my $fd      = $path.open: :w;
            $stream    .= do: { $fd.print: $_ }
            $file.clone: :$path, :content($path.open.Supply)
        }
        #$stream.tap;
        await $stream;
        |@ret
    }
}

my Pulp::Run $run .= new;

#| Set what to run when what path changes
sub watch-path(*@paths, Str :$task!) is export {
    my $watches = Supply.merge(
        |do for @paths -> $path {
            |do for glob($path) {
                .watch
            }
        }
    );

    @*watch.push: { :$watches, :$task }
}

#| Create a task with another name
multi trait_mod:<is>(Sub $r, Str :$task!) is export {
    $run.add-task: $task, $r
}

#| Create a task
multi trait_mod:<is>(Sub $r, Bool :$task! where * === True) is export {
    trait_mod:<is>($r, :task($r.name))
}

#| Create a parallel task with another name
multi trait_mod:<is>(Sub $r, Str :$parallel-task!) is export {
    my @sub-tasks = $r.();
    $run.add-task: $parallel-task, :type<parallel>, :@sub-tasks, -> {
        await do for @sub-tasks -> $task {
            start {
                $run.run-task: $task
            }
        }
    }
}

#| Create a parallel task
multi trait_mod:<is>(Sub $r, Bool :$parallel-task! where * === True) is export {
    trait_mod:<is>($r, :parallel-task($r.name))
}

#| Create a serial task with another name
multi trait_mod:<is>(Sub $r, Str :$serial-task!) is export {
    my @sub-tasks = $r.();
    $run.add-task: $serial-task, :type<serial>, :@sub-tasks, -> {
        do for @sub-tasks -> $task {
            $run.run-task: $task
        }
    }
}

#| Create a serial task
multi trait_mod:<is>(Sub $r, Bool :$serial-task! where * === True) is export {
    trait_mod:<is>($r, :serial-task($r.name))
}

#| List all tasks
multi MAIN(Bool :tasks(:$T)!) is export {
    say "";
    say "Tasks:";
    say $run.task-descriptions.indent: 3;
    say ""
}

#| Run a task
multi MAIN(Str $task where $run.task-exists($task) = "default") is export {
    $run.events.tap: {
        note "{ .when.DateTime }: { .task } - { .type }"
    }
    $run.run-task( $task )
}
