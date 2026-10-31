#import <UIKit/UIKit.h>

// задаётся в JVMBridge.m перед JLI_Launch
extern int (*sileniumJVMReentry)(int argc, char **argv);

int main(int argc, char *argv[]) {
    // openjdk launcher на macOS-ветке (CreateExecutionEnvironment) заново зовёт main() в новом потоке
    // (apple_main). второй UIApplicationMain даёт "There can only be one UIApplication instance",
    // поэтому отдаём управление JLI, как это делает Amethyst.
    if (sileniumJVMReentry != NULL) {
        return sileniumJVMReentry(argc, argv);
    }
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, @"SileniumAppDelegate");
    }
}
