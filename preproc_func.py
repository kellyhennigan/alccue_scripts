#!/usr/bin/python

# filename: preproc_func.py
# script to do pre-processing of functional data. Does the following: 

# 1) drops first X volumes from each scan run
# 2) slice time correction
# 3) pulls out a functional reference volume from the 1st run for each task 
# 4) motion correct to task functional reference volume; saves out motion params 
#    to a text file
# 5) smooths data
# 6) converts to % change units
# 6) applies a high-pass filter

# after doing that for each scan within a task: 

# 7) concatanate preprocessed scans & motion params, delete intermediary files


# NOTE: this script was written for usign nifti formatted data, 
# not afni's annoying brik/head format

# TO DO: 
# remove ref file; change

import os,sys,glob


##################### define global variables ##################################
# EDIT AS NEEDED:

# path to main data directory 
dataDir = '/Users/kelly/nicotinecue/data'

# list of subject ids to process 
subjects = ['pilot171111']


# name of raw functional data file(s)
task = 'cue' 
task_runs = [1] # (in case there's more than 1 scan run for the task)
rawFile = os.path.join(dataDir,'%s','raw','%s%d.nii.gz') # %s for subject,
# then task, %d for task run number

outDir = os.path.join(dataDir,'%s','func_proc') # dir for processed data


print 'execute commands?'
xc = bool(input('enter 1 for yes, or 0 to only print: '))
	

############## define relevant variables for each pre-processing step as needed

# how many volumes to drop from the beginning of each scan? 
drop_nvols = 6 


# slice timing correction parameter string
st_param_str = '-slice 0 -tpattern altplus'  


# which volume to use from 1st func run as a reference volume? 
ref_idx = 4	 
	
	
# motion correction parameter string
mc_param_str = '-Fourier -twopass -zpad 4'  # mc params
censor_lim = 0.5  # euclidian norm limit for censoring vols due to motion


# fwhm gaussian kernel to use for smoothing (in mm)
smooth_mm = 4 		


# high-pass filter cutoff (.011 hz ~= 1 cycle/90 sec)
hz_limit = .011		



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


#########  make sure that the filename makes sense 
def checkNiiFName(niiFileName):

	i = niiFileName.find('nii')
	
	# if there's no nifti suffix in the filename, add it:
	if i==-1:
		if niiFileName.find('+')==-1:	 # (unless there's an afni suffix)
			niiFileName=niiFileName+'.nii.gz'

	return niiFileName


#########  concatenate data in the 4th dim; sub_idx must be either string in 
# afni notation or an integer indexing which vol(s) to concatanate
def cat4d(inFiles,outFile,sub_idx=''):

	outFile = checkNiiFName(outFile)

	if type(inFiles) is str:
		inFiles = [inFiles]

	if type(sub_idx) is int:
		sub_idx = '['+str(sub_idx)+']'

	
	cmd = ('3dTcat -output '+outFile+' '+' '.join([s + sub_idx for s in inFiles]))
	doCommand(cmd)

	return outFile



#########  slice time correct  
def correctSliceTiming(inFile):
	
	outFile = checkNiiFName('t'+inFile)

	# uses global variable st_param_str		
	cmd = ('3dTshift -prefix '+outFile+' '+st_param_str+' '+inFile)
	doCommand(cmd)
	
	return outFile
	
			

#########  motion correct: inFile, r is run num, refFile is functional ref volume 
def correctMotion(inFile,refFile):

	outFile = checkNiiFName('m'+inFile)

	# uses global variables task, r, mc_param_str, censor_lim
	mc_str = task+str(r)+'_vr'
	
	# motion correct; uses global var mc_param_str
	cmd = ('3dvolreg '+mc_param_str+' -dfile '+mc_str+'.1D -base '+refFile+' '
	'-prefix '+outFile+' '+inFile)
	doCommand(cmd)

						
	# censor vols w/motion; uses global var censor_lim
	cmd = ('1d_tool.py -infile '+mc_str+'.1D[1..6] -show_censor_count '
	'-censor_prev_TR -censor_motion '+str(censor_lim)+' '+task+str(r))
	doCommand(cmd)

	
	# make a list that contains all motion-correction related generated files
	mc_files = [mc_str+'.1D',task+str(r)+'_censor.1D',task+str(r)+'_enorm.1D']
	return (outFile, mc_files)



