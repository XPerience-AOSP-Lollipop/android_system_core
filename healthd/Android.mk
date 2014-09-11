# Copyright 2013 The Android Open Source Project

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := BatteryMonitor.cpp
LOCAL_MODULE := libbatterymonitor
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_STATIC_LIBRARIES := libutils libbase libbinder
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := \
    healthd_mode_android.cpp \
    BatteryPropertiesRegistrar.cpp

LOCAL_MODULE := libhealthd_android
LOCAL_EXPORT_C_INCLUDE_DIRS := \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/include

LOCAL_STATIC_LIBRARIES := \
    libbatterymonitor \
    libbatteryservice \
    libutils \
    libbase \
    libcutils \
    liblog \
    libc \

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

HEALTHD_PATH := \
    RED_LED_PATH \
    GREEN_LED_PATH \
    BLUE_LED_PATH \
    TW_BRIGHTNESS_PATH \
    TW_SECONDARY_BRIGHTNESS_PATH

$(foreach healthd_charger_define,$(HEALTHD_PATH), \
  $(if $($(healthd_charger_define)), \
    $(eval LOCAL_CFLAGS += -D$(healthd_charger_define)=\"$($(healthd_charger_define))\") \
  ) \
)

ifeq ($(strip $(HEALTHD_FORCE_BACKLIGHT_CONTROL)),true)
LOCAL_CFLAGS += -DHEALTHD_FORCE_BACKLIGHT_CONTROL
endif

ifeq ($(strip $(HEALTHD_ENABLE_TRICOLOR_LED)),true)
LOCAL_CFLAGS += -DHEALTHD_ENABLE_TRICOLOR_LED
endif

ifneq ($(strip $(HEALTHD_BACKLIGHT_ON_LEVEL)),)
LOCAL_CFLAGS += -DHEALTHD_BACKLIGHT_ON_LEVEL=$(HEALTHD_BACKLIGHT_ON_LEVEL)
endif

LOCAL_CFLAGS := -Werror
ifeq ($(strip $(BOARD_CHARGER_DISABLE_INIT_BLANK)),true)
LOCAL_CFLAGS += -DCHARGER_DISABLE_INIT_BLANK
endif
ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
LOCAL_CFLAGS += -DCHARGER_ENABLE_SUSPEND
endif

LOCAL_SRC_FILES := \
    healthd_mode_charger.cpp \
    AnimationParser.cpp

LOCAL_MODULE := libhealthd_charger
LOCAL_C_INCLUDES := bootable/recovery $(LOCAL_PATH)/include
LOCAL_EXPORT_C_INCLUDE_DIRS := \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/include

LOCAL_STATIC_LIBRARIES := \
    libminui \
    libpng \
    libz \
    libutils \
    libbase \
    libcutils \
    liblog \
    libm \
    libc \

ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
LOCAL_STATIC_LIBRARIES += libsuspend
endif

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := healthd_board_msm.cpp
LOCAL_MODULE := libhealthd.qcom
LOCAL_CFLAGS := -Werror
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include

LOCAL_STATIC_LIBRARIES := \
    libbase

LOCAL_WHOLE_STATIC_LIBRARIES := \
    libcutils

include $(BUILD_STATIC_LIBRARY)

### charger ###
include $(CLEAR_VARS)
ifeq ($(strip $(BOARD_CHARGER_NO_UI)),true)
LOCAL_CHARGER_NO_UI := true
endif
ifdef BRILLO
LOCAL_CHARGER_NO_UI := true
endif

LOCAL_SRC_FILES := \
    healthd_common.cpp \
    charger.cpp \

LOCAL_MODULE := charger
LOCAL_MODULE_TAGS := optional
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT_SBIN)
LOCAL_UNSTRIPPED_PATH := $(TARGET_ROOT_OUT_SBIN_UNSTRIPPED)
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include

LOCAL_CFLAGS := -Werror
ifeq ($(strip $(LOCAL_CHARGER_NO_UI)),true)
LOCAL_CFLAGS += -DCHARGER_NO_UI
endif
ifneq ($(BOARD_PERIODIC_CHORES_INTERVAL_FAST),)
LOCAL_CFLAGS += -DBOARD_PERIODIC_CHORES_INTERVAL_FAST=$(BOARD_PERIODIC_CHORES_INTERVAL_FAST)
endif
ifneq ($(BOARD_PERIODIC_CHORES_INTERVAL_SLOW),)
LOCAL_CFLAGS += -DBOARD_PERIODIC_CHORES_INTERVAL_SLOW=$(BOARD_PERIODIC_CHORES_INTERVAL_SLOW)
endif

LOCAL_STATIC_LIBRARIES := \
    libhealthd_charger \
    libbatterymonitor \
    libbase \
    libutils \
    libcutils \
    liblog \
    libm \
    libc \

ifneq ($(strip $(LOCAL_CHARGER_NO_UI)),true)
LOCAL_STATIC_LIBRARIES += \
    libminui \
    libpng \
    libz \

endif

ifeq ($(strip $(BOARD_CHARGER_ENABLE_SUSPEND)),true)
LOCAL_STATIC_LIBRARIES += libsuspend
endif

LOCAL_HAL_STATIC_LIBRARIES := libhealthd

ifeq ($(BOARD_USES_QCOM_HARDWARE),true)
BOARD_HAL_STATIC_LIBRARIES ?= libhealthd.qcom
endif

# Symlink /charger to /sbin/charger
LOCAL_POST_INSTALL_CMD := $(hide) mkdir -p $(TARGET_ROOT_OUT) \
    && ln -sf /sbin/charger $(TARGET_ROOT_OUT)/charger

include $(BUILD_EXECUTABLE)

ifneq ($(strip $(LOCAL_CHARGER_NO_UI)),true)
define _add-charger-image
include $$(CLEAR_VARS)
LOCAL_MODULE := system_core_charger_res_images_$(notdir $(1))
LOCAL_MODULE_STEM := $(notdir $(1))
_img_modules += $$(LOCAL_MODULE)
LOCAL_SRC_FILES := $1
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $$(TARGET_ROOT_OUT)/res/images/charger
include $$(BUILD_PREBUILT)
endef

_img_modules :=
_images :=
$(foreach _img, $(call find-subdir-subdir-files, "images", "*.png"), \
  $(eval $(call _add-charger-image,$(_img))))

include $(CLEAR_VARS)
LOCAL_MODULE := charger_res_images
LOCAL_MODULE_TAGS := optional
LOCAL_REQUIRED_MODULES := $(_img_modules)
include $(BUILD_PHONY_PACKAGE)

_add-charger-image :=
_img_modules :=
endif # LOCAL_CHARGER_NO_UI

### healthd ###
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    healthd_common.cpp \
    healthd.cpp \

LOCAL_MODULE := healthd
LOCAL_MODULE_TAGS := optional
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include

ifneq ($(BOARD_PERIODIC_CHORES_INTERVAL_FAST),)
LOCAL_CFLAGS += -DBOARD_PERIODIC_CHORES_INTERVAL_FAST=$(BOARD_PERIODIC_CHORES_INTERVAL_FAST)
endif
ifneq ($(BOARD_PERIODIC_CHORES_INTERVAL_SLOW),)
LOCAL_CFLAGS += -DBOARD_PERIODIC_CHORES_INTERVAL_SLOW=$(BOARD_PERIODIC_CHORES_INTERVAL_SLOW)
endif

LOCAL_STATIC_LIBRARIES := \
    libhealthd_android \
    libbatterymonitor \
    libbatteryservice \
    android.hardware.health@1.0-convert \

LOCAL_SHARED_LIBRARIES := \
    libbinder \
    libbase \
    libutils \
    libcutils \
    liblog \
    libm \
    libc \
    libhidlbase \
    libhidltransport \
    android.hardware.health@1.0 \

include $(BUILD_EXECUTABLE)
