/*

 HOT DOG Linux

 Copyright (c) 2020 Arthur Choung. All rights reserved.

 Email: arthur -at- hotdoglinux.com

 This file is part of HOT DOG Linux.

 HOT DOG Linux is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.

 */

#import "HOTDOG.h"

static void signal_handler(int num)
{
NSLog(@"signal_handler %d", num);
}

int main(int argc, char **argv)
{
    if (signal(SIGPIPE, signal_handler) == SIG_ERR) {
NSLog(@"unable to set signal handler for SIGPIPE");
    }

#ifndef BUILD_FOR_OSX
    extern void HOTDOG_initialize(FILE *);
    if ((argc >= 2) && !strcmp(argv[1], "dialog")) {
        FILE *fp = fopen("/dev/null", "w");
        if (!fp) {
            fprintf(stderr, "unable to open /dev/null\n");
            exit(1);
        }
        HOTDOG_initialize(fp);
    } else {
        HOTDOG_initialize(stderr);
    }
#endif


    id pool = [[NSAutoreleasePool alloc] init];

#ifdef BUILD_FOR_ANDROID
#else
        id execDir = [Definitions execDir];

        /* If argv[0] contains a slash, then add the directory that the
           executable resides in to the PATH */
        if ((argc > 0) && strchr(argv[0], '/')) {
            char *pathcstr = getenv("PATH");
            id path = nil;
            if (pathcstr && strlen(pathcstr)) {
                path = nsfmt(@"%@:%s", execDir, pathcstr);
            } else {
                path = execDir;
            }
            if (setenv("PATH", [path UTF8String], 1) != 0) {
NSLog(@"Unable to set PATH");
            }
        }

        if (setenv("SUDO_ASKPASS", [[Definitions execDir:@"hotdog-getPassword.pl"] UTF8String], 1) != 0) {
NSLog(@"Unable to setenv SUDO_ASKPASS");
        }

        if (argc == 1) {
            id object = [Definitions navigationStack];
            [[Definitions configDir:@"MainMenu"] changeDirectory];
            [object pushObject:[Definitions ObjectInterface]];
            [Definitions runWindowManagerForObject:object];
            [[Definitions navigationStack] setValue:nil forKey:@"context"];
        } else if ((argc > 1) && !strcmp(argv[1], "open")) {
            if (argc > 2) {
                id filePath = nscstr(argv[2]);
                if ([filePath isDirectory]) {
                    chdir(argv[2]);
                }
            }
            id obj = [Definitions ObjectInterface];
            if (obj) {
                if ([obj isKindOfClass:[@"Panel" asClass]]) {
                    id nav = [Definitions navigationStack];
                    [nav pushObject:obj];
                    [Definitions runWindowManagerForObject:nav];
                } else {
                    [Definitions runWindowManagerForObject:obj];
                }
                [[Definitions navigationStack] setValue:nil forKey:@"context"];
            }
        } else if ((argc > 1) && !strcmp(argv[1], "stringFromFile")) {
            if (argc > 2) {
                id obj = [nsfmt(@"%s", argv[2]) stringFromFile];
//NSLog(@"message %@", message);
                if (obj) {
                    [Definitions runWindowManagerForObject:obj];
                }
            }
        } else if ((argc > 1) && !strcmp(argv[1], "show")) {
            id args = nsarr();
            for (int i=2; i<argc; i++) {
                id str = nscstr(argv[i]);
                [args addObject:str];
            }
            id message = [args join:@" "];
//NSLog(@"message %@", message);
            id object = [nsdict() evaluateMessage:message];
            if (object) {
                [Definitions runWindowManagerForObject:object];
                [[Definitions navigationStack] setValue:nil forKey:@"context"];
            }
        } else if ((argc == 2) && !strcmp(argv[1], ".")) {
            id obj = [Definitions ObjectInterface];
            [Definitions runWindowManagerForObject:obj];
            [[Definitions navigationStack] setValue:nil forKey:@"context"];
        } else if ((argc > 1) && !strcmp(argv[1], "lines")) {
            id lines = nil;
            if (argc > 2) {
                lines = [nscstr(argv[2]) linesFromFile];
                if (!lines) {
NSLog(@"unable to read file '%s'", argv[2]);
exit(1);
                }
            } else {
                lines = [Definitions linesFromStandardInput];
NSLog(@"lines %@", lines);
            }
            if (lines) {
                id arr = nsarr();
                for (int i=0; i<[lines count]; i++) {
                    id line = [lines nth:i];
                    id dict = nsdict();
                    [dict setValue:line forKey:@"line"];
                    [arr addObject:dict];
                }
                id nav = [Definitions navigationStack];
                id obj = [lines asTableInterface];
                [nav pushObject:obj];
                [Definitions runWindowManagerForObject:nav];
            }
        } else if ((argc > 1) && !strcmp(argv[1], "table")) {
            id lines = nil;
            if (argc > 2) {
                lines = [nscstr(argv[2]) linesFromFile];
                if (!lines) {
NSLog(@"unable to read file '%s'", argv[2]);
exit(1);
                }
            } else {
                lines = [Definitions linesFromStandardInput];
NSLog(@"lines %@", lines);
            }
            if (lines) {
                id nav = [Definitions navigationStack];
                id obj = [lines asTableInterface];
                [nav pushObject:obj];
                [Definitions runWindowManagerForObject:nav];
            }
        } else if ((argc > 1) && !strcmp(argv[1], "ipod")) {
            id ipod = [@"IpodInterface" asInstance];
            [ipod setAsValueForKey:@"IpodInterface"];
            id home = [@"HomeScreen" asInstance];
            [ipod setValue:home forKey:@"object"];
            [ipod goToLockScreen];
            [Definitions runWindowManagerForObject:ipod];
        } else if ((argc > 1) && !strcmp(argv[1], "nav")) {
            if ((argc == 3) && !strcmp(argv[2], ".")) {
                id obj = [Definitions ObjectInterface];
                id nav = [Definitions navigationStack];
                [nav pushObject:obj];
                [Definitions runWindowManagerForObject:nav];
                [[Definitions navigationStack] setValue:nil forKey:@"context"];
            } else {
                id args = nsarr();
                for (int i=2; i<argc; i++) {
                    id str = nscstr(argv[i]);
                    [args addObject:str];
                }
                id message = [args join:@" "];
                id object = [nsdict() evaluateMessage:message];
                if (object) {
                    id nav = [Definitions navigationStack];
                    [nav pushObject:object];
                    [Definitions runWindowManagerForObject:nav];
                    [[Definitions navigationStack] setValue:nil forKey:@"context"];
                }
            }
        } else if ((argc > 1) && !strcmp(argv[1], "alert")) {
            id str = nil;
            if (argc > 2) {
                for (int i=2; i<argc; i++) {
                    if (!str) {
                        str = nsfmt(@"%s", argv[i]);
                    } else {
                        str = nsfmt(@"%@\n%s", str, argv[i]);
                    }
                }
            } else {
                id data = [Definitions dataFromStandardInput];
                str = [data asString];
            }
            if ([str length]) {
                id hotdogMode = [Definitions valueForEnvironmentVariable:@"HOTDOG_MODE"];
                id obj = nil;
                if ([hotdogMode isEqual:@"aqua"]) {
                    obj = [@"AquaAlert" asInstance];
                } else if ([hotdogMode isEqual:@"amiga"]) {
                    obj = [@"AmigaAlert" asInstance];
                } else {
                    obj = [@"MacAlert" asInstance];
                }
                [obj setValue:str forKey:@"text"];
                [obj setValue:@"OK" forKey:@"okText"];
                [Definitions runWindowManagerForObject:obj];
            }
        } else if ((argc > 1) && !strcmp(argv[1], "confirm")) {
            id okText = @"OK";
            id cancelText = @"Cancel";
            if (argc > 2) {
                okText = nsfmt(@"%s", argv[2]);
            }
            if (argc > 3) {
                cancelText = nsfmt(@"%s", argv[3]);
            }
            id text = nil;
            if (argc > 4) {
                for (int i=4; i<argc; i++) {
                    if (!text) {
                        text = nsfmt(@"%s", argv[i]);
                    } else {
                        text = nsfmt(@"%@\n%s", text, argv[i]);
                    }
                }
            } else {
                id data = [Definitions dataFromStandardInput];
                text = [data asString];
            }
            if ([text length]) {
                id hotdogMode = [Definitions valueForEnvironmentVariable:@"HOTDOG_MODE"];
                id obj = nil;
                if ([hotdogMode isEqual:@"aqua"]) {
                    obj = [@"AquaAlert" asInstance];
                } else if ([hotdogMode isEqual:@"amiga"]) {
                    obj = [@"AmigaAlert" asInstance];
                } else {
                    obj = [@"MacAlert" asInstance];
                }
                [obj setValue:text forKey:@"text"];
                [obj setValue:okText forKey:@"okText"];
                [obj setValue:cancelText forKey:@"cancelText"];
                [Definitions runWindowManagerForObject:obj];
            }
        } else if ((argc > 1) && !strcmp(argv[1], "progress")) {
            id obj = [@"Progress" asInstance];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "amigadrives")) {
            id obj = [Definitions AmigaDrives];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "amigadir")) {
            if (argc > 2) {
                id filePath = nscstr(argv[2]);
                if ([filePath isDirectory]) {
                    chdir(argv[2]);
                }
            }

            id obj = [Definitions AmigaDir];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "amigagurumeditation")) {
            id obj = [Definitions AmigaGuruMeditation];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "amigabuiltindir")) {
            if (argc > 2) {
                id name = nscstr(argv[2]);
                id obj = [Definitions AmigaBuiltInDir:name];
                [Definitions runWindowManagerForObject:obj];
            } else {
                id obj = [Definitions AmigaBuiltInDir:nil];
                [Definitions runWindowManagerForObject:obj];
            }
        } else if ((argc > 1) && !strcmp(argv[1], "amigaalert")) {
            if (argc > 2) {
                id str = nsfmt(@"%s", argv[2]);
                id obj = [@"AmigaAlert" asInstance];
                [obj setValue:str forKey:@"text"];
                [obj setValue:@"OK" forKey:@"okText"];
                [Definitions runWindowManagerForObject:obj];
            } else {
                id data = [Definitions dataFromStandardInput];
                id str = [data asString];
                if ([str length]) {
                    id obj = [@"AmigaAlert" asInstance];
                    [obj setValue:str forKey:@"text"];
                    [obj setValue:@"OK" forKey:@"okText"];
                    [Definitions runWindowManagerForObject:obj];
                }
            }
        } else if ((argc > 1) && !strcmp(argv[1], "macclassicdrives")) {
            id obj = [Definitions MacClassicDrives];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "macclassicdir")) {
            if (argc > 2) {
                id filePath = nscstr(argv[2]);
                if ([filePath isDirectory]) {
                    chdir(argv[2]);
                }
            }

            id obj = [Definitions MacClassicDir];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "macclassictrash")) {
            id obj = [Definitions MacClassicTrash];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "maccolordrives")) {
            id obj = [Definitions MacColorDrives];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "maccolordir")) {
            if (argc > 2) {
                id filePath = nscstr(argv[2]);
                if ([filePath isDirectory]) {
                    chdir(argv[2]);
                }
            }

            id obj = [Definitions MacColorDir];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "maccolortrash")) {
            id obj = [Definitions MacColorTrash];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "macplatinumtrash")) {
            id obj = [Definitions MacPlatinumTrash];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "ataristdrives")) {
            id obj = [Definitions AtariSTDrives];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "ataristtrash")) {
            id obj = [Definitions AtariSTTrash];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "hotdogstandprograms")) {
            id obj = [Definitions HotDogStandPrograms];
            [Definitions runWindowManagerForObject:obj];
        } else if ((argc > 1) && !strcmp(argv[1], "aquaalert")) {
            if (argc > 2) {
                id str = nsfmt(@"%s", argv[2]);
                id obj = [@"AquaAlert" asInstance];
                [obj setValue:str forKey:@"text"];
                [obj setValue:@"OK" forKey:@"okText"];
                [Definitions runWindowManagerForObject:obj];
            } else {
                id data = [Definitions dataFromStandardInput];
                id str = [data asString];
                if ([str length]) {
                    id obj = [@"AquaAlert" asInstance];
                    [obj setValue:str forKey:@"text"];
                    [obj setValue:@"OK" forKey:@"okText"];
                    [Definitions runWindowManagerForObject:obj];
                }
            }
        } else if ((argc > 1) && !strcmp(argv[1], "dialog")) {
            if (argc > 3) {
                char *classPrefix = "Amiga";
                if (!strcmp(argv[2], "amiga")) {
                    classPrefix = "Amiga";
                } else if (!strcmp(argv[2], "mac")) {
                    classPrefix = "Mac";
                } else if (!strcmp(argv[2], "aqua")) {
                    classPrefix = "Aqua";
                }
                [Definitions dialog:classPrefix :argc-3 :&argv[3]];
            }
            exit(-1);
        } else if ((argc > 1) && !strcmp(argv[1], "VCFPanel")) {
            if (argc > 2) {
                id obj = [Definitions VCFPanel:nsfmt(@"%s", argv[2])];
                [Definitions runWindowManagerForObject:obj];
                exit(0);
            }
            exit(1);
        } else {
            id args = nsarr();
            for (int i=1; i<argc; i++) {
                if (!strcmp(argv[i], "evaluateFile:")) {
                    [args addObject:@"evaluateFile:"];
                    i++;
                    if (i < argc) {
                        [args addObject:[nscstr(argv[i]) asQuotedString]];
                    }
                    break;
                } else {
                    id str = nscstr(argv[i]);
                    [args addObject:str];
                }
            }
            id message = [args join:@" "];
//NSLog(@"message %@", message);
            id object = [nsdict() evaluateMessage:message];
            if (object) {
                [nsfmt(@"%@", object) writeToStandardOutput];
            }
        }
#endif

/*
#ifdef BUILD_FOR_ANDROID
#else
        if (object == [object class]) {
            object = [object asInstance];
        }
        if (isnsarr(object)) {
            object = [object asListInterface];
            id mainInterface = [Definitions mainInterface];
            [mainInterface pushObject:object];
            object = mainInterface;
        } else if (isnsdict(object)) {
            object = [object asKeyValueArray];
            object = [object asListInterface];
            id mainInterface = [Definitions mainInterface];
            [mainInterface pushObject:object];
            object = mainInterface;
        }
        [Definitions runWindowManagerForObject:object];
#endif
*/

	[pool drain];

    return 0;
}
