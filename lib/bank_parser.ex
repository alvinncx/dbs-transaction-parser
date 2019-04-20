defmodule BankParser do
  @moduledoc """
  
  Parser is a parser for DBS credit card transaction information

  """
  @regex_figures ~r/(S\$)(\d{0,}\.\d{0,2})/

  @doc """
  
  Parses a file

  """
  def parse_file(file, output_name \\ "output") do
    File.read!(file)
    |> parse(output_name)
  end

  @doc """
  Parses a binary. Use this if you are using the raw inputs from the website.

    Sample: 
    `"13 Mar 2019   DELIVEROO.COM.SG  S$33.42\\n15 Mar 2019   FAVEPAY   S$24.70\\n15 Mar 2019   GRAB *4435999-9-024   S$11.00`

  Take note that if the `\\n` in the binary.
  """
  def parse(binary, output_name \\ "output") do
    binary
    |> String.split("\n")
    |> Enum.map(&(&1 |> parse_line!))
    |> convert_to_table
    |> write(output_name)
  end

  defp parse_line!(line) do
    case <<date::binary-size(11), rest::binary>> = line do
      line -> 
        {item, amount, type} = rest |> parse_rest
        %{
          date: date,
          item: item,
          amount: amount |> parse_figure,
          type: type
        }
      _ -> 
        {:error}
    end
  end

  defp parse_rest(line) do
    case Regex.split(@regex_figures, line, include_captures: :true, trim: true) do
      [line, figures] ->
        {line |> String.trim, figures, "debit"} 
      [line, figures, " cr"] ->
        {line |> String.trim, figures, "credit"} 
      _rest -> 
        {:error}
    end
  end

  defp parse_figure(figure) do
    case <<83, 36, amount::binary >> = figure do
      figure -> 
        amount |> String.to_float
    end
  end

  defp convert_to_table(list) do
    headers = list 
    |> List.first 
    |> Map.keys 
    |> Enum.map(&(Atom.to_string(&1)))

    list = list
    |> Enum.map(&(&1 |> Map.values))

    [headers | list] |> IO.inspect
  end

  defp write(table_data, filename) do
    file = File.open!(filename <> ".csv", [:write, :utf8])
    
    table_data
    |> CSV.encode 
    |> Enum.each(&IO.write(file, &1))
  end
end
