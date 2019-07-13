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
        my Supply $stream = $file.content;
        LEAVE $stream.tap;
        |do for @paths -> $CWD {
            my $path    = $file.path.clone(:$CWD).IO;
            my $dir     = $path.absolute.IO.relative($*CWD).IO.dirname;
            mkdir-p $dir.IO unless $dir.IO.d;
            my $fd      = $path.open: :w;
            $stream    .= do: { $fd.print: $_ }
            $file.clone: :$path, :content($path.open.Supply)
        }
    }
}

sub rename(&trans) is export {
    -> File $file {
        $file.clone: :path($file.path.clone: :path("{ $file.path.dirname }/{ trans $file.path.basename }"))
    }
}

enum EventType<start-task finish-task error>;

class Event {
    has EventType $.type;
    has Instant   $.when = now;
    has Str       $.task is required;
    has           $.data
}

class PulpRun {
    has Callable %!tasks;
    has Supplier $!supplier .= new;
    has Supply   $.events    = $!supplier.Supply;

    method add-task(Str $name, &task) {
        die "Task $name alredy exists" if %!tasks{ $name };
        %!tasks{ $name } = &task
    }

    method tasks { %!tasks.keys }

    method task-exists($name) { %!tasks{ $name }:exists }

    method emit(Str $task where self.task-exists($task), EventType $type, $data?) {
        $!supplier.emit: Event.new: :$type, :$task, :$data
    }

    method run-task(Str $name) {
        CATCH { self.emit: $name, error, $_ }

        self.emit: $name, start-task;
        my $res = %!tasks{ $name }.();

        my Promise $p .= new;
        my $v = $p.vow;
        with $res {
            .map: {
                #say "saving file '{ .path.relative($*CWD) }'";
                .content.tap:
                    done => { $v.keep: $_ },
                    quit => -> $err { $v.break: $err },
            }
        }
        self.emit: $name, finish-task;
        await $p
    }
}

my PulpRun $run .= new;

multi trait_mod:<is>(Sub $r, Str :$task!) is export {
    $run.add-task: $task, $r
}

multi trait_mod:<is>(Sub $r, Bool :$task! where * === True) is export {
    trait_mod:<is>($r, :task($r.name))
}

multi trait_mod:<is>(Sub $r, Str :$parallel-task!) is export {
    my @tasks = $r.();
    $run.add-task: $parallel-task, -> {
        await do for @tasks -> $task {
            start {
                $run.run-task: $task
            }
        }
    }
}

multi trait_mod:<is>(Sub $r, Bool :$parallel-task! where * === True) is export {
    trait_mod:<is>($r, :parallel-task($r.name))
}

multi trait_mod:<is>(Sub $r, Str :$serial-task!) is export {
    my @tasks = $r.();
    $run.add-task: $serial-task, -> {
        do for @tasks -> $task {
            $run.run-task: $task
        }
    }
}

multi trait_mod:<is>(Sub $r, Bool :$serial-task! where * === True) is export {
    trait_mod:<is>($r, :serial-task($r.name))
}

multi MAIN(Bool :tasks(:$T)!) is export {
    say "Tasks:";
    for $run.tasks -> $task {
        say " - $task"
    }
}

multi MAIN(Str $task where $run.task-exists($task)) is export {
    $run.events.tap: {
        note "{ .when.DateTime }: { .task } - { .type }"
    }
    $run.run-task( $task )
}
