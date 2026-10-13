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

- `rtl/vg93_top.v` — верхний модуль; `rtl/vg93_*.v` — блоки; `rtl/*.vh` — include-файлы; `rtl/vg93_config.vh` —
  макросы сборки в коде (пустой: микросхема как есть).
- `rtl/vg93-microcode-rom.hex` — ПЗУ микрокода (`$readmemh`).
- `epm570/` — проект Quartus для MAX II EPM570 (микрокод в UFM, обвязка Beta Disk как у Pentagon 1024zp, сепаратор
  и предкомпенсация для дисковода, подключённого напрямую); общий код берёт из `rtl/`.
- `datasheet/fd1793_1818vg93.md` (английский) и `datasheet/fd1793_1818vg93_ru.md` (русский) — даташит, исправленный по кристаллу: все ошибки и противоречия даташита
  WD FD179X-02 исправлены, описано реальное поведение микросхемы, список исправлений; приложение — микропрограмма
  (формат микрослова, микрооперации, всё ПЗУ). `datasheet/microcode/` — дамп ПЗУ и листинг с расшифровкой titus.

## Files

- `rtl/vg93_top.v` — the top module; `rtl/vg93_*.v` — the blocks; `rtl/*.vh` — include files; `rtl/vg93_config.vh` —
  the build macros in code (empty: the chip as it is).
- `rtl/vg93-microcode-rom.hex` — the microcode ROM (`$readmemh`).
- `epm570/` — a Quartus project for a MAX II EPM570 (microcode in the UFM, Beta Disk glue as on the Pentagon 1024zp,
  data separator and write precompensation for a drive wired straight to the device); takes the common code from
  `rtl/`.
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
3. Макросы — см. раздел «Макросы сборки» ниже.

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
3. Macros — see "Build macros" below.

## Макросы сборки

Все необязательные. Без макросов модель совпадает со схемой кристалла по выводам и по трассе микрослов. Задаются в
коде — `rtl/vg93_config.vh` (по умолчанию пустой; свой вариант кладут раньше по пути поиска, так сделано в
`epm570/`), — или в проекте Quartus / через `+define` симулятора.

| макрос | что делает |
|---|---|
| `VG93_ROM_FILE` | путь к образу ПЗУ микрокода (по умолчанию `vg93-microcode-rom.hex`) |
| `VG93_EMBEDDED` | модель внутри большой ПЛИС: DRQ, INTRQ (активная единица) и /VFOE двухтактные вместо открытого стока |
| `VG93_FD1793_MARKS` | синхрометки A1 / C2 как у WD FD1793 (бит канала 13 сравнивается). По умолчанию — дефект ВГ93: бит 13 не сравнивается, 0x6489 / 0x7224 синхронизируют как A1 / C2 (на это опираются защиты) |
| `VG93_MFM_ONLY` | нет вывода DDEN_n: только MFM (как DDEN_n = 0); синтез убирает логику FM — детекторы FM-меток, FM-конвейеры записи, FM-фазы ячейки |
| `VG93_NO_TEST` | нет вывода TEST_n: задержка шагов всегда отсчитывается (как TEST_n = 1) |
| `VG93_NO_RG` | нет вывода RG (логика read gate убирается) |
| `VG93_NO_PIN33` | нет вывода 33: ни входа /WF (вектор ошибки записи), ни выхода /VFOE (как вывод 33, подтянутый к единице; на платах Beta Disk он свободен) |
| `VG93_TURBO_STEP` | скорость шагов как при CLK 2 МГц, ядро на 1 МГц: настройки 6 / 12 / 20 / 30 мс дают 3 / 6 / 10 / 15 мс; вдвое короче и задержки в тех же тиках (успокоение и загрузка головки). Длина импульса STEP (4 мкс), времена слов, ячеек, чтения и записи не меняются |
| `VG93_FAST_SYSCLK` | для SYSCLK от 40 МГц (при 16 МГц не включать): убраны две входные ступени, которые делают модель точной при любой SYSCLK; каждая сдвигает событие не больше чем на такт SYSCLK (ниже) |

`VG93_FAST_SYSCLK` подробно:

- /RAWREAD без асинхронной ловушки — используется только уровень, выбранный по SYSCLK. Импульс короче такта SYSCLK
  может пропасть (16 МГц: < 62,5 нс, 50 МГц: < 20 нс; импульсы дисковода и сепаратора обычно от 100 нс, у некоторых
  сепараторов 50…125 нс). Половина ячейки (уровень RCLK) берётся в первой выборке, а не на фронте импульса: импульс,
  начавшийся меньше чем за такт SYSCLK до фронта RCLK, попадёт в следующую половину (окно 20 нс из 500 нс при 50 МГц —
  импульс на краю окна сепаратора, где чтение и так на грани). Пропадает домен posedge /RAWREAD — остаётся один
  SYSCLK.
