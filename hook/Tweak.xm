#include "substrate.h"
#include "QuartzCore/CAWindowServer.h"
#include "QuartzCore/CAWindowServerDisplay.h"
#include "stdlib.h"
#include "mach_time.h"
#include <mach/mach_port.h>
#include "GSEvent.h"
#include <dlfcn.h>

//IPC Declaration
@interface CPDistributedMessagingCenter
+ (id)centerNamed:(id)arg1;
- (BOOL)sendMessageName:(id)arg1 userInfo:(id)arg2;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)arg1 target:(id)arg2 selector:(SEL)arg3;
- (id)sendMessageAndReceiveReplyName:(id)arg1 userInfo:(id)arg2;
@end

int Level_;

static void postMouseEvent(float x, float y, int status){

	if (dlsym(RTLD_DEFAULT, "GSLibraryCopyGenerationInfoValueForKey") != NULL)
	        Level_ = 3;
	    else if (dlsym(RTLD_DEFAULT, "GSKeyboardCreate") != NULL)
	        Level_ = 2;
	    else if (dlsym(RTLD_DEFAULT, "GSEventGetWindowContextId") != NULL)
	        Level_ = 1;
	    else
	        Level_ = 0;
	
	//1 down : 0 up : 2 drag
	CGPoint point = {x,y};
	
	struct{
		struct GSEventRecord record;
		struct{
			struct GSEventRecordInfo info;
			struct GSPathInfo path;
		}data;
	}event;
	
	memset(&event, 0, sizeof(event));
	event.record.type = GSEventTypeMouse;
	event.record.locationInWindow = point;
	event.record.timestamp = GSCurrentEventTimestamp();
	event.record.size = sizeof(event.data);
	
	event.data.info.handInfo.type = 
		status == 0?
		GSMouseEventTypeUp:
		status == 1?
		GSMouseEventTypeDown :
		status == 2?
		GSMouseEventTypeDragged:
		status == 3?
		GSEventTypeStatusBarMouseDown:
		status == 4?
		GSEventTypeStatusBarMouseDragged:
		GSEventTypeStatusBarMouseUp;
		
	
	event.data.info.handInfo.x34 = 0x1;
	event.data.info.handInfo.x38 = status? 0x1:0x0;
	
	if(Level_ < 3){
		event.data.info.pathPositions = 1;
	}else{
		event.data.info.x52 = 1;
	}
	event.data.path.x00 = 0x01;
	event.data.path.x01 = 0x02;
	event.data.path.x02 = status? 0x03:0x00;
	event.data.path.position = event.record.locationInWindow;
	
	mach_port_t port_(0);
	mach_port_t purple(0);
	
	if (CAWindowServer *server = [CAWindowServer serverIfRunning]){
		NSArray *displays([server displays]);
		if (displays != nil && [displays count] != 0){
			if (CAWindowServerDisplay *display = [displays objectAtIndex:0]){
				CGPoint point2;
				point2.x = point.x;
				point2.y = point.y;
				port_ = [display clientPortAtPosition:point2];
			}
		}
	}
	
	if (port_ == 0){
		if(purple == 0){
			purple = GSGetPurpleSystemEventPort();
			NSLog(@"---SB: %i---", purple);
		}
		port_ = purple;
	}
	
	NSLog(@"----PORT: %i----", port_);
	GSSendEvent(&event.record, port_);
	
}

//Drag
static void Drag(int x, int y, int z, int dir){
	
	dispatch_async(dispatch_get_global_queue(0, 0),^{
		postMouseEvent(x,y, 1);
	});
	
	dispatch_async(dispatch_get_global_queue(0, 0),^{
		[NSThread sleepForTimeInterval: 3];
		if(dir == 1){
			for(int i = 0; i < z; i++){
				postMouseEvent(x,y - i, 2);
			}
		}else if(dir == 2){
			for(int i = 0; i < z; i++){
				postMouseEvent(x,y + i, 2);
			}
		}else if(dir == 3){
			for(int i = 0; i < z; i++){
				postMouseEvent(x - i,y, 2);
			}
		}else if(dir == 4){
			for(int i = 0; i < z; i++){
				postMouseEvent(x + i,y, 2);
			}
		}
	});
	dispatch_async(dispatch_get_global_queue(0, 0),^{
		[NSThread sleepForTimeInterval: 4];
		if(dir == 1){
			postMouseEvent(x, y - z, 0);
		}else if(dir == 2){
			postMouseEvent(x, y + z, 0);
		}else if( dir == 3){
			postMouseEvent(x - z, y, 0);
		}else if(dir == 4){
			postMouseEvent(x + z, y, 0);
		}
	});
}
//Click
static void Click(int x, int y, int times){
	for(int i = 0; i < times; i++){
		postMouseEvent(x, y, 1);
		postMouseEvent(x, y, 0);
	}
}
//Swipe
static void Swipe(int x, int y, int dir){
	if(dir == 1){
		for(int i = 0; i < 200; i++){
			postMouseEvent(x, y - i, 1);
		}
		postMouseEvent(x, y - 200, 0);
	}else if(dir == 2){
		for(int i = 0; i < 200; i++){
			postMouseEvent(x, y + i, 1);
		}
		postMouseEvent(x, y + 200, 0);
	}else if( dir == 3){
		for(int i = 0; i < 200; i++){
			postMouseEvent(x - i, y, 1);
		}
		postMouseEvent(x - 200, y, 0);
	}else if(dir == 4){
		for(int i = 0; i < 200; i++){
			postMouseEvent(x + i, y, 1);
		}
		postMouseEvent(x + 200, y, 0);
	}
}


%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1{
	CPDistributedMessagingCenter *
		center = [CPDistributedMessagingCenter centerNamed:@"com.iN.hook"];
	if(![center doesServerExist]){
		[center runServerOnCurrentThread];
		[center registerForMessageName:@"com.iN.hook.test" target:self selector:@selector(handleTest:userInfo:)];
	}
	%orig;
}

%new(v@:@@)
-(void) handleTest:(NSString*)name userInfo:(NSDictionary*) userInfo{
	if([name isEqualToString:@"com.iN.hook.test"]){
		NSLog(@"----Action----");
		
		int myType = [[userInfo valueForKey:@"myType"] intValue];
		if(myType == 1 || myType == 2){
			int x = [[userInfo valueForKey:@"x"] intValue];
			int y = [[userInfo valueForKey:@"y"] intValue];
			Click(x,y,myType);
		}else if(myType == 3){
			int x = [[userInfo valueForKey:@"x"] intValue];
			int y = [[userInfo valueForKey:@"y"] intValue];
			int dir = [[userInfo valueForKey:@"dir"] intValue];
			Swipe(x,y,dir);
		}else if(myType == 4){
			int x = [[userInfo valueForKey:@"x"] intValue];
			int y = [[userInfo valueForKey:@"y"] intValue];
			int z = [[userInfo valueForKey:@"z"] intValue];
			int dir = [[userInfo valueForKey:@"dir"] intValue];
			Drag(x,y,z,dir);
		}
		
	}
}
%end








