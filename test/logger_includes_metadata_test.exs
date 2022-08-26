defmodule Checks.LoggerIncludesMetadataTest do
  use Assertions.Case

  alias Credo.{Issue, SourceFile}

  alias Checks.LoggerIncludesMetadata

  test "warns if Logger calls do not contain metadata :somekey" do
    expected_issues = [
      %Issue{
        category: :warning,
        check: LoggerIncludesMetadata,
        filename: "lib/app/file_test.ex",
        line_no: 5,
        message: "`Logger` call missing metadata with [:somekey] key(s)"
      }
    ]

    """
    defmodule App.FileTest do
      require Logger

      def test(arg) do
        Logger.info("message")
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      require Logger

      def test(arg) do
        Logger.info("message", key: "some")
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      require Logger

      def test(arg) do
        Logger.info(\"\"\"
        message
        \"\"\"
        )
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues(expected_issues)

    """
    defmodule App.FileTest do
      require Logger

      def test(arg) do
        Logger.info(\"\"\"
        message
        \"\"\",
        key: "key"
        )
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues(expected_issues)
  end

  test "does not warn for Logger calls containing metadata with :somekey" do
    """
    defmodule App.FileTest do
      def test(arg) do
        Logger.info("message",
          somekey: :value,
          other_key: "some-value",
          third_key: "some-other-value")
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues([])

    """
    defmodule App.FileTest do
      require Logger

      def test(arg) do
        Logger.info("message", somekey: :value)
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues([])
  end

  test "does not warn for other Logger function calls" do
    """
    defmodule App.FileTest do
      def test(arg) do
        Logger.metadata(
          somekey: :value,
          other_key: "some-value",
          third_key: "some-other-value")
        arg
      end
    end
    """
    |> SourceFile.parse("lib/app/file_test.ex")
    |> LoggerIncludesMetadata.run(keys: [:somekey])
    |> assert_issues([])
  end

  defp assert_issues(issues, expected) do
    assert_lists_equal(issues, expected, fn issue, expected ->
      assert_structs_equal(issue, expected, [:category, :check, :filename, :line_no, :message])
    end)
  end
end
