.SILENT:

clean:
	rm -rf artifacts

print-version:
	/bin/bash Scripts/Version.sh \
		-workspace "XcodeBuildScripts.xcworkspace" \
		-scheme "XcodeBuildScripts"

test-debug:
	/bin/bash Scripts/Build.sh \
		-workspace "XcodeBuildScripts.xcworkspace" \
		-scheme "XcodeBuildScripts" \
		-configuration "Debug" \
		-sdk "iphonesimulator7.0" \
		-artifacts "artifacts" \
		-run-tests

build-live:
	/bin/bash Scripts/Build.sh \
		-workspace "XcodeBuildScripts.xcworkspace" \
		-scheme "XcodeBuildScripts" \
		-configuration "Release" \
		-sdk "iphoneos7.0" \
		-artifacts "artifacts" \
		-identity "iPhone Distribution: That Guy" \
		-profile "Provisioning/TestApp-Live.mobileprovision"

test-live:
	/bin/bash Scripts/Build.sh \
		-workspace "XcodeBuildScripts.xcworkspace" \
		-scheme "XcodeBuildScripts" \
		-configuration "Release" \
		-sdk "iphonesimulator7.0" \
		-artifacts "artifacts" \
		-run-tests

testflight:
	/bin/bash Scripts/Build/Testflight.sh \
		-artifacts artifacts \
		-api-token 'auth-token-here' \
		-team-token 'team-token-here' \
		-output-file artifacts/testflight.json
