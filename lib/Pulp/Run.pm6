use Pulp::EventType;
use Pulp::Event;

class Pulp::Run {
    has Callable %!tasks;
    has          %!list;
    has Supplier $!supplier .= new;
    has Supply   $.events    = $!supplier.Supply;

    method add-task(Str $name, &task, :@sub-tasks, :$type) {
        die "Task $name alredy exists" if %!tasks{ $name };
        my %sub-desc = %!list{ @sub-tasks }:p;
        %!list{$name} = { :$type, :%sub-desc };
        %!tasks{ $name } = &task
    }

    method tasks { %!tasks.keys }

    method task-descriptions(%list = %!list) {
        do for %list.kv -> $task, % ( :$type, :%sub-desc ) {
            (
                "- $task" ~ (" <{$type}>" with $type),
                (self.task-descriptions(%sub-desc).indent: 3 with $type)
            ).join: "\n"
        }.join: "\n"
    }

    method task-exists($name) { %!tasks{ $name }:exists }

    method emit(Str $task where self.task-exists($task), Pulp::EventType $type, $data?) {
        $!supplier.emit: Pulp::Event.new: :$type, :$task, :$data
    }

    method run-task(Str $name) {
        CATCH { self.emit: $name, error, $_ }

        self.emit: $name, start-task;
        my $res = %!tasks{ $name }.();

        my Promise $p .= new;
        my $v = $p.vow;
        with $res {
            .map: {
                if .^can: "content" {
                    .content.tap:
                        done => { $v.keep: $_ },
                        quit => -> $err { $v.break: $err },
                } else {
                    $v.keep: $_
                }
            }
        }
        self.emit: $name, finish-task;
        await $p
    }
}

