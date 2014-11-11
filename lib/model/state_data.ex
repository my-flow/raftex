defmodule Persistent do
    defstruct [allServers: [], currentTerm: 0, votedFor: nil, log: []]
end


defmodule Volatile do
    defstruct [commitIndex: 0, lastApplied: 0]
end


defmodule StateData do
  defstruct [persistent: %Persistent{}, volatile: %Volatile{}]
end
