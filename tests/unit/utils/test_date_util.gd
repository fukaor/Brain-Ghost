## GUT test for DateUtil
extends "res://addons/gut/test.gd"

func test_days_between_same_day():
    assert_eq(DateUtil.days_between("2026-04-10", "2026-04-10"), 0)

func test_days_between_next_day():
    assert_eq(DateUtil.days_between("2026-04-09", "2026-04-10"), 1)

func test_days_between_7_days():
    assert_eq(DateUtil.days_between("2026-04-03", "2026-04-10"), 7)

func test_days_between_8_days():
    assert_eq(DateUtil.days_between("2026-04-02", "2026-04-10"), 8)

func test_days_between_year_boundary():
    assert_eq(DateUtil.days_between("2025-12-31", "2026-01-01"), 1)

func test_days_between_leap_year():
    assert_eq(DateUtil.days_between("2024-02-28", "2024-03-01"), 2, "2024 is a leap year")

func test_days_between_non_leap_year():
    assert_eq(DateUtil.days_between("2025-02-28", "2025-03-01"), 1, "2025 is not a leap year")

func test_days_between_empty_strings():
    assert_eq(DateUtil.days_between("", "2026-04-10"), 0)
    assert_eq(DateUtil.days_between("2026-04-10", ""), 0)

func test_date_string_to_seed():
    assert_eq(DateUtil.date_string_to_seed("2026-04-15"), 20260415)
    assert_eq(DateUtil.date_string_to_seed("2026-12-31"), 20261231)
