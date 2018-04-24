# nicotine cue reactivity scripts

Repository of scripts for processing data from the nicotine cue reactivity project

## software requirements 

These scripts require the following software: 

* [Python 2.7](https://www.python.org/)
* [Matlab](https://www.mathworks.com/products/matlab.html)
* [AFNI](https://afni.nimh.nih.gov/)
* [matlab package, VISTASOFT](https://github.com/vistalab/vistasoft)

## raw data: 

Start with the following raw data files:
cue_matrix.csv - behavioral data from the task
cue_ratings.csv – valence and arousal cue ratings (post task ratings)
t1_raw.nii.gz – subjects t1-weighted anatomical scan
cue1.nii.gz – functional task data

## pre-processing pipeline

(1) coregister subject's functional and anatomical data in native space and estimate the transform to bring subject's data into standard group space
<i>from a terminal command line, type:</i> 
```
python coreg_norm1.py
```
this script does the following using AFNI commands:
* skull strips t1 data using afni command "3dSkullStrip"
* aligns skull-stripped t1 data to t1 template in tlrc space using afni command @auto_tlrc, which allows for a 12 parameter affine transform
* pulls out the first volume of functional data to be coregistered to anatomy and skullstrips this volume using "3dSkullStrip"
* coregisters anatomy to functional data, and then calculates the transform from native functional space to standard group space (tlrc space)


(2) run pre-processing steps on functional data 
<i>from a terminal command line, type:</i> 
```
python preproc_func.py
```
this script does the following using AFNI commands:
* removes first 6 volumes from functional scan (to allow t1 to reach steady state)
* slice time correction
* motion correction 
* saves out a vector of which volumes have lots of motion (will use this to censor volumes in glm estimation step)
* spatially smooths data 
* converts data to be in units of percent change (mean=100; so a value of 101 means 1% signal change above that voxel's mean signal)
* highpass filters the data to remove low frequency fluctuations
* transforms pre-processed functional data into standard group (tlrc) space using transforms estimated in "coreg_norm1.py" script
<i>note there's an option to apply coregistration transform between t1 and functional data in native space; use this if t1 and raw functional data aren't aligned; if they are aligned, sometimes this transform can actually make there alignment worse due to differences in spatial distortions between the scans (e.g., signal dropout in OFC of functional data may cause optimal coregistration solution to incorrectly tilt head backward on anatomy scan to match functional data)</i>
* saves out white matter & csf VOI time series as single vector text files (e.g., 'cue_csf_afni.1D') 


(3) make regressor time series 
<i>from matlab command line, type:</i> 
```
createRegs_script
```
this script loads behavioral data to get stimulus onset times and saves out regressors of interest. Saved out files each contain a single vector of length equal to the number of TRs in the task with mostly 0 entries, and than 1 to indicate when an event of interest occurs. These vectors are then convolved with an hrf using AFNI's waver command to model the hemodynamic response. 

## To generate VOI timecourses: 
<i>from matlab command line, type:</i> 
```
saveRoiTimeCourses_script
```
and then: 
```
plotRoiTimeCourses_script
```
to save & plot ROI timecourses for events of interest

## To make brain maps: 
<i>from a terminal command line, type:</i>
```
python glm_cue.py
```
this script calls AFNI's 3dDeconvolve command to fit a GLM to a subject's fMRI data. 

For group analysis: 
<i>from a terminal command line, type:</i>
```
python ttest_2sample_cue.py
```
to use AFNI's command 3dttest++ to perform t-ttests on subjects' brain maps

## QA
<i>from matlab command line, type:</i> 
```
doFuncQA_script
```
to save out some plots that display head motion



