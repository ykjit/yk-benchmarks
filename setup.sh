# Setup submodules in the realworld suite.
cd suites/realworld/Lua

cd hashids
cp src/init.lua hashids.lua
cd ..

cd heightmap
git apply ../heightmap.patch
cd ..

cd LuLPeg
git apply ../luagrammar.patch
cd ..

cd ../../../

# Setup cbgame suite.
LUA=$1
# Generate fasta output used by the knucleotide benchmark.
LUA_PATH="?.lua;suites/awfy/Lua/?.lua;suites/cbgame/Lua/?.lua" $LUA -l fasta -e "fasta:inner_benchmark_loop(500000)" > suites/cbgame/Lua/fasta500000.txt
# Generate fasta output used by the revcomp benchmark.
LUA_PATH="?.lua;suites/awfy/Lua/?.lua;suites/cbgame/Lua/?.lua" $LUA -l fasta -e "fasta:inner_benchmark_loop(1000000)" > suites/cbgame/Lua/fasta1000000.txt
