#!/bin/zsh
# Quick test of all channel combinations
# Uses --msg to skip AI and speed up tests

MSGME="./msgme"
PASS=0
FAIL=0

test_case() {
    local desc="$1"; shift
    local expect_phones="$1"; shift
    local expect_emails="$1"; shift
    local expect_speech="$1"; shift

    # Run msgme with debug, capture output
    local out
    out=$(zsh $MSGME "$@" --msg "test" -d -- echo "test" 2>&1)

    # Count actual deliveries
    local actual_phones=$(echo "$out" | grep -c "Sending iMessage to")
    local actual_emails=$(echo "$out" | grep -c "Sending email to")
    local actual_speech=$(echo "$out" | grep -c "Speaking:")

    if [[ "$actual_phones" -eq "$expect_phones" && "$actual_emails" -eq "$expect_emails" && "$actual_speech" -eq "$expect_speech" ]]; then
        echo "✅ $desc"
        echo "   phones=$actual_phones emails=$actual_emails speech=$actual_speech"
        ((PASS++))
    else
        echo "❌ $desc"
        echo "   expected: phones=$expect_phones emails=$expect_emails speech=$expect_speech"
        echo "   actual:   phones=$actual_phones emails=$actual_emails speech=$actual_speech"
        ((FAIL++))
    fi
}

echo "=== msgme channel tests ==="
echo "Config: PHONE=+17607031770, EMAIL=John@Netverse.net, DEFAULT=IMESSAGE EMAIL"
echo ""

# No flags — uses DEFAULT (IMESSAGE EMAIL)
test_case "No flags (DEFAULT)" 1 1 0

# Single channel flags
test_case "-n (add iMessage, default email stays)" 1 1 0 -n
test_case "--email (add email, default iMessage stays)" 1 1 0 --email
test_case "-s (add speech, defaults stay)" 1 1 1 -s

# Additive: -n adds ON TOP of config phone
test_case "-n +15551111111 (config + extra = 2)" 2 1 0 -n +15551111111
test_case "--email extra@test.com (config + extra = 2)" 1 2 0 --email extra@test.com

# Replace: -nr/--emailr drops config, uses only CLI values
test_case "-nr +15552222222 (replace = 1)" 1 1 0 -nr +15552222222
test_case "-er other@test.com (replace = 1)" 1 1 0 -er other@test.com
test_case "--emailr other@test.com (replace = 1)" 1 1 0 --emailr other@test.com

# Multiple values
test_case "-n +1555 +1666 (config + 2 = 3)" 3 1 0 -n +15551111111 +15552222222
test_case "--email a@t b@t (config + 2 = 3)" 1 3 0 --email a@test.com b@test.com
test_case "-nr +1555 +1666 (replace with 2)" 2 1 0 -nr +15551111111 +15552222222

# Combinations
test_case "-n -s (iMessage + speech, default email stays)" 1 1 1 -n -s
test_case "-n +1555 --email extra -s (add both + speech)" 2 2 1 -n +15551111111 --email extra@test.com -s
test_case "-nr +1559 -er solo -s (replace both + speech)" 1 1 1 -nr +15559999999 -er solo@test.com -s

# Additive with both channels explicit
test_case "-n +1555 --email a@t (add to both)" 2 2 0 -n +15551111111 --email a@test.com

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
