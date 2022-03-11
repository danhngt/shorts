#!/bin/bash
previous_branch=$(git rev-parse --abbrev-ref HEAD)
test_file="/tmp/test.sh"

test_folders() {
	xargs dirname \
	| grep -P "^features/" \
	| grep -v "common" \
	| sort -u
}
test_services() {
	test_folders \
	| sed 's/^[^/]*\///' \
	| sed 's/\/.*$//' \
	| sort -u
}

base_branch=$(\
	git show-branch \
	| sed "s/].*//" \
	| grep "\*" \
	| grep -v "$previous_branch" \
       	| head -n1 \
       	| sed "s/^.*\[//" \
)
folders="$(
	git diff "$base_branch" "$previous_branch" --name-only \
	| test_folders \
	| sort -u \
	| xargs -i echo -e "\t{} \\"
)"
services="$(\
	git diff "$base_branch" "$previous_branch" --name-only \
	| test_services \
	| sort -u \
	| xargs -i echo -e "\t{} \\"
)"

echo -e "#!/bin/bash

./deployments/build.bash
./deployments/build.bash \\
${services}
;

manabie.run ./deployments/k8s_bdd_test.bash \\
${folders}
;

notify-send -i emblem-default "Done"
paplay /usr/share/sounds/freedesktop/stereo/complete.oga
" > "$test_file"

vi "$test_file"
bash "$test_file"
