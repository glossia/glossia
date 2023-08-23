defmodule Glossia.Plan do
  @type plan_t :: :community | :cloud | :enterprise

  @doc """
  A macro to selectively compile code based on the plan of this instance of Glossia.

  ## Parameters

  - `plan` - The plan or list of plans to compile the code for.
  - `do` - The block of code to compile.
  """
  defmacro only_for(plans, do: block) when is_list(plans) do
    quote do
      if Enum.member?(unquote(plans), Application.compile_env(:glossia, :plan, :community)) do
        unquote(block)
      end
    end
  end

  @doc """
  It returns the plan of this instance of Glossia.
  """
  @spec current() :: plan_t
  def current() do
    Application.get_env(:glossia, :plan, :community)
  end
end
