BUNDLE := com.amywhile.Nitroless

.PHONY: all clean

all: clean
	xcodebuild clean build ONLY_ACTIVE_ARCH=NO -sdk iphoneos -scheme NitrolessiOS -configuration Automation -derivedDataPath build 
	ln -sf build/Build/Products/Automation-iphoneos Payload
	rm -rf Payload/NitrolessiOS.app/Frameworks
	zip -r9 NitrolessiOS.ipa Payload/NitrolessiOS.app

clean:
	rm -rf build Payload NitrolessiOS.ipa
