#!/bin/bash

TREE_DIR=${TREE_DIR:-}

# Support to specify multiple trees too, separated by space
for tree in $TREE_DIR; do
    tree_args="--tree $PWD/$tree $tree_args"
done

tree_l=$(printf "$PWD/%s " $TREE_DIR)
tree_l=${tree_l% }

tree_args=${tree_args% }

export TREE=${TREE:-$tree_l}
TREE_ARGS=${TREE_ARGS:-$tree_args}

YAML_TREE=$(printf "/%s," $TREE_DIR)
YAML_TREE="[${YAML_TREE%,}]"
REPOSITORY_NAME="${REPOSITORY_NAME:-MocaccinoOS Desktop}"
BUCKET=${BUCKET:-}
GITHUB_REPO=${GITHUB_REPO:-mocaccinoOS/desktop}
GITHUB_BRANCH=${GITHUB_BRANCH:-master}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-}
CACHE_REPOSITORY=${CACHE_REPOSITORY:-$IMAGE_REPOSITORY}
MINIO_API_URL=${MINIO_API_URL:-}
MINIO_SECRET_KEY=${MINIO_SECRET_KEY:-}
MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY:-}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-}
DOCKER_USER=${DOCKER_USER:-}
DOCKER_PASS=${DOCKER_PASS:-}
SMART_BUILD=${SMART_BUILD:-true}
BUILD_PHASE=${BUILD_PHASE:-true}
CREATE_PHASE=${CREATE_PHASE:-false}
PRUNE_PHASE=${PRUNE_PHASE:-false}
TRACE_LOGS_BACKGROUND=${TRACE_LOGS_BACKGROUND:-true}
BACKEND=${BACKEND:-img}
DOCKER_HOST=${DOCKER_HOST:-}
PRIVILEGED=${PRIVILEGED:-true}
REF=${REF:-}
NAMESPACE=${NAMESPACE:-}
PKG_LIST=$(luet tree pkglist $TREE_ARGS -o json)
COMPRESSION_TYPE=${COMPRESSION_TYPE:-gzip}
K8S_SCHEDULER=${K8S_SCHEDULER:-}
NODE_SELECTOR=${NODE_SELECTOR:-}
REPOSITORY_TYPE=${REPOSITORY_TYPE:-http}
REPOSITORY_URL=${REPOSITORY_URL:-https://get.mocaccino.org/mocaccino-desktop}

create_repo() {
    set -e
    mkdir build
    for i in $(echo "$PKG_LIST" | jq -rc '.packages[]'); do
        PACKAGE_PATH=$(echo "$i" | jq -r ".path")
        PACKAGE_NAME=$(echo "$i" | jq -r ".name")
        PACKAGE_CATEGORY=$(echo "$i" | jq -r ".category")
        PACKAGE_VERSION=$(echo "$i" | jq -r ".version")
        PACKAGE_VERSION="${PACKAGE_VERSION/+/-}"
        sudo -E luet util unpack $REPOSITORY_URL:$PACKAGE_NAME-$PACKAGE_CATEGORY-$PACKAGE_VERSION.metadata.yaml build
    done

    sudo -E luet create-repo \
          --push-images \
          --type docker \
          --output $REPOSITORY_URL \
          --name "$REPOSITORY_NAME" \
          --packages ${PWD}/build \
          $tree_args
}

create_job() {
    cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: luet.k8s.io/v1alpha1
kind: RepoBuild
metadata:
    name: $JOB_NAME
    annotations:
      luet-k8s.io/retry: "5"
spec:
    nodeSelector:
        $NODE_SELECTOR
    podScheduler: "k8s-resource-scheduler"
    annotations:
        k8s-resource-scheduler/burst-protect: "200"
    git_repository: 
        url: "https://github.com/${GITHUB_REPO}.git"
        checkout: "$REF"
    repository:
        name: "buildjob"
        description: ""
        urls:
        - "$REPOSITORY_URL"
        type: "$REPOSITORY_TYPE"
    storage:
        enabled: false
        url: "$MINIO_API_URL"
        secretKey: "$MINIO_SECRET_KEY"
        accessID: "$MINIO_ACCESS_KEY"
        bucket: "$BUCKET"
        path: ""
    options:
        pull: true
        push: true
        imageRepository: "$CACHE_REPOSITORY"
        pullRepository:
        - "$REPOSITORY_URL"
        pushFinalImages: true
        finalImagesRepository: "$IMAGE_REPOSITORY"
        onlyTarget: true
        compression: "$COMPRESSION_TYPE"
        tree: $YAML_TREE
        privileged: $PRIVILEGED
        liveOutput: true
        backend: $BACKEND
        environment:
        - name: DOCKER_HOST
          value: "$DOCKER_HOST"
    registry:
        enabled: true
        registry: "$DOCKER_REGISTRY"
        username: "$DOCKER_USER"
        password: "$DOCKER_PASS"
EOF
}

build() {
    JOB_NAME="$REPO-$GITHUB_BRANCH"

    if kubectl get repobuild -n $NAMESPACE $JOB_NAME; then
        JOB_STATE=$(kubectl get repobuild -n $NAMESPACE $JOB_NAME -o json | jq -r '.status.state')
        if [[ "$JOB_STATE" == "Pending" ]] || [[ "$JOB_STATE" == "Running" ]]; then
            echo "Job $JOB_NAME already running"
            current_checkout=$(kubectl get repobuild -n $NAMESPACE $JOB_NAME -o json | jq '.spec.git_repository.checkout' -r)
            if [[ "$REF" != "$current_checkout" ]]; then
	    	kubectl delete repobuild -n $NAMESPACE $JOB_NAME
                create_job
            fi
        fi
        if [[ "$JOB_STATE" == "Failed" ]]; then
            echo "Current job failed, deleting and recreating"
            kubectl delete repobuild -n $NAMESPACE $JOB_NAME
            create_job
        fi
    else 
        create_job
    fi

    STATE=$(kubectl get repobuild -n $NAMESPACE $JOB_NAME -o json | jq -r '.status.state')
    while ( [ "$STATE" == "Pending" ] || [ "$STATE" == "Running" ] || [[ "$STATE" == "null" ]])
    do
        echo "Jobs still running sleeping"
	sleep 10
        STATE=$(kubectl get repobuild -n $NAMESPACE $JOB_NAME -o json | jq -r '.status.state')
    done

    STATE=$(kubectl get repobuild -n $NAMESPACE $JOB_NAME -o json | jq -r '.status.state')

    case $STATE in

    Succeeded)
        echo "Repo build succeeded"
        kubectl delete repobuild -n $NAMESPACE $JOB_NAME
        ;;
    Failed)
        echo "Repo build failed"
        exit 1
        ;;
    *)
        echo -n "unknown state"
	exit 1
        ;;
    esac

}

if hash stern 2>/dev/null; then
    stern -n $NAMESPACE . &
fi

# mc alias set minio-ci $MINIO_API_URL $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

if [[ "$BUILD_PHASE" == "true" ]]; then
    build
fi

if [[ "$CREATE_PHASE" == "true" ]]; then
    create_repo
fi
