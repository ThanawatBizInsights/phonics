#!/usr/bin/env python3
"""Generates PhonicsPond.xcodeproj (Xcode 16+, synchronized folders) and its shared scheme.

Targets: PhonicsPond (iPad app), PhonicsPondTests (unit), PhonicsPondUITests (UI flows).
Because the folders are synchronized, files added to PhonicsPond/PhonicsPond (including
recordings in Resources/Audio) join the app target with no project edits.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "PhonicsPond", "PhonicsPond.xcodeproj")
I = lambda n: "AA%022X" % n

proj = I(1)
T = {  # name: (target id, product ref, group, frameworks, sources, resources, config list, debug, release, proxy, dep)
    "PhonicsPond":        dict(t=I(10), ref=I(30), g=I(40), fw=I(50), src=I(80), res=I(82), cl=I(70), d=I(92), r=I(93)),
    "PhonicsPondTests":   dict(t=I(11), ref=I(31), g=I(41), fw=I(51), src=I(81), res=I(83), cl=I(71), d=I(94), r=I(95), proxy=I(20), dep=I(21)),
    "PhonicsPondUITests": dict(t=I(12), ref=I(32), g=I(42), fw=I(52), src=I(84), res=I(85), cl=I(73), d=I(96), r=I(97), proxy=I(22), dep=I(23)),
}
main, products, clProj, pD, pR = I(60), I(61), I(72), I(90), I(91)

def settings(d):
    out = []
    for k, v in d.items():
        if isinstance(v, list):
            out.append("\t\t\t\t%s = (\n%s\t\t\t\t);" % (k, "".join("\t\t\t\t\t%s,\n" % x for x in v)))
        else:
            out.append("\t\t\t\t%s = %s;" % (k, v))
    return "\n".join(out)

common = {
    "ALWAYS_SEARCH_USER_PATHS": "NO", "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES", "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"', "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES", "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES", "CLANG_WARN_UNREACHABLE_CODE": "YES",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES", "ENABLE_USER_SCRIPT_SANDBOXING": "YES", "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES", "IPHONEOS_DEPLOYMENT_TARGET": "17.0", "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES", "SDKROOT": "iphoneos", "SWIFT_VERSION": "5.0",
}
projD = dict(common, **{
    "COPY_PHASE_STRIP": "NO", "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO", "GCC_OPTIMIZATION_LEVEL": "0", "GCC_PREPROCESSOR_DEFINITIONS": ['"DEBUG=1"', '"$(inherited)"'],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE", "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG $(inherited)"', "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"'})
projR = dict(common, **{
    "COPY_PHASE_STRIP": "NO", "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"', "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO", "SWIFT_COMPILATION_MODE": "wholemodule", "VALIDATE_PRODUCT": "YES"})
appS = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon", "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic", "CURRENT_PROJECT_VERSION": "1", "DEVELOPMENT_TEAM": '""', "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES", "INFOPLIST_KEY_CFBundleDisplayName": '"Phonics Pond"',
    "INFOPLIST_KEY_LSApplicationCategoryType": '"public.app-category.education"',
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES", "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UIRequiresFullScreen": "YES", "INFOPLIST_KEY_UIStatusBarHidden": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": '"UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"',
    "LD_RUNPATH_SEARCH_PATHS": ['"$(inherited)"', '"@executable_path/Frameworks"'], "MARKETING_VERSION": "0.1",
    "PRODUCT_BUNDLE_IDENTIFIER": "app.phonicspond.PhonicsPond", "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"', "SUPPORTS_MACCATALYST": "NO",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO", "SWIFT_EMIT_LOC_STRINGS": "YES", "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "2"}
testBase = {
    "CODE_SIGN_STYLE": "Automatic", "CURRENT_PROJECT_VERSION": "1", "DEVELOPMENT_TEAM": '""',
    "GENERATE_INFOPLIST_FILE": "YES", "IPHONEOS_DEPLOYMENT_TARGET": "17.0", "MARKETING_VERSION": "0.1",
    "PRODUCT_NAME": '"$(TARGET_NAME)"', "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
    "SWIFT_EMIT_LOC_STRINGS": "NO", "SWIFT_VERSION": "5.0", "TARGETED_DEVICE_FAMILY": "2"}
unitS = dict(testBase, **{
    "BUNDLE_LOADER": '"$(TEST_HOST)"', "PRODUCT_BUNDLE_IDENTIFIER": "app.phonicspond.PhonicsPondTests",
    "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/PhonicsPond.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PhonicsPond"'})
uiS = dict(testBase, **{"PRODUCT_BUNDLE_IDENTIFIER": "app.phonicspond.PhonicsPondUITests", "TEST_TARGET_NAME": "PhonicsPond"})
SET = {"PhonicsPond": appS, "PhonicsPondTests": unitS, "PhonicsPondUITests": uiS}
TYPE = {"PhonicsPond": ("com.apple.product-type.application", "wrapper.application", "app"),
        "PhonicsPondTests": ("com.apple.product-type.bundle.unit-test", "wrapper.cfbundle", "xctest"),
        "PhonicsPondUITests": ("com.apple.product-type.bundle.ui-testing", "wrapper.cfbundle", "xctest")}

def cfg(i, name, s):
    return "\t\t%s /* %s */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n%s\n\t\t\t};\n\t\t\tname = %s;\n\t\t};\n" % (i, name, settings(s), name)

def phase(i, isa, name):
    return "\t\t%s /* %s */ = {\n\t\t\tisa = %s;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n" % (i, name, isa)

def clist(i, name, d, r):
    return ("\t\t%s /* %s */ = {\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t%s /* Debug */,\n\t\t\t\t%s /* Release */,\n\t\t\t);\n"
            "\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n") % (i, name, d, r)

o = "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n\n"
o += "/* Begin PBXContainerItemProxy section */\n"
for n in ("PhonicsPondTests", "PhonicsPondUITests"):
    o += ("\t\t%s /* PBXContainerItemProxy */ = {\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = %s /* Project object */;\n"
          "\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = %s;\n\t\t\tremoteInfo = PhonicsPond;\n\t\t};\n") % (T[n]["proxy"], proj, T["PhonicsPond"]["t"])
o += "/* End PBXContainerItemProxy section */\n\n/* Begin PBXFileReference section */\n"
for n, t in T.items():
    ext = TYPE[n][2]
    o += "\t\t%s /* %s.%s */ = {isa = PBXFileReference; explicitFileType = %s; includeInIndex = 0; path = %s.%s; sourceTree = BUILT_PRODUCTS_DIR; };\n" % (t["ref"], n, ext, TYPE[n][1], n, ext)
o += "/* End PBXFileReference section */\n\n/* Begin PBXFileSystemSynchronizedRootGroup section */\n"
for n, t in T.items():
    o += "\t\t%s /* %s */ = {\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\tpath = %s;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n" % (t["g"], n, n)
o += "/* End PBXFileSystemSynchronizedRootGroup section */\n\n/* Begin PBXFrameworksBuildPhase section */\n"
o += "".join(phase(t["fw"], "PBXFrameworksBuildPhase", "Frameworks") for t in T.values())
o += "/* End PBXFrameworksBuildPhase section */\n\n/* Begin PBXGroup section */\n"
o += "\t\t%s = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n%s\t\t\t\t%s /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n" % (
    main, "".join("\t\t\t\t%s /* %s */,\n" % (t["g"], n) for n, t in T.items()), products)
o += "\t\t%s /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n%s\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n" % (
    products, "".join("\t\t\t\t%s,\n" % t["ref"] for t in T.values()))
o += "/* End PBXGroup section */\n\n/* Begin PBXNativeTarget section */\n"
for n, t in T.items():
    deps = "\t\t\t\t%s /* PBXTargetDependency */,\n" % t["dep"] if "dep" in t else ""
    o += ("\t\t%s /* %s */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = %s;\n\t\t\tbuildPhases = (\n\t\t\t\t%s /* Sources */,\n\t\t\t\t%s /* Frameworks */,\n\t\t\t\t%s /* Resources */,\n\t\t\t);\n"
          "\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n%s\t\t\t);\n\t\t\tfileSystemSynchronizedGroups = (\n\t\t\t\t%s /* %s */,\n\t\t\t);\n\t\t\tname = %s;\n"
          "\t\t\tpackageProductDependencies = (\n\t\t\t);\n\t\t\tproductName = %s;\n\t\t\tproductReference = %s;\n\t\t\tproductType = \"%s\";\n\t\t};\n") % (
        t["t"], n, t["cl"], t["src"], t["fw"], t["res"], deps, t["g"], n, n, n, t["ref"], TYPE[n][0])
o += "/* End PBXNativeTarget section */\n\n/* Begin PBXProject section */\n"
app = T["PhonicsPond"]["t"]
attrs = "\t\t\t\t\t%s = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t};\n" % app
for n in ("PhonicsPondTests", "PhonicsPondUITests"):
    attrs += "\t\t\t\t\t%s = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t\tTestTargetID = %s;\n\t\t\t\t\t};\n" % (T[n]["t"], app)
o += ("\t\t%s /* Project object */ = {\n\t\t\tisa = PBXProject;\n\t\t\tattributes = {\n\t\t\t\tBuildIndependentTargetsInParallel = 1;\n\t\t\t\tLastSwiftUpdateCheck = 1600;\n\t\t\t\tLastUpgradeCheck = 1600;\n"
      "\t\t\t\tTargetAttributes = {\n%s\t\t\t\t};\n\t\t\t};\n\t\t\tbuildConfigurationList = %s;\n\t\t\tdevelopmentRegion = en;\n\t\t\thasScannedForEncodings = 0;\n"
      "\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t);\n\t\t\tmainGroup = %s;\n\t\t\tminimizedProjectReferenceProxies = 1;\n\t\t\tpreferredProjectObjectVersion = 77;\n"
      "\t\t\tproductRefGroup = %s /* Products */;\n\t\t\tprojectDirPath = \"\";\n\t\t\tprojectRoot = \"\";\n\t\t\ttargets = (\n%s\t\t\t);\n\t\t};\n") % (
    proj, attrs, clProj, main, products, "".join("\t\t\t\t%s /* %s */,\n" % (t["t"], n) for n, t in T.items()))
o += "/* End PBXProject section */\n\n/* Begin PBXResourcesBuildPhase section */\n"
o += "".join(phase(t["res"], "PBXResourcesBuildPhase", "Resources") for t in T.values())
o += "/* End PBXResourcesBuildPhase section */\n\n/* Begin PBXSourcesBuildPhase section */\n"
o += "".join(phase(t["src"], "PBXSourcesBuildPhase", "Sources") for t in T.values())
o += "/* End PBXSourcesBuildPhase section */\n\n/* Begin PBXTargetDependency section */\n"
for n in ("PhonicsPondTests", "PhonicsPondUITests"):
    o += "\t\t%s /* PBXTargetDependency */ = {\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = %s /* PhonicsPond */;\n\t\t\ttargetProxy = %s /* PBXContainerItemProxy */;\n\t\t};\n" % (T[n]["dep"], app, T[n]["proxy"])
o += "/* End PBXTargetDependency section */\n\n/* Begin XCBuildConfiguration section */\n"
o += cfg(pD, "Debug", projD) + cfg(pR, "Release", projR)
for n, t in T.items():
    o += cfg(t["d"], "Debug", SET[n]) + cfg(t["r"], "Release", SET[n])
o += "/* End XCBuildConfiguration section */\n\n/* Begin XCConfigurationList section */\n"
for n, t in T.items():
    o += clist(t["cl"], 'Build configuration list for PBXNativeTarget "%s"' % n, t["d"], t["r"])
o += clist(clProj, 'Build configuration list for PBXProject "PhonicsPond"', pD, pR)
o += "/* End XCConfigurationList section */\n\t};\n\trootObject = %s /* Project object */;\n}\n" % proj

os.makedirs(os.path.join(PROJ, "xcshareddata", "xcschemes"), exist_ok=True)
open(os.path.join(PROJ, "project.pbxproj"), "w").write(o)

def ref(n):
    ext = TYPE[n][2]
    return ('<BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "%s" BuildableName = "%s.%s" '
            'BlueprintName = "%s" ReferencedContainer = "container:PhonicsPond.xcodeproj"></BuildableReference>') % (T[n]["t"], n, ext, n)

scheme = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            %(app)s
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES" shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference skipped = "NO" parallelizable = "NO">
            %(unit)s
         </TestableReference>
         <TestableReference skipped = "NO" parallelizable = "NO">
            %(ui)s
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         %(app)s
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         %(app)s
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
""" % dict(app=ref("PhonicsPond"), unit=ref("PhonicsPondTests"), ui=ref("PhonicsPondUITests"))
open(os.path.join(PROJ, "xcshareddata", "xcschemes", "PhonicsPond.xcscheme"), "w").write(scheme)
print("wrote", os.path.relpath(PROJ, ROOT))
