# Yk Benchmarks

This is a repository of benchmarks for evaluating the performance of the [yk
meta-tracer](https://github.com/ykjit/yk/).

## Suites

At present the following benchmark suites are here:

| **Suite**                                                    | **Languages** |
|--------------------------------------------------------------|---------------|
| [are-we-fast-yet](https://github.com/smarr/are-we-fast-yet/) | Lua           |

## Setup

To prepare to run benchmarks, run (with a clean recursive git clone of this
repo):

```
$ sh setup.sh /path/to/lua5.4
```

## Running the benchmarks

This repo currently contains two ways to run the benchmarks:
 - haste (for development use)
 - rebench (for automated benchmarks)

### haste

Edit `haste.toml` to your needs (e.g. interpreter paths) and run `haste b`.

### rebench

To run the benchmarks run `sh benchmark.sh <res-dir>`, where `<res_dir>` is the
directory under which to put the results file.

This will build the latest versions of everything required (yk, yklua, etc.)
and run the suite under ReBench using the `rebench.conf` found in this
directory.

(Note that for now the benchmarks are run under docker)

## Licenses

See the `LICENSE-<suite>` files for information on software licenses.
