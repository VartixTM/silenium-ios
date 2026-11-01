// Отдельный фреймворк только ради символа main.
// jli (openjdk launcher на darwin) делает dlsym(RTLD_DEFAULT, "main"), а executable Swift/ObjC
// этот символ не экспортирует (nm -gU пусто), поэтому ищем его в загруженных образах.
// dlsym(RTLD_DEFAULT) видит экспорт любого загруженного dylib, поэтому main живёт здесь.
#include <stddef.h>

static int (*sileniumHandler)(int argc, char **argv) = NULL;

// executable вызывает это перед JLI_Launch
void SileniumEntrySetHandler(int (*handler)(int argc, char **argv)) {
    sileniumHandler = handler;
}

int main(int argc, char *argv[]) {
    if (sileniumHandler == NULL) {
        return -1;
    }
    return sileniumHandler(argc, argv);
}
