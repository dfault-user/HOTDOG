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

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <errno.h>

@implementation NSString(JFksdljfklsdjfkljsdkf)
- (id)findInPath
{
    id execPath = [Definitions execDir:self];
    if ([execPath fileExists]) {
        return execPath;
    }

    id utilsPath = [Definitions execDir:nsfmt(@"Utils/%@", self)];
    if ([utilsPath fileExists]) {
        return utilsPath;
    }

    char *cstr = getenv("PATH");
    if (!cstr) {
        cstr = "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin";
    }
    id str = nscstr(cstr);
    id arr = [str split:@":"];
    for (id elt in arr) {
        id path = [elt stringByAppendingPathComponent:self];
        if ([path fileExists]) {
            return path;
        }
    }
    return nil;
}
@end

@implementation NSString(jksldfjkldsjflk)
- (void)writeToStandardOutput
{
    char *bytes = [self UTF8String];
    int length = strlen(bytes);
    if (length) {
        write(1, bytes, length);
    }
}
@end
@implementation NSData(jkfldsjfks)
- (void)writeToStandardOutput
{
    void *bytes = [self bytes];
    int length = [self length];
    if (length) {
        write(1, bytes, length);
    }
}
@end

@implementation Definitions(jfkldsjfklsdjf)
+ (void)runCommandInBackground:(id)cmd
{
    [cmd runCommandInBackground];
}
@end

@implementation NSArray(jfkdlsjfkldsjflksdjf)

// SUDO_ASKPASS environment variable is set in linux/foundation-main.m

- (void)runCommandWithSudoInBackground
{
    id cmd = [@[ @"sudo", @"-A" ] arrayByAddingObjectsFromArray:self];
    id process = [cmd runCommandAndReturnProcess];
    [process setValue:@"0" forKey:@"pid"];
}
- (id)runCommandWithSudoAndReturnOutput
{
    id cmd = [@[ @"sudo", @"-A" ] arrayByAddingObjectsFromArray:self];
    id process = [cmd runCommandAndReturnProcess];
    return [process readAllDataFromOutputThenCloseAndWait];
}
- (id)runCommandWithSudoAndReturnError
{
    id cmd = [@[ @"sudo", @"-A" ] arrayByAddingObjectsFromArray:self];
    id process = [cmd runCommandAndReturnProcess];
    return [process readAllDataFromErrorThenCloseAndWait];
}
- (id)runCommandWithSudoAndReturnProcess
{
    id cmd = [@[ @"sudo", @"-A" ] arrayByAddingObjectsFromArray:self];
    id process = [cmd runCommandAndReturnProcess];
    return process;
}
@end

@implementation NSArray(jfklsdjkf)
- (id)runAsArgumentsForCommandAndReturnOutput:(id)command
{
NSLog(@"runAsArgumentsForCommandAndReturnOutput %@ self %@", command, self);
    id arr = nsarr();
    [arr addObjectsFromArray:command];
    [arr addObjectsFromArray:self];
    return [arr runCommandAndReturnOutput];
}

- (id)runCommandAndReturnExitStatus
{
    id process = [self runCommandAndReturnProcess];
    return [process waitForExitStatus];
}

- (id)runCommandAndReturnOutput
{
    id process = [self runCommandAndReturnProcess];
    return [process readAllDataFromOutputThenCloseAndWait];
}

- (id)runCommandAndReturnProcess
{
    return [self runCommandAndReturnProcess];
}

- (int)runCommandInBackground
{
    NSLog(@"runCommandInBackground: %@", self);
    if ([self count] < 1) {
        return 0;
    }
    
    pid_t   childpid;
    
    if((childpid = fork()) == -1)
    {
        perror("fork");
        return 0;
    }
    
    if(childpid == 0)
    {

        setpgid(0, 0);
        int nullfd = open("/dev/null", O_RDONLY);
        if (nullfd < 0) {
NSLog(@"unable to open /dev/null");
        } else {
            dup2(nullfd, 0);
        }

        int argc = [self count];
        char **argv = malloc(sizeof(char *)*(argc+1));
        for (int i=0; i<argc; i++) {
            if (i == 0) {
                id elt = [self nth:0];
                if ([elt hasPrefix:@"/"]) {
                    argv[0] = [elt UTF8String];
                    continue;
                }
                id path = [elt findInPath];
                if (path) {
                    argv[0] = [path UTF8String];
                } else {
                    argv[0] = [elt UTF8String];
                }
            } else {
                argv[i] = [[self nth:i] UTF8String];
            }
        }
        argv[argc] = 0;
        execv(argv[0], argv);
        free(argv);
        _exit(0);
    }
    else
    {
        return childpid;
    }
}
@end


