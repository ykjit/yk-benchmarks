# Setup the submodules.

cd hashids
cp src/init.lua hashids.lua
cd ..

cd heightmap
git apply ../heightmap.patch
cd ..

cd LuLPeg
git apply ../luagrammar.patch
cd ..
