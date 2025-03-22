defmodule Dopamin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DopaminWeb.Telemetry,
      Dopamin.Repo,
      {DNSCluster, query: Application.get_env(:dopamin, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dopamin.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Dopamin.Finch},
      # Start a worker by calling: Dopamin.Worker.start_link(arg)
      # {Dopamin.Worker, arg},
      # Start to serve requests, typically the last entry
      DopaminWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dopamin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DopaminWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
