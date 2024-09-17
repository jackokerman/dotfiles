import {
  arrowKeyCodes,
  controlOrSymbolKeyCodes,
  DeviceIdentifier,
  FromKeyCode,
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

const appleMagicKeyboardWithTouchId: DeviceIdentifier = { product_id: 666 };

// ! Change '--dry-run' to your Karabiner-Elements Profile name.
// (--dry-run print the config json into console)
// + Create a new profile if needed.
writeToProfile("Default profile", [
  rule(
    "Disable all keys on an Apple Magic Keyboard except Touch ID"
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

// Install by running
// `deno run --allow-env --allow-read --allow-write karabiner-config.ts`
