#!/bin/bash

set -e

PINMAP="./pinmap.json"
TEMPLATE_DIR="./templates"
OUTPUT_DIR="./out"

mkdir -p "$OUTPUT_DIR"

check_tools() {
  command -v jq >/dev/null || {
    echo "❌ Please install jq"
    exit 1
  }
  command -v dtc >/dev/null || {
    echo "❌ Please install device-tree-compiler"
    exit 1
  }
}

prompt_overlay_info() {
  echo "🧩 Select overlay type:"
  select type in "UART" "I2C" "SPI" "GPIO" "PWM" "ADC" "PRU"; do
    [[ -n $type ]] && break
  done

  read -p "🔤 Enter overlay name (e.g. BB-UART1): " OVERLAY_NAME
  read -p "📍 Enter pins (space-separated, e.g. P9.24 P9.26): " PINS

  PERIPHERAL=$(echo "$OVERLAY_NAME" | cut -d- -f2 | tr '[:upper:]' '[:lower:]')
  TEMPLATE="$TEMPLATE_DIR/$(echo "$type" | tr '[:upper:]' '[:lower:]').dts.template"
  DTS="$OUTPUT_DIR/${OVERLAY_NAME}-00A0.dts"
  DTBO="$OUTPUT_DIR/${OVERLAY_NAME}-00A0.dtbo"
}

generate_pinmux() {
  PINMUX_LINES=""
  EXCLUSIVE_USE=""

  for pin in $PINS; do
    entry=$(jq -r --arg pin "$pin" '.[$pin]' "$PINMAP")
    if [[ "$entry" == "null" ]]; then
      echo "❌ Pin $pin not found in pinmap.json"
      exit 1
    fi
    offset=$(echo "$entry" | jq -r .offset)
    mode=$(echo "$entry" | jq -r .mode)
    desc=$(echo "$entry" | jq -r .desc)
    PINMUX_LINES+="\n        $offset $mode  /* $pin = $desc */"
    EXCLUSIVE_USE+="\n        \"$pin\","
  done
  EXCLUSIVE_USE+="\n        \"$PERIPHERAL\";"
}

generate_dts() {
  echo "⚙️ Generating DTS file..."
  sed -e "s/{{PART_NUMBER}}/$OVERLAY_NAME/" \
    -e "s/{{PERIPHERAL}}/$PERIPHERAL/g" \
    -e "s|{{PINMUX_LINES}}|$PINMUX_LINES|" \
    -e "s|{{EXCLUSIVE_USE}}|$EXCLUSIVE_USE|" \
    "$TEMPLATE" >"$DTS"
}

compile_dtbo() {
  echo "🛠 Compiling .dtbo..."
  dtc -@ -O dtb -o "$DTBO" "$DTS"
  echo "✅ Created: $DTBO"
}

deploy_prompt() {
  read -p "📤 Deploy to BeagleBone? (y/n): " deploy
  if [[ "$deploy" == "y" ]]; then
    read -p "Target (e.g., root@192.168.7.2:/boot/overlays): " target
    scp "$DTBO" "$target"
    echo "✅ Deployed."
  fi

  read -p "📝 Append to uEnv.txt (uboot_overlay_addrX=...)? (y/n): " patch
  if [[ "$patch" == "y" ]]; then
    echo "uboot_overlay_addr4=${OVERLAY_NAME}-00A0.dtbo"
  fi
}

main() {
  check_tools
  prompt_overlay_info
  generate_pinmux
  generate_dts
  compile_dtbo
  deploy_prompt
}

main
