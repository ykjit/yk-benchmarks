-- Benchmark a heightmap generator.

local hm = {} do
setmetatable(hm, {__index = require'benchmark'})

heightmap = require("heightmap/heightmap")

-- define a custom height function
-- (reusing the default but scaling it)
f = function(map, x, y, d, h)
    return 2 * heightmap.defaultf(map, x, y, d, h)
end

function hm:inner_benchmark_loop (mapsize)
    -- Create a large heightmap
    map = heightmap.create(mapsize, mapsize, f)
    return true
end

end -- object hm

return hm
