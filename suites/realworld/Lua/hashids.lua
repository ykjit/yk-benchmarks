-- Benchmark a hashing library for URL shortening.

local hi = {} do
setmetatable(hi, {__index = require'benchmark'})

local hashids = require("hashids/hashids");
local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
local h = hashids.new(nil, 8, alphabet);

function hi:inner_benchmark_loop (inner_loops)
    local correct = true
    for i = 1, inner_loops do
        local dec = h:decode(h:encode(i, 2525));
        if i ~= dec[1] then
            correct = false
        end
    end
    return correct
end

end -- object hi

return hi
