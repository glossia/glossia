defmodule Glossia.Foundation.Utilities.Core.Plan do
  @type plan_t :: :community | :cloud | :enterprise

  @doc """
  A macro to selectively compile code based on the plan of this instance of Glossia.

  ## Parameters

  - `plan` - The plan or list of plans to compile the code for.
  - `do` - The block of code to compile.
  """
  defmacro only_for_plans(plans, do: block) when is_list(plans) do
    quote do
      if Enum.member?(unquote(plans), Application.compile_env!(:glossia, :plan)) do
        unquote(block)
      end
    end
  end

  @doc """
  It returns the plan of this instance of Glossia.
  """
  @spec current() :: plan_t
  def current() do
    Application.fetch_env!(:glossia, :plan)
  end
end
