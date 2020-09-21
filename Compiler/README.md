# MP-SPDZ Compiler
Experimental MP-SPDZ compiler that can be installed separately from the
MP-SPDZ codebase.

Currently, it has to be installed from GitHub:

```shell
$ pip install -e 'git+https://github.com/sbellem/MP-SPDZ.git@compiler-isolation#egg=mpspdz&subdirectory=Compiler'
```

To compile programs, just do the same as with `compile.py`, except that the
command is `mpspdz-compile` and can be invoked without specifying the path to
it, e.g.:

```shell
$ mpspdz-compile -R 64 --verbose tutorial
```
