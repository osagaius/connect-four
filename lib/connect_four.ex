defmodule ConnectFour do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(ConnectFour.Endpoint, []),
      # Start your own worker by calling: ConnectFour.Worker.start_link(arg1, arg2, arg3)
      # worker(ConnectFour.Worker, [arg1, arg2, arg3]),
    ]

    workers = case mix_env() do
      :test ->
        [

        ]
      _ ->
        [
                    
        ]
    end

    children = children ++ workers

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ConnectFour.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ConnectFour.Endpoint.config_change(changed, removed)
    :ok
  end

  def mix_env(), do: Application.get_env(:connect_four, :mix_env, :prod)
end
