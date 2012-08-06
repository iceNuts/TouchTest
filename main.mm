#include <stdio.h>
#include <iostream.h>
#include <IOKit/hid/IOHIDEventSystem.h>


//IPC Declaration
@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
- (id)sendMessageAndReceiveReplyName:(id)arg1 userInfo:(id)arg2;
@end

void handle_event (void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
    // handle the events here.
    
    if(IOHIDEventGetType(event) == kIOHIDEventTypeDigitizer){
        printf("Received event of type %i from service %p.\n", IOHIDEventGetType(event), service);
        CPDistributedMessagingCenter *
		center = [CPDistributedMessagingCenter centerNamed:@"com.iN.hook"];
        [center sendMessageName: @"com.iN.hook.test" userInfo: nil];
    }    
}

int main(int argc, char **argv, char **envp) {
    /*
    // Create and open an event system.
    IOHIDEventSystemRef system = IOHIDEventSystemCreate(NULL);
    IOHIDEventSystemOpen(system, handle_event, NULL, NULL, NULL);
    
    printf("HID Event system should now be running. Hit enter to quit any time.\n");
    getchar();
    
    IOHIDEventSystemClose(system, NULL);
    CFRelease(system);
    */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int x,y,z,dir,myType;
    cout << "Type: 1 Click 2 Double Click 3 Swipe 4 Drag" << endl;
    cout << "Direction: 1 up 2 down 3 left 4 right" << endl;
    NSDictionary *dictionary = [[NSDictionary alloc] init];
    while(1){
        cout << "Typed: ",cin >> myType;
        
        if(myType == 1){
            cout << "One Click: Point x & y" << endl;
            cin >> x >> y;
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", myType], @"myType", [NSString stringWithFormat:@"%d", x], @"x", [NSString stringWithFormat:@"%d", y], @"y",nil ];
        }else if(myType == 2){
            cout << "Double Click: Point x & y" << endl;
            cin >> x >> y;
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", myType], @"myType", [NSString stringWithFormat:@"%d", x], @"x", [NSString stringWithFormat:@"%d", y], @"y",nil ];
        }else if(myType == 3){
            cout << "Swipe: Point x & y & direction" << endl;
            cin >> x >> y >> dir;
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", myType], @"myType", [NSString stringWithFormat:@"%d", x], @"x", [NSString stringWithFormat:@"%d", y], @"y",[NSString stringWithFormat:@"%d", dir], @"dir",nil ];
        }else if(myType == 4){
            cout << "Drag: Point x & y & force & direction" << endl;
            cin >> x >> y >> z >> dir;
            dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", myType], @"myType", [NSString stringWithFormat:@"%d", x], @"x", [NSString stringWithFormat:@"%d", y], @"y",[NSString stringWithFormat:@"%d", z], @"z",[NSString stringWithFormat:@"%d", dir], @"dir",nil ];
        }
        
        CPDistributedMessagingCenter *
        center = [CPDistributedMessagingCenter centerNamed:@"com.iN.hook"];
        [center sendMessageName: @"com.iN.hook.test" userInfo: dictionary];
    }
    [pool release];
    return 0;
}

// vim:ft=objc
