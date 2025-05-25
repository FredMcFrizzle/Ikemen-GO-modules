## Forced Palette

Orignally written by Rakiel and edited by me.
Forced palette allows for characters to be forced into a palette on selection.
adding palnum = 4 to a character in the select.def file will force that character to pick palette 4.
also adding 
example:
### This KFM will be selected like normal, a b c x y z palettes. 
kfm, stages/kfm.def
### This KFM will select palette 7 no matter which button you press.
kfm, palnum=7, stages/kfm.def
### This KFM will select palette 1 because 12 - 13 = 1
kfm, palnum=13, stages/kfm.def
![Image of KFM with different palettes](https://drive.google.com/u/0/drive-viewer/AKGpihYttHrj5qDQa7KHz7rJF3QuHReiRUN4is-4mjG0Z-uOSP6CM0JI7ZBWKg-NXRXRRQU9WhiH_PsqnuiarvAsyv5-9FYLvyLvqKs=s2560)

You can also add palname to add a name for the palette the character uses.
example:
### This KFM doesnt use palname so it doesnt show in game
kfm, palnum=1, stages/kfm.def
### This KFM uses a green palette so using palname you can display that its a green color
kfm, palnum=7, palname=green, stages/kfm.def
![Image of palname working](https://drive.google.com/u/0/drive-viewer/AKGpihas1TEukcCjS5BeQUIOVrApYwQAbKEA8qGntUQuqMueV5heAhhWL2_SBI6YBCdTT6JILH4y0FVDh1r4VrapOx_gjT3sRDW3NQ=s2560)

