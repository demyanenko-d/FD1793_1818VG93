# 1818VG93 / WD FD1793 — synthesizable Verilog model

## Благодарности

Спасибо **deathsoft** за транзисторную схему кристалла 1818ВГ93 и дамп ПЗУ микропрограммы и **titus** за вентильный RTL
и расшифровку микрокода. Без их реверса этой модели не было бы.

## Thanks

Thanks to **deathsoft** for the transistor-level schematic of the 1818VG93 die and the microcode ROM dump, and to
**titus** for the gate-level RTL and the decoding of the microcode. This model would not exist without their reverse
engineering.

## Что это

Модель контроллера дисковода 1818ВГ93 (советский аналог WD FD1793) на Verilog-2001, синтезируемая в ПЛИС.

- **На основе реверса кристалла.** Модель построена не по даташиту, а по вентильной схеме, восстановленной с
  транзисторной схемы кристалла. Каждый блок и сигнал имеет ссылку на элемент схемы (U…, q…).
- **Приведена к поведенческому дизайну, насколько это возможно.** Вместо сотен защёлок и двухфазных тактов F1 / F2
  кристалла — синхронная схема на одном системном такте SYSCLK, читаемые блоки (таймер, декодер микрокоманд,
  секвенсор, регистры, канал данных, счётчики, привод, статус, тракт чтения, CRC, тракт записи, шина хоста) и
  именованные действия вместо битов микрослова. Там, где поведение кристалла держится на гонках и асинхронных
  защёлках, модель повторяет их результат, а не устройство.
- **Использует настоящий микрокод.** Секвенсор исполняет ПЗУ микропрограммы, снятое с кристалла (дамп deathsoft,
  расшифровка titus; 256 слов по 19 бит, `rtl/vg93-microcode-rom.hex`), — не переписанный заново автомат. Поэтому все команды, тайминги и
  особенности (включая недокументированные) такие же, как у микросхемы.
- **Особенности кристалла сохранены.** В том числе дефект детекторов синхрометок A1 / C2 (не смотрят на бит 13
  канального слова), на котором держатся защиты игр; поведение FD1793 включается макросом.
- **Сверено со схемой кристалла:** состояние после каждой микрокоманды и выводы на 71 сценарии, с турбо 1 / 2 МГц и
  плавающей скоростью диска; проверено в ПЛИС (Terasic DE1) с TR-DOS, виртуальным и реальным дисководом 3,5″.

## What it is

A model of the 1818VG93 floppy disk controller (the Soviet counterpart of the WD FD1793) in Verilog-2001, synthesizable
for FPGAs.

- **Based on the reverse engineering of the die.** It is built from the gate-level schematic recovered from the
  transistor-level schematic of the chip, not from the datasheet. Blocks and signals refer to the schematic elements
  (U…, q…).
- **Brought to a behavioural design as far as possible.** Instead of the hundreds of latches and the two-phase F1 / F2
  clocks of the die: a synchronous design on one system clock SYSCLK, readable blocks (timing, microword decoder,
  sequencer, task registers, data channel, counters, drive, status, read path, CRC, write path, host bus) and named
  actions instead of microword bits. Where the chip relies on races and asynchronous latches, the model reproduces
  their result, not their structure.
- **Uses the real microcode.** The sequencer runs the microprogram ROM taken from the die (dump by deathsoft, decoded
  by titus; 256 words of 19 bits, `rtl/vg93-microcode-rom.hex`), not a rewritten state machine, so all commands, timings and quirks (undocumented ones
  included) are those of the chip.
- **The quirks of the die are kept**, among them the defect of the A1 / C2 sync mark detectors (channel bit 13 is not
  compared), which game copy protections rely on; the FD1793 behaviour is a build option.
- **Checked against the die schematic:** the state after every microword and the pins on 71 scenarios, with 1 / 2 MHz
  turbo and a varying disk speed; run in an FPGA (Terasic DE1) with TR-DOS, a virtual and a real 3.5″ drive.

## Файлы

- `rtl/vg93_top.v` — верхний модуль; `rtl/vg93_*.v` — блоки; `rtl/*.vh` — include-файлы.
- `rtl/vg93-microcode-rom.hex` — ПЗУ микрокода (`$readmemh`).
- `datasheet/fd1793_1818vg93.md` (английский) и `datasheet/fd1793_1818vg93_ru.md` (русский) — даташит, исправленный по кристаллу: все ошибки и противоречия даташита
  WD FD179X-02 исправлены, описано реальное поведение микросхемы, список исправлений; приложение — микропрограмма
  (формат микрослова, микрооперации, всё ПЗУ). `datasheet/microcode/` — дамп ПЗУ и листинг с расшифровкой titus.

