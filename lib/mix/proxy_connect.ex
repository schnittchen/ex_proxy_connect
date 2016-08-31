defmodule Mix.Tasks.ProxyConnect do
  use Mix.Task

  def run([remote, app_cookie]) do
    node_info = node_info(remote)
    start_tunnel(remote, node_info)
    start_node(String.to_atom(app_cookie))
    connect(node_info)
  end

  defp node_info(remote) do
    {epmd_out, 0} = System.cmd("ssh", [remote, "epmd -names"])

    [[_, epmd_port]] = Regex.scan(~r/epmd: up and running on port ([0-9]+) with data/, epmd_out)
    nodes =
      Regex.scan(~r/name (\w*) at port ([0-9]+)/, epmd_out)
      |> Enum.map(fn [_, name, port] -> %{name: name, port: port} end)

    %{epmd_port: epmd_port, nodes: nodes}
  end

  defp start_tunnel(remote, node_info) do
    node_forwards =
      node_info.nodes
      |> Enum.map(&(bigl_forward(&1.port)))

    ssh_args = [remote, "-o", "ExitOnForwardFailure yes"]
      ++ bigl_forward(node_info.epmd_port)
      ++ List.flatten(node_forwards)
      ++ ["echo FINE && cat"]

    ssh = :os.find_executable('ssh') || :erlang.error(:enoent, 'ssh')

    {:ok, agent} = Agent.start_link fn ->
      port = Port.open {:spawn_executable, ssh}, [:exit_status, :binary, {:args, ssh_args}]
      receive do
        {^port, {:data, "FINE" <> _}} ->
          # the subprocess sends FINE _after_ setting up the forwarding.
          # We wait for that here, then continue
          nil
        {^port, {:exit_status, status}} ->
          raise "ssh child process died with exit status #{status}"
      end
      port
    end
    Agent.cast agent, fn port ->
      receive do
        {^port, {:exit_status, status}} ->
          raise "ssh child process died with exit status #{status}"
      end
    end
  end

  defp bigl_forward(port) do
    # specify the local bind address so binding to ::1 does not count as success
    ["-L", "127.0.0.1:#{port}:127.0.0.1:#{port}"]
  end

  def start_node(cookie) do
    {:ok, _} = :net_kernel.start [:'remote_shell_connector@127.0.0.1', :longnames]
    true = Node.set_cookie(cookie)
  end

  def connect(node_info) do
    nodes =
      node_info.nodes
      |> Enum.map(fn n -> :"#{n.name}@127.0.0.1" end)

    nodes
    |> Enum.each(fn node ->
      success = Node.connect(node)
      IO.puts "Connected to #{node}: #{success}"
    end)
  end
end
