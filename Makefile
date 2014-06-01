.SILENT: print-version

VERSION_SCRIPT = "Scripts/Version.sh"
BUILD_SCRIPT = "Scripts/Build.sh"
TESTFLIGHT_SCRIPT = "Scripts/Testflight.sh"

WORKSPACE = "XcodeBuildScripts.xcworkspace"
IOS_SDK = "iphoneos"
IOS_SIMULATOR_SDK = "iphonesimulator7.1"
ARTIFACTS_DIR = "artifacts"

TESTFLIGHT_API_TOKEN = "123"
TESTFLIGHT_TEAM_TOKEN = "321"
TESTFLIGHT_DISTRIBUTION_LISTS = "Developers"
TESTFLIGHT_ARTIFACT = "artifacts/testflight.json"

clean:
	rm -rf artifacts

print-version:
	/bin/bash ${VERSION_SCRIPT} \
		-workspace ${WORKSPACE} \
		-scheme "XcodeBuildScripts"

test-debug:
	/bin/bash ${BUILD_SCRIPT} \
		-workspace ${WORKSPACE} \
		-scheme "XcodeBuildScripts" \
		-configuration "Debug" \
		-sdk ${IOS_SIMULATOR_SDK} \
		-artifacts ${ARTIFACTS_DIR} \
		-run-tests

build-release:
	/bin/bash ${BUILD_SCRIPT} \
		-workspace ${WORKSPACE} \
		-scheme "XcodeBuildScripts" \
		-configuration "Release" \
		-sdk ${IOS_SDK} \
		-artifacts ${ARTIFACTS_DIR} \
		-identity "iPhone Distribution: That Guy" \
		-profile "Provisioning/TestApp-Release.mobileprovision"

testflight:
	/bin/bash ${TESTFLIGHT_SCRIPT} \
		-artifacts ${ARTIFACTS_DIR} \
		-api-token ${TESTFLIGHT_API_TOKEN} \
		-team-token ${TESTFLIGHT_TEAM_TOKEN} \
		-distribution-lists ${TESTFLIGHT_DISTRIBUTION_LISTS} \
		-output-file ${TESTFLIGHT_ARTIFACT}
