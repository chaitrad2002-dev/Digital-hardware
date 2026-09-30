@echo off
REM Edit these three paths for your installed SKY130 PDK.
REM Example filenames are shown; exact base directory depends on your installation.
set SKY130_LIB_TT=C:\sky130\libs.ref\sky130_fd_sc_hd\lib\sky130_fd_sc_hd__tt_025C_1v80.lib
set SKY130_LIB_MAX=C:\sky130\libs.ref\sky130_fd_sc_hd\lib\sky130_fd_sc_hd__ss_100C_1v60.lib
set SKY130_LIB_MIN=C:\sky130\libs.ref\sky130_fd_sc_hd\lib\sky130_fd_sc_hd__ff_n40C_1v95.lib

if not exist reports mkdir reports

echo === Yosys synthesis ===
yosys -c scripts\synth_sky130.tcl
if errorlevel 1 exit /b 1

echo === OpenSTA setup ===
sta scripts\sta_setup.tcl
if errorlevel 1 exit /b 1

echo === OpenSTA hold ===
sta scripts\sta_hold.tcl
if errorlevel 1 exit /b 1

echo === Done. Check the reports folder. ===
