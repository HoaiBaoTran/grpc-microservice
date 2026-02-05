#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure grpcio-tools exists in the current python env
python3 - <<'PY'
import sys
try:
    import grpc_tools  # noqa
except Exception:
    print("ERROR: grpcio-tools not installed in this environment.")
    print("Install it: pip install grpcio-tools")
    sys.exit(1)
PY

gen_one_pkg() {
  local pkg_dir="$1"        # e.g. api/user-contracts-v1
  local proto_glob="$2"     # e.g. "user/v1/*.proto"

  local abs_pkg_dir="${ROOT_DIR}/${pkg_dir}"

  echo "==> Generating protos for ${pkg_dir}"

  # Find protos
  mapfile -t protos < <(cd "${abs_pkg_dir}" && find ${proto_glob} -type f -name "*.proto" 2>/dev/null | sort)
  if [[ ${#protos[@]} -eq 0 ]]; then
    echo "WARN: No protos found for ${pkg_dir} (pattern: ${proto_glob})"
    return 0
  fi

  # Create __init__.py in every folder that will contain generated code
  for p in "${protos[@]}"; do
    local dir
    dir="$(dirname "${p}")"
    while [[ "${dir}" != "." && "${dir}" != "/" ]]; do
      mkdir -p "${dir}"
      touch "${dir}/__init__.py"
      dir="$(dirname "${dir}")"
    done
  done

  # Include paths
  # -I points to package root containing the proto tree
  local include_path="${abs_pkg_dir}"

  # If this package uses google/protobuf/timestamp.proto, grpc_tools can resolve it automatically.
  # If you have your own shared protos later, add more -I here.

  # Build args list
  local args=()
  args+=("-I" "${include_path}")
  args+=("--python_out=${abs_pkg_dir}")
  args+=("--grpc_python_out=${abs_pkg_dir}")

  # Append proto file paths relative to include_path
  for p in "${protos[@]}"; do
    args+=("${abs_pkg_dir}/${p}")
  done

  python3 -m grpc_tools.protoc "${args[@]}"

  echo "✅ Done: ${abs_pkg_dir}"
  echo
}

# ---- Add packages here ----
gen_one_pkg "api/user-contracts/v1alpha" "./*.proto"
gen_one_pkg "api/user-contracts/v2alpha" "./*.proto"
# gen_one_pkg "api/order-contracts-v1" "order_contracts_v1" "order/v1/*.proto"

echo "All proto generations completed ✅"
