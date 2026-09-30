# plock2sound

A mod for the Digitone (mk1) and Digitone Keys, OS 1.43, that turns one
step's parameter locks into a sound you can save:

1. Hold **one step TRIG** plus **that step's TRK key**, tap **RECORD**,
   release.
2. Open the **SOUND MANAGER**, pick a free slot, press **FUNC+STOP**.

The saved sound is the track sound with that step's parameter locks baked
into it. Name, tags and arp data are kept. In one gesture, a p-locked step
becomes a preset you can load anywhere.

It is an [elekloader](https://github.com/irpina/elekloader) mod.
elekloader builds a custom OS file on your own machine, from your stock OS
file and the mods you pick; nothing from Elektron is distributed.

## What changes, and what does not

The stock Digitone can copy a track's sound (TRK + RECORD) and copy a trig
(TRIG + RECORD), but there is no way to lift one step's locks into a sound.
The mod hooks the sound-copy call:

- **Exactly one step TRIG held** (with the one synth TRK the stock handler
  already requires): the copy it pushes is a private one with the step's 79
  lock values baked over the track sound. The toast is the stock
  `COPY TRK n SOUND`; paste with FUNC+STOP as usual.
- **Everything else stays stock.** No TRIG held, several steps, a TRK
  combination the stock gate rejects, a MIDI track: the ordinary copy runs.
  Plain TRIG+RECORD trig copy is untouched.
- **A sound-locked (pool-sound) step is left to stock too**: baking onto
  the base sound would quietly edit the wrong sound.

Locks hold all four synth tracks, steps 1–64 and the 79 stock lock ids;
an unlock (`0xffff`) leaves the track sound's value, and zero is a valid
lock. Baking is a copy: the pattern and the track sound are never written.

## Install

You need three things:

- **elekloader**:
  - **Windows:** download `elekloader-<version>-windows.exe` from
    [elekloader's releases](https://github.com/irpina/elekloader/releases/latest)
    and run it. The core mod, which every linkable mod needs, is built in
    (the Digitone's from elekloader 0.4.0).
  - **Other systems:** run elekloader from source with Python 3.9 or newer
    (see [its README](https://github.com/irpina/elekloader#install)). There
    you also need the Digitone's core (`core-dn1-2.0a.elemod`), attached to
    this repository's releases too.
- **This mod:** `plock2sound-1.0.elemod` from
  [this repository's releases](https://github.com/irpina/plock2sound/releases/latest).
- **The stock OS file:** `Digitone_and_Digitone_Keys_OS1.43.syx`, from
  [Elektron's Digitone downloads](https://www.elektron.se/support-downloads/digitone)
  (the `.zip` works as it is). elekloader recognises the file by its hash.

Then build your OS in elekloader's window:

1. **Your stock OS file:** elekloader asks for it the first time; **Change
   stock firmware...** (top right) picks another.
2. **+ Install from file...**: choose `plock2sound-1.0.elemod`. From source,
   install the core the same way.
3. **Tick P-lock to sound.** core is ticked with it. The check below the
   list should say "No conflicts ... Ready to build". To add other mods,
   such as [digihealth](https://github.com/irpina/digihealth), install and
   tick them as well.
4. **OS version shown**: the 4 characters the unit will show, for example
   `P2S1`.
5. **BUILD FIRMWARE**, and save the `.syx`. elekloader verifies it before
   writing it.

Flash it with Elektron Transfer, as for any OS update
([Elektron's instructions](https://support.elektron.se/support/solutions/articles/43000662890-how-to-update-your-device)):
1. Connect the unit over USB.
2. In Transfer, select the unit and **Connect**.
3. Drag the `.syx` onto **Drop files here**.
4. Press **YES** on the unit.

Don't turn it off until the upgrade is done.

Or on the command line (elekloader from source):

```bash
python -m elekloader.patch --stock Digitone_and_Digitone_Keys_OS1.43.syx \
    --mod core-dn1-2.0a.elemod --mod plock2sound-1.0.elemod \
    --out Digitone_OS1.43-plock2sound.syx --version P2S1
```

**Recovery:** elekloader never changes the bootloader, so the stock OS
file always restores the unit. Hold **FUNC** while powering on for the
startup menu, and press **TRIG 4** for OS UPGRADE. Then send the stock
`.syx` with Transfer's legacy OS upgrade mode.

## Build it from source

The Digitone cross toolchain (m68k binutils and gcc; on Debian or Ubuntu,
`apt install binutils-m68k-linux-gnu gcc-m68k-linux-gnu`; on Windows,
inside WSL) and elekloader, importable (installed, or on `PYTHONPATH`):

```bash
python -m elekloader.sdk.build . --stock Digitone_and_Digitone_Keys_OS1.43.syx --out out
python -m elekloader.lint out/plock2sound-1.0.elemod --stock Digitone_and_Digitone_Keys_OS1.43.syx --with core-dn1-2.0a.elemod
```

| file | |
|---|---|
| `mod.json` | the mod: its one hook site, source and name |
| `plock2sound.s` | the hook: gate checks, the lock bake and the stock replay |

The same build and lint run on every push and pull request in the
[build workflow](.github/workflows/build.yml), which uploads the `.elemod`
as an artifact, and attaches it to a GitHub release on `v*` tags. The
workflow fetches the stock OS file from
[Elektron's Digitone downloads](https://www.elektron.se/support-downloads/digitone)
itself (its sha256 is pinned), so nothing needs setting up.
If Elektron ever replaces the file, the workflow fails on the hash check:
update the URL and the pinned hash in the download step then.

## How it was checked

The mod is one 6-byte hook on the sound-copy call plus the handler above.
Its addresses were measured on the stock OS 1.43 image and it was checked:

- **Hook matrix:** 265 executed cases on an emulator of the CPU: every step
  on every synth track; no, one and several steps held in each mask half;
  sound-locked steps; the ABI (every register the stock call may rely on);
  the exact baked overlay, including zero and `0xffff` locks. All pass, and
  every non-feature path replays the stock call unmodified.
- **The real panel and OS:** in [digiemu](https://github.com/irpina/digiemu),
  which runs the stock OS through the real bootloader: T1 + TRIG 1 + RECORD
  reaches the hook, and the pushed copy carries the step's locks; a full
  boot and run against stock passes, with all screens identical.
- **On a unit:** the same hook design, placed inline instead of by
  elekloader, passed a full device test matrix on a Digitone mk1: bake and
  save on steps 1 and 33 and track 4, exact locked values, unlocked steps,
  and the regression cases (no TRK, several TRKs, several steps, MIDI
  track, sound-locked step, plain TRK+RECORD) all behaving as stock.

## Licence

GPL-2.0: see [LICENSE](LICENSE). Not affiliated with Elektron. Digitone is
a trademark of Elektron. Custom firmware is at your own risk.
