defmodule StateMachine do
  use ExActor.Strict

  import Logger


  # Initialization

  defstart start_link do
    initial_state nil
  end


  # Apply log entry to local state machine

  defcall apply(command), when: is_function(command), state: state do
    new_state = case state do
      nil -> command.() # initial state has no arguments
      _   -> command.(state)
    end
    set_and_reply new_state, new_state
  end


  # Get latest state
  defcall get_state, state: state do
    reply state
  end

end
