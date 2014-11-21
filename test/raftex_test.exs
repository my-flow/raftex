defmodule RaftexTest do
  use ExUnit.Case

  def command1 do
    2
  end


  def command2(s) do
    s + 3
  end


  setup do
    Raftex.run :r
    :timer.sleep(TimeHelper.get_election_timeout_max)
  end


  test "apply a function" do
    result = case Distributor.apply_command :r, &__MODULE__.command1/0 do
      {:noleader, pid} -> Distributor.apply_command :r, pid, &__MODULE__.command1/0
      other -> other
    end
    assert(result == 2)
    Process.exit(Process.whereis(:r), :shutdown)
  end


  test "apply two functions sequentially" do
    result1 = case Distributor.apply_command :r, &__MODULE__.command1/0 do
      {:noleader, pid} -> Distributor.apply_command :r, pid, &__MODULE__.command1/0
      other -> other
    end

    assert(result1 == 2)


    result2 = case Distributor.apply_command :r, &__MODULE__.command2/1 do
      {:noleader, pid} -> Distributor.apply_command :r, pid, &__MODULE__.command2/1
      other -> other
    end

    assert(result2 == 5)
    Process.exit(Process.whereis(:r), :shutdown)
  end


  test "apply two functions in parallel" do
    result1 = case Distributor.apply_command :r, &__MODULE__.command1/0 do
      {:noleader, pid} ->
        Task.start(fn -> Distributor.apply_command :r, pid, &__MODULE__.command1/0 end)
        task2 = Task.async(fn -> Distributor.apply_command :r, pid, &__MODULE__.command2/1 end)
      other ->
        other
    end

    assert(Task.await(task2) == 5)
    Process.exit(Process.whereis(:r), :shutdown)
  end


  test "apply two functions sequentially and crash leader" do
    result1 = case Distributor.apply_command :r, &__MODULE__.command1/0 do
      {:noleader, pid} -> Distributor.apply_command :r, pid, &__MODULE__.command1/0
      other -> other
    end

    assert(result1 == 2)

    Distributor.kill_leaders(:r)
    :timer.sleep(TimeHelper.get_election_timeout_max)

    result2 = case Distributor.apply_command :r, &__MODULE__.command2/1 do
      {:noleader, pid} -> Distributor.apply_command :r, pid, &__MODULE__.command2/1
      other -> other
    end

    Process.exit(Process.whereis(:r), :shutdown)
    assert(result2 == 5)
  end
end
