# typed: false
# frozen_string_literal: true

require "search"

describe Homebrew::Search do
  describe "#search_taps" do
    before do
      ENV.delete("HOMEBREW_NO_GITHUB_API")
    end

    it "does not raise if `HOMEBREW_NO_GITHUB_API` is set" do
      ENV["HOMEBREW_NO_GITHUB_API"] = "1"
      expect(described_class.search_taps("some-formula")).to match(formulae: [], casks: [])
    end

    it "does not raise if the network fails" do
      allow(GitHub::API).to receive(:open_rest).and_raise(GitHub::API::Error)

      expect(described_class.search_taps("some-formula"))
        .to match(formulae: [], casks: [])
    end

    it "returns Formulae and Casks separately" do
      json_response = {
        "items" => [
          {
            "path"       => "Formula/some-formula.rb",
            "repository" => {
              "full_name" => "Homebrew/homebrew-foo",
            },
          },
          {
            "path"       => "Casks/some-cask.rb",
            "repository" => {
              "full_name" => "Homebrew/homebrew-bar",
            },
          },
        ],
      }

      allow(GitHub::API).to receive(:open_rest).and_return(json_response)

      expect(described_class.search_taps("some-formula"))
        .to match(formulae: ["homebrew/foo/some-formula"], casks: ["homebrew/bar/some-cask"])
    end
  end

  describe "#query_regexp" do
    it "correctly parses a regex query" do
      expect(described_class.query_regexp("/^query$/")).to eq(/^query$/)
    end

    it "returns the original string if it is not a regex query" do
      expect(described_class.query_regexp("query")).to eq("query")
    end

    it "raises an error if the query is an invalid regex" do
      expect { described_class.query_regexp("/+/") }.to raise_error(/not a valid regex/)
    end
  end
end
