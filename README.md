# cue reactivity scripts for alcohol dependent patient group

Repository of scripts for processing data from the cue reactivity project

## software requirements 

These scripts require the following software: 

* [AFNI](https://afni.nimh.nih.gov/)
* [Python 2.7](https://www.python.org/)
* [Matlab](https://www.mathworks.com/products/matlab.html)
* [matlab package, VISTASOFT](https://github.com/vistalab/vistasoft)

## raw data: 

Start with the following raw data files:

- cue_matrix.csv -behavioral data from the task
- t1_raw.nii.gz –subjects t1-weighted anatomical scan
- cue1.nii.gz –functional task data


## change permissions to be able to execute bash scripts
<i>from a terminal command line, cd to the directory containing these scripts. Then type:</i> 
```
chmod 777 *sh
```
to be able to execute them.


## pre-processing pipeline

(1) coregister subject's functional and anatomical data in native space and estimate the transform to bring subject's data into standard group space
<i>from a terminal command line, type:</i> 
```
./preprocess_anat.sh
```
this script does the following using AFNI commands:
* skull strips t1 data using afni command "3dSkullStrip"
* aligns skull-stripped t1 data to t1 template in tlrc space using afni command @auto_tlrc, which allows for a 12 parameter affine transform
* pulls out the first volume of functional data to be co-registered to anatomy and skullstrips this volume using "3dSkullStrip"
* coregisters anatomy to functional data, and then calculates the transform from native functional space to standard group space (tlrc space)

QUALITY CHECK:
in afni viewer, load subject's anatomy and functional volume in tlrc space (files "t1_tlrc_afni.nii.gz" and "vol1_cue_tlrc_afni.nii.gz"). These should be reasonably aligned. If they aren't, that means 1) the anatomical <-> functional alignment in native space messed up, 2) the subject's anatomical <-> tlrc template alignment messed up, or 3) both messed up. 



(2) run pre-processing steps on functional data 
<i>from a terminal command line, type:</i> 
```
./preprocess_cue.sh
```
this script does the following using AFNI commands:
* removes first 6 volumes from functional scan (to allow t1 to reach steady state)
* slice time correction
* motion correction 
* saves out a vector of which volumes have lots of motion (will use this to censor volumes in glm estimation step)
* spatially smooths data 
* converts data to be in units of percent change (mean=100; so a value of 101 means 1% signal change above that voxel's mean signal)
* highpass filters the data to remove low frequency fluctuations
* transforms pre-processed functional data into standard group (tlrc) space using transforms estimated in "preprocess_anat.sh" script
* saves out white matter, csf, and nacc VOI time series as single vector text files (e.g., 'cue_csf_ts.1D') 



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


## To make single-subject brain maps: 
<i>from a terminal command line, type:</i>
```
python glm_cue.py
```
this script calls AFNI's 3dDeconvolve command to fit a GLM to a subject's fMRI data. 


## To make group brain maps: 
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


