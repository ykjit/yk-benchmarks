from benchmark import Benchmark

class BigLoop(Benchmark):
    def inner_benchmark_loop(self, inner_iterations):
        sum = 0
        for _ in range(inner_iterations):
            sum += 1
        return sum == inner_iterations
