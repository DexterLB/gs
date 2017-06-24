defmodule GsServer.ActionSpec do
  defmacro __using__(_) do
    quote do
      import GsServer.ActionSpec

      @actions %{}

      @before_compile GsServer.ActionSpec
    end
  end

  defmacro action(name, do: block) do
    action_name = String.to_atom("action_" <> name)

    quote do
      @actions Map.put(
        @actions,
        unquote(name),
        unquote(action_name)
      )

      def unquote(action_name)(), do: unquote(block)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def get_actions do
        @actions
      end

      def run_action(action, args \\ []) do
        apply(__MODULE__, Map.get(@actions, action), args)
      end
    end
  end
end
