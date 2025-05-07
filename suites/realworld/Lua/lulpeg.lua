-- Benchmark a peg parser parsing a luafile.

local pg = {} do
setmetatable(pg, {__index = require'benchmark'})

lpeg = require "LuLPeg/lulpeg"
lpeg.setmaxstack(10000)
-- The file we want to parse.
src = io.open("LuLPeg/lulpeg.lua","r"):read"*all"

function pg:inner_benchmark_loop (inner_loops)
    dofile("LuLPeg/tests/luagrammar.lua") -- run the lua parser
    return true
end

end -- object pg

return pg
