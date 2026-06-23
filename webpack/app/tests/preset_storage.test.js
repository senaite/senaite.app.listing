import {
  capture_payload,
  find_default_preset,
  generate_preset_id,
  load_presets,
  payloads_equal,
  save_presets,
  sort_presets,
} from "../storage/preset_storage.js"


// jsdom (the jest test env) provides a working window.localStorage.
beforeEach(() => window.localStorage.clear())


describe("load_presets / save_presets", () => {

  it("returns an empty array when nothing was stored", () => {
    expect(load_presets("samples")).toEqual([])
  })

  it("round-trips a list of presets", () => {
    const presets = [
      { id: "p1", name: "Default", is_default: true, payload: {} },
      { id: "p2", name: "Late", payload: { review_state: "late" } },
    ]
    save_presets("samples", presets)
    expect(load_presets("samples")).toEqual(presets)
  })

  it("falls back to [] for malformed JSON in storage", () => {
    window.localStorage.setItem(
      "senaite.listing.saved_filters.samples", "{not json")
    expect(load_presets("samples")).toEqual([])
  })

  it("falls back to [] when stored value is not an array", () => {
    window.localStorage.setItem(
      "senaite.listing.saved_filters.samples", JSON.stringify({}))
    expect(load_presets("samples")).toEqual([])
  })

  it("isolates presets per storage_id", () => {
    save_presets("samples",  [{ id: "p1", name: "A" }])
    save_presets("worksheets", [{ id: "p2", name: "B" }])
    expect(load_presets("samples")[0].id).toBe("p1")
    expect(load_presets("worksheets")[0].id).toBe("p2")
  })
})


describe("find_default_preset", () => {

  it("returns null when no preset is marked default", () => {
    save_presets("samples", [{ id: "p1", name: "A" }])
    expect(find_default_preset("samples")).toBeNull()
  })

  it("returns the first default preset", () => {
    save_presets("samples", [
      { id: "p1", name: "A" },
      { id: "p2", name: "B", is_default: true },
      { id: "p3", name: "C", is_default: true },
    ])
    expect(find_default_preset("samples").id).toBe("p2")
  })
})


describe("generate_preset_id", () => {

  it("produces unique strings prefixed with 'p_'", () => {
    const ids = new Set()
    for (let i = 0; i < 50; i++) ids.add(generate_preset_id())
    expect(ids.size).toBe(50)
    for (const id of ids) expect(id.startsWith("p_")).toBe(true)
  })
})


describe("sort_presets", () => {

  it("sorts case-insensitively by name without mutating the input", () => {
    const input = [
      { name: "banana" }, { name: "Apple" }, { name: "carrot" },
    ]
    const sorted = sort_presets(input)
    expect(sorted.map((p) => p.name)).toEqual(["Apple", "banana", "carrot"])
    // Original untouched.
    expect(input.map((p) => p.name)).toEqual(["banana", "Apple", "carrot"])
  })

  it("treats missing names as empty strings, not crashes", () => {
    expect(() => sort_presets([{}, { name: "x" }])).not.toThrow()
  })
})


describe("payloads_equal", () => {

  it("treats absent and empty column_filters as equal", () => {
    expect(payloads_equal({}, { column_filters: {} })).toBe(true)
  })

  it("ignores key order in column_filters", () => {
    expect(payloads_equal(
      { column_filters: { a: "1", b: "2" } },
      { column_filters: { b: "2", a: "1" } })).toBe(true)
  })

  it("treats empty-string filter entries as absent", () => {
    expect(payloads_equal(
      { column_filters: { a: "" } },
      { column_filters: {} })).toBe(true)
  })

  it("treats null filter entries as absent", () => {
    expect(payloads_equal(
      { column_filters: { a: null } },
      { column_filters: {} })).toBe(true)
  })

  it("flags a different review_state", () => {
    expect(payloads_equal(
      { review_state: "late" }, { review_state: "all" })).toBe(false)
  })

  it("treats missing pagesize and null pagesize as equal", () => {
    expect(payloads_equal({}, { pagesize: null })).toBe(true)
  })

  it("flags a non-trivial sort change", () => {
    expect(payloads_equal(
      { sort_on: "created" },
      { sort_on: "Title" })).toBe(false)
  })
})


describe("capture_payload", () => {

  it("returns the canonical shape with defaults", () => {
    expect(capture_payload({})).toEqual({
      review_state: "",
      column_filters: {},
      sort_on: "",
      sort_order: "",
      pagesize: null,
      filter: "",
      labels: [],
    })
  })

  it("clones column_filters so later edits do not leak", () => {
    const live = { column_filters: { a: "1" } }
    const captured = capture_payload(live)
    live.column_filters.a = "2"
    expect(captured.column_filters.a).toBe("1")
  })

  it("captures labels sorted and stripped of empties", () => {
    const captured = capture_payload({ labels: ["foo", "", "bar"] })
    expect(captured.labels).toEqual(["bar", "foo"])
  })

  it("clones labels so later edits do not leak", () => {
    const live = { labels: ["foo"] }
    const captured = capture_payload(live)
    live.labels.push("bar")
    expect(captured.labels).toEqual(["foo"])
  })

  it("normalizes a missing labels value to an empty array", () => {
    expect(capture_payload({}).labels).toEqual([])
    expect(capture_payload({ labels: null }).labels).toEqual([])
    expect(capture_payload({ labels: "not-an-array" }).labels).toEqual([])
  })
})
