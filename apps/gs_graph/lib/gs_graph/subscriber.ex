defmodule GsGraph.Subscriber do
  use GenServer

  def start_link(target = {pid, _}) when is_pid(pid) do
    GenServer.start_link(__MODULE__, target)
  end

  def init(target = {pid, _}) do
    Process.link(pid)
    {:ok, target}
  end


  def start_link(name, target) do
    GenServer.start_link(__MODULE__, target, name: name)
  end

  def handle_cast(:check, target) do
    IO.inspect {:stuff, target}

    {:noreply, target}
  end
end
