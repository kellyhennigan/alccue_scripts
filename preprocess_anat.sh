#!/bin/bash

##############################################

# usage: process anatomy for data in cue reactivity project

# written by Kelly, 27-Jun-2018, 

# assumes the directory structure is: 
# $dataDir/$subjid/raw (e.g. "~/cuefmri/data/jj180618/raw")

# assumes there is 1 run of cue reactivity data and a t1 nifti in the raw directory 
# named "cue1.nii.gz" and "t1_raw.nii.gz"

# output files are (all found in the output directory): 

	# t1_ns.nii.gz - skull-stripped anatomical volume 
	# t1_tlrc_afni.nii.gz - anatomical volume in tlrc space
	# vol1_cue_ns.nii.gz - 1st volume of functional data, skull-stripped
	# vol1_cue_tlrc_afni.nii.gz - 1st volume of functional data in tlrc space
	
	# the following transforms (saved in "xfs" subdirectory of output dir): 
		# cue2t1_xform_afni - functional > anatomical xform
		# cue2tlrc_xform_afni - functional > tlrc space xform
		# t12cue_xform_afni - anatomical > functional xform
		# t12tlrc_xform_afni - anatomical > tlrc space xform
		# t12tlrc_xform_afni.log - record of RMS for the co-registration

	

#########################################################################
########################## DEFINE VARIABLES #############################
#########################################################################

# dataDir is the parent directory of subject-specific directories
dataDir='/Users/kelly/cueexp_claudia/data' 


# subject ids to process
subjects='B002'  # e.g. '301 308 309'

t1_template=$dataDir/templates/TT_N27.nii # %s is data_dir

func_template=$dataDir/templates/TT_N27_func_dim.nii # %s is data_dir


# should t1 and functional data be aligned by AFNI in native space prior to 
# xforming functional data to group space? 
doFuncAnatCoreg=1

#########################################################################
############################# RUN IT ###################################
#########################################################################

for subject in $subjects
do
	
	echo WORKING ON SUBJECT $subject

	# subject input & output directories
	inDir=$dataDir/$subject/raw
	outDir=$dataDir/$subject/func_proc


	# make outDir & cd to it: 
	mkdir $outDir
	cd $outDir


	# also make a "xfs" directory to house all xform files
	mkdir xfs

	# remove skull from t1 anatomical data
	3dSkullStrip -prefix t1_ns.nii.gz -input $inDir/t1_raw.nii.gz


	# estimate transform to put t1 in tlrc space
	@auto_tlrc -no_ss -base $t1_template -suffix _afni -input t1_ns.nii.gz


	# the @auto_tlrc command produces a bunch of extra files; clean them up 
	gzip t1_ns_afni.nii; 
	mv t1_ns_afni.nii.gz t1_tlrc_afni.nii.gz; 
	mv t1_ns_afni.Xat.1D xfs/t12tlrc_xform_afni; 
	mv t1_ns_afni.nii_WarpDrive.log xfs/t12tlrc_xform_afni.log; 
	rm t1_ns_afni.nii.Xaff12.1D


	# take first volume of raw functional data:
	3dTcat -output $inDir/vol1_cue.nii.gz $inDir/cue1.nii.gz[0]

	
	# skull-strip functional vol
	3dSkullStrip -prefix vol1_cue_ns.nii.gz -input $inDir/vol1_cue.nii.gz


	# estimate xform between anatomy and functional data
	if [ $doFuncAnatCoreg -eq 1 ]
	then 
		align_epi_anat.py -epi2anat -epi vol1_cue_ns.nii.gz -anat t1_ns.nii.gz -epi_base 0 -tlrc_apar t1_tlrc_afni.nii.gz -epi_strip None -anat_has_skull no
	else	
		adwarp -apar t1_tlrc_afni.nii.gz -dpar vol1_cue_ns.nii.gz -prefix vol1_cue_ns_tlrc_al -dxyz 2.9
	fi

	# put in nifti format 
	3dAFNItoNIFTI -prefix vol1_cue_tlrc_afni.nii.gz vol1_cue_ns_tlrc_al+tlrc


	# clean up intermediate files
	rm vol1_cue_ns_tlrc_al+tlrc*
	mv t1_ns_al*aff12.1D xfs/t12cue_xform_afni; 
	mv vol1_cue_ns_al_mat.aff12.1D xfs/cue2t1_xform_afni; 
	mv vol1_cue_ns_al_tlrc_mat.aff12.1D xfs/cue2tlrc_xform_afni; 
	rm vol1_cue_ns_al_reg_mat.aff12.1D; 
	rm vol1_cue_ns_al+orig*


done # subject loop




