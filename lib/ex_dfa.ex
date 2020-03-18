defmodule ExDfa do
  @moduledoc """
  A simple DFA filter for sensitive words filter.
  """
  @delimit '0'
  @zh_re ~r([\x{4e00}-\x{9fa5}]+)u
  @en_re ~r/[a-z]/

  @type word_group_type :: {integer, [String.t()]}
  @type filter_struct_type :: Map.t()

  @doc """
  Build a filter with sensitive words group.

  The `words_group` struct is a list with tuple item {level, [words...]},
  the level is How serious the sensitive words in this group, may starts with 0.

  ## Examples

      iex> ExDfa.build_filter([{0, ["Fuck", "Fucku"]}, {1, ["傻逼", "傻帽"]}])
      %{
        "f" => %{"u" => %{"c" => %{"k" => %{'0' => 0, "u" => %{'0' => 0}}}}},
        "傻" => %{"帽" => %{'0' => 1}, "逼" => %{'0' => 1}}
      }

  """
  @spec build_filter([word_group_type], filter_struct_type) :: filter_struct_type
  def build_filter(words_group, initial \\ %{}) do
    Enum.reduce(words_group, initial, fn {level, words}, acc ->
      Enum.reduce(words, acc, fn word, acc2 ->
        word =
          word
          |> String.downcase()
          |> String.trim()

        word_list =
          word
          |> String.split("")
          |> Enum.filter(fn x -> x != "" end)

        case length(word_list) do
          0 ->
            acc2

          _ ->
            word_list =
              word
              |> String.split("")
              |> Enum.filter(fn x -> x != "" end)

            put_in(acc2, Enum.map(word_list, &Access.key(&1, %{})), %{@delimit => level})
        end
      end)
    end)
  end

  @doc """
  Do dfa filter. Returns a tuple {:ok, nil} or {:error, levels}
  The `levels` describe the sensitive words in different levels found.

  ## Examples

      iex> ExDfa.do_filter(%{
      ...>   "F" => %{"u" => %{"c" => %{"k" => %{'0' => 0, "u" => %{'0' => 0}}}}},
      ...>   "傻" => %{"帽" => %{'0' => 1}, "逼" => %{'0' => 1}}
      ...> }, "你是大傻逼")
      {:error, [1]}

  """
  @spec do_filter(filter_struct_type, String.t()) :: {:ok, nil} | {:error, [integer]}
  def do_filter(filter_struct, content) do
    len = String.length(content)

    levels =
      Enum.reduce(0..(len - 1), [], fn n, acc ->
        if String.at(content, n) == " " do
          acc
        else
          Enum.reduce_while(n..(len - 1), acc, fn m, acc2 ->
            word = content |> String.slice(n..m)

            word_list =
              word
              |> String.split("")
              |> Enum.filter(fn x -> x != "" and x != " " end)

            res =
              if word_list != [] do
                get_in(filter_struct, Enum.map(word_list, &Access.key(&1, %{nil => nil})))
              else
                nil
              end

            case res do
              %{@delimit => level} ->
                val =
                  cond do
                    String.match?(word, @zh_re) ->
                      [level | acc2]

                    (n == 0 or not String.match?(String.at(content, n - 1), @en_re)) and
                        (m == len - 1 or not String.match?(String.at(content, m + 1), @en_re)) ->
                      [level | acc2]

                    true ->
                      acc2
                  end

                {:halt, val}

              %{nil => nil} ->
                {:halt, acc2}

              _ ->
                {:cont, acc2}
            end
          end)
        end
      end)

    if length(levels) == 0 do
      {:ok, nil}
    else
      {:error, levels}
    end
  end
end
