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
} from "https://deno.land/x/karabinerts@1.30.0/deno.ts";

const PROFILE_NAME = "Default profile";
const appleMagicKeyboardWithTouchId: DeviceIdentifier = { product_id: 666 };

/**
 * Configures Karabiner-Elements to disable all keys on an Apple Magic Keyboard
 * except Touch ID. Creates a default profile and config directory if they don't
 * exist.
 *
 * Run with: deno run --allow-env --allow-read --allow-write karabiner-config.ts
 */
async function main() {
  const configPath = `${Deno.env.get("HOME")}/.config/karabiner/karabiner.json`;

  // Ensure karabiner config exists with a default profile
  try {
    await Deno.stat(configPath);
  } catch {
    // File doesn't exist, create minimal config with default profile
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

    await Deno.mkdir(`${Deno.env.get("HOME")}/.config/karabiner`, {
      recursive: true,
    });
    await Deno.writeTextFile(configPath, JSON.stringify(minimalConfig, null, 2));
    console.log(`✓ Created initial Karabiner config at ${configPath}`);
  }

  writeToProfile(PROFILE_NAME, [
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
}

// Execute main function if this script is run directly
if (import.meta.main) {
  await main();
}
