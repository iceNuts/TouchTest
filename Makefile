GO_EASY_ON_ME=1
include theos/makefiles/common.mk

TOOL_NAME = touchtest
touchtest_FILES = main.mm
touchtest_FRAMEWORKS= CoreFoundation IOKit QuartzCore
touchtest_PRIVATE_FRAMEWORKS= AppSupport
SUBPROJECTS=hook

include $(THEOS_MAKE_PATH)/tool.mk
include $(THEOS_MAKE_PATH)/aggregate.mk