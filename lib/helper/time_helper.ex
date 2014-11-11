defmodule TimeHelper do

    @election_timeout_min  5_000 # milliseconds
    @election_timeout_max 10_000 # milliseconds

    @heartbeat_frequency   2_000 # milliseconds


    def generate_random_election_timeout do
        @election_timeout_min + :random.uniform(@election_timeout_max - @election_timeout_min)
    end


    def get_heartbeat_frequency do
        @heartbeat_frequency
    end
end
