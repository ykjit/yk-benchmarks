# frozen_string_literal: true

# Copyright (c) 2015-2016 Stefan Marr <git@stefan-marr.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# mruby has no require_relative or Process.clock_gettime, so we stub it here.
#
# require_relative is a no-op: this file, the benchmark file, and som.rb
# (when the benchmark needs it) are already loaded up front via mruby's `-r`
# flag (see haste_harness_mruby.sh), so any require_relative calls left over
# from the CRuby originals have nothing left to do - they just need to not
# raise NoMethodError.
def require_relative(_p); true; end

# mruby has no Process class at all, so it's defined here. 
# The stub ignores the clock/unit args and always returns float seconds.
class Process; end unless defined?(Process)
def Process.clock_gettime(_c, _u = :float_second); Time.now.to_f; end

class Benchmark
  def inner_benchmark_loop(inner_iterations)
    inner_iterations.times do
      return false unless verify_result(benchmark)
    end
    true
  end

  def benchmark
    raise 'subclass_responsibility'
  end

  # noinspection RubyUnusedLocalVariable
  def verify_result(_result)
    raise 'subclass_responsibility'
  end
end
