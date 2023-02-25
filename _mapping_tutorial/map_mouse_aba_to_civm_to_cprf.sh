#!/bin/bash

# script requires FSL, Convert3d (> 1.0.0) and wb_command to be on the path


PROCESSING_DIR=/some/path/for/processing
[[ -d ${PROCESSING_DIR} ]] || mkdir -p ${PROCESSING_DIR}

REPO_DIR=/path/to/the/repo/EvolutionOfCorticalShape
HEMI=R


# get ISH data from ABA
EXPERIMENT_ID=275  # see http://mouse.brain-map.org/experiment/show/275
wget http://api.brain-map.org/grid_data/download/${EXPERIMENT_ID}?include=energy,intensity -O ${PROCESSING_DIR}/ish.zip
unzip ish.zip

# transform to SBA space  (see https://scalablebrainatlas.incf.org/mouse/ABA_v3)
c3d energy.mhd -o energy_sba.nii.gz
fslswapdim energy_sba.nii.gz z -x -y energy_sba.nii.gz
c3d energy_sba.nii.gz -orient RPI -spacing 0.2x0.2x0.2mm -origin -5.7x7.825x-2.825mm -o energy_sba.nii.gz

popd

# VOLUME=/Users/ernst/Arbeit/Projects/Evolution/Publications/Pub001_PhylogeneticModel/_Draft_001/EvoRepo/_tutorial/Clu/275/energy_sba.nii.gz
VOLUME=${PROCESSING_DIR}/energy_sba.nii.gz


SURFACE=${REPO_DIR}/_mappings/Mus_musculus/${HEMI}.ABA_CCF3_sba.surf.gii
OUTPUT=${PROCESSING_DIR}/mouse_aba-sba-Clu275_${HEMI}.func.gii


# this value is derived from the voxel size of the input volume to reduce the number of "missed" voxels due to interpolation
offset=0.1


## GENERATE A 'PSEUDO' CORTICAL RIBBON AROUND THE PROVIDED PIAL SURFACE ==================================================================================
# convert to metric file
wb_command -surface-coordinates-to-metric ${SURFACE} ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/.func.gii})
# store surface normals
wb_command -surface-normals ${SURFACE} ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/normals.func.gii})
# generate inner ribbon placeholder file
wb_command -metric-math x-${offset}*y ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/inner.func.gii}) -var x ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/.func.gii}) -var y ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/normals.func.gii})
wb_command -surface-set-coordinates ${SURFACE} ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/inner.func.gii}) ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/inner.surf.gii})
## ========================================================================================================================================================

# interpolate value volume to surface
wb_command -volume-to-surface-mapping ${VOLUME} ${SURFACE} ${OUTPUT} -ribbon-constrained ${PROCESSING_DIR}/$(basename ${SURFACE/.surf.gii/inner.surf.gii}) ${SURFACE} -volume-roi $VOLUME




# map values from ABA to CIVM_DWI -------------------------------------------------------------------------------------------------------------------------
SOURCE_SPACE=ABA_CCF3_sba
TARGET_SPACE=CIVM_DWI

HEMI=R

IN_FILE_METRIC=${OUTPUT}

# sphere, surface model for ABA data
SPH_SOURCE=${REPO_DIR}/_mappings/Mus_musculus/${HEMI}.${SOURCE_SPACE}.sphere.surf.gii
MODEL_SOURCE=${REPO_DIR}/_mappings/Mus_musculus/${HEMI}.${SOURCE_SPACE}.surf.gii

SPH_RESAMPLE=${REPO_DIR}/_mappings/Mus_musculus/${HEMI}.${SOURCE_SPACE}-${TARGET_SPACE}.sphere.reg.surf.gii

SPH_TARGET=${REPO_DIR}/_surfaces/sub-043_species-Mus+musculus_hemi-${HEMI}.sphere.surf.gii
MODEL_TARGET=${REPO_DIR}/_surfaces/sub-043_species-Mus+musculus_hemi-${HEMI}.surf.gii

OUT_FILE=${PROCESSING_DIR}/mouse_aba-sba_civm-dwi-Clu275_${HEMI}.func.gii

# map to CIVM_DWI
wb_command -metric-resample ${IN_FILE_METRIC} $SPH_SOURCE $SPH_RESAMPLE ADAP_BARY_AREA ${OUT_FILE} -area-surfs $MODEL_SOURCE $MODEL_TARGET



# map to common phylogenetic reference frame / fsaverage6 topology
OUT_FILE_CPRF=${PROCESSING_DIR}/mouse_aba-sba2civm-dwi2cprf-Clu275_${HEMI}.func.gii

SPH_RESAMPLE_CPRF=${REPO_DIR}/_surfaces/sub-043_species-Mus+musculus_hemi-${HEMI}_topo-Homo.sapiens.sphere.reg.surf.gii
MODEL_TARGET_CPRF=${REPO_DIR}/_surfaces/sub-043_species-Mus+musculus_hemi-${HEMI}_topo-Homo.sapiens.surf.gii

wb_command -metric-resample ${OUT_FILE} $SPH_TARGET $SPH_RESAMPLE_CPRF ADAP_BARY_AREA ${OUT_FILE_CPRF} -area-surfs $MODEL_TARGET $MODEL_TARGET_CPRF