- Регистр данных записи (REG_DAL_IN) грузится прямо с выводов DAL, без регистра-копии: та же выборка, на такт
  раньше. Заметно, только если запись хоста накладывается на разрешение предыдущей записи в тот же регистр.
- Времена слов и ячеек, WD и трасса микрослов — как без макроса.

Сборка `epm570/` включает `VG93_MFM_ONLY`, `VG93_NO_TEST`, `VG93_NO_RG`, `VG93_NO_PIN33`, `VG93_FAST_SYSCLK`,
`VG93_TURBO_STEP`, `VG93_EMBEDDED` и `BDI_SNOOP_7FFD` (признак ПЗУ 48 — по записи в #7FFD; макрос `bdi_top`).

## Build macros

All optional. Without macros the model matches the die schematic at the pins and in the microword trace. Set in code
— `rtl/vg93_config.vh` (empty by default; a variant puts its own earlier in the search path, as `epm570/` does) — or
in the Quartus project / with the simulator's `+define`.

| macro | what it does |
|---|---|
| `VG93_ROM_FILE` | path of the microcode ROM image (default `vg93-microcode-rom.hex`) |
| `VG93_EMBEDDED` | the model inside a larger FPGA: DRQ, INTRQ (active high) and /VFOE push-pull instead of open drain |
| `VG93_FD1793_MARKS` | A1 / C2 sync marks as on the WD FD1793 (channel bit 13 compared). Default: the VG93 defect — bit 13 not compared, 0x6489 / 0x7224 sync like A1 / C2 (copy protections rely on it) |
| `VG93_MFM_ONLY` | no DDEN_n pin: MFM only (as DDEN_n = 0); synthesis removes the FM logic — FM mark detectors, FM write pipelines, FM cell phases |
| `VG93_NO_TEST` | no TEST_n pin: the step rate is always counted (as TEST_n = 1) |
| `VG93_NO_RG` | no RG output (the read gate logic is removed) |
| `VG93_NO_PIN33` | no pin 33: neither the /WF input (write fault vector) nor the /VFOE output (as pin 33 pulled up; Beta Disk boards leave it open) |
| `VG93_TURBO_STEP` | step rate as with CLK 2 MHz, the core at 1 MHz: the 6 / 12 / 20 / 30 ms settings give 3 / 6 / 10 / 15 ms; the delays counted in the same ticks (head settle, head load) are halved too. The STEP pulse (4 µs), word, cell, read and write timing stay as they are |
| `VG93_FAST_SYSCLK` | for SYSCLK from 40 MHz (keep it off at 16 MHz): two input stages that make the model exact at any SYSCLK are left out; each moves an event by at most one SYSCLK period (below) |

`VG93_FAST_SYSCLK` in detail:

- /RAWREAD without the asynchronous catcher — only the SYSCLK-sampled level is used. A pulse shorter than a SYSCLK
  period can be missed (16 MHz: < 62.5 ns, 50 MHz: < 20 ns; drive and separator pulses are usually >= 100 ns, some
  separators give 50..125 ns). The half cell (RCLK level) is taken at the first sample instead of at the pulse edge:
  a pulse starting less than a SYSCLK period before an RCLK edge counts in the next half (a 20 ns window of a 500 ns
  half cell at 50 MHz — a pulse at the edge of the separator window, where the read is marginal anyway). The posedge
  /RAWREAD domain goes away: one SYSCLK domain.
- The write data register (REG_DAL_IN) loads straight from the DAL pins, no copy register: the same sample, one
  SYSCLK earlier. Visible only when a host write overlaps the enable of the previous write to the same register.
- Word and cell timing, WD and the microword trace are as without the macro.

The `epm570/` build sets `VG93_MFM_ONLY`, `VG93_NO_TEST`, `VG93_NO_RG`, `VG93_NO_PIN33`, `VG93_FAST_SYSCLK`,
`VG93_TURBO_STEP`, `VG93_EMBEDDED` and `BDI_SNOOP_7FFD` (ROM 48 from the #7FFD write; a `bdi_top` macro).

## Ресурсы / Resources

Cyclone IV E EP4CE10E22C8, Quartus 22.1:

| | |
|---|---|
| логических элементов / logic elements | 580 / 10 320 (6 %) |
| регистров / registers | 252 |
| память / memory (микрокод в M9K / microcode in M9K) | 4 864 бит / bits |
| Fmax (SYSCLK) | 50,9 МГц / MHz |

На Cyclone II (DE1, вместе с Pentagon 128 и Beta Disk) модель работает на SYSCLK 28 МГц.
On a Cyclone II (DE1, together with a Pentagon 128 and a Beta Disk) the model runs at SYSCLK 28 MHz.

EPM570T100C5 (MAX II), Quartus 22.1, проект `epm570/` (модель + обвязка Beta Disk + сепаратор и предкомпенсация) /
the `epm570/` project (model + Beta Disk glue + separator and precompensation):

| | |
|---|---|
| логических элементов / logic elements | 562 / 570 (99 %) |
| регистров / registers | 279 |
| UFM (микрокод / microcode, 512 × 16) | 1 / 1 |
| выводов / pins | 45 / 76 |
| Fmax (SYSCLK, худший случай / slow corner) | 55,1 МГц / MHz (нужно / needed 50) |

Без обвязки Beta Disk (только `vg93_top` с макросами MAX II) — около 486 LE / without the Beta Disk glue (`vg93_top`
alone with the MAX II macros) — about 486 LE.

## EPM570 (MAX II)

`epm570/` — проект Quartus (22.1) для EPM570T100C5: `quartus_sh --flow compile epm570` в этой папке. Верхний модуль
`epm570_board` — плата с генератором 50 МГц (вывод 64), шиной Спектрума и 3,5″ дисководом прямо на выводах; номера
выводов в `epm570.qsf`.

- Микрокод — в UFM (512 × 16, слово 19 бит = два слова UFM, `vg93-ufm19.mif`), перекодирован ради меньшего
  декодера; `vg93_urom.v` читает слово последовательно после того, как известен его адрес (58 тактов SYSCLK из
  4 мкс слова). `vg93_dcnt.v` — счётчики на цепочке переноса MAX II. Эти файлы и `vg93_ucode.vh`, `vg93_config.vh`
  подменяют одноимённые из `rtl/` (SEARCH_PATH: сначала эта папка).
- Сборка: только MFM, без TEST, RG и вывода 33, SYSCLK 50 МГц, турбо-шаг.
- `bdi_top.v` — Beta Disk: порты #1F/#3F/#5F/#7F/#FF по A1 и A5…A7 при активном DOS, вход в TR-DOS выборкой команды
  на #3Dxx при ПЗУ 48 (по записи в #7FFD), выход — выборкой вне ПЗУ; `DOS_n` — единственный выход для страниц ПЗУ;
  `DOS_BOOT` — состояние DOS после сброса, `DOS_DIS` — блокировка (DivMMC). Разводка дисковода как у Pentagon 1024zp:
  HLD — READY, общий мотор START/ и разрешение выбора; HLT подмешивается в /IP (VD1).
- `fdd_glue.v` — сепаратор данных (по алгоритму fapch_zek, ZEK, ZX-Evolution / TS-Config) и предкомпенсация записи.
- Ресурсы — в таблице выше.

`epm570/` — a Quartus (22.1) project for the EPM570T100C5: `quartus_sh --flow compile epm570` in that folder. The top
`epm570_board` is a board with a 50 MHz oscillator (pin 64), the Spectrum bus and a 3.5″ drive wired straight to the
pins; pin numbers in `epm570.qsf`.

- The microcode is in the UFM (512 × 16, a 19-bit word = two UFM words, `vg93-ufm19.mif`), re-encoded for a smaller
  decoder; `vg93_urom.v` reads a word serially once its address is known (58 SYSCLK of a 4 µs word). `vg93_dcnt.v` —
  counters on the MAX II carry chain. These files and `vg93_ucode.vh`, `vg93_config.vh` replace the same-named ones
  of `rtl/` (SEARCH_PATH: this folder first).
- Build: MFM only, no TEST, RG and pin 33, SYSCLK 50 MHz, turbo step.
- `bdi_top.v` — Beta Disk: ports #1F/#3F/#5F/#7F/#FF by A1 and A5..A7 while DOS is active, TR-DOS entered by an
  opcode fetch at #3Dxx with ROM 48 (from the #7FFD write), left by a fetch outside the ROM; `DOS_n` is the only ROM
  paging output; `DOS_BOOT` — the DOS state after reset, `DOS_DIS` — block (DivMMC). Drive wiring as the Pentagon
  1024zp: HLD is READY, the common motor START/ and the select enable; HLT is mixed into /IP (VD1).
- `fdd_glue.v` — data separator (after fapch_zek by ZEK, ZX-Evolution / TS-Config) and write precompensation.
- Resources — the table above.
