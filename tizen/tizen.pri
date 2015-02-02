TIZEN_APP_WRAPPER_FILES += tizen/tizen.pro \
               tizen/tizen-manifest.xml \
               tizen/tizenmain.cpp

OTHER_FILES += tizen/*.png

#command to build tizenWrapper (executable which will load )
tizenWrapper.name = Generating tizen application launcher
tizenWrapper.input = TIZEN_APP_WRAPPER_FILES
tizenWrapper.output = $$OUT_PWD/tizenWrapper/$$TARGET
tizenWrapper.commands = $(MKDIR) $$OUT_PWD/tizenWrapper;\
                        cd $$OUT_PWD/tizenWrapper; \
                        $(QMAKE) TARGET=$$TARGET $$PWD/tizen.pro; \
                        make clean; \
                        make

tizenWrapper.CONFIG += combine no_link target_predeps

tizenWrapperInstall.commands = rm -rf $(INSTALL_ROOT); \
                               make INSTALL_ROOT=$(INSTALL_ROOT) -C $$OUT_PWD/tizenWrapper install
tizenWrapperInstall.depends = tizenWrapper
tizenWrapperInstall.CONFIG = no_check_exist
tizenWrapperInstall.path = /

INSTALLS += tizenWrapperInstall

QMAKE_CLEAN += -r $$OUT_PWD/tizenWrapper
QMAKE_CLEAN += -r $$OUT_PWD/tizen-build

QMAKE_EXTRA_COMPILERS += tizenWrapper

install_target.depends = install_tizenWrapperInstall
!contains(TARGET, ".so"): TARGET = lib$${TARGET}.so

QMAKE_LFLAGS += -Wl,-soname,$$shell_quote($$TARGET) -pie
target.path = /bin

INSTALLS += target



