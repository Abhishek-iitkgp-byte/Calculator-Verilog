# Calculator-Verilog

## Overview

This project implements a parameterized 16-bit calculator in Verilog HDL.

The calculator supports the following operations:

- Addition
- Subtraction
- Multiplication (Booth Algorithm)
- Division (Non-Restoring Division)
- GCD (Euclid Algorithm)

---

## Algorithms Used

| Operation | Algorithm |
|-----------|-----------|
| Addition | Carry Lookahead Adder |
| Subtraction | Two's Complement |
| Multiplication | Booth Algorithm |
| Division | Non-Restoring Division |
| GCD | Euclid Algorithm |

---

## Files

- `calc_all.v` : Contains all Verilog modules.
- `interactive_calc_tb.v` : Testbench for simulation.
- `input.txt` : Input file containing arithmetic operations.

---

## Sample Input

```text
25 + 17
50 - 70
12 * 8
100 / 7
270 G 192
```

## Sample Output

```text
25 + 17 = 42
50 - 70 = -20
12 * 8 = 96
100 / 7 = 14
270 G 192 = 6
```

---

## Features

- Parameterized 16-bit design
- Modular Verilog implementation
- Supports multiple arithmetic operations
- File-based testbench for easy verification
