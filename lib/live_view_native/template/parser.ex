defmodule LiveViewNative.Template.Parser do
  @whitespace_chars ~c"\0\a\b\t\n\v\f\r\e\s\#\\"

  def parse_document(document) do
    do_parse(document)
  end

  def parse_document!(document) do
    case parse_document(document) do
      {:ok, tree} -> tree
      {:error, message} -> raise LiveViewNative.Template.ParserException, message: message
    end
  end

  defp do_parse(document) when is_binary(document) do
    document
    |> String.to_charlist()
    |> do_parse()
  end

  defp do_parse(document) when is_list(document) do
    tokenize_document(document, [])
  end

  defp tokenize_document([], {:error, message}),
    do: {:error, message}

  defp tokenize_document([], acc),
    do: {:ok, Enum.reverse(acc)}

  defp tokenize_document(~c"<!--" ++ t, acc) do
    case tokenize_comment(t, {:comment, [], []}) do
      {:error, message} -> {:error, message}
      {t, comment_acc} -> tokenize_document(t, [comment_acc | acc])
    end
  end

  defp tokenize_document([char | t], acc) when char in @whitespace_chars do
    tokenize_document(t, acc)
  end

  # defp tokenize_document(~c"<%" ++ t, acc) do
  #   case tokenize_eex_statement(t, []) do
  #     {:error, message} -> {:error, message}
  #     {t, eex_acc} -> tokenize_document(t, [eex_acc | acc])
  #   end
  # end

  defp tokenize_document(~c"<" ++ t, acc) do
    {t, tag_name} = tokenize_tag_name(t, [])

    case tokenize_tag(t, {tag_name, [], []}) do
      {:error, message} -> {:error, message}
      {t, tag_acc} -> tokenize_document(t, [tag_acc | acc])
    end
  end

  defp tokenize_document([char | t], _acc) do
    word = List.to_string([char | get_next_word(t, [])])
    {:error, "unbound word in document: #{word}"}
  end

  defp get_next_word([char | _t], acc) when char in @whitespace_chars,
    do: Enum.reverse(acc)

  defp get_next_word([char | t], acc),
    do: get_next_word(t, [char | acc])

  defp tokenize_comment(~c"-->" ++ t, {:comment, attributes, content}) do
    {t, {:comment, attributes, content |> Enum.reverse() |> List.to_string()}}
  end

  defp tokenize_comment([char | t], {:comment, attributes, content}) do
    tokenize_comment(t, {:comment, attributes, [char | content]})
  end

  defp tokenize_tag([char | t], acc) when char in @whitespace_chars do
    tokenize_tag(t, acc)
  end

  defp tokenize_tag(~c"/>" ++ t, {tag_name, attributes, children}) do
    {t, {tag_name, attributes, Enum.reverse(children)}}
  end

  defp tokenize_tag(~c">" ++ t, {tag_name, attributes, _children}) do
    case tokenize_children(t, String.to_charlist(tag_name), []) do
      {:error, message} -> {:error, message}
      {t, children} -> {t, {tag_name, attributes, children}}
    end
  end

  defp tokenize_tag_name([char | t], acc) when char in ?a..?z or char in ?A..?Z do
    tokenize_tag_name(t, [char | acc])
  end

  defp tokenize_tag_name(t, acc) do
    tag_name =
      acc
      |> Enum.reverse()
      |> List.to_string()

    {t, tag_name}
  end

  defp tokenize_children(~c"</" ++ t, tag_name, acc) do
    case validat_tag_closure(t, tag_name, []) do
      {:error, message} -> {:error, message}
      t -> {t, Enum.reverse(acc)}
    end
  end

  # defp tokenize_children([char | t], acc) when char in @whitespace_chars do
  #   tokenize_children(t, acc)
  # end

  defp tokenize_children([char | t], acc) do
    case tokenize_text_node([char | t], []) do
      {:error, message} -> {:error, message}
      {t, }
    end
  end

  defp validate_tag_closure([char | t], tag_name, acc) when char in @whitespace_chars ++ ~c">" do
    extracted_tag_name =
      acc
      |> Enum.reverse()
      |> List.to_string()

    if tag_name == extracted_tag_name do
      if char == ?> do
        t
      else
        validate_tag_closure(t)
      end
    else
      {:error, "expected: #{tag_name} as the closing tag name but got: #{extracted_tag_name}"}
    end
  end

  defp validate_tag_closure([char | t], tag_nam, acc) do
    validate_tag_closure(t, tag_name, [char | acc])
  end

  defp validate_tag_closure([]) do
    {:error, "expected a tag closure but got EOF"}
  end

  defp validate_tag_closure([char | t]) do
    {:error, "invalid symbol in tag closure: #{char}"}
  end
end
