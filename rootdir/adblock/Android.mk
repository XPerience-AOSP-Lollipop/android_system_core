ifeq ($(XPERIENCE_IN_ADBLOCK),true)
	PRODUCT_COPY_FILES += hosts_block:system/etc/hosts
else
	PRODUCT_COPY_FILES += hosts:system/etc/hosts
endif