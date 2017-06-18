defmodule Mix.Tasks.GsGraph.Visualise do
  use Mix.Task

  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:gs_graph)

    GSGraph.visualise_all |> writedot |> picturify |> show
  end

  def writedot(text) do
    name = "/tmp/gs.dot"
    {:ok, file} = File.open(name, [:write])
    :ok = file |> IO.binwrite(text)
    :ok = File.close(file)

    name
  end

  def picturify(dotfile) do
    result_file = dotfile <> ".svg"

    {_, 0} = System.cmd("dot", [
      "-Goverlap=prism",
      "-Tsvg",
      dotfile,
      "-o", result_file
    ])

    result_file
  end

  def show(image_file) do
    {_, 0} = System.cmd("xdg-open", [
      image_file
    ])

    :ok
  end
end
