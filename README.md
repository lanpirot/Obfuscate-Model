[![DOI](https://zenodo.org/badge/808521433.svg)](https://doi.org/10.5281/zenodo.16944786) [![View SMOKE:Simulink Model Anonymizer on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://ch.mathworks.com/matlabcentral/fileexchange/181869-smoke-simulink-model-anonymizer)

# SMOKE: Simulink Model Obfuscation Keeping structurE

The SMOKE Tool removes, renames, and/or hides various aspects of a Simulink model in order to hide confidential information. This can be useful for eliminating proprietary details when sending models to third-parties, or even by removing details from models in order to create simpler images suitable for publication. The SMOKE Tool can obfuscate (change layout, remove/hide names, remove colors, resize, rearrange diagrams etc.) and remove data and functionality (remove annotations, docblocks, functions from function blocks, stateflow innards, customized callbacks, all customized block parameters) while keeping the structure of the model intact. This way it can be shared while still being useful for structural analysis and/or screenshots that may be published.

Remove all sensitive IP from models with SMOKE!

<img src="imgs/Cover.png" width="850">

*__Disclaimer__: The authors of this tool make no guarantees that all proprietary/confidential information is indeed removed from the Simulink model file. Users should inspect the model to verify that no proprietary/confidential information remains.*

## User Guide
**TL;DR:**
- watch our 5 minutes [YouTube walkthrough](https://youtu.be/0i42BzgJAUA)
- Download this repository (SMOKE)
- Download [Simulink Utility](https://github.com/McSCert/Simulink-Utility)
- Add both SMOKE and Simulink Utility to your MATLAB path (click Selected folders and their subfolders)
- start SMOKE by running `src/SMOKEgui.mlapp`

For more detailed installation and usage instructions, please refer to the [User Guide](doc/SMOKE_UserGuide.pdf).

**Scripting:** `SMOKE(model)` applies all default transformations; `SMOKE(model, 'renameblocks', 0)` all but one; `SMOKE(model, 'all', 0, 'removeannotations', 1, 'renameblocks', 1)` only the listed ones (see `help SMOKE` for all option names).

## What SMOKE could not change
Simulink refuses some changes (blocks inside locked library links, read-only subsystems, blocks that cannot be resized, parameters whose reset would add or remove ports, ...). SMOKE never aborts because of such an element: it skips it, continues, and prints a summary at the end. Inspect the skipped elements with
```matlab
t = smokeLog('report')   % one row per skipped element: rule, element path, parameter, Simulink error
```
or take the table directly: `t = SMOKE(model, ...)`. Everything listed there is still in its original state and needs a manual check before the model is shared.

## Tests
- `src/tests/test_basics.m` builds a small model with one instance of every element SMOKE handles, runs SMOKE, and checks on the raw model file that every secret is gone, that secrets outside the chosen scope are kept, and that the structure is unchanged. Runs in under a minute.
- `src/tests/test_scalability.m` runs SMOKE over the SLNET corpus, see below.

Run tests without a display (`matlab -nodisplay -batch "test_basics"`), otherwise Simulink opens editor windows and dialogs for models with broken callbacks or missing libraries.

## Replication 
For replication, see [the replication directory](https://github.com/lanpirot/SMOKE/tree/master/src/tests).
