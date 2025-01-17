defmodule ExNVR.Onvif.Discovery do
  @moduledoc false

  import ExNVR.Onvif.Utils, only: [delete_namespaces: 1]
  import Mockery.Macro

  @multicast_addr {239, 255, 255, 250}
  @multicast_port 3702
  @probe_message """
  <?xml version="1.0" encoding="UTF-8"?>
  <e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope"
      xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing"
      xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery"
      xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
    <e:Header>
      <w:MessageID>uuid:edf6ea85-3a68-46f2-9d02-0b15ef52a787</w:MessageID>
      <w:To e:mustUnderstand="true">urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To>
      <w:Action a:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action>
    </e:Header>
    <e:Body>
      <d:Probe>
        <d:Types>dn:NetworkVideoTransmitter</d:Types>
      </d:Probe>
    </e:Body>
  </e:Envelope>
  """
  @scope_regex ~r[^onvif://www.onvif.org/(name|hardware)/(.*)]

  def probe(timeout) do
    with {:ok, socket} <- mockable(:gen_udp).open(0, [:binary, active: false]),
         :ok <- mockable(:gen_udp).send(socket, @multicast_addr, @multicast_port, @probe_message) do
      socket
      |> recv(timeout)
      |> Map.values()
      |> Enum.map(&String.replace(&1, ["\r\n", "\r", "\n"], ""))
      |> Enum.map(&%Soap.Response{body: &1, status_code: 200})
      |> Enum.map(&Soap.Response.parse/1)
      |> Enum.map(&delete_namespaces/1)
      |> Enum.map(&format_response/1)
      |> then(&{:ok, &1})
    end
  end

  defp recv(socket, timeout, acc \\ %{}) do
    case mockable(:gen_udp).recv(socket, 0, timeout) do
      {:ok, {address, port, packet}} ->
        acc = Map.update(acc, {address, port}, packet, fn data -> data <> packet end)
        recv(socket, timeout, acc)

      {:error, _error} ->
        acc
    end
  end

  defp format_response(response) do
    probe_match = get_in(response, [:ProbeMatches, :ProbeMatch])
    scopes = probe_match[:Scopes] |> String.split()

    %{
      types: probe_match[:Types] |> String.split(),
      addresses: probe_match[:XAddrs] |> String.split()
    }
    |> Map.merge(parse_scopes(scopes))
  end

  defp parse_scopes(scopes) do
    scopes
    |> Enum.flat_map(&Regex.scan(@scope_regex, &1, capture: :all_but_first))
    |> Enum.map(fn [key, value] -> {String.to_atom(key), URI.decode(value)} end)
    |> Map.new()
  end
end
