class_name TestCase
extends RefCounted
## Base class for headless tests. Methods starting with "test_" are run by
## tests/godot/run_tests.gd. Use the assert_* helpers; failures are collected.

var failures: Array[String] = []
var _current := ""


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func fail(msg: String) -> void:
	failures.append("%s: %s" % [_current, msg])


func assert_true(cond: bool, msg := "expected true") -> void:
	if not cond:
		fail(msg)


func assert_false(cond: bool, msg := "expected false") -> void:
	if cond:
		fail(msg)


func assert_eq(actual, expected, msg := "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_num(actual) and _is_num(expected)):
		fail("%s expected %s (%s), got %s (%s)" % [msg, expected, type_string(typeof(expected)), actual, type_string(typeof(actual))])
	elif actual != expected:
		fail("%s expected %s, got %s" % [msg, expected, actual])


func assert_near(actual: float, expected: float, eps := 0.001, msg := "") -> void:
	if absf(actual - expected) > eps:
		fail("%s expected ~%s, got %s" % [msg, expected, actual])


func assert_has(container, value, msg := "") -> void:
	if not (value in container):
		fail("%s %s not in %s" % [msg, value, container])


func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
