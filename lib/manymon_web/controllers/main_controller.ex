defmodule ManymonWeb.MainController do
  use ManymonWeb, :controller

  require Logger
  alias Manymon.Tests

  def index(conn, _params) do
    text(conn, "MANYMON Prometheus Exporter\nRequests expected at /metrics\n")
  end

  def metrics(conn, _params) do
    host_metrics = get_host_metrics()
    docker_metrics = get_docker_metrics()
    test_metrics = get_test_metrics()
    text(conn, host_metrics <> "\n\n" <> docker_metrics <> "\n\n" <> test_metrics <> "\n")
  end

  defp get_host_metrics() do
    proc_folder = System.get_env("PROC_LOCATION", "/proc/")

    {:ok, loadavg} = File.read(proc_folder <> "loadavg")
    [ld_1, ld_5, ld_15 | _] = String.split(loadavg)
    load = String.trim(~s(
# HELP node_load1 Host's load average over the last minute
# TYPE node_load1 gauge
node_load1 #{ld_1}

# HELP node_load1 Host's load average over the last 5 minutes
# TYPE node_load5 gauge
node_load5 #{ld_5}

# HELP node_load1 Host's load average over the last 15 minutes
# TYPE node_load1 gauge
node_load15 #{ld_15}
    ))

    {:ok, meminfo} = File.read(proc_folder <> "meminfo")
    meminfo = String.split(meminfo, "\n")
    [_, memtotal, _] = Enum.at(meminfo, 0) |> String.split
    [_, memavail, _] = Enum.at(meminfo, 2) |> String.split
    mem = String.trim(~s(
# HELP node_mem_total Total RAM usable in the system, in kilobytes
# TYPE node_mem_total gauge
node_mem_total #{memtotal}

# HELP node_mem_available How much RAM is available for starting new applications without swapping, in kilobytes
# TYPE node_mem_available gauge
node_mem_available #{memavail}
    ))
    load <> "\n\n" <> mem
  end

  defp get_docker_metrics() do
    {json, 0} = System.cmd("docker", ["stats", "--format", "json", "--no-stream"])
    containers = json |> String.trim |> String.split("\n") |> Enum.map(&Jason.decode!/1)
    cpu_usage =
      "# HELP container_cpu_usage The amount of the CPU this container is using.\n" <>
      "# TYPE container_cpu_usage gauge\n" <> (
        containers
        |> Enum.map(fn %{"Name" => name, "CPUPerc" => perc, "ID" => id} ->
          {usage, _} = Float.parse(perc)
          ~s(container_cpu_usage{name="#{name}",id="#{id}"} #{usage / 100})
        end) |> Enum.join("\n")
      )
    memory_usage =
      "# HELP container_memory_usage The amount of its memory allocation that this container is using.\n" <>
      "# TYPE container_memory_usage gauge\n" <> (
        containers
        |> Enum.map(fn %{"Name" => name, "MemPerc" => perc, "ID" => id} ->
          {usage, _} = Float.parse(perc)
          ~s(container_memory_usage{name="#{name}",id="#{id}"} #{usage / 100})
        end) |> Enum.join("\n")
      )
    pids =
      "# HELP container_pids The number of processes running in this container.\n" <>
      "# TYPE container_pids gauge\n" <> (
        containers
        |> Enum.map(fn %{"Name" => name, "PIDs" => pids, "ID" => id} ->
          ~s(container_memory_usage{name="#{name}",id="#{id}"} #{pids})
        end) |> Enum.join("\n")
      )
    Enum.join([cpu_usage, memory_usage, pids], "\n\n")
  end

  defp get_test_metrics() do
    tests = Tests.list_tests()
    if length(tests) == 0 do
      ""
    else
      results = Task.async_stream(tests, fn test ->
        method = String.downcase(test.method) |> String.to_atom()
        timeout = round(test.timeout * 1000)
        Logger.info("#{test.name}: Requesting #{test.url}...")
        r_start = System.monotonic_time(:millisecond)
        resp = HTTPoison.request(method, test.url, test.body, test.headers, timeout: timeout, recv_timeout: timeout)
        r_end = System.monotonic_time(:millisecond)
        elapsed = r_end - r_start
        success = case resp do
          {:ok, %{status_code: code}} ->
            Logger.info("#{test.name}: Got response code #{code}")
            code < 400
          {:error, err} ->
            Logger.warning("#{test.name}: " <> inspect(err))
            false
        end
        {test.name, success, elapsed}
      end, max_concurrency: 32, timeout: 12000)
      outputs = Enum.map(results, fn {:ok, {name, success, elapsed}} ->
        suc = ~s(http_test_success{name="#{name}"} #{if success, do: 1, else: 0})
        elp = ~s(http_test_elapsed{name="#{name}"} #{elapsed})
        [suc, elp]
      end) |> List.flatten() |> Enum.sort()
      [elp, suc] = Enum.chunk_every(outputs, Integer.floor_div(length(outputs), 2))
        |> Enum.map(&(Enum.join(&1, "\n")))
      elp =
        "# HELP http_test_elapsed The number of milliseconds it took to get an HTTP response for this test endpoint, or for it to timeout.\n" <>
        "# TYPE http_test_elapsed gauge\n" <> elp
      suc =
        "# HELP http_test_success Whether or not this HTTP test succeeded (got a 200 or 300 response code), either 1 or 0.\n" <>
        "# TYPE http_test_success gauge\n" <> suc
      elp <> "\n\n" <> suc
    end
  end
end
