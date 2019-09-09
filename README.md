[![Build Status](https://travis-ci.org/FCO/pulp.svg?branch=master)](https://travis-ci.org/FCO/pulp)

### sub src

```perl6
sub src(
    *@paths
) returns Mu
```

Create a new Seq of virtual files from the paths

### sub dest

```perl6
sub dest(
    *@paths
) returns Mu
```

Set where to save the transformed files

### sub watch-path

```perl6
sub watch-path(
    *@paths,
    Str :$task!
) returns Mu
```

Set what to run when what path changes

### multi sub trait_mod:<is>

```perl6
multi sub trait_mod:<is>(
    Sub $r,
    Str :$task!
) returns Mu
```

Create a task with another name

### multi sub trait_mod:<is>

```perl6
multi sub trait_mod:<is>(
    Sub $r,
    Bool :$task! where { ... }
) returns Mu
```

Create a task

### multi sub trait_mod:<is>

```perl6
multi sub trait_mod:<is>(
    Sub $r,
    Str :$parallel-task!
) returns Mu
```

Create a parallel task with another name

### multi sub trait_mod:<is>

```perl6
multi sub trait_mod:<is>(
    Sub $r,
    Bool :$parallel-task! where { ... }
) returns Mu
```

Create a parallel task

### multi sub trait_mod:<is>

```perl6
multi sub trait_mod:<is>(
    Sub $r,
    Str :$serial-task!
) returns Mu
```

Create a serial task with another name

### multi sub trait_mod:<is>

```perl6
multi sub trait_mod:<is>(
    Sub $r,
    Bool :$serial-task! where { ... }
) returns Mu
```

Create a serial task

### multi sub MAIN

```perl6
multi sub MAIN(
    Bool :tasks(:$T)!
) returns Mu
```

List all tasks

### multi sub MAIN

```perl6
multi sub MAIN(
    Str $task where { ... } = "default"
) returns Mu
```

Run a task

