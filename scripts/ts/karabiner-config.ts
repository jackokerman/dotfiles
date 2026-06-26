import { homedir } from "node:os";
import { mkdir } from "node:fs/promises";
import {
  arrowKeyCodes,
  controlOrSymbolKeyCodes,
  type DeviceIdentifier,
  type FromKeyCode,
  functionKeyCodes,
  ifDevice,
  letterKeyCodes,
  map,
  modifierKeyCodes,
  numberKeyCodes,
  rule,
  withCondition,
  withMapper,
  writeToProfile,
} from "karabiner.ts";

const PROFILE_NAME = "Default profile";
const appleMagicKeyboardWithTouchId: DeviceIdentifier = {
  product_id: 666,
  vendor_id: 1452,
};
const builtInKeyboardCondition = {
  type: "device_if",
  identifiers: [{ is_built_in_keyboard: true }],
} as const;
const nonTouchIdMagicKeyboardCondition = ifDevice(appleMagicKeyboardWithTouchId).unless();

type KarabinerDevice = {
  identifiers?: {
    is_keyboard?: boolean;
    product_id?: number;
    vendor_id?: number;
  };
  ignore?: boolean;
};

type KarabinerProfile = {
  name: string;
  devices?: KarabinerDevice[];
};

type KarabinerConfig = {
  profiles?: KarabinerProfile[];
};

function isTouchIdMagicKeyboard(device: KarabinerDevice) {
  return device.identifiers?.product_id === appleMagicKeyboardWithTouchId.product_id
    && device.identifiers?.vendor_id === appleMagicKeyboardWithTouchId.vendor_id;
}

async function normalizeKeyboardDevices(configPath: string) {
  const config = await Bun.file(configPath).json() as KarabinerConfig;
  const profile = config.profiles?.find((candidate) => candidate.name === PROFILE_NAME);

  if (!profile?.devices?.length) {
    return;
  }

  for (const device of profile.devices) {
    if (!device.identifiers?.is_keyboard || isTouchIdMagicKeyboard(device)) {
      continue;
    }

    delete device.ignore;
  }

  await Bun.write(configPath, `${JSON.stringify(config, null, 2)}\n`);
}

/**
 * Configures shared keyboard modifier remaps and disables all keys on an Apple
 * Magic Keyboard except Touch ID. Creates a default profile and config
 * directory if they don't exist.
 *
 * Run with: bun run scripts/ts/karabiner-config.ts
 */
async function main() {
  const configPath = `${homedir()}/.config/karabiner/karabiner.json`;

  // Ensure karabiner config exists with a default profile
  if (!(await Bun.file(configPath).exists())) {
    const minimalConfig = {
      global: {
        show_in_menu_bar: true,
        show_profile_name_in_menu_bar: false,
      },
      profiles: [
        {
          name: PROFILE_NAME,
          selected: true,
          complex_modifications: {
            rules: [],
          },
          devices: [],
          fn_function_keys: [],
          simple_modifications: [],
          virtual_hid_keyboard: {
            country_code: 0,
          },
        },
      ],
    };

    await mkdir(`${homedir()}/.config/karabiner`, { recursive: true });
    await Bun.write(configPath, JSON.stringify(minimalConfig, null, 2));
    console.log(`✓ Created initial Karabiner config at ${configPath}`);
  }

  writeToProfile(PROFILE_NAME, [
    rule(
      "Caps Lock: Tap for Caps Lock, Hold for Control (built-in keyboard only)",
    ).manipulators([
      withCondition(builtInKeyboardCondition)([
        map("caps_lock")
          .to("left_control")
          .toIfAlone("caps_lock"),
      ]),
    ]),
    rule(
      "Right Command: Hyper key (all keyboards except Touch ID Magic Keyboard)",
    ).manipulators([
      withCondition(nonTouchIdMagicKeyboardCondition)([
        map("right_command").toHyper(),
      ]),
    ]),
    rule(
      "Disable all keys on an Apple Magic Keyboard except Touch ID",
    ).manipulators([
      withMapper([
        ...letterKeyCodes,
        ...numberKeyCodes,
        ...controlOrSymbolKeyCodes,
        ...functionKeyCodes,
        ...modifierKeyCodes,
        ...arrowKeyCodes,
      ])((key_code: FromKeyCode) =>
        withCondition(ifDevice(appleMagicKeyboardWithTouchId))([
          map({ key_code }).to("vk_none"),
        ])
      ),
    ]),
  ]);

  await normalizeKeyboardDevices(configPath);
}

// Execute main function if this script is run directly
if (import.meta.main) {
  await main();
}
