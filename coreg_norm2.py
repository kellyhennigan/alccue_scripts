#!/usr/bin/python

# this script should be run AFTER coreg_norm1 and preproc_func scripts. 

# Coreg_norm1 estimates xforms between: 
	# functional data (uses 1st vol for best contrast) and t1 in native space &
	# native space t1 and group template (tlrc)

# and them applies those transforms to put the 1st vol of functional data & t1
# into tlrc space. Before running this script, coregistration should be visually checked 
# between group template and subject's t1, as well as subject's t1 and func vol. 

# preproc_func script must also be completed (preprocessing pipeline). 

# this script then takes the pre-processed functional data and xforms it
# into tlrc space, using the xforms estimated in coreg_norm1 script. 

# Roi time courses are also then saved out. 


import os,sys,glob


##################### define global variables #################################
# EDIT AS NEEDED:


# path to main data directory 
data_dir = '/Users/kelly/nicotinecue/data'

# list of subject ids to process 
subjects = ['pilot171111']

# path to subject's pre-processed data directory
in_dir = os.path.join(data_dir,'%s','func_proc')  # %s is subject id

print 'execute commands?'
xc = bool(input('enter 1 for yes, or 0 to only print: '))


print 'apply func2t1 coregistration?'
doCoreg = bool(input('enter 1 for yes, or 0 for no: '))


task = 'cue'
funcFile = 'pp_'+task+'.nii.gz'	

# filepaths for white matter and CSF ROI masks
roiPath = os.path.join(data_dir,'ROIs','%s_func.nii') # %s is roiNames
roiNames = ['csf','wm','nacc','ins']




###############################################################################
############################### DO IT #########################################
###############################################################################
###### HOPEFULLY DON T HAVE TO EDIT BELOW HERE. OR THATS THE PLAN ANYWAY. #####
###############################################################################
	
	
#########  print commands & execute if xc is True, otherwise just print them
def doCommand(cmd):
	
	print cmd+'\n'
	if xc is True:
		os.system(cmd)



#########  normalize functional data
def normalizeAfniFunc(inFile,t1_tlrc_afni_file,xf_afni,vox_dim):
	
	inStr,_ = os.path.splitext(inFile)
	inStr,_ = os.path.splitext(inStr)
	outStr = inStr+'_tlrc_afni'			# out file string

	if os.path.isfile(outStr+'.nii.gz'):
		outFile = outStr+'.nii.gz'
		print '\n afni xformed file: '+outFile+' already exists...\n'
	else:
		if doCoreg:
			cmd = ('3dAllineate -base '+t1_tlrc_afni_file+' -1Dmatrix_apply '+xf_afni+
			' -prefix '+outStr+' -input '+inFile+' -verb -master BASE -mast_dxyz '+str(vox_dim)+
			' -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -onepass')
		else:
			cmd = ('adwarp -apar '+t1_tlrc_afni_file+' -dpar '+inFile+' '
			'-prefix '+outStr+' -dxyz '+str(vox_dim))
		doCommand(cmd)

	
		outFile = convertToNifti(outStr+'+tlrc')

	return outFile



#########  convert file from afni to nifti format & delete afni file
def convertToNifti(inFile,out_str=''):

	# use inFile's prefix as out_str by default, + '_tlrc' if in tlrc space
	if not out_str:
		a=inFile.split('+') # split inFile to get fname & space string
		out_str = a[0] # use inFile's prefix for out file name
		if a[1][0:4]=='tlrc' and a[0].find('tlrc')==-1:
			out_str = out_str+'_tlrc'
	
	outFile = out_str+'.nii.gz'

	cmd = ('3dAFNItoNIFTI -prefix '+outFile+' '+inFile)
	doCommand(cmd)
	
	# delete inFile in afni format
	cmd = ('rm '+inFile+'*')
	doCommand(cmd)


	return outFile



#########  extract average time series of white matter & csf masks 
def extractRoiTS(inFile,roiFilePath,outTsName):

	# uses global variables csfFilePath & wmFilePath & baseStr
	
	cmd = ('3dmaskave -mask '+roiFilePath+' -quiet -mrange 1 2 '+inFile+
	' > '+outTsName)
	doCommand(cmd)
	


###########################  MAIN FUNCTION ###########################

if __name__ == '__main__':

	
	for subject in subjects:
	
		print '\nPROCESSING SUBJECT: '+subject+'\n'	
		
		# cd to subject specific data dir
		this_inDir = in_dir % (subject)
		print 'cd '+this_inDir+'\n'
		os.chdir(this_inDir)
		
		print 'PROCESSING '+task+' DATA\n'
		
		
############### COREG & NORMALIZATION PIPELINE (AFNI METHOD) ###################


		#### transform to group space using AFNI affine xform 
 		t1_tlrc_afni_file = 't1_tlrc_afni.nii.gz' # t1 in tlrc space, using afni xform
		vox_dim = 2.9 	# voxel dimensions and template for group space
		xf_afni = 'xfs/'+task+'2tlrc_xform_afni' # %s is task
	
 		afni_tlrcFile = normalizeAfniFunc(funcFile,t1_tlrc_afni_file,xf_afni,vox_dim)
 	

		#### save out roi time series 
		for r in roiNames:
 			this_roiPath = roiPath % (r)
 			outTsName = task+'_'+r+'_afni.1D'
			extractRoiTS(afni_tlrcFile,this_roiPath,outTsName)

		
		# save a note about whether func2t1 coreg xform is being applied
		cmd='echo "applied '+task+'2t1 coreg xform: '+str(doCoreg)+' " >> coreg_log'
		doCommand(cmd)


		print '\n\nDONE WITH '+task+' TASK DATA, SAVED OUT AS '+afni_tlrcFile+'\n\n'

		print 'FINISHED SUBJECT '+subject
		





			

