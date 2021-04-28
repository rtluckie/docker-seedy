#!/usr/bin/env bash
set -euo pipefail

function main() {
    if [ "$#" -eq 0 ]; then
      set_vars
    else
        $@
    fi
}

function set_vars() {
  OUTPUTS=( "CFLAGS" "CPPFLAGS" "LDFLAGS" "PKG_CONFIG_PATH" )

  declare -A VAR_MAP
  VAR_MAP[TARGET_CF_PATH]=CFLAGS
  VAR_MAP[TARGET_CPP_PATH]=CPPFLAGS
  VAR_MAP[TARGET_LD_PATH]=LDFLAGS
  VAR_MAP[TARGET_PKG_CONFIG_PATH]=PKG_CONFIG_PATH

  declare -A PREFIX_MAP
  PREFIX_MAP[CFLAGS]="-I"
  PREFIX_MAP[CPPFLAGS]="-I"
  PREFIX_MAP[LDFLAGS]="-L"
  PREFIX_MAP[PKG_CONFIG_PATH]=""

  for OUTPUT in "${OUTPUTS[@]}"; do
    unset ${OUTPUT}
  done

  TARGETS=( "bzip2" "lbzip2" "lzlib" "openssl" "readline" "sqlite" "zlib" "xz" "libffi" )
  for TARGET in "${TARGETS[@]}"; do
    unset TARGET_PREFIX TARGET_CPP_PATH TARGET_LD_PATH TARGET_PKG_CONFIG_PATH TPV VAR_NAME PREFIX
    TARGET_PREFIX=$(brew --prefix --quiet "${TARGET}")
    TARGET_CF_PATH="${TARGET_PREFIX}/include"
    TARGET_CPP_PATH="${TARGET_PREFIX}/include"
    TARGET_LD_PATH="${TARGET_PREFIX}/lib"
    TARGET_PKG_CONFIG_PATH="${TARGET_PREFIX}/lib/pkgconfig"

    TARGET_PATHS=( "TARGET_CF_PATH" "TARGET_CPP_PATH" "TARGET_LD_PATH" "TARGET_PKG_CONFIG_PATH" )
    for TARGET_PATH in "${TARGET_PATHS[@]}"; do
      TPV="${!TARGET_PATH}"
      if [[ -d ${TPV} ]]; then
        VAR_NAME=${VAR_MAP[$(echo $TARGET_PATH)]}
        PREFIX=${PREFIX_MAP[$(echo $VAR_NAME)]}
        echo "PREFIX '${PREFIX}' VAR_NAME '${VAR_NAME}' TPV '${TARGET_PATH}' -> '${TPV}' exists" >&2 ;
        if [[ -z "${!VAR_NAME+none}" ]]; then
          echo "VAR_NAME is unset" >&2;
          eval $(printf "export %s=%s%s\n" "${VAR_NAME}" "${PREFIX}" "${TPV}")
          echo "${!VAR_NAME}" >&2;
        else
          echo "VAR_NAME is set to '${VAR_NAME}'" >&2 ;
		  if [[ "${VAR_NAME}" == *"_PATH"* ]]; then
			  DELIMETER=":"
		  else
			  DELIMETER=" "
		  fi
          eval $(printf "export %s=\"\${%s}%s%s%s\"\n" "${VAR_NAME}" "${VAR_NAME}" "${DELIMETER}" "${PREFIX}" "${TPV}")
          echo "${!VAR_NAME}" >&2;
        fi
      else
        echo "TPV '${TARGET_PATH}' -> '${TPV}' does not exist" >&2 ;
      fi
    done
  done

  for OUTPUT in "${OUTPUTS[@]}"; do
    printf "export %s=\"%s\"\n" "${OUTPUT}" "${!OUTPUT}"
  done
}


# Run the main program
main "$@"
