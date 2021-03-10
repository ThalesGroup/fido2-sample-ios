#!/bin/sh
set -e
set -u
set -o pipefail

function on_error {
  echo "$(realpath -mq "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR

if [ -z ${FRAMEWORKS_FOLDER_PATH+x} ]; then
  # If FRAMEWORKS_FOLDER_PATH is not set, then there's nowhere for us to copy
  # frameworks to, so exit 0 (signalling the script phase was successful).
  exit 0
fi

# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????")

install_artifact()
{
  local source="$1"
  local destination="$2"
  local headersFolderName="$3"

  cp -R "$source" "$destination"
  if [ -d "$destination/Headers" ]; then
      rm -rf "$destination/$headersFolderName"
      mv "$destination/Headers" "$destination/$headersFolderName"
  fi  
}

# Copies a static library to derived data for use in later build phases
install_static_lib()
{
  if [ -r "${BUILT_PRODUCTS_DIR}/$1" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$1"
  elif [ -r "${BUILT_PRODUCTS_DIR}/$(basename "$1")" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$(basename "$1")"
  elif [ -r "$1" ]; then
    local source="$1"
  fi

  local headersFolderName="$2"
  local destination="${CONFIGURATION_BUILD_DIR}"
  install_artifact "$source" "$destination" "$headersFolderName"
}

install_xcframework() {
  local basepath="$1"
  local dependency_name="$2"

  # These are the slices currently supported
  local paths=( "ios-x86_64-simulator/" "ios-arm64/" )

  # Locate the correct slice of the .xcframework for the current architectures
  local target_path=""
  local target_arch="$ARCHS"

  # Replace spaces in compound architectures with _ to match slice format
  target_arch=${target_arch// /_}

  local target_variant=""
  if [[ "$PLATFORM_NAME" == *"simulator" ]]; then
    target_variant="simulator"
  fi
  if [[ ! -z ${EFFECTIVE_PLATFORM_NAME+x} && "$EFFECTIVE_PLATFORM_NAME" == *"maccatalyst" ]]; then
    target_variant="maccatalyst"
  fi
  for i in ${!paths[@]}; do
    if [[ "${paths[$i]}" == *"$target_arch"* ]] && [[ "${paths[$i]}" == *"$target_variant"* ]]; then
      # Found a matching slice
      echo "Selected xcframework slice ${paths[$i]}"
      target_path=${paths[$i]}
      break;
    fi
  done

  if [[ -z "$target_path" ]]; then
    echo "warning: [CP] Unable to find matching .xcframework slice in '${paths[@]}' for the current build architectures ($ARCHS)."
    return
  fi

  install_static_lib "$basepath/$target_path" "$dependency_name"
}

if [[ "$CONFIGURATION" == "Debug" ]]; then
    install_xcframework "${LIB_ROOT}/fido2/$CONFIGURATION/fido2.xcframework" "fido2"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
    install_xcframework "${LIB_ROOT}/fido2/$CONFIGURATION/fido2.xcframework" "fido2"
fi
