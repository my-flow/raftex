defmodule DebugHelper do

    @colors [
        IO.ANSI.blue,
        IO.ANSI.cyan,
        IO.ANSI.green,
        IO.ANSI.magenta,
        IO.ANSI.white,
        IO.ANSI.yellow
    ]

    @max_string_length 9 # the longest state name is c-a-n-d-i-d-a-t-e


    def t(stateData, stateName \\ "", message) when is_binary(message) do
        state = String.ljust(String.upcase(to_string stateName), @max_string_length)
        {_, name} = stateData.name
        IO.puts(
            get_color(to_string name) <>
            "(#{to_string name}) #{state} t#{stateData.currentTerm}: #{message}" <>
            IO.ANSI.default_background <> IO.ANSI.default_color
        )
    end


    defp get_color(string) when is_binary(string) do
        if IO.ANSI.enabled? do
            count = Enum.count(@colors)
            keys = Enum.reduce(
                String.codepoints(string),
                0, # acc
                fn << c :: utf8 >>, acc ->
                    rem(c + acc, count)
                end
            )
            Enum.fetch!(@colors, keys)
        else
            ""
        end
    end
end