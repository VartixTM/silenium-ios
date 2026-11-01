#import "JVMBridge.h"

#import <dlfcn.h>
#import <signal.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>

// сигнатура JLI_Launch, как в openjdk launcher (та же, что использует Amethyst)
typedef int (*SileniumJLILaunchFunc)(int argc, const char **argv,
                                     int jargc, const char **jargv,
                                     int appclassc, const char **appclassv,
                                     const char *fullversion, const char *dotversion,
                                     const char *pname, const char *lname,
                                     unsigned char cpwildcard, unsigned char javaargs,
                                     unsigned char javaw, int ergo);

int (*sileniumJVMReentry)(int argc, char **argv) = NULL;
static SileniumJLILaunchFunc sileniumLaunch = NULL;

// SileniumEntry.framework: экспортирует main для dlsym(RTLD_DEFAULT, "main") в jli
extern void SileniumEntrySetHandler(int (*handler)(int argc, char **argv));

static int sileniumReentry(int argc, char **argv) {
    return sileniumLaunch(argc, (const char **)argv, 0, NULL, 0, NULL,
                          "1.8.0-internal", "1.8", "java", "openjdk",
                          0, 1, 0, 1);
}

@implementation SileniumJVM

+ (int)launchWithJavaHome:(NSString *)javaHome arguments:(NSArray<NSString *> *)arguments {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *jli8 = [javaHome stringByAppendingPathComponent:@"lib/jli/libjli.dylib"];
    NSString *jli11 = [javaHome stringByAppendingPathComponent:@"lib/libjli.dylib"];
    NSString *jli = [fm fileExistsAtPath:jli8] ? jli8 : jli11;

    setenv("JAVA_HOME", javaHome.UTF8String, 1);

    // stdout/stderr JVM и ошибки лаунчера пишем в Documents/silenium-jvm.log
    // (видно в Files → Silenium на устройстве)
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *logPath = [docs stringByAppendingPathComponent:@"silenium-jvm.log"];
    freopen(logPath.UTF8String, "w", stdout);
    dup2(fileno(stdout), fileno(stderr));
    setvbuf(stdout, NULL, _IONBF, 0);

    void *lib = dlopen(jli.UTF8String, RTLD_GLOBAL);
    if (lib == NULL) {
        NSLog(@"[silenium-jvm] dlopen %@: %s", jli, dlerror());
        return -1;
    }

    SileniumJLILaunchFunc launch = (SileniumJLILaunchFunc)dlsym(lib, "JLI_Launch");
    if (launch == NULL) {
        NSLog(@"[silenium-jvm] JLI_Launch не найден в %@", jli);
        return -2;
    }

    // JVM ловит свои краши сама, иначе приложение умирает раньше, чем отчёт
    signal(SIGSEGV, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGFPE, SIG_DFL);

    int argc = (int)arguments.count + 1;
    const char **argv = calloc((size_t)argc + 1, sizeof(char *));
    if (argv == NULL) {
        return -3;
    }
    argv[0] = "java";
    for (NSUInteger i = 0; i < arguments.count; i++) {
        // строки живут, пока жив массив arguments у вызывающего кода
        argv[i + 1] = arguments[i].UTF8String;
    }

    NSLog(@"[silenium-jvm] JLI_Launch, argc=%d, java=%@", argc, javaHome);
    printf("[silenium] java=%s\n", javaHome.UTF8String);
    for (int i = 0; i < argc; i++) {
        // токен в лог не пишем
        if (i > 0 && strcmp(argv[i - 1], "--accessToken") == 0) {
            printf("[silenium] argv[%d]=<redacted>\n", i);
            continue;
        }
        printf("[silenium] argv[%d]=%s\n", i, argv[i]);
    }
    sileniumLaunch = launch;
    sileniumJVMReentry = sileniumReentry;
    SileniumEntrySetHandler(sileniumReentry);
    int ret = launch(argc, argv, 0, NULL, 0, NULL,
                     "1.8.0-internal", "1.8", "java", "openjdk",
                     0, 1, 0, 1);
    free(argv);
    return ret;
}

@end
