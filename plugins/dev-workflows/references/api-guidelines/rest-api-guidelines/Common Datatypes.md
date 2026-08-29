# Common Datatypes

**Sources:** [Google AIP-142 — Time and duration](https://google.aip.dev/142), [Google AIP-143 — Standardized codes](https://google.aip.dev/143), [RFC 3339 — Date and Time on the Internet](https://www.rfc-editor.org/rfc/rfc3339.html), [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html), [IANA Time Zone Database](https://www.iana.org/time-zones), [ISO 639-1](https://www.iso.org/iso-639-language-codes.html), [ISO 3166-1 alpha-2](https://www.iso.org/iso-3166-country-codes.html), [RFC 8259 §6 — JSON Numbers](https://www.rfc-editor.org/rfc/rfc8259.html#section-6), [Zalando — Data formats](https://opensource.zalando.com/restful-api-guidelines/#data-formats)

## Integer Value (32-bit)

- Unsigned types **should not** be used.
- If a signed integer where negative values are unused has a special meaning like "undefined" or "infinite", the value `-1` **must** be used. Arbitrary sentinels like `Integer.MAX_VALUE` **must not** be used.
- All special values (including `0` if its meaning is not obvious) **must** be clearly documented.

## Long Integer Value (64-bit)

Long (64-bit) values **must** be represented as strings. This is necessary because JSON numbers are commonly parsed as IEEE 754 doubles, which lose precision above 2^53 ([RFC 8259, Section 6](https://www.rfc-editor.org/rfc/rfc8259.html#section-6)). Timestamps **may** be represented as JSON numbers as described in [Timestamp](#timestamp) — millisecond epoch values stay exact in a double until roughly the year 287000, and second-resolution values indefinitely for practical purposes.

## Timezone

Time zones **must** be represented as a field named `timeZone`, containing the time zone identifier as specified in the [IANA time zone database](https://www.iana.org/time-zones) ([AIP-143](https://google.aip.dev/143)).

#### Examples
```
America/New_York
Asia/Shanghai
Etc/GMT+8
Europe/Berlin
```

## Timestamp

Unless explicitly defined otherwise, all timestamps **should** be represented as UTC times. Time zone designators **should** be represented as offsets from UTC.

Fields representing a point in time **should** end with "Time", such as `startTime` or `endTime`. In general, if a time refers to an action, the name **should** have the form '_\<verb>Time_', such as `createTime`. Avoid past tense for the verb, such as `createdTime` ([AIP-142](https://google.aip.dev/142)).

If timestamps are encoded as strings, they **must** be encoded in the [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339.html) profile of [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html):
```
YYYY-MM-DDTHH:MM:SS.ssssssZ
```
#### Examples
```
startTime = "2021-10-06T11:08:14.859831Z"
endTime = "2021-10-06T11:08:14.859831-05:00"
```

An additional separate field **may** be added to clarify the time zone used in the timestamp (only to improve readability, e.g. for UI display purposes).

#### Examples

| timestamp                        | timeZone         |
| -------------------------------- | ---------------- |
| 2021-10-06T11:08:14.859831Z      | Etc/UTC          |
| 2021-10-06T11:08:14.859831-05:00 | America/New_York |
| 2021-10-06T11:08:14.859831+01:00 | Europe/Berlin    |

Timestamps **may** be encoded as [Unix epoch](https://en.wikipedia.org/wiki/Unix_time) integers in second, millisecond, microsecond, or nanosecond resolution. Keep in mind that nanosecond values exceed the exact-integer range of a JSON double and **must** therefore be encoded as strings (see [Long Integer Value](#long-integer-value-64-bit)).

Timestamp fields encoded as epoch integers **must** carry the resolution (_Seconds_, _Millis_, _Micros_, _Nanos_) in the field name.

#### Examples
```
startTimeSeconds = 1633523598
createTimeMillis = 1633523598453
updateTimeMicros = 1633523598453862
endTimeNanos = "1633523598453862094"
```

## Time Span

Time spans **should** be represented by 2 separate fields defining the start and the end of the span. The default interpretation is that the start time is inclusive and the end time is exclusive. If the interpretation differs, it **must** be carefully documented.

#### Example
```
startTimeMillis = 1633523598453
endTimeMillis = 1643523598453
```

## Date

Dates without time zone and time **should** be represented as strings in the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) calendar date format "YYYY-MM-DD". Field names representing a date **should** end with "Date", such as `startDate`.

#### Example
```
startDate = "2021-10-06"
```

## Language Code

Language codes **must** be represented in a field named `languageCode` containing a string that follows [ISO 639-1](https://www.iso.org/iso-639-language-codes.html) — e.g. "en" for English ([AIP-143](https://google.aip.dev/143)).

## Country Code

Country codes **must** be represented in a field named `countryCode` containing a string that follows [ISO 3166-1 alpha-2](https://www.iso.org/iso-3166-country-codes.html) — e.g. "DE" for Germany ([AIP-143](https://google.aip.dev/143)).
