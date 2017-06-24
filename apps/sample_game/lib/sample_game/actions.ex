defmodule SampleGame.Actions do
  use GsServer.ActionSpec

  action "register", [foo, bar] do
    IO.inspect {"foooooo", foo, bar}
  end

  action "print", [text] do
    IO.puts ["it was requested that I print ", text]
  end
end
