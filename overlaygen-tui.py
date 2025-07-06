#!/usr/bin/env python3
import npyscreen
import os
import json
import subprocess

PINMAP_FILE = "pinmap.json"
TEMPLATES_DIR = "templates"
OUTPUT_DIR = "out"

OVERLAY_TYPES = [
    "uart",
    "i2c",
    "spi",
    "gpio",
    "pwm",
    "adc",
    "can",
    "pru",
    "hdmi-disable",
]


class OverlayForm(npyscreen.ActionForm):
    def create(self):
        self.name = "🧩 BeagleBone Overlay Generator (TUI)"
        self.overlay_type = self.add(
            npyscreen.TitleSelectOne,
            name="Type",
            values=OVERLAY_TYPES,
            max_height=8,
            scroll_exit=True,
        )
        self.overlay_name = self.add(
            npyscreen.TitleText, name="Overlay Name (e.g. BB-UART1):"
        )
        self.pins = self.add(npyscreen.TitleText, name="Pins (e.g. P9.24 P9.26):")
        self.deploy = self.add(
            npyscreen.TitleSelectOne,
            name="Deploy to BeagleBone?",
            values=["Yes", "No"],
            max_height=2,
            scroll_exit=True,
        )

    def on_ok(self):
        otype = OVERLAY_TYPES[self.overlay_type.value[0]]
        name = self.overlay_name.value.strip()
        pins = self.pins.value.strip().split()
        deploy = self.deploy.value[0] == 0

        with open(PINMAP_FILE) as f:
            pinmap = json.load(f)

        pinmux_lines = ""
        exclusive_use = ""
        for pin in pins:
            if pin not in pinmap:
                npyscreen.notify_confirm(
                    f"Pin {pin} not found in pinmap.", title="Error"
                )
                return
            entry = pinmap[pin]
            pinmux_lines += f"        {entry['offset']} {entry['mode']}  /* {pin} = {
                entry['desc']
            } */\n"
            exclusive_use += f'        "{pin}",\n'
        exclusive_use += f'        "{otype}";'

        # Read and render template
        template_path = os.path.join(TEMPLATES_DIR, f"{otype}.dts.template")
        with open(template_path) as tf:
            tpl = tf.read()

        dts = (
            tpl.replace("{{PART_NUMBER}}", name)
            .replace("{{PERIPHERAL}}", otype)
            .replace("{{PINMUX_LINES}}", pinmux_lines.strip())
            .replace("{{EXCLUSIVE_USE}}", exclusive_use.strip())
        )

        os.makedirs(OUTPUT_DIR, exist_ok=True)
        dts_path = os.path.join(OUTPUT_DIR, f"{name}-00A0.dts")
        dtbo_path = os.path.join(OUTPUT_DIR, f"{name}-00A0.dtbo")

        with open(dts_path, "w") as out_dts:
            out_dts.write(dts)

        try:
            subprocess.run(
                ["dtc", "-@", "-O", "dtb", "-o", dtbo_path, dts_path], check=True
            )
        except subprocess.CalledProcessError:
            npyscreen.notify_confirm(
                "dtc failed. Ensure dtc is installed.", title="Build Failed"
            )
            return

        if deploy:
            dest = npyscreen.notify_input("Enter SCP target (user@ip:/path):")
            subprocess.run(["scp", dtbo_path, dest])

        npyscreen.notify_confirm(f"Overlay generated:\n\n{dtbo_path}", title="Success")
        self.parentApp.setNextForm(None)

    def on_cancel(self):
        self.parentApp.setNextForm(None)


class OverlayApp(npyscreen.NPSAppManaged):
    def onStart(self):
        self.addForm("MAIN", OverlayForm)


if __name__ == "__main__":
    OverlayApp().run()
