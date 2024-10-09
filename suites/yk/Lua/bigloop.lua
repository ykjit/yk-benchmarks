local bigloop = {} do
setmetatable(bigloop, {__index = require'benchmark'})

function bigloop:inner_benchmark_loop (inner_iterations)
    local sum = 0
    print(inner_iterations)
    for _ = 0, inner_iterations do
        sum = sum + 1
    end
    return sum == inner_iterations + 1
end

end -- object bigloop

return bigloop
