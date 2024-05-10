defmodule LiveViewNative.Template.ParserTest do
  use ExUnit.Case, async: false

  import LiveViewNative.Template.Parser, only: [
    parse_document: 1,
    parse_document!: 1
  ]

  test "empty template" do
    {:ok, tree} = parse_document("")
    assert tree == []
  end

  describe "comments" do
    test "parses comments" do
      document = """
      <!-- foobar
      barbaz
      -->
      """

      {:ok, tree} = parse_document(document)
      assert tree == [
        {:comment, [], " foobar\nbarbaz\n"}
      ]
    end

    test "parses multiple comments" do
    document = """
    <!-- foobar
    barbaz
    -->
    <!--
    dockyard
    brian
    narwin
    -->
    """

    {:ok, tree} = parse_document(document)
    assert tree == [
      {:comment, [], " foobar\nbarbaz\n"},
      {:comment, [], "\ndockyard\nbrian\nnarwin\n"}
    ]
    end
  end

  describe "tags" do
    test "parses a tag" do
      document = """
      <Text>Hello</Text>
      """

      {:ok, tree} = parse_document(document)
      assert tree == [{"Text", [], ["Hello"]}]
    end
  end

  describe "errors" do
    test "will error when unbound content" do
      document = """
      foobar
      """

      {:error, message} = parse_document(document)
      assert message == "unbound word in document: foobar"
    end

    test "parse_docuemnt! will raise ParseException" do
      document = """
      foobar
      """

      assert_raise LiveViewNative.Template.ParserException,"unbound word in document: foobar", fn ->
        parse_document!(document)
      end
    end
  end
end
