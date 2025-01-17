defmodule ExNVR.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Membrane.Logger

  @cert_file_path "priv/integrated_turn_cert.pem"

  @impl true
  def start(_type, _args) do
    config_common_dtls_key_cert()
    create_integrated_turn_cert_file()

    children = [
      ExNVR.Repo,
      ExNVR.TokenPruner,
      {Phoenix.PubSub, name: ExNVR.PubSub},
      {Finch, name: ExNVR.Finch},
      {DynamicSupervisor, [name: ExNVR.PipelineSupervisor, strategy: :one_for_one]},
      Task.child_spec(fn -> ExNVR.start() end)
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ExNVR.Supervisor)
  end

  @impl true
  def stop(_state) do
    delete_cert_file()
    :ok
  end

  defp create_integrated_turn_cert_file() do
    cert_path = Application.fetch_env!(:ex_nvr, :integrated_turn_cert)
    pkey_path = Application.fetch_env!(:ex_nvr, :integrated_turn_pkey)

    if cert_path != nil and pkey_path != nil do
      cert = File.read!(cert_path)
      pkey = File.read!(pkey_path)

      File.touch!(@cert_file_path)
      File.chmod!(@cert_file_path, 0o600)
      File.write!(@cert_file_path, "#{cert}\n#{pkey}")

      Application.put_env(:ex_nvr, :integrated_turn_cert_pkey, @cert_file_path)
    else
      Membrane.Logger.warning("""
      Integrated TURN certificate or private key path not specified.
      Integrated TURN will not handle TLS connections.
      """)
    end
  end

  defp delete_cert_file(), do: File.rm(@cert_file_path)

  defp config_common_dtls_key_cert() do
    {:ok, pid} = ExDTLS.start_link(client_mode: false, dtls_srtp: true)
    {:ok, pkey} = ExDTLS.get_pkey(pid)
    {:ok, cert} = ExDTLS.get_cert(pid)
    :ok = ExDTLS.stop(pid)
    Application.put_env(:ex_nvr, :dtls_pkey, pkey)
    Application.put_env(:ex_nvr, :dtls_cert, cert)
  end
end
