defmodule GsServer.ActionSpec do
  defmacro __using__(_) do
    quote do
      import GsServer.ActionSpec

      @actions %{}

      @before_compile GsServer.ActionSpec
    end
  end

  defmacro action(name, args, do: block) do
    action_name = String.to_atom("action_" <> name) # need a better name

    arg_names = args |> Enum.map(fn({name, _, _}) -> name end)

    quote do
      @actions Map.put(
        @actions,
        unquote(name),
        {unquote(action_name), unquote(arg_names)}
      )

      def unquote(action_name)(unquote(args)), do: unquote(block)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def get_actions do
        @actions
      end

      def run_action(action, args \\ %{}) when is_map(args) do
        {action_name, arg_names} = Map.get(@actions, action)

        arg_list = arg_names
          |> Enum.map(fn(name) -> Map.get(args, Atom.to_string(name)) end)

        apply(__MODULE__, action_name, [arg_list])
      end
    end
  end
end
