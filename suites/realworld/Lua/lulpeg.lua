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
    
    -- luagrammar.lua was designed to run standalone with command-line arguments:
    --   arg[1] = lpeg module to require
    --   arg[2] = source file to parse
    --
    -- When called via dofile() from the harness, arg contains the harness arguments:
    --   arg[0] = ../../awfy/Lua/harness.lua
    --   arg[1] = lulpeg        <-- WRONG: loads benchmark object, not LuLPeg library
    --   arg[2] = 1             <-- WRONG: inner iterations, not file path
    --
    -- When run correctly (standalone or with fixed arg):
    --   arg[0] = LuLPeg/tests/luagrammar.lua
    --   arg[1] = LuLPeg/lulpeg      <-- CORRECT: loads LuLPeg library
    --   arg[2] = LuLPeg/lulpeg.lua  <-- CORRECT: file to parse
    --
    -- Fix: temporarily set arg to the values luagrammar.lua expects.
    local saved_arg = arg
    arg = { [0] = "LuLPeg/tests/luagrammar.lua", "LuLPeg/lulpeg", "LuLPeg/lulpeg.lua" }
    
    dofile("LuLPeg/tests/luagrammar.lua")
    
    arg = saved_arg
    
    assert(END == 89661)
    return true
end

end -- object pg

return pg
