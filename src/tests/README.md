# How to Run Replication

## Quick Test
`test_basics.m` needs no external data: it generates a small model, runs SMOKE on it, and checks the result (removal, scope, structure). Run it after every change to SMOKE:
```
matlab -nodisplay -batch "addpath(genpath('<SMOKE>/src')); addpath(genpath('<Simulink-Utility>')); test_basics"
```
Use `-nodisplay` (or unset `DISPLAY`) for all test runs: Simulink then prints dialogs (broken callbacks, missing libraries, mask errors) to the command window instead of opening windows for each of them.

## Results
The raw results will be saved to `results_scalability.csv`. We also provide a `SMOKE.xlsx` file with some further analysis used in our publication.

## Prerequisites
- Download the 3.9GB dataset of Simulink projects [SLNET](https://zenodo.org/records/5259648). Unzip it at some `SLNET Location` on your computer. Unzip all project files within the subfolders, as well.
- Download and install a recent MATLAB (we used MATLAB R2024b in our experiments). During the install check to download all available toolboxes for MATLAB, Simulink inclusive. If you have more toolboxes, models can get analyzed deeper and with less errors.
- Download the package of useful MATLAB/Simulink scripts [Simulink Utility](https://github.com/McSCert/Simulink-Utility). Add it and its subfolders to your [MATLAB path](https://ch.mathworks.com/help/matlab/ref/path.html).
- For a full analysis, use a MATLAB with graphics display activated. The obfuscation fully works without a display, but a few parts of the analysis -- specifically the simulation part -- are only working with a graphical display. Everything else should still work, as intended.


## Configuration
- In the file `test_scalability.m` in `src/tests`, adapt the lines 6-9. We give two examples of Windows-style and Unix-style notation.
- Choose the `SLNET Location` for the variable `SLNET_PATH`.
- Choose a directory on your system for `TMP_MODEL_SAVE_PATH`, where the un/obfuscated models and the main result file `results_scalability.csv` should get stored.
- In lines 23-25 you can also choose, whether you want a complete replication or just a partial one. The complete replication analyzes more than 9000 models and takes ca. 4 days on our machine. The partial one, that is pre-configured takes around 20 minutes on our machine.
- If you want the complete replication, comment out the lines 23 and 24 with a `%` symbol, and uncomment line 25.


## Run the Replication
To run the replication, run the MATLAB script `test_scalability.m` in `src/tests`. The output, i.e. un/obufuscated models and main results will be put into your chosen `TMP_MODEL_SAVE_PATH`.



## General Remarks
While executing, expect a number of compilation or simulation notes, figures, warnings, and errors be reported. 
Errors result either from of misconfigured models (that were misconfigured from the start) or because our obfuscation or input/output harnessing broke parts of the model. 
Furthermore, some models' analysis triggers callbacks within in the model, where they output some information onto the cmd line.
This is to be expected and not a sign of failure -- simply ignore all such output.
To get less errors presented, don't use 'dbstop if error' (in MATLAB CMD linee) or 'pause on errors' (in the MATLAB IDE).

Note: some models' simulation (e.g., 3560 SINGLE_PWM.slx) may expect user input and halts the analysis. Your user input or simply hitting <Enter> a few times will resume the analysis.


## Our replication setup
We tested and ran all scripts on a laptop with: Windows 11 Pro, MATLAB R2024b (with graphics display activated), Intel i9-13980HX, 96GB RAM.

# Improvements
Please contact us, if you miss a feature in our tool or experience difficulties or crashes.
