#import "AppDelegate.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (IBAction)dfsAction:(NSButton *)sender
{
    NSOpenPanel *panelPath = [NSOpenPanel openPanel];
    [panelPath setCanChooseFiles:YES];
    [panelPath setCanChooseDirectories:YES];
    [panelPath setTitle:@"上传文件选择"];
    [panelPath setCanCreateDirectories:YES];
    [panelPath setPrompt:@"上传"];
    [panelPath setMessage:@"这就是message"];
    panelPath.allowsMultipleSelection = YES;
    [panelPath beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self dfsUrls:panelPath.URLs];
        }
    }];
}

- (void)dfsUrls:(NSArray *)urls
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"所有URLs%@",urls);
        if (urls.count == 0) { return; }
        
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        
        
        
        //深度遍历
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableArray *urlDirFiles = [[NSMutableArray alloc] initWithCapacity:0];
        NSArray *keys = [NSArray arrayWithObjects:NSURLIsDirectoryKey,NSURLParentDirectoryURLKey, nil];
        for (NSURL *localUrl in urls) {
            NSDirectoryEnumerator *enumerator = [self enumeratorPathByFileManager:fileManager atURL:localUrl propertiesForKeys:keys options:0];
            
            //这里包含的元素是 有子文件的忽略父路径结点
            //eg: /A/1/2/ (这个就需要移除)   /A/1/2/sun.txt(保留这个文件即可）
            for (NSURL *url in enumerator) {
                NSError *error;
                NSNumber *isDirectory = nil;
                if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                    // handle error
                }
                else if (! [isDirectory boolValue]) {
                    // No error and it’s not a directory; do something with the file
                }
                
                //是否为文件夹
                if ([isDirectory boolValue]) {
                    NSDirectoryEnumerator *dirEnumerator = [self enumeratorPathByFileManager:fileManager atURL:url propertiesForKeys:@[NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants];
                    if (dirEnumerator.allObjects.count > 0) {
                        NSLog(@"文件夹内有文件,忽略此条路径 %@",[url path]);
                    } else {
                        [urlDirFiles addObject:[url path]];
                        
                    }
                } else {
                    [urlDirFiles addObject:[url path]];
                }
            }
            NSLog(@"所有可上传文件列表:\n%@",urlDirFiles);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
            NSLog(@"\n文件数量:%zd\n耗时:%.2f 秒",urlDirFiles.count,(nowTime - currentTime));
        });
    });
}

- (NSDirectoryEnumerator *)enumeratorPathByFileManager:(NSFileManager *)fileManager
                                                 atURL:(NSURL *)url
                                     propertiesForKeys:(nullable NSArray<NSString *> *)keys
                                               options:(NSDirectoryEnumerationOptions)mask
{
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:url
                                         includingPropertiesForKeys:keys
                                         options:mask
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"深度遍历出错%@",error);
                                             return YES;
                                         }];
    return enumerator;
}

@end
