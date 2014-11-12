defmodule RuleHelper do

    def check_for_outdated_term(term, stateData = %StateData{}, f) when is_function(f) do

        if (term > stateData.currentTerm) do

            case f.(stateData) do

                {:next_state, _newState, newStateData, timeout} ->
                    newStateData = %StateData{newStateData | :currentTerm => term, :votedFor => nil}
                    {:next_state, :follower, newStateData, timeout}

                {:next_state, _newState, newStateData}    ->
                    newStateData = %StateData{newStateData | :currentTerm => term, :votedFor => nil}
                    {:next_state, :follower, newStateData}
            end

        else
            f.(stateData)
        end
    end

end
