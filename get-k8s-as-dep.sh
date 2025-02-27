#!/bin/bash

rm go.mod go.sum
go mod init sample-scheduler

VERSION=${1#"v"}
if [ -z "$VERSION" ]; then
    echo "Please specify the Kubernetes version: e.g."
    echo "bash hack/get-k8s-as-dep.sh 1.21.6"
    exit 1
fi

set -euo pipefail
set -x

# Find out all the replaced imports, make a list of them.
MODS=($(
    curl -sS "https://raw.githubusercontent.com/kubernetes/kubernetes/v${VERSION}/go.mod" |
        sed -n 's|.*k8s.io/\(.*\) => ./staging/src/k8s.io/.*|k8s.io/\1|p'
))

# Now add those similar replace statements in the local go.mod file, but first find the version that
# the Kubernetes is using for them.
for MOD in "${MODS[@]}"; do
    V=$(
        go mod download -json "${MOD}@kubernetes-${VERSION}" |
            sed -n 's|.*"Version": "\(.*\)".*|\1|p'
    )

    go mod edit "-replace=${MOD}=${MOD}@${V}"
done

go get "k8s.io/kubernetes@v${VERSION}"
go mod download
go mod tidy
