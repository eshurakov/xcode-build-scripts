#### Automatically update build number in Xcode

Each time you build your project, CFBundleVersion is updated with repository revision number.

* Copy `Scripts/Version.sh` script to your project dir
* Create new aggregate target in the project and add "Run Script" build phase (check and chage paths if needed): 
 
```bash  
/bin/bash "${PROJECT_DIR}/Scripts/Version.sh" \
          -plist "${PROJECT_DIR}/XcodeBuildScripts/XcodeBuildScripts-Info.plist" \
          -output "${PROJECT_DIR}/Version.h" \
          -prefix "XC_"
```
* Modify build settings of the main target:  
	* `Preprocess Info.plist File` => `YES`  
	* `Info.plist Preprocessor Prefix File` => `${PROJECT_DIR}/Version.h`
* Set `CFBundleVersion` in Info.plist to `XC_BUILD_NUMBER`
* Add aggregate target as a dependency of the main target, so that `Version.h` file is generated before Info.plist is preprocessed.
* Add `Version.h` to version control ignore list.