@interface Process : IvarObject
{
    int _infd;
    int _outfd;
    int _errfd;
    int _pid;
    id _status;
    id _exitStatus;
    int _len;
    id _data;
}
@end
@implementation Process

- (id)init
{
    self = [super init];
    if (self) {
        _infd = -1;
        _outfd = -1;
        _errfd = -1;
    }
    return self;
}

- (void)dealloc
{
NSLog(@"Process dealloc pid %d getpid %d", _pid, getpid());
    if (_infd != -1) {
        close(_infd);
        _infd = -1;
    }
    if (_outfd != -1) {
        close(_outfd);
        _outfd = -1;
    }
    if (_errfd != -1) {
        close(_errfd);
        _errfd = -1;
    }
    if (_pid) {
        kill(_pid, SIGTERM);
        _pid = 0;
    }
    [super dealloc];
}

- (int)fileDescriptor
{
    return _outfd;
}

- (void)handleFileDescriptor
{
    if (_outfd == -1) {
        return;
    }
    if (!_data) {
        [self setValue:[[[NSMutableData alloc] init] autorelease] forKey:@"data"];
    }
    char buf[4096];
    int result = read(_outfd, buf, sizeof(buf));
    if (result > 0) {
//NSLog(@"Received %d bytes", result);
        [_data appendBytes:buf length:result];
        _len = result;
    } else if (result == 0) {
        close(_outfd);
        _outfd = -1;
        [self setValue:@"Success" forKey:@"status"];
    } else {
        close(_outfd);
        _outfd = -1;
        [self setValue:nsfmt(@"Error: %s", strerror(errno)) forKey:@"status"];
    }
}
- (BOOL)writeString:(id)str
{
NSLog(@"writeString infd %d", _infd);
    if (_infd == -1) {
        return NO;
    }
    int len = [str length];
NSLog(@"writeString len %d", len);
    int result = write(_infd, [str UTF8String], len);
NSLog(@"writeString result %d", result);
    if (result == len) {
        return YES;
    }
    return NO;
}
- (void)writeDataAndClose:(id)data
{
    [self writeData:data];
    [self closeInput];
}
- (void)writeData:(id)data
{
    if (_infd == -1) {
        return;
    }
    int result = write(_infd, [data bytes], [data length]);
NSLog(@"write result %d", result);
}

- (void)closeInput
{
    if (_infd == -1) {
        return;
    }
    close(_infd);
    _infd = -1;
}

- (void)closeOutput
{
    if (_outfd == -1) {
        return;
    }
    close(_outfd);
    _outfd = -1;
}

- (void)closeError
{
    if (_errfd == -1) {
        return;
    }
    close(_errfd);
    _errfd = -1;
}

- (id)readAllDataFromErrorThenCloseAndWait
{
    if (_errfd == -1) {
        return nil;
    }
    id data = [self readAllData:_errfd];
    [self closeError];
    [self waitForExitStatus];
    return data;
}
- (id)readAllDataFromOutputThenCloseAndWait
{
    if (_outfd == -1) {
        return nil;
    }
    id data = [self readAllData:_outfd];
    [self closeOutput];
    [self waitForExitStatus];
    return data;
}

