# ConcatMiniscope
MATLAB algorithm for the concatenation of miniscope recorded sessions.

Requirements:
1. Matlab 2016 or later
2. [NormCorre algorithm](https://github.com/flatironinstitute/NoRMCorre) for motion correction 
3. [CNMF-e algorithm](https://github.com/zhoupc/CNMF_E) for cell detection
4. [msDeleteROI algorith](https://github.com/ayallavi/msDeleteROI): Neuron Deletion GUI used for deleting ROIs that were mistakenly detected as neurons (optional)

# Getting Started
1. Install the `checkNoisyCells.mlappinstall` Matlab app through the **Install App** button in the **APPS** tab on Matlab.
1. Organize your data with a parent folder for each animal:
    1. Within each parent folder, place all the information from each session to be concatenated within a child folder.
1. Follow the steps in the `concatSessionsPipeline.m` file.
   1. In the Parameters section, choose the parameters marked with `%%%****************%%%`** . **Attention to the `concatInfo.order` parameter in which you need to inform the order sessions should be concatenated based on their order in the `concatInfo.Sessions` variable.**
   1. After running CNMF-e on the concatenated video (*Step 4*), you may delete ROIs that do not correspond to real neurons using the msDeleteROI (optional) based on ROIs' spatial and temporal shapes.
   1. On *Step 6* select the downsampling factor (`dSFactor`) you want to use on the calcium traces for spike inference.
   1. *Step 7* is a Matlab app (`checkNoisyCells`) used for deleting neurons that are too noisy and show poor spike inference from calcium traces.
   1. The last step (*Step 8*) joins the raw calcium traces and the putative related firing rate of the cells into a single Matlab variable (`concatResults.mat`).
  
  
