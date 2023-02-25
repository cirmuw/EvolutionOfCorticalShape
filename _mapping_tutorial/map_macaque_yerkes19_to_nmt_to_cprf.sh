#!/bin/bash


PROCESSING_DIR=/some/path/for/processing
[[ -d ${PROCESSING_DIR} ]] || mkdir -p ${PROCESSING_DIR}

REPO_DIR=/path/to/the/repo/EvolutionOfCorticalShape
HEMI=R

# load values defined on yerkes19 space
BALSA_DATA_DIR=/path/to/MacaqueYerkes19_v1.2_Vj_976nz/MNINonLinear/fsaverage_LR32k

# extract metric data from cifti file
IN_FILE_CIFTI=${BALSA_DATA_DIR}/MacaqueYerkes19_v1.2.All.MyelinMap_BC.32k_fs_LR.dscalar.nii
IN_FILE_METRIC=${PROCESSING_DIR}/MacaqueYerkes19_v1.2.All.MyelinMap_BC.32k_fs_LR.${HEMI}.func.gii

OUT_FILE=${PROCESSING_DIR}/${HEMI}.yerkes2mnt_mid.func.gii
if [ $HEMI == "L" ] ; then
	STRUCTURE=CORTEX_LEFT
else
	STRUCTURE=CORTEX_RIGHT
fi

wb_command -cifti-separate ${IN_FILE_CIFTI} COLUMN -metric ${STRUCTURE} ${IN_FILE_METRIC}


# define source and target space for mapping
SOURCE_SPACE=Yerkes19
TARGET_SPACE=NMTv1.3

# sphere, surface model for yerkes19 data
SPH_SOURCE=${BALSA_DATA_DIR}/MacaqueYerkes19_v1.2.${HEMI}.sphere.32k_fs_LR.surf.gii
MODEL_SOURCE=${BALSA_DATA_DIR}/MacaqueYerkes19_v1.2.${HEMI}.pial.32k_fs_LR.surf.gii

# sphere, surface model for NMT surface model data 
SPH_RESAMPLE=${REPO_DIR}/_mappings/Macaca_mulatta/${HEMI}.${SOURCE_SPACE}-${TARGET_SPACE}.sphere.reg.surf.gii

SPH_TARGET=${REPO_DIR}/_surfaces/sub-028_species-Macaca+mulatta_hemi-${HEMI}.sphere.surf.gii
MODEL_TARGET=${REPO_DIR}/_mappings/Macaca_mulatta/${HEMI}.${TARGET_SPACE}.surf.gii


# map to NMT
wb_command -metric-resample ${IN_FILE_METRIC} $SPH_SOURCE $SPH_RESAMPLE ADAP_BARY_AREA ${OUT_FILE} -area-surfs $MODEL_SOURCE $MODEL_TARGET

# map to common phylogenetic reference frame / fsaverage6 topology
OUT_FILE_CPRF=${PROCESSING_DIR}/${HEMI}.yerkes2mnt2cprf_mid.func.gii

SPH_RESAMPLE_CPRF=${REPO_DIR}/_surfaces/sub-028_species-Macaca+mulatta_hemi-${HEMI}_topo-Homo.sapiens.sphere.reg.surf.gii
MODEL_TARGET_CPRF=${REPO_DIR}/_surfaces/sub-028_species-Macaca+mulatta_hemi-${HEMI}_topo-Homo.sapiens.surf.gii

wb_command -metric-resample ${OUT_FILE} $SPH_TARGET $SPH_RESAMPLE_CPRF ADAP_BARY_AREA ${OUT_FILE_CPRF} -area-surfs $MODEL_TARGET $MODEL_TARGET_CPRF
