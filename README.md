
This is a modified Clang Static Analyzer which supports C++ exception, based on Clang 13.

# How to build

Before building, you need to install z3. (e.g. `apt install libz3-dev`)

`git clone https://github.com/ewfsdvvr/csa-eh.git`

`cd csa-eh`

`mkdir build`

`cd build`

`cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_FORCE_ENABLE_STATS=ON -DLLVM_ENABLE_PROJECTS=clang -DLLVM_ENABLE_Z3_SOLVER=ON ../llvm`

`make`

For more details see [https://clang.llvm.org](https://clang.llvm.org).

After building, the clang executable is located in `csa-eh/build/bin/clang`.

# How to use

A python script `csa-eh/driver/driver` is used to run the analyzer.

We will use an example `csa-eh/example/example.cpp` to show the usage.

## Generate the compilation database

First you need to generate a [compilation_database](https://clang.llvm.org/docs/JSONCompilationDatabase.html). To do that, you can use [Bear](https://github.com/rizsotto/Bear).

For simplicity, we have generated the compilation database for you (i.e. `csa-eh/example/compile_commands.json`). But you have to **modify the `directory` entry to the absolute path of the `example` directory**.

## Run the analyzer

`cd example`

`../driver/driver -c ../build/bin/clang --conf config.json compile_commands.json`

The `-c` option tells the driver to use the clang we just built.

The `--confg` is used to config the analyzer. The config file (i.e. `config.json`) is directly copied from `csa-eh/driver/config.json`, except that we enabled a checker called "debug.ExprInspection". This checker is used to dump variables during the analysis.

For more details see `driver --help`.

## View the report

After the analysis, there should be an `analyze` folder. In `analyze`, there should be a folder with a name of date and time. In that folder, there is a `reports` folder. Open `index.html` in `reports` to view the report. (e.g. `csa-eh/example/analyze/xxxxxxxx-xxxxxx/reports/index.html`)