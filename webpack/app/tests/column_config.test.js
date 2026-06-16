import {
  merge_column_config,
  toggle_in,
  reorder_in,
  visibility_from,
  keys_from,
} from "../storage/column_config.js"


describe("merge_column_config", () => {

  it("returns server keys in server order when nothing is stored", () => {
    const merged = merge_column_config([], ["A", "B", "C"])
    expect(merged).toEqual([
      { key: "A", toggle: true },
      { key: "B", toggle: true },
      { key: "C", toggle: true },
    ])
  })

  it("preserves user-chosen order for keys that still exist", () => {
    const stored = [
      { key: "C", toggle: true },
      { key: "A", toggle: false },
      { key: "B", toggle: true },
    ]
    const merged = merge_column_config(stored, ["A", "B", "C"])
    expect(keys_from(merged)).toEqual(["C", "A", "B"])
    expect(visibility_from(merged).A).toBe(false)
  })

  it("auto-appends NEW server keys at the end as visible", () => {
    // Simulates an add-on package that adds column "D" after the
    // user already customised order + visibility for A/B/C.
    const stored = [
      { key: "B", toggle: false },
      { key: "A", toggle: true },
      { key: "C", toggle: true },
    ]
    const merged = merge_column_config(stored, ["A", "B", "C", "D"])
    expect(keys_from(merged)).toEqual(["B", "A", "C", "D"])
    expect(visibility_from(merged).D).toBe(true)
  })

  it("drops stored entries whose keys no longer exist server-side", () => {
    // Simulates an add-on package that removed column "B".
    const stored = [
      { key: "A", toggle: true },
      { key: "B", toggle: true },
      { key: "C", toggle: false },
    ]
    const merged = merge_column_config(stored, ["A", "C"])
    expect(keys_from(merged)).toEqual(["A", "C"])
    expect(visibility_from(merged).C).toBe(false)
  })

  it("filters by allowed_keys when provided", () => {
    // The active review_state declares only A and C as allowed.
    const stored = [
      { key: "A", toggle: true },
      { key: "B", toggle: true },
      { key: "C", toggle: true },
    ]
    const merged = merge_column_config(stored, ["A", "B", "C"], ["A", "C"])
    expect(keys_from(merged)).toEqual(["A", "C"])
  })

  it("treats missing toggle as visible", () => {
    const merged = merge_column_config(
      [{ key: "A" }, { key: "B", toggle: false }], ["A", "B"])
    expect(visibility_from(merged)).toEqual({ A: true, B: false })
  })

  it("ignores malformed entries gracefully", () => {
    const stored = [
      null,
      undefined,
      "not an object",
      { toggle: true },             // missing key
      { key: 42, toggle: true },    // non-string key
      { key: "A", toggle: false },
    ]
    const merged = merge_column_config(stored, ["A", "B"])
    expect(keys_from(merged)).toEqual(["A", "B"])
    expect(visibility_from(merged).A).toBe(false)
  })

  it("deduplicates repeated keys in stored config", () => {
    const merged = merge_column_config(
      [{ key: "A" }, { key: "A", toggle: false }], ["A", "B"])
    expect(keys_from(merged)).toEqual(["A", "B"])
    // Earliest occurrence wins (visible default), since dedup keeps
    // the first.
    expect(visibility_from(merged).A).toBe(true)
  })
})


describe("toggle_in", () => {

  it("flips the toggle for the matching entry without mutating input", () => {
    const before = [{ key: "A", toggle: true }, { key: "B", toggle: false }]
    const after = toggle_in(before, "A")
    expect(after).toEqual([
      { key: "A", toggle: false },
      { key: "B", toggle: false },
    ])
    expect(before).toEqual([
      { key: "A", toggle: true },
      { key: "B", toggle: false },
    ])
  })

  it("flips a default-visible entry to hidden", () => {
    const after = toggle_in([{ key: "A" }], "A")
    expect(after).toEqual([{ key: "A", toggle: false }])
  })
})


describe("reorder_in", () => {

  it("rearranges entries to match the given key sequence", () => {
    const config = [
      { key: "A", toggle: true },
      { key: "B", toggle: false },
      { key: "C", toggle: true },
    ]
    const reordered = reorder_in(config, ["C", "A", "B"])
    expect(keys_from(reordered)).toEqual(["C", "A", "B"])
    // Toggles travel with their key.
    expect(visibility_from(reordered)).toEqual(
      { A: true, B: false, C: true })
  })

  it("appends entries missing from the order at the end (no data loss)", () => {
    const config = [
      { key: "A", toggle: true },
      { key: "B", toggle: false },
    ]
    const reordered = reorder_in(config, ["B"])
    expect(keys_from(reordered)).toEqual(["B", "A"])
  })
})
