all=$(bspc query -D --names | jq -R -s 'split("\n") | map(select(. != ""))')
occupied=$(bspc query -D -d .occupied --names | jq -R -s 'split("\n") | map(select(. != ""))')
focused=$(bspc query -D -d .focused --names | jq -R -s 'split("\n") | map(select(. != ""))')

jq -n --argjson all "$all" --argjson occ "$occupied" --argjson foc "$focused" '
  [$all[] | {
    name: .,
    status: if (. as $d | ($foc | index($d))) then "focused"
            elif (. as $d | ($occ | index($d))) then "occupied"
            else "empty"
            end
  }]
'