#########  smooth
def smooth(inFile):
		
	outFile = checkNiiFName('s'+inFile)
	
	# uses global variable smooth_mm
	cmd = ('3dmerge -1blur_fwhm '+str(smooth_mm)+' -doall -quiet '
	'-prefix '+outFile+' '+inFile)
	doCommand(cmd)
		
	return outFile



#########  convert BOLD data to units of % signal change 
def convertUnits(inFile):

	outFile = checkNiiFName('p'+inFile)
	meanFile = checkNiiFName(task+str(r)+'_mean')

	# first calculate run mean
	cmd = ('3dTstat -mean -prefix '+meanFile+' '+inFile)
	doCommand(cmd)
	
	# now scale data 
	cmd = ('3dcalc -a '+inFile+' -b '+meanFile+' -expr "((a-b)/b)*100" '
	'-prefix '+outFile+' -datum float')
	doCommand(cmd)
		
	return outFile	



#########  high-pass filter 
def hpFilter(inFile):
	
	outFile = checkNiiFName('f'+inFile)

	# uses global variable hz_limit
	cmd = ('3dFourier -highpass '+str(hz_limit)+' -prefix '+outFile+' '+inFile)
	doCommand(cmd)
		
	return outFile	



#########  concatenate motion files across runs - this is very specific!!
def concatRunMCFiles(mcFiles):

	########## clear out any pre-existing concatenated motion files
	cmd = ('rm '+task+'_vr.1D; rm '+task+'_censor.1D; rm '+task+'_enorm.1D')
	doCommand(cmd)
		

	########## create master motion regs file for all runs 
	cmd = ('cat '+mcFiles[0]+' >> '+task+'_vr.1D')
	doCommand(cmd)
	
	########## create master motion censor file for all runs 
	cmd = ('cat '+mcFiles[1]+' >> '+task+'_censor.1D')
	doCommand(cmd)
	
	########## create master motion enorm file for all runs 
	cmd = ('cat '+mcFiles[2]+' >> '+task+'_enorm.1D')
	doCommand(cmd)



###########################  MAIN PREPROC FUNCTION ###########################

if __name__ == '__main__':
    
	
	for subject in subjects:  	# subject loop
	
		print('\nWORKING ON SUBJECT '+subject+'\n')
	
		# define subject specific directory for processed data
		this_outDir =  outDir % (subject)
		
		# make out directory if doesn't already exist 
		if not os.path.exists(this_outDir):
			print 'making new dir: '+this_outDir+'\n'
			if xc is True: 
				os.makedirs(this_outDir)


		# cd to processed data directory 
		print 'cd '+this_outDir+'\n'
		if xc is True: 
			os.chdir(this_outDir)


		# pre-processing pipeline	
		print 'PROCESSING '+task+' DATA\n'

		ppFiles = [] # list of pre-processed file names
		mcFiles = ['','',''] # motion file names from each run 
	
		for r in task_runs:
			

			#########  raw to afni format, omit first TRs if desired
			this_rawFile = rawFile % (subject,task,r)
			funcFile = cat4d(this_rawFile,task+str(r),'['+str(drop_nvols)+'..$]')
				

			#########  slice time correct  
			funcFile = correctSliceTiming(funcFile)
				
			
			#########  make a functional reference volume if it doesn't exist yet
			if r==1: 
				refFile = cat4d(funcFile,'ref_'+task,ref_idx)
				
			
			#########  motion correct
			funcFile,these_mc_files = correctMotion(funcFile,refFile)
			mcFiles = ["%s %s" % t for t in zip(mcFiles,these_mc_files)]


			#########  smooth
			funcFile = smooth(funcFile)
		

			#########  convert to % change units
			funcFile = convertUnits(funcFile)
	

			#########  high pass filter 
			funcFile = hpFilter(funcFile)
 		

 			#########  list of pre-processed file names for concatenating 
			ppFiles = ppFiles + [funcFile]

			print('\n\nFINISHED RUN '+str(r)+'\n\n')


 		######### convert pre-processed files to nifti & concat runs
		outFile = cat4d(ppFiles,'pp_'+task)
		
		
		######### concatenate motion files across runs 
		concatRunMCFiles(mcFiles)


		########## remove intermediary steps (i.e., *mid1* , *mid2*, etc.)
		for ri in range(r,0,-1):
			cmd = ('rm *'+task+str(ri)+'*')
			doCommand(cmd)
		

		print('\n\npre-processed '+task+' data saved to '+outFile+'\n\n')


		print('\nFINISHED SUBJECT '+subject+'\n') ########### end of subject loop
		
	print('\nDONE\n')
	