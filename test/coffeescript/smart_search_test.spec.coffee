GLOBAL.window = GLOBAL
require "../../public/coffee/smart_search.coffee"

describe "search query parser", ->
  beforeEach ->
    @smartSearch = new window.SmartSearch
    @parse = (string) -> @smartSearch.parseSearch(string)
    @parsePartialQuery = (string) -> @smartSearch.parsePartialQuery(string)

  it "should interpret a query term with a colon as a key/value pair", ->
    expect(@parse("foo:bar")["foo"]).toEqual "bar"

  it "should identify the key and partial term correctly for a query term with a colon", ->
    expect(@parsePartialQuery("foo:bar")).toEqual
      key: "foo:",
      value: "bar",
      unrelatedPrefix: "foo:",
      searchType: "value"

    expect(@parsePartialQuery("foo:bar ")).toEqual
      key: "",
      value: "",
      unrelatedPrefix: "foo:bar ",
      searchType: "key"

  it "should parse an empty key to path", ->
    expect(@parse(":foo")["paths"]).toEqual(["foo"])

  it "should allow for a comma-separated list, including spaces", ->
    expect(@parse("repos:db, barkeep,coffee")["repos"]).toEqual "db,barkeep,coffee"
    expect(@parsePartialQuery("repos:db, barkeep,coffee")).toEqual
      key: "repos:",
      value: "coffee",
      unrelatedPrefix: "repos:db,barkeep,",
      searchType: "value"

  it "should allow for spaces after the colon in a search term", ->
    expect(@parse("repos: barkeep authors: caleb")).toEqual { paths: [], repos: "barkeep", authors: "caleb" }
    expect(@parsePartialQuery("repos: barkeep authors: caleb")).toEqual
      key: "authors:",
      value: "caleb",
      unrelatedPrefix: "repos:barkeep authors:",
      searchType: "value"

  it "should gracefully handle (ignore) weird leading colons", ->
    expect(@parse(":foo:bar, baz")["foo"]).toEqual "bar,baz"

  it "should handle arbitrary amounts of whitespace", ->
    expect(@parse("    repos:  foo,  bar, baz      authors:joe,bob,   jimmy")).toEqual
      paths: []
      repos: "foo,bar,baz"
      authors: "joe,bob,jimmy"

    expect(@parsePartialQuery("    repos:  foo,  bar, baz      authors:joe,bob,   jimmy")).toEqual
      key: "authors:",
      value: "jimmy",
      unrelatedPrefix: " repos:foo,bar,baz authors:joe,bob,",
      searchType: "value"

  it "should gracefully handle a trailing comma", ->
    expect(@parse("foo:bar,baz,")["foo"]).toEqual "bar,baz"
    expect(@parsePartialQuery("foo:bar,baz,")).toEqual
      key: "foo:",
      value: "",
      unrelatedPrefix: "foo:bar,baz,",
      searchType: "value"

  it "should allow for using paths like any other key", ->
    expect(@parse("paths: foo, bar,baz")["paths"]).toEqual ["foo,bar,baz"]

  it "should allow for setting paths by not specifying a key", ->
    expect(@parse("foo bar baz repos:blah paths:some/path")).toEqual
      paths: ["foo", "bar", "baz", "some/path"]
      repos: "blah"

  it "should handle sha in the query", ->
    sampleShas = ["0e7d9bd88dfe54ca05356edec1fdf293d1e61658", "0e7d9bd88d", "0e7d9bd"]
    for sampleSha in sampleShas
      expect(@parse(sampleSha)["sha"]).toEqual(sampleSha)

  it "should handle sha plus another search term", ->
    expect(@parse("0e7d9bd repos:barkeep")).toEqual
      paths: []
      sha: "0e7d9bd"
      repos: "barkeep"

  it "should not confuse words for sha", ->
    sampleWords = ["sevens", "migrations"]
    expect(@parse(word)["paths"]).toEqual([word]) for word in sampleWords

  it "should allow for some synonyms instead of the intended keywords", ->
    for keyword, synonym of { branches: "branch", authors: "author", repos: "repo" }
      expect(@parse("#{synonym}: foobar")[keyword]).toEqual "foobar"

  it "should correctly parse quoted author names", ->
    expect(@parse("authors:\"Nicolas\"")["authors"]).toEqual "Nicolas"
    expect(@parsePartialQuery("authors:\"Nicolas\"")).toEqual
      key: "authors:"
      value: "\"Nicolas\""
      unrelatedPrefix: "authors:"
      searchType: "value"

  it "should correctly parse quoted author names containing spaces", ->
    expect(@parse("authors:\"Nicolas Cage\"")["authors"]).toEqual "Nicolas Cage"
    expect(@parsePartialQuery("authors:\"Nicolas Cage\"")).toEqual
      key: "authors:"
      value: "\"Nicolas Cage\""
      unrelatedPrefix: "authors:"
      searchType: "value"

  it "should correctly parse multiple quoted author names", ->
    expect(@parse("authors:\"Nicolas Cage\",\"Betty White\"")["authors"]).toEqual "Nicolas Cage,Betty White"
    expect(@parsePartialQuery("authors:\"Nicolas Cage\",\"Betty White\"")).toEqual
      key: "authors:"
      value: "\"Betty White\""
      unrelatedPrefix: "authors:\"Nicolas Cage\","
      searchType: "value"

  it "should correctly parse quoted and non-quoted author names together", ->
    expect(@parse("authors:\"Nicolas Cage\",Prince,\"Betty White\"")["authors"]).toEqual "Nicolas Cage,Prince,Betty White"
    expect(@parsePartialQuery("authors:\"Nicolas Cage\",Prince,\"Betty White\"")).toEqual
      key: "authors:"
      value: "\"Betty White\""
      unrelatedPrefix: "authors:\"Nicolas Cage\",Prince,"
      searchType: "value"

  it "should correctly parse unmatched-quoted author names", ->
    expect(@parsePartialQuery("authors:\"Nicolas")).toEqual
      key: "authors:"
      value: "\"Nicolas"
      unrelatedPrefix: "authors:"
      searchType: "value"

  it "should correctly parse unmatched-quoted author names ending with a space", ->
    expect(@parsePartialQuery("authors:\"Nicolas ")).toEqual
      key: "authors:"
      value: "\"Nicolas "
      unrelatedPrefix: "authors:"
      searchType: "value"

  it "should correctly parse unmatched-quoted author names containing a space", ->
    expect(@parsePartialQuery("authors:\"Nicolas Cage")).toEqual
      key: "authors:"
      value: "\"Nicolas Cage"
      unrelatedPrefix: "authors:"
      searchType: "value"

  it "should correctly parse unmatched-quoted author names preceded by another quoted author name", ->
    expect(@parsePartialQuery("authors:\"Nicolas Cage\",\"Betty White")).toEqual
      key: "authors:"
      value: "\"Betty White"
      unrelatedPrefix: "authors:\"Nicolas Cage\","
      searchType: "value"

  it "should correctly parse unmatched-quoted author names preceded by another key with a quoted value", ->
    expect(@parsePartialQuery("authors:\"Betty White\" authors:\"Nicolas Cage")).toEqual
      key: "authors:"
      value: "\"Nicolas Cage"
      unrelatedPrefix: "authors:\"Betty White\" authors:"
      searchType: "value"
