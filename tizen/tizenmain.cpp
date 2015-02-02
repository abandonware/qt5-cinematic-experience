#include <tizen.h>
#include <app.h>
#include <system_settings.h>
#include <pthread.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dlog.h>

#include <QCoreApplication>
#include <QMutex>
#include <QSemaphore>
#include <QWaitCondition>
#include <QtPlatformHeaders/qxcbfunctions.h>

typedef int (*Main)(int, char **); //use the standard main method to start the application
Main m_main = 0;
void *m_mainLibraryHnd = 0;

int argcGlobal = 0;
char ** argvGlobal = 0;
int qtRet = 0;
QSemaphore appStartedSemaphore(0);
QMutex appTerminatedMutex;
QWaitCondition qtAppCreatedOrErrorEncountered;

static void
ui_app_orient_changed(app_event_info_h /*event_info*/, void */*user_data*/)
{
    /*APP_EVENT_DEVICE_ORIENTATION_CHANGED*/
    app_device_orientation_e nativeOrientation = app_get_device_orientation();

    static Qt::ScreenOrientation orientations[] = {
        Qt::PortraitOrientation,
        Qt::InvertedLandscapeOrientation,
        Qt::InvertedPortraitOrientation,
        Qt::LandscapeOrientation
    };

    //  Tizen orientation
    //    typedef enum
    //    {
    //        APP_DEVICE_ORIENTATION_0 = 0, /**< The device is oriented in a natural position */
    //        APP_DEVICE_ORIENTATION_90 = 90, /**< The device's left side is at the top */
    //        APP_DEVICE_ORIENTATION_180 = 180, /**< The device is upside down */
    //        APP_DEVICE_ORIENTATION_270 = 270, /**< The device's right side is at the top */
    //    } app_device_orientation_e;
    QXcbFunctions::setDeviceOrientation(orientations[nativeOrientation/90]);
}

void dlogMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QString localMsg = qFormatLogMessage(type, context, msg);
    log_priority priority = DLOG_DEBUG;
    switch (type) {
    case QtDebugMsg: priority = DLOG_DEBUG; break;
    case QtWarningMsg: priority = DLOG_WARN; break;
    case QtCriticalMsg: priority = DLOG_ERROR; break;
    case QtFatalMsg: priority = DLOG_FATAL; break;
    };

    dlog_print(priority, qPrintable(QCoreApplication::applicationName()), "%s", qPrintable(localMsg));
}

// Called once QCoreApplication exists
static void afterAppStarted()
{
    qtAppCreatedOrErrorEncountered.wakeAll();
}

static void *invokeQtMain(void */*notUsed*/) {
    qAddPreRoutine(afterAppStarted);
    qInstallMessageHandler(dlogMessageOutput);
    qtRet = m_main(argcGlobal, argvGlobal);
    if (m_mainLibraryHnd) {
        int res = dlclose(m_mainLibraryHnd);
        if (res < 0)
            fprintf(stderr, "dlclose failed: %s.\n",dlerror());
    }

    m_mainLibraryHnd = 0;
    m_main = 0;
    if (appTerminatedMutex.tryLock()) {
        //app_terminate has not locked mutex so it was Qt app
        //which exited first and we need to exit also from
        //tizen app
        ui_app_exit();
    }
    //handling scenario where afterAppStarted is never invoked
    //this way we wake up wait condition in app_create
    qtAppCreatedOrErrorEncountered.wakeAll();
    return 0;
}

static bool startQtApp() {
    char *dllPath = (char *)calloc(sizeof(char), strlen(argvGlobal[0])+6);
    char *pointerToLastSlashInPath = strrchr(argvGlobal[0], '/');
    char *binaryName = (pointerToLastSlashInPath + 1);
    strncpy(dllPath, argvGlobal[0], strlen(argvGlobal[0]) - strlen(pointerToLastSlashInPath) + 1);
    strcat(strcat(strcat(dllPath, "lib"), binaryName), ".so");
    m_mainLibraryHnd = dlopen(dllPath, RTLD_LAZY);
    free(dllPath);
    if (m_mainLibraryHnd == 0) {
        fprintf(stderr,"dlopen failed:%s.\n", dlerror());
        return false;
    }
    m_main = (Main)dlsym(m_mainLibraryHnd, "main");
    if (!m_main) {
        fprintf(stderr,"dlsym failed:%s.\n", dlerror());
        return false;
    }
    pthread_t appThread;
    return pthread_create(&appThread, 0, invokeQtMain, 0) == 0;
}

static bool
app_create(void */*data*/)
{
    /* Hook to take necessary actions before main event loop starts
        Initialize UI resources and application's data
        If this function returns true, the main loop of application starts
        If this function returns false, the application is terminated */
    //appdata_s *ad = data;

    bool ret = startQtApp();
    if (ret) {
        //wait until Qt app will be created or error will be encountered and
        QMutex tmp;
        tmp.lock();
        qtAppCreatedOrErrorEncountered.wait(&tmp);
        tmp.unlock();
        //we check if invokeQtApp not exited Qt's app main
        if (appTerminatedMutex.tryLock()) {
            appTerminatedMutex.unlock();
            ui_app_orient_changed(0,0);
        } else
            //Qt's app exited main
            return false;
    }
    return ret;
}

static void
app_terminate(void */*data*/)
{
    /* Release all resources. */
    if (appTerminatedMutex.tryLock())
        QMetaObject::invokeMethod(qApp, "quit", Qt::QueuedConnection);
    else
        appTerminatedMutex.unlock();
}

int
main(int argc, char *argv[])
{
    argcGlobal = argc;
    argvGlobal = argv;
    int ret = 0;
    setenv("QT_XKB_CONFIG_ROOT", "/etc/X11/xkb", 1);
    ui_app_lifecycle_callback_s event_callback = {0,0,0,0,0};
    app_event_handler_h handlers[5] = {NULL, };

    event_callback.create = app_create;
    event_callback.terminate = app_terminate;
    ui_app_add_event_handler(&handlers[APP_EVENT_DEVICE_ORIENTATION_CHANGED], APP_EVENT_DEVICE_ORIENTATION_CHANGED, ui_app_orient_changed, 0);
    ret = ui_app_main(argc, argv, &event_callback, 0);

    if (ret != APP_ERROR_NONE) {
        fprintf(stderr,"app_main() is failed. err = %d", ret);
    }

    if (ret == 0 && qtRet)
        return qtRet;

    return ret;
}


