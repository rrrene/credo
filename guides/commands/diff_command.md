# mix credo diff

`diff` suggests issues to fix in your code (based on git-diff).

## Examples

Example usage:

    $ mix credo diff v1.4.0
    $ mix credo diff main
    $ mix credo diff --from-git-ref HEAD --files-included "lib/**/*.ex"

    $ mix credo diff --help               # more options

## Command Line Switches

There are a couple of switches to control the diff parameters:

| Name, shorthand                                 | Description                                                             |
|-------------------------------------------------|-------------------------------------------------------------------------|
| [`--from-dir`](#from-dir)                       | Diff from the given directory                                           |
| [`--from-git-ref`](#from-git-ref)               | Diff from the given Git ref                                             |
| [`--from-git-merge-base`](#from-git-merge-base) | Diff from where the current HEAD branched off from the given merge base |
| [`--since`](#since)                             | Diff from the given point in time (using Git)                           |

To adjust the analysis all [command line switches of the `suggest` command](suggest_command.html#command-line-switches) are supported.


## Descriptions

### `--from-dir`

Diff from the given directory. This is a great option if you are not using `git` for version control.

```bash
$ mix credo diff --from-dir ../my-project-v1.3.1
```

### `--from-git-ref`

Diff from the given Git ref by comparing Credo's analysis for the given ref with `HEAD`.

```bash
$ mix credo diff --from-git-ref v1.3.1
```

To oversimplify, this runs Credo on the code points returned by `git diff`.

### `--from-git-merge-base`

Diff from where the current `HEAD` branched off from the given merge base.

```bash
$ mix credo diff --from-git-merge-base develop
```

This runs Credo only on the things that changed on your branch after it branched off of the given ref.
