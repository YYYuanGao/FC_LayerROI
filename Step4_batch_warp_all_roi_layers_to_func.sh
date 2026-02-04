#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Inputs
# ----------------------------
ROI_DIR="/data/p_03179/Kenshu_Resting/BIDS/sub-01/anat/HCPMMP_KSrest/Kenshu_rest/roi_layer_masks"

# func reference (mean EPI you created)
FUNCREF="/data/p_03179/Kenshu_Resting/derivatives/micapipe_v0.2.0/sub-01/func/desc-se_task-test_bold/volumetric/sub-01_space-func_desc-se_mean_bold.nii.gz"

# affine transform you created in /derivatives/xfm_T1_to_func_test
AFF="/data/p_03179/Kenshu_Resting/derivatives/xfm_T1_to_func_test/T1toFUNC_0GenericAffine.mat"

# output dir
OUTDIR="${ROI_DIR}/func_space_affine"
mkdir -p "${OUTDIR}"

# ----------------------------
# Sanity checks
# ----------------------------
[[ -d "${ROI_DIR}" ]]  || { echo "ERROR: ROI_DIR not found: ${ROI_DIR}"; exit 1; }
[[ -f "${FUNCREF}" ]]  || { echo "ERROR: FUNCREF not found: ${FUNCREF}"; exit 1; }
[[ -f "${AFF}" ]]      || { echo "ERROR: AFF not found: ${AFF}"; exit 1; }

echo "[INFO] ROI_DIR  = ${ROI_DIR}"
echo "[INFO] FUNCREF  = ${FUNCREF}"
echo "[INFO] AFFINE   = ${AFF}"
echo "[INFO] OUTDIR   = ${OUTDIR}"
echo ""

# ----------------------------
# Warp all *_T1.nii.gz masks
# ----------------------------
shopt -s nullglob
FILES=("${ROI_DIR}"/*_T1.nii.gz)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "ERROR: No *_T1.nii.gz found in ${ROI_DIR}"
  exit 1
fi

for f in "${FILES[@]}"; do
  base=$(basename "$f" .nii.gz)
  out="${OUTDIR}/${base/_T1/}_func.nii.gz"

  echo "[WARP] $(basename "$f") -> $(basename "$out")"
  antsApplyTransforms \
    -d 3 \
    -i "$f" \
    -r "${FUNCREF}" \
    -o "$out" \
    -n NearestNeighbor \
    -t "${AFF}"

  # make sure output is binary 0/1 (avoid float masks)
  3dcalc -a "$out" -expr 'step(a)' -prefix "$out" -overwrite >/dev/null
done

echo ""
echo "[DONE] All ROI×layer masks warped to:"
echo "  ${OUTDIR}"
