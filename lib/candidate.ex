import Logger

defmodule Candidate do

    def start_election(
        %StateData{:persistent =>
            %Persistent{
                :allServers => allServers,
                :currentTerm => currentTerm,
                :log => log
            }
        }) do

        votes = Enum.map(allServers, &Server.request_vote(&1, currentTerm, Enum.count(log), List.last(log)[:term]))

        Logger.debug("Results of voting: #{inspect votes}")
        total = 1 + Enum.count(Enum.filter(votes, fn {_, voteGranted} -> voteGranted end))
        
        majority = div(1 + Enum.count(allServers), 2) + 1
        Logger.warn("Received #{inspect total} votes out of #{inspect majority} required (majority)")

        if (total >= majority) do
            :leader
        else
            :candidate
        end
    end
end
