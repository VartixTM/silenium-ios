#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// запускает java через JLI_Launch из JRE (lib/jli/libjli.dylib или lib/libjli.dylib).
/// блокирующий вызов: JVM работает в текущем потоке и завершает процесс при выходе.
/// вызывать из потока с большим стеком (см. GameLauncher).
@interface SileniumJVM : NSObject

+ (int)launchWithJavaHome:(NSString *)javaHome arguments:(NSArray<NSString *> *)arguments;

@end

NS_ASSUME_NONNULL_END
