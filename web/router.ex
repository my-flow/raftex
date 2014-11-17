defmodule Raftex.Router do
  use Phoenix.Router

  scope "/" do
    # Use the default browser stack.
    pipe_through :browser

    get  "/",                     Raftex.PageController,  :index,             as: :pages
    post "/nodes/start",          Raftex.PageController,  :start,             as: :pages
    post "/nodes/resume",         Raftex.PageController,  :resume,            as: :pages

    get  "/nodes/info",           Raftex.PageController,  :info,              as: :pages

    delete "/leaders/kill/all",   Raftex.PageController,  :kill_leaders,      as: :pages
    delete "/followers/kill/any", Raftex.PageController,  :kill_any_follower, as: :pages
  end

end
