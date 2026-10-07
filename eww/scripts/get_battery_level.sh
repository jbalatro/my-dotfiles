battery=$(cat /sys/class/power_supply/BAT0/capacity)

if ((battery >= 90)); then
    echo "battery-4.svg"
elif ((battery >= 70)); then
    echo "battery-3.svg"
elif ((battery >= 40)); then
    echo "battery-2.svg"
elif ((battery >= 10)); then
    echo "battery-1.svg"
else
    echo "battery-0.svg"
fi