- (id)readData:(int)fd
{
    char readbuf[4096];
    int result = read(fd, readbuf, sizeof(readbuf));
    if (result > 0) {
        id data = [[[NSMutableData alloc] init] autorelease];
        [data appendBytes:readbuf length:result];
        return data;
    } else if (result == 0) {
        NSLog(@"EOF");
    } else {
        perror("Error");
    }
    return nil;
}
- (id)readAllData:(int)fd
{
    id data = [[[NSMutableData alloc] init] autorelease];
    char readbuf[4096];
    for(;;) {
        int result = read(fd, readbuf, sizeof(readbuf));
        if (result > 0) {
//NSLog(@"Received %d bytes", result);
            [data appendBytes:readbuf length:result];
        } else if (result == 0) {
            NSLog(@"EOF");
            break;
        } else {
            perror("Error");
            data = nil;
            break;
        }
    }
    return data;
}
- (void)drawInBitmap:(id)bitmap rect:(Int4)r
{
    id str = [_data asString];
    if (_status) {
        str = nsfmt(@"%@*** %@ ***", str, _status);
    }
    [bitmap setColor:@"white"];
    [bitmap fillRect:r];
    [bitmap setColorIntR:0 g:0 b:0 a:255];
    [bitmap drawBitmapText:str x:0+5 y:r.h-1-5];
}
- (id)waitForExitStatus
{
    if (_exitStatus) {
        return _exitStatus;
    }
    if (!_pid) {
        return nil;
    }
    int wstatus = 0;
    if (waitpid(_pid, &wstatus, 0) == _pid) {
        _pid = 0;
        if (WIFEXITED(wstatus)) {
            int status = WEXITSTATUS(wstatus);
            id str = nsfmt(@"%d", status);
            [self setValue:str forKey:@"exitStatus"];
            return str;
        }
    }
    return nil;
}


@end

@implementation NSArray(jfkldsjflksdkljf)
- (id)runCommandAndReturnProcess
{
    NSLog(@"runCommandAndReturnProcess: %@", self);
    if ([self count] < 1) {
        return nil;
    }
    
    int fdzero[2];
    int fdone[2];
    int fdtwo[2];
    pid_t   childpid;
    
    pipe(fdzero);
    pipe(fdone);
    pipe(fdtwo);
    
    if((childpid = fork()) == -1)
    {
        perror("fork");
        return nil;
    }
    
    if(childpid == 0)
    {

        close(fdzero[1]);
        dup2(fdzero[0], STDIN_FILENO);
        close(fdzero[0]);

        /* Child process closes up input side of pipe */
        close(fdone[0]);
        dup2(fdone[1], STDOUT_FILENO);
        close(fdone[1]);

        close(fdtwo[0]);
        dup2(fdtwo[1], STDERR_FILENO);
        close(fdtwo[1]);

        int argc = [self count];
        char **argv = malloc(sizeof(char *)*(argc+1));
        for (int i=0; i<argc; i++) {
            if (i == 0) {
                id elt = [self nth:0];
                if ([elt hasPrefix:@"/"]) {
                    argv[0] = [elt UTF8String];
                    continue;
                }
                id path = [elt findInPath];
                if (path) {
                    argv[0] = [path UTF8String];
                } else {
                    argv[0] = [elt UTF8String];
                }
            } else {
                argv[i] = [[self nth:i] UTF8String];
            }
        }
        argv[argc] = 0;
        execv(argv[0], argv);
        free(argv);
        _exit(0);
    }
    else
    {
        close(fdzero[0]);

        /* Parent process closes up output side of pipe */
        close(fdone[1]);

        close(fdtwo[1]);

        id process = [[[Process alloc] init] autorelease];
        [process setValue:nsfmt(@"%d", childpid) forKey:@"pid"];
        [process setValue:nsfmt(@"%d", fdzero[1]) forKey:@"infd"];
        [process setValue:nsfmt(@"%d", fdone[0]) forKey:@"outfd"];
        [process setValue:nsfmt(@"%d", fdtwo[0]) forKey:@"errfd"];
        return process;
    }
}

@end

@implementation NSString(jfklsdkfj)
- (id)downloadURL
{
    return [self downloadURLWithCurl];
}
- (id)downloadURLWithCurl
{
    NSLog(@"downloadURLWithCurl %@", self);
    id arr = nsarr();
    [arr addObject:@"curl"];
#ifdef BUILD_FOR_IOS
    [arr addObject:@"-k"];
#endif
    [arr addObject:self];
    return [arr runCommandAndReturnOutput];
}
@end
