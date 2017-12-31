#!/usr/bin/env bats

@test "1. Single action hook" {
  result="$(bash asc/custom/debug.sh)"
  [ -n "$result" ]
}
