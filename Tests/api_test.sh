#!/bin/bash
# Homie API Tests
# Run with: ./Tests/api_test.sh

BASE_URL="http://127.0.0.1:8420"
PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🏠 Homie API Tests"
echo "=================="
echo ""

# Test helper
test_endpoint() {
    local name="$1"
    local method="$2"
    local path="$3"
    local expected="$4"
    local data="$5"
    
    if [ "$method" == "GET" ]; then
        response=$(curl -s "$BASE_URL$path")
    else
        response=$(curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$path")
    fi
    
    if echo "$response" | grep -q "$expected"; then
        echo -e "  ${GREEN}✓${NC} $name"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $name"
        echo "    Expected: $expected"
        echo "    Got: $response"
        ((FAILED++))
    fi
}

# Health Check
echo "📋 Health & Status"
test_endpoint "Health check returns ok" "GET" "/health" '"status"'
test_endpoint "Health includes port" "GET" "/health" '8420'

# Debug
echo ""
echo "🔍 Debug Info"
test_endpoint "Debug returns auth status" "GET" "/debug" '"authStatus"'
test_endpoint "Debug returns device count" "GET" "/debug" '"devicesLoaded"'

# Devices
echo ""
echo "💡 Devices"
test_endpoint "List devices returns array" "GET" "/devices" '"devices"'

# Get device count
device_count=$(curl -s "$BASE_URL/devices" | grep -o '"id"' | wc -l | tr -d ' ')
if [ "$device_count" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} Found $device_count devices"
    ((PASSED++))
else
    echo -e "  ${RED}✗${NC} No devices found"
    ((FAILED++))
fi

# Get first device ID for further tests
first_device_id=$(curl -s "$BASE_URL/devices" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$first_device_id" ]; then
    test_endpoint "Get device by ID" "GET" "/device/$first_device_id" '"name"'
    test_endpoint "Device has isOn property" "GET" "/device/$first_device_id" '"isOn"'
fi

# Scenes
echo ""
echo "🎬 Scenes"
test_endpoint "List scenes returns array" "GET" "/scenes" '"scenes"'

scene_count=$(curl -s "$BASE_URL/scenes" | grep -o '"id"' | wc -l | tr -d ' ')
echo -e "  ${YELLOW}ℹ${NC} Found $scene_count scenes"

# Rules
echo ""
echo "⚡ Rules"
test_endpoint "List rules returns array" "GET" "/rules" '"rules"'

# Error handling
echo ""
echo "🚫 Error Handling"
test_endpoint "404 on unknown device" "GET" "/device/fake-device-id" '"error"'
test_endpoint "404 on unknown path" "GET" "/unknown" '"error"'

# Toggle test (optional - requires confirmation)
echo ""
echo "🔀 Toggle Test (skipped - would change device state)"

# Summary
echo ""
echo "=================="
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
