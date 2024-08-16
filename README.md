# Yk Benchmarks

This is a repository of benchmarks for evaluating the performance of the [yk
meta-tracer](https://github.com/ykjit/yk/).

## Suites

At present the following benchmark suites are here:

| **Suite**                                                    | **Languages** |
|--------------------------------------------------------------|---------------|
| [are-we-fast-yet](https://github.com/smarr/are-we-fast-yet/) | Lua           |

## Running the benchmarks

To run the benchmarks run `sh benchmark.sh <res-dir>`, where `<res_dir>` is the
directory under which to put the resulting results file.

This will build the latest versions of everything required (yk, yklua, etc.)
and run the suite under ReBench using the `rebench.conf` found in this
directory.

(Note that for now the benchmarks are run under docker)

## Licenses

See the `LICENSE-<suite>` files for information on software licenses.
