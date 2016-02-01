defmodule DefMemo.Test do
  use ExUnit.Case

  import IO, only: [puts: 1]

  @tag timeout: 100_000
  test "The Proof Is In The Pudding" do
    puts "\nUNMEMOIZED VS MEMOIZED "
    puts "***********************"
    puts "fib (unmemoized)"
    puts "function -> {result, running time(μs)}"
    puts "=================================="
    puts "fibs(30) -> #{inspect TimedFunction.time fn -> Fib.fibs(30) end}"
    puts "fibs(30) -> #{inspect TimedFunction.time fn -> Fib.fibs(30) end}"

    puts "\nFibMemo (memoized)"
    puts "=================================="
    puts "fibs(30) -> #{inspect TimedFunction.time fn -> FibMemo.fibs(30) end}"
    puts "fibs(30) -> #{inspect TimedFunction.time fn -> FibMemo.fibs(30) end}"
    puts "fibs(50) -> #{inspect TimedFunction.time fn -> FibMemo.fibs(50) end}"
    puts "fibs(50) -> #{inspect TimedFunction.time fn -> FibMemo.fibs(50) end}"
  end

  test "identical function signatures in different modules return correct results" do
    FibMemo.fibs(20)
    FibMemoOther.fibs(20)

    assert FibMemo.fibs(20) == 6765
    assert FibMemoOther.fibs(20) == "THE NUMBER 20 IS BORING"
  end

  test "identical function names with different arities return correct results" do
    FibMemo.fibs(20)
    FibMemoOther.fibs(20)
    FibMemoOther.fibs(20, 21)

    assert FibMemo.fibs(20) == 6765
    assert FibMemoOther.fibs(20) == "THE NUMBER 20 IS BORING"
    assert FibMemoOther.fibs(20, 21) == "21 AND 20 /2"
  end

  test "identical function names with guard conditions return correct results" do
    TestMemoWhen.fibs(20)
    TestMemoWhen.fibs("20")
    TestMemoWhen.fibs([1, 2, 3])

    assert TestMemoWhen.fibs(20) == {:no_guard, 20}
    assert TestMemoWhen.fibs("20") == {:binary, "20"}
    assert TestMemoWhen.fibs([1, 2, 3]) == {:list, [1, 2, 3]}
  end

  test "normalized function arguments return correct results" do

    assert TestMemoNormalized.slow_upper("A") == TestMemoNormalized.slow_upper("a"), "single argument match"
    assert TestMemoNormalized.slow_upper("A") != TestMemoNormalized.slow_upper("B"), "single argument mis-match"

    assert TestMemoNormalized.slow_sum([1,2], false) == TestMemoNormalized.slow_sum([2,1], false), "multi-argument match"
    assert TestMemoNormalized.slow_sum([1,2], true) != TestMemoNormalized.slow_sum([2,1], false), "multi-argument mis-match"

  end

  test "normalized arguments performance improves" do

    {"AB", first_upper }  = TimedFunction.time fn -> TestMemoNormalized.slow_upper("Ab") end
    {"AB", second_upper } = TimedFunction.time fn -> TestMemoNormalized.slow_upper("AB") end

    assert first_upper >= second_upper, "Second run on similar slow_upper arguments is faster"

    {9, first_sum }  = TimedFunction.time fn -> TestMemoNormalized.slow_sum([2,3,4], false) end
    {9, second_sum } = TimedFunction.time fn -> TestMemoNormalized.slow_sum([4,2,3], false) end

    assert first_sum >= second_sum, "Second run on similar slow_sum arguments is faster"

  end

end
