defmodule RaftEx do
  use Application

  # Run

  def run do
    Distributor.start_link
    Distributor.run
  end

end
