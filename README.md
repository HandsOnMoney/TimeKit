# TimeKit
Generic Swift library for Gregorian calendar-based time periods, intervals, and timelines.

> ⚠️ This README was written with LLM assistance. For the authenticity, check out the [HandsOnMoney blog](https://handson.money/blog).

Swift's standard library lacks a package for working with calendar-based date intervals. TimeKit was written out of the necessity of displaying a common personal finance concern — a timeline of periods such as weeks, months, quarters, and years. It also supports non-standard intervals spanning an arbitrary number of days.

## Concepts

- **`Cadence`** — defines the shape of a period: `.days(count:)`, `.week`, `.month`, `.quarter`, or `.year`.
- **`CadenceCalc`** — computes period boundaries for a given cadence, including optional gaps between periods.
- **`Timeline`** — a sorted, lazily-extended collection of your own `TimePeriod`-conforming values.
- **`TimePeriod`** — a protocol your model type adopts to participate in a `Timeline`.

## Setup

Define a type that conforms to `TimePeriod`:

```swift
import TimeKit

struct Period: TimePeriod {
    let id: UUID
    var start: Date
    var end: Date

    init(start: Date, end: Date) {
        self.id = UUID()
        self.start = start
        self.end = end
    }

    mutating func change(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}
```

## Examples

### Monthly periods

Periods run from the first to the last day of each calendar month. The `gap` of one day means each period's `end` is the last day of the month (inclusive) rather than midnight of the next month.

```swift
let calc = CadenceCalc(length: .month, gap: DateComponents(day: 1))
var timeline = Timeline<Period>(cadenceCalc: calc) { start, end in
    Period(start: start, end: end)
}

// Extend to cover a date range, returns the newly created periods
let newPeriods = timeline.extend(
    start: Date(), // e.g. today
    end: Calendar.current.date(byAdding: .month, value: 3, to: Date())!
)
// newPeriods contains the current month and the three following months
```

### Flexible day-count periods (`.days`)

Useful for budgeting cycles that don't align with calendar months — for example a 14-day pay period starting on a chosen date.

```swift
let calc = CadenceCalc(length: .days(count: 14), gap: DateComponents(day: 1))
var timeline = Timeline<Period>(cadenceCalc: calc) { Period(start: $0, end: $1) }

_ = timeline.extend(Date())
// timeline[0] spans exactly 14 days starting from today's midnight
```

### Weekly periods

```swift
let calc = CadenceCalc(length: .week, gap: DateComponents(day: 1))
var timeline = Timeline<Period>(cadenceCalc: calc) { Period(start: $0, end: $1) }

_ = timeline.extend(Date())
// timeline[0] spans Mon–Sun (or Sun–Sat, depending on the Calendar's firstWeekday)
```

### Quarterly periods

```swift
let calc = CadenceCalc(length: .quarter, gap: DateComponents(day: 1))
var timeline = Timeline<Period>(cadenceCalc: calc) { Period(start: $0, end: $1) }

_ = timeline.extend(Date())
// timeline[0] spans Jan 1–Mar 31, Apr 1–Jun 30, Jul 1–Sep 30, or Oct 1–Dec 31
```

### Yearly periods

```swift
let calc = CadenceCalc(length: .year, gap: DateComponents(day: 1))
var timeline = Timeline<Period>(cadenceCalc: calc) { Period(start: $0, end: $1) }

_ = timeline.extend(Date())
// timeline[0] spans Jan 1–Dec 31 of the current year
```

### Changing a period's dates

`change(start:end:of:)` resizes a period and automatically adjusts the boundaries of the immediately preceding and following periods to maintain gap spacing. It returns all modified periods so you can sync only what changed.

```swift
var timeline = Timeline<Period>(
    cadenceCalc: CadenceCalc(length: .month, gap: DateComponents(day: 1)),
    makePeriod: { Period(start: $0, end: $1) }
)

// Populate three months: April, May, June
_ = timeline.extend(
    start: /* April 1 */ ...,
    end:   /* June 30 */ ...
)

// Shrink May: start it on the 10th instead of the 1st
let mayID = timeline[1].id
let modifiedPeriods = try timeline.change(
    start: /* May 10 */,
    end:   timeline[1].end,
    of: mayID
)
// modifiedPeriods contains:
//   • April — its end is now May 9 (one day before the new May start)
//   • May   — its start is now May 10
// June is unchanged because only the start moved
```

If the requested change would make an adjacent period's range invalid (e.g. the previous period's start would fall after its new end), `change` throws a `TimeError` instead of producing an inconsistent timeline.

## Array utilities for sorted event sequences

TimeKit extends `Array` with three operations designed for working with chronologically sorted sequences of events.

### `lowerBound(target:by:)`

Binary search that returns the index of the last element whose date is ≤ `target`. Returns `-1` when no element precedes the target.

```swift
struct Reading { let date: Date; let value: Double }

let readings: [Reading] = [
    Reading(date: jan1,  value: 10),
    Reading(date: jan15, value: 20),
    Reading(date: feb1,  value: 30),
]

// What is the latest reading on or before Jan 20?
let i = readings.lowerBound(target: jan20, by: \.date) // → 1 (jan15 entry)
let i2 = readings.lowerBound(target: dec31, by: \.date) // → -1 (nothing precedes it)
```

Use the index to slice: `Array(readings[i...])` gives all readings from that point forward.

### `lowerBoundElement(target:by:)`

Convenience wrapper around `lowerBound` that returns the element itself instead of its index. Returns `nil` when `lowerBound` would return `-1`.

```swift
let latest = readings.lowerBoundElement(target: jan20, by: \.date)
// → Reading(date: jan15, value: 20)

let none = readings.lowerBoundElement(target: dec31, by: \.date)
// → nil
```

Use this to answer "what was the last known state before this date?" without managing index arithmetic.

### `mergeReduce(with:by:andBy:transform:)`

Merges two ascending-sorted arrays by date and reduces them into a single output array. At each date the transform receives the previous output element (or `nil` for the first), the left element (or `nil` if only the right fired), and the right element (or `nil` if only the left fired). Both arrays are fully consumed.

```swift
struct Event { let date: Date; let delta: Int }

let lefts:  [Event] = [Event(date: jan1, delta: 5), Event(date: feb1, delta: 3)]
let rights: [Event] = [Event(date: jan15, delta: -2), Event(date: feb1, delta: -1)]

struct Total { let date: Date; let sum: Int }

let totals = lefts.mergeReduce(with: rights, by: \.date, andBy: \.date) { previous, l, r -> Total in
    let base = previous?.sum ?? 0
    let lDelta = l?.delta ?? 0
    let rDelta = r?.delta ?? 0
    let date = (l ?? r)!.date
    return Total(date: date, sum: base + lDelta + rDelta)
}
// totals[0] = Total(date: jan1,  sum:  5)   // left only
// totals[1] = Total(date: jan15, sum:  3)   // right only
// totals[2] = Total(date: feb1,  sum:  5)   // both fired on the same date
```

When both arrays have an element on the same date they are delivered together in a single transform call — the output array never has duplicate dates from a same-date coincidence.

## Usage of AI

This package was heavily refactored with LLM assistance. All unit tests are generated by LLM. Everything is reviewed by a human.