## Files

- `rtl/vg93_top.v` — the top module; `rtl/vg93_*.v` — the blocks; `rtl/*.vh` — include files.
- `rtl/vg93-microcode-rom.hex` — the microcode ROM (`$readmemh`).
- `datasheet/fd1793_1818vg93.md` (English) and `datasheet/fd1793_1818vg93_ru.md` (Russian) — the datasheet corrected to the die: every error and contradiction of the WD FD179X-02
  datasheet fixed, the real behaviour of the chip described, the list of corrections; appendix — the microprogram
  (microword format, micro-operations, the whole ROM). `datasheet/microcode/` — the ROM dump and titus's decoded
  listing.

## Как использовать

1. Такты:
   - `SYSCLK` — от того же генератора, что `CLK` и `RCLK`, не меньше 8 × CLK (8 МГц при CLK 1 МГц, 16 МГц при турбо
     2 МГц). Фронты CLK и RCLK обрабатываются как события, частоту CLK можно переключать на ходу (турбо).
   - `CLK` — меандр 1 МГц (2 МГц — турбо): импульс WD в MFM длится низкую фазу CLK.
   - `RCLK` / `RAWREAD_n` — от сепаратора данных (окно RCLK = одна ячейка в MFM).
2. Выходы:
   - `DRQ`, `INTRQ`, `WF_n_VFOE_n` — открытый сток, как у микросхемы. Внутри большой ПЛИС соберите с макросом
     `VG93_EMBEDDED`: они станут двухтактными (DRQ / INTRQ — активная единица).
   - `WD` — комбинационный, как на кристалле: перед выводом ПЛИС к дисководу пропустите его через триггер, иначе
     иголки на фронтах SYSCLK дисковод запишет как лишние переходы.
3. Только MFM — подайте `DDEN_n = 0`, синтез уберёт логику FM.
4. Макросы (все необязательные):
   - `VG93_ROM_FILE` — путь к ПЗУ микрокода;
   - `VG93_EMBEDDED` — DRQ / INTRQ / VFOE двухтактные;
   - `VG93_FD1793_MARKS` — синхрометки A1 / C2 как у WD FD1793 (бит 13 сравнивается); по умолчанию — дефект ВГ93;
   - `VG93_UTRACE`, `VG93_CHECKS` — отладка, только для симуляции.

## How to use

1. Clocks:
   - `SYSCLK` — from the oscillator of `CLK` and `RCLK`, at least 8 × CLK (8 MHz for a 1 MHz CLK, 16 MHz for a 2 MHz
     turbo). CLK and RCLK edges are handled as events, CLK may change its frequency on the fly (turbo).
   - `CLK` — a 1 MHz square wave (2 MHz turbo): an MFM WD pulse lasts the CLK low phase.
   - `RCLK` / `RAWREAD_n` — from the data separator (an RCLK window is one cell in MFM).
2. Outputs:
   - `DRQ`, `INTRQ`, `WF_n_VFOE_n` are open drain, as on the chip. Inside a larger FPGA design build with
     `VG93_EMBEDDED`: they become push-pull (DRQ / INTRQ active high).
   - `WD` is combinational, as on the die: register it before an FPGA pin to a drive, or its glitches at the SYSCLK
     edges are written as extra flux transitions.
3. MFM only — tie `DDEN_n` to 0, synthesis removes the FM logic.
4. Macros (all optional):
   - `VG93_ROM_FILE` — path of the microcode ROM;
   - `VG93_EMBEDDED` — DRQ / INTRQ / VFOE push-pull;
   - `VG93_FD1793_MARKS` — A1 / C2 sync marks as on the WD FD1793 (bit 13 compared); default: the VG93 defect;
   - `VG93_UTRACE`, `VG93_CHECKS` — debugging, simulation only.

## Ресурсы / Resources

Cyclone IV E EP4CE10E22C8, Quartus 22.1:

| | |
|---|---|
| логических элементов / logic elements | 607 / 10 320 (6 %) |
| регистров / registers | 252 |
| память / memory (микрокод в M9K / microcode in M9K) | 4 864 бит / bits |
| Fmax (SYSCLK) | 51,7 МГц / MHz |

На Cyclone II (DE1, вместе с Pentagon 128 и Beta Disk) модель работает на SYSCLK 28 МГц.
On a Cyclone II (DE1, together with a Pentagon 128 and a Beta Disk) the model runs at SYSCLK 28 MHz.
