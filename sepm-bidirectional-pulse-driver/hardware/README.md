# S-EPM Power-Driver Hardware

## Purpose

The hardware stage provides the bidirectional high-current pulse required to change the magnetic state of the S-EPM. A full H-bridge is used so the direction of current through the coil can be reversed electronically.

The FPGA or microcontroller supplies only logic-level control signals. The H-bridge supplies the coil current.

## Prototype Measurements

A prototype S-EPM coil was measured at approximately **5.9 ohms**.

During bench testing:

| Supply | Measured coil current | Observation |
|---|---:|---|
| Below 16 V | - | Switching was not reliable |
| 18-20 V | ~3 A at 20 V | Reliable switching threshold region |
| 30 V | ~5 A | Strong bidirectional switching |

The current measurements were taken with a current probe during short switching pulses.

## Driver Choice

The compact single-channel prototype used the **ST L6203 full-bridge driver**.

The L6203 was selected for the higher-resistance S-EPM prototype because it provides a complete bidirectional bridge in a compact implementation. The hardware included bulk capacitance and transient protection for the inductive load.

Supporting components used during development included:

- 470 uF / 63 V bulk capacitor
- Bootstrap / decoupling capacitors around the bridge
- P6KE30CA TVS protection
- Optional optocoupler isolation during interface development

## Pulse Operation

A typical pulse duration was approximately **1 ms**. The coil is energised only during the switching event; continuous current is not required to maintain the magnetic state.

The two bridge polarities correspond to:

```text
Forward: IN1 = 1, IN2 = 0
Reverse: IN1 = 0, IN2 = 1
Off:     IN1 = 0, IN2 = 0
```

The unsafe `IN1 = 1, IN2 = 1` condition is prevented by the digital controller.

## LTspice Reference Case

The reference simulation used:

- V = 30 V
- R = 4 ohms
- L = 192.3 uH
- tau = L/R = 48.1 us
- I(infinity) = V/R = 7.5 A

This model was used to study transient current behaviour and pulse duration. It is a reference design case rather than the exact measured 5.9-ohm prototype coil.

## Development Progression

The hardware work progressed through:

1. S-EPM coil resistance and switching-threshold measurements
2. LTspice modelling of the inductive load
3. Bidirectional H-bridge evaluation
4. L6203 single-channel prototype
5. Arduino-based forward/reverse pulse testing
6. Compact PCB development
7. Migration of pulse timing and safety control to FPGA

The present FPGA stage scales the digital control to four channels, while the power stage remains external to the Basys 3.
