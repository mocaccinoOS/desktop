#!/bin/bash

PACK=$1
ADD="${ADD:-false}"
GENERATE_PROVIDES="${GENERATE_PROVIDES:-false}"
DEBUG="${DEBUG:-false}"
if [ -z "${PACK}" ]; then
	echo "You must provide a package as an argument at least"
	exit 1
fi
packages=()
REPO_CACHE="${REPO_CACHE:-quay.io/mocaccino/desktop}"
#set -ex
IMAGES_DATA=$(luet tree images --image-repository $REPO_CACHE $PACK -o json)
PKG_LIST=$(luet tree pkglist -o json)
images=($(echo $IMAGES_DATA | jq -r '.packages[].image' ))
images_names=($(echo $IMAGES_DATA | jq -r '.packages[].name' ))

if [ "$DEBUG" == "true" ]; then
echo "For layer $PACK:
previous packages layer: ${images_names[-2]}
after packages layer: ${images_names[-1]}
"
fi

if [[ "${#images[@]}" == "1" ]];then
  packages_before=()
else
  if [ "${images_names[-1]}" == "system-x" ] ; then
    packages_before=()
  else
    packages_before=( $(docker run --rm ${images[-2]} qlist -ISC) )
  fi
fi
packages_after=( $(docker run --rm ${images[-1]} qlist -ICS) )

IFS=/ read -a p <<< $PACK


path=$(echo "$PKG_LIST" | jq -r ".packages[] | select(.name==\"${p[1]}\" and .category==\"${p[0]}\").path")
for target in "${packages_before[@]}"; do
  for i in "${!packages_after[@]}"; do
    if [[ ${packages_after[i]} = $target ]]; then
      unset 'packages_after[i]'
    fi
  done
done

if [ -e "$path/definition.yaml" ] && [ ${#packages_after[@]} -ne 0 ]; then
  # Prune existing provides first
  yq w -i $path/definition.yaml 'provides' ''
fi

p=0
for i in ${packages_after[@]};
do
  echo "$i"
  if [ "${ADD}" == "true" ]; then
  	echo "Adding $i"
  	yq w -i $path/definition.yaml "emerge_packages[$p]" "${i}"
  fi

  if [ "${GENERATE_PROVIDES}" == "true" ]; then
    name=$(pkgs-checker pkg info $i --json | jq '.name' -r)
    cat=$(pkgs-checker pkg info $i --json | jq '.category' -r)
  
    echo "Adding ${cat}/${name} ($i)"

    yq w -i $path/definition.yaml "provides[$p].name" "${name}"
    yq w -i $path/definition.yaml "provides[$p].category" "${cat}"
    yq w -i $path/definition.yaml "provides[$p].version" ">=0"
  fi

  p=$((p+1))
done
