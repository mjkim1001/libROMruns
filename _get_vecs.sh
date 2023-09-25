#!/bin/bash

get_vectors() {
  local filename="$1"
  local data=$(cat "$filename")

  declare -a fractions

  # Read file and extract number of basis vectors
  while IFS= read -r line; do
    vectors=$(echo "$line" | grep -oE "take first [0-9]+")
    num_vectors=$(echo "$vectors" | grep -oE "[0-9]+" | head -n 1)
    fractions+=("$num_vectors")
  done <<< "$data" > /dev/null

  echo "${fractions[@]}"
  #echo $fractions
}
