-- Benchmark a peg parser parsing a luafile.

local pg = {} do
setmetatable(pg, {__index = require'benchmark'})

lpeg = require "LuLPeg/lulpeg"
lpeg.setmaxstack(10000)
-- The file we want to parse.
init_src = io.open("LuLPeg/lulpeg.lua","r"):read"*all"

function pg:inner_benchmark_loop (inner_loops)
    -- Note: the test file mutates the input string, so to ensure each
    -- iteration does the same work, each iteration parses a copy of the
    -- original input.
    src = init_src
    dofile("LuLPeg/tests/luagrammar.lua") -- run the lua parser
    assert(END == 89661)
    return true
end

end -- object pg

return pg
