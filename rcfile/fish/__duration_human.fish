function __duration_human -a ms -d 'Format a millisecond duration as a human readable string'
  if test $ms -lt 1000
    printf '%dms' $ms
  else if test $ms -lt 60000
    printf '%dsec' (math --scale=0 "floor($ms / 1000)")
  else if test $ms -lt 3600000
    printf '%dmin %02dsec' (math --scale=0 "floor($ms / 60000)") (math --scale=0 "floor($ms / 1000) % 60")
  else if test $ms -lt 86400000
    printf '%dh %02dmin' (math --scale=0 "floor($ms / 3600000)") (math --scale=0 "floor($ms / 60000) % 60")
  else if test $ms -lt 2592000000
    printf '%dday %02dhour' (math --scale=0 "floor($ms / 86400000)") (math --scale=0 "floor($ms / 3600000) % 24")
  else
    printf '%dmonth %02dday' (math --scale=0 "floor($ms / 2592000000)") (math --scale=0 "floor($ms / 86400000) % 30")
  end
end
