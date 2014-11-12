defmodule DebugHelper do

    import Logger

    @max_string_length 9 # the longest state name is c-a-n-d-i-d-a-t-e


    def e(stateData, stateName \\ "", message) when is_binary(message) do
        error t(stateData, stateName, message)
    end


    def w(stateData, stateName \\ "", message) when is_binary(message) do
        warn t(stateData, stateName, message)
    end


    def i(stateData, stateName \\ "", message) when is_binary(message) do
        info t(stateData, stateName, message)
    end


    def d(stateData, stateName \\ "", message) when is_binary(message) do
        debug t(stateData, stateName, message)
    end


    defp t(stateData, stateName, message) when is_binary(message) do
        state = String.ljust(String.upcase(to_string stateName), @max_string_length)
        "#{inspect self} #{state} (#{stateData.currentTerm}): #{message}"
    end
end