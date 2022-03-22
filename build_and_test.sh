#!/bin/bash
previous_branch=$(git rev-parse --abbrev-ref HEAD)

test_file="/tmp/test.sh"
chmod +x $test_file

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
folder_test=""
for folder in $(
		git diff "$base_branch" "$previous_branch" --name-only \
		| test_folders \
		| sort -u \
	); do
	folder_test="$folder_test\nmanabie.run ./deployments/k8s_bdd_test.bash $folder"
done

services="$(\
	git diff "$base_branch" "$previous_branch" --name-only \
	| test_services \
	| sort -u \
	| xargs -i echo "\t{} \\";
)"

echo -e "#!/bin/bash

./deployments/build.bash \\
	gandalf \\
${services}
;
${folder_test}

notify-send -i emblem-default "Done"
paplay /usr/share/sounds/freedesktop/stereo/complete.oga
" > $test_file
