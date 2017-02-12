//
//  PenguinViewController.m
//  PenguinVer1
//
//  Created by Jongwon Lee on 6/27/15.
//  Copyright (c) 2015 Jongwon Lee. All rights reserved.
//

#import "PenguinViewController.h"

@interface PenguinViewController ()

@end

NSString *const MODE_AUTO = @"MODE:AUTO";
NSString *const MODE_MANUAL = @"MODE:MANUAL";
NSString *const MODE_CHANGE = @"MODE:CHANGE";
NSString *const MODE_TEST = @"MODE:TEST";
NSString *const MODE_ABV = @"MODE:ABV";
NSString *const V = @"V";

NSString *const SCENARIO = @"SCENARIO:";
NSString *const FOURSEASONS = @"FOURSEASONS";
NSString *const SENSES = @"SENSES";
NSString *const PHASE = @"PHASE:";  // spring, summer, fall, winter
NSString *const CODE = @"C";
NSString *const TYPE_EMOTION = @"TYPE:E";
NSString *const TYPE_MOVEMENT = @"TYPE:M";
NSString *const A_SPACE = @" ";
NSString *const CMD_NUMBER = @"CMD:";
NSString *const TILT_ANGLE = @"TILT_ANGLE:";
NSString *const MOVEMENT_SPEED = @"SPEED:";
NSString *const MOVEMENT_RADIUS = @"RADIUS:";
NSString *const MOVEMENT_ANGLE = @"ANGLE:";
NSString *const CMD_DURATION = @"DURATION:";
NSString *const PARAMETER = @"PARAMETER:";

int const NUM_EMOTION = 25; //updated from 16 on 02/05/16 to 25 on 2/17/16

@implementation PenguinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [RMCore setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkMessage)
                                                 name:SocketCommunicatorDidReadData
                                               object:nil];
    
    socketComm = [SocketSingleton sharedInstance].getSocketCommunicator;
    
    CGRect defaultFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    animationImageView = [[UIImageView alloc] initWithFrame:defaultFrame];
    
    //[self.view addSubview:animationImageView];
    
    playingMusicArray = [[NSMutableArray alloc] init];
    
    
    finishingAction = RMCoreTurnFinishingActionDriveForward;
    
    
    // test
    testPenguinEmotion = 0;
    [self addGestureRecognizers];
    
    emotionDuration = -1.f;
    emotionQueue = [[NSMutableArray alloc] init];
    
    movementDuration = -1.f;
    movementQueue = [[NSMutableArray alloc] init];
    
    cmdQueue = [[NSMutableArray alloc] init];
    
    // initialize expression parameters
    defaultParam = 2;
    happyParam = 2;
    sadParam = 2;
    frustratedParam = 2;
    scaredParam = 2;
    angryParam = 2;
    sneezeParam = 2;
    dizzyParam = 2;
    curiousParam = 2;
    sniffParam = 2;
    excitedParam = 2;
    sleepyParam = 2;
    wantParam = 2;
    tiredParam = 2;
    unhappyParam = 2;
    cryingParam = 2;
    nervousParam = 2;   //all new 2/17/16
    terrifiedParam = 2;
    surprisedParam = 2;
    celebratingParam = 2;
    grumpyParam = 2;
    furiousParam = 2;
    boredParam = 2;
    ickParam = 2;
    disgustParam = 2;
    
    animationHandler = [[AnimationHandler alloc] init];
    
    previousEmotion = -1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)robotDidConnect:(RMCoreRobot *)robot {
    if(robot.isDrivable && robot.isHeadTiltable && robot.isLEDEquipped) {
        self.robot = (RMCoreRobot<HeadTiltProtocol, DriveProtocol, LEDProtocol> *)robot;
    }
}

- (void)robotDidDisconnect:(RMCoreRobot *)robot {
    if(robot == self.robot) {
        self.robot = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGRect messageRect = CGRectMake(0, self.view.frame.size.height-120, self.view.frame.size.width, 40);
    messageLabel = [[UILabel alloc] initWithFrame:messageRect];
    messageLabel.backgroundColor = [UIColor whiteColor];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.textColor = [UIColor blackColor];
    messageLabel.font = [UIFont systemFontOfSize:10];
    //messageLabel.text = @"TEST";
    [self.view addSubview:messageLabel];
    
    CGRect emotionRect = CGRectMake(0, self.view.frame.size.height-80, self.view.frame.size.width, 40);
    emotionLabel = [[UILabel alloc] initWithFrame:emotionRect];
    emotionLabel.backgroundColor = [UIColor blackColor];
    emotionLabel.textAlignment = NSTextAlignmentCenter;
    emotionLabel.textColor = [UIColor whiteColor];
    emotionLabel.font = [UIFont systemFontOfSize:10];
    [self.view addSubview:emotionLabel];
    
    CGRect movementLabelRect = CGRectMake(0.0, CGRectGetHeight(self.view.frame)-40, self.view.frame.size.width, 40.0);
    movementLabel = [[UILabel alloc] initWithFrame:movementLabelRect];
    movementLabel.backgroundColor = [UIColor whiteColor];
    movementLabel.textAlignment = NSTextAlignmentCenter;
    movementLabel.textColor = [UIColor blackColor];
    movementLabel.font = [UIFont systemFontOfSize:10];
    [self.view addSubview:movementLabel];

    [self.view addSubview:animationImageView];
    [self makeEmotion:@"CMD:0 "];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)checkMessage {
    //NSString *msgString = [[notification userInfo] objectForKey:@"msgString"];
    NSString *message = socketComm->lastMessage;
    if(message) {
        messageLabel.text = message;
        [self parseMessage:message];
    }
}


- (void)parseMessage:(NSString *)message {
    if([message rangeOfString:MODE_AUTO].location != NSNotFound) {
        [self doAutomaticActions:message];
    }
    else if([message rangeOfString:MODE_MANUAL].location != NSNotFound) {
        [self doManualActions:message];
    }
    // paramter modification message (expression, emotion)
    else if([message rangeOfString:MODE_TEST].location != NSNotFound) {
        [self doTest];
    }
    else if([message rangeOfString:MODE_ABV].location != NSNotFound) {
        [self doAbv:message];
    }
    else if([message rangeOfString:V].location != NSNotFound) {
        [self doAbv:message];
    }
}

- (void)doAutomaticActions:(NSString *)message {
    NSString *scenario = [self extractString:message toLookFor:SCENARIO skipForwardX:[SCENARIO length] toStopBefore:A_SPACE];
    if([scenario rangeOfString:FOURSEASONS].location != NSNotFound) {
        [self doFourSeasons:message];
    }
    else if([scenario rangeOfString:SENSES].location != NSNotFound) {
        [self doSenses:message];
    }
    
}

- (void)doAbv:(NSString *)message {
    NSString *abv = [self extractString:message toLookFor:CODE skipForwardX:[CODE length] toStopBefore:A_SPACE];
    NSString *message2;
    if([abv rangeOfString:@"MTA"].location != NSNotFound) {
        NSString *tiltstr = [self extractString:message toLookFor:@"CMTA" skipForwardX:[@"CMTA" length] toStopBefore:A_SPACE];
        message2 = [NSString stringWithFormat:@"%@ %@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, TILT_ANGLE, tiltstr];
        [self doManualActions:message2];
        //[self doTest];
        
    }
    else if([abv rangeOfString:@"AU"].location != NSNotFound) {
        NSString *cmd = [self extractString:message toLookFor:@"CAU" skipForwardX:[@"CAU" length] toStopBefore:A_SPACE];
        message2 = [NSString stringWithFormat:@"%@ %@%@ %@%@ ", MODE_AUTO, SCENARIO, SENSES, PHASE, cmd];
        [self doSenses:message2];
        //[self doTest];
    }
    else if([abv rangeOfString:@"E"].location != NSNotFound) {
        NSString *cmd = [self extractString:message toLookFor:@"CE" skipForwardX:[@"CE" length] toStopBefore:A_SPACE];
        message2 = [NSString stringWithFormat:@"%@ %@ %@%@ ", MODE_MANUAL, TYPE_EMOTION, CMD_NUMBER, cmd];
        [self doManualActions:message2];
        //[self doTest];
    }
    else if([abv rangeOfString:@"MC"].location != NSNotFound) {
        NSString *cmd = [self extractString:message toLookFor:@"MC" skipForwardX:[@"MC" length] toStopBefore:A_SPACE];
        NSInteger cmdInt = [cmd intValue];
        switch (cmdInt) {
            case 0: {   // stop
                message2 = [NSString stringWithFormat:@"%@ %@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, CMD_NUMBER, cmd];
                [self doManualActions:message2];
                break;
            }
            case 1: {   // drive forward
                NSString *speed = [self extractString:message toLookFor:@"S" skipForwardX:[@"S" length] toStopBefore:A_SPACE];
                message2 = [NSString stringWithFormat:@"%@ %@ %@%@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, CMD_NUMBER, cmd, MOVEMENT_SPEED, speed];
                [self doManualActions:message2];
                break;
            }
            case 2: {   // drive backward
                NSString *speed = [self extractString:message toLookFor:@"S" skipForwardX:[@"S" length] toStopBefore:A_SPACE];
                message2 = [NSString stringWithFormat:@"%@ %@ %@%@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, CMD_NUMBER, cmd, MOVEMENT_SPEED, speed];
                [self doManualActions:message2];
                break;
            }
            case 3: {   // drive with radius
                NSString *radius = [self extractString:message toLookFor:@"R" skipForwardX:[@"R" length] toStopBefore:A_SPACE];
                NSString *speed = [self extractString:message toLookFor:@"S" skipForwardX:[@"S" length] toStopBefore:A_SPACE];
                message2 = [NSString stringWithFormat:@"%@ %@ %@%@ %@%@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, CMD_NUMBER, cmd, MOVEMENT_RADIUS, radius, MOVEMENT_SPEED, speed];
                [self doManualActions:message2];
                break;
            }
            case 4: {
                NSString *angle = [self extractString:message toLookFor:@"AN" skipForwardX:[@"AN" length] toStopBefore:A_SPACE];
                NSString *radius = [self extractString:message toLookFor:@"R" skipForwardX:[@"R" length] toStopBefore:A_SPACE];
                message2 = [NSString stringWithFormat:@"%@ %@ %@%@ %@%@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, CMD_NUMBER, cmd, MOVEMENT_ANGLE, angle, MOVEMENT_RADIUS, radius];
                [self doManualActions:message2];
                break;
            }
            case 6: {
                NSString *angle = [self extractString:message toLookFor:@"AN" skipForwardX:[@"AN" length] toStopBefore:A_SPACE];
                NSString *radius = [self extractString:message toLookFor:@"R" skipForwardX:[@"R" length] toStopBefore:A_SPACE];
                NSString *speed = [self extractString:message toLookFor:@"S" skipForwardX:[@"S" length] toStopBefore:A_SPACE];
                message2 = [NSString stringWithFormat:@"%@ %@ %@%@ %@%@ %@%@ %@%@ ", MODE_MANUAL, TYPE_MOVEMENT, CMD_NUMBER, cmd, MOVEMENT_ANGLE, angle, MOVEMENT_RADIUS, radius, MOVEMENT_SPEED, speed];
                [self doManualActions:message2];
                break;
            }
            case 101: {
                NSString *speed = [self extractString:message toLookFor:@"S" skipForwardX:[@"S" length] toStopBefore:A_SPACE];
                NSString *duration = [self extractString:message toLookFor:@"D" skipForwardX:[@"D" length] toStopBefore:A_SPACE];
                message2 = [NSString stringWithFormat:@"MODE:MANUAL TYPE:M CMD:101 %@%@ %@%@ ", MOVEMENT_SPEED, speed, CMD_DURATION, duration];
                /*if(speed && duration) {
                    [self driveForwardWithDuration:[duration floatValue] withSpeed:[speed floatValue]];
                }
                else {
                    // send message "wrong command"
                }*/
                [self doManualActions:message2];
                //[self driveForwardWithDuration:[duration floatValue] withSpeed:[speed floatValue]];
                //[movementQueue addObject:message2];
                //[self movementTimerRun];
                break;
            }

            default: {
                break;
            }
        }

    }
}

- (void)doTest {
    // only for test
    [emotionQueue addObject:@"TYPE:E DURATION:2.5 CMD:1 "];     // happy
    [movementQueue addObject:@"TYPE:M DURATION:2.5 CMD:0 "];    // stop
    [movementQueue addObject:@"TYPE:M CMD:108 SPEED:0.2 RADIUS:0.2 "];  // draw 8
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:2 "];    // sad
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:1 "];    // drive forward for 2sec
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];    // stop for 0.5sec
    [movementQueue addObject:@"TYPE:M CMD:103 SPEED:0.7 RADIUS:0.5 "];   // drive circle clockwise
    [emotionQueue addObject:@"TYPE:E CMD:11 DURATION:10 "];     // sleepy
    [movementQueue addObject:@"TYPE:M CMD:2 DURATION:3.0 "];    // drive backward for 3sec
    [movementQueue addObject:@"TYPE:M CMD:101 DURATION:2.0 "];  // drive forward for 2sec
    [movementQueue addObject:@"TYPE:M CMD:2 DURATION:2.5 "];    // drive backward for 2.5
    [emotionQueue addObject:@"TYPE:E CMD:3 DURATION:10 "];      // frustrated for 3
    [emotionQueue addObject:@"TYPE:E CMD:0 DURATION:5 "];       // default for 5sec and to end
    [self movementTimerRun];
    [self emotionTimerRun];
}


- (void)doFourSeasons:(NSString *)message {
    int phase = [[self extractString:message toLookFor:PHASE skipForwardX:[PHASE length] toStopBefore:A_SPACE] intValue];
    switch (phase) {
        case 0: {   // spring
            [self doSpring];
            break;
        }
        case 1: {   // summer
            [self doSummer];
            break;
        }
        case 2: {   // fall
            [self doFall];
            break;
        }
        case 3: {   // winter
            [self doWinter];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)doSpring {
    //testing using the test function, emotion only
    [emotionQueue addObject:@"TYPE:E DURATION:5.0 CMD:1 "];     // happy
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:12 "];   // want
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:3 "];    // frustrated
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:11 "];   // sleepy
    [emotionQueue addObject:@"TYPE:E DURATION:5.0 CMD:1 "];     // happy
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:12 "];   // want
    //[self movementTimerRun];
    [self emotionTimerRun];

}
- (void)doSummer {
    //testing using the test function, emotion only
    [emotionQueue addObject:@"TYPE:E DURATION:5.0 CMD:0 "];    // default
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:2 "];   // sad
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:13 "];  // tired
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:8 "];   // curious
    [emotionQueue addObject:@"TYPE:E DURATION:5.0 CMD:7 "];    // dizzy
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:4 "];   // scared
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:3 "];   // frustrated
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:5 "];   // angry
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:9 "];   // sniff
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:6 "];   // sneeze
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:5 "];   // angry
    
    //[self movementTimerRun];
    [self emotionTimerRun];
}
- (void)doFall {
}
- (void)doWinter {
}

- (void)doSenses:(NSString *)message {
    int phase = [[self extractString:message toLookFor:PHASE skipForwardX:[PHASE length] toStopBefore:A_SPACE] intValue];
    switch (phase) {
        case 11: {   // sense of sight, negative reaction
            [self doSight1];
            break;
        }
        case 12: {  // sense of sight, neutral reaction
            [self doSight2];
            break;
        }
        case 13: {  // sense of sight, positive reaction
            [self doSight3];
            break;
        }
        case 21: {   // sense of hearing, negative reaction
            [self doHearing1];
            break;
        }
        case 22: {   // sense of hearing, neutral reaction
            [self doHearing2];
            break;
        }
        case 23: {   // sense of hearing, positive reaction
            [self doHearing3];
            break;
        }
        case 31: {   // sense of smell, negative reaction
            [self doSmell1];
            break;
        }
        case 32: {   // sense of smell, neutral reaction
            [self doSmell2];
            break;
        }
        case 33: {   // sense of smell, positive reaction
            [self doSmell3];
            break;
        }
        case 41: {   // sense of taste, negative reaction
            [self doTaste1];
            break;
        }
        case 42: {   // sense of taste, neutral reaction
            [self doTaste2];
            break;
        }
        case 43: {   // sense of taste, positive reaction
            [self doTaste3];
            break;
        }
        case 51: {   // sense of touch, negative reaction
            [self doTouch1];
            break;
        }
        case 52: {   // sense of touch, neutral reaction
            [self doTouch2];
            break;
        }
        case 53: {   //sense of touch, positive reaction
            [self doTouch3];
            break;
        }
        case 6: {   //sense of vestibular
            [self doVestibular];
            break;
        }
        case 71:{
            [self doCallOver1];
            break;
        }
        case 72:{
            [self doCallOver2];
            break;
        }
        case 73:{
            [self doCallOver3];
            break;
        }
        default: {
            break;
        }
    }

    
}
- (void) doSight1{
    
    /*[emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:70 "];			//tilt angle 70
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.2 "];    //drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0 CMD:7 "];   // dizzy
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:130 "];		//tilt angle 130
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:1.5 "];    //stationary
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:2 SPEED:0.2 "];  //backwards
    
    [emotionQueue addObject:@"TYPE:E DURATION:4.0  CMD:3 "];   // frustrated
    [movementQueue addObject:@"TYPE:M CMD:4 ANGLE:180 RADIUS:0.1 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:2 "];   // sad
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:2.0 "];    //stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:16 "];   // nervous
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:0 "];	//stationary
    */
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "];    //stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.1 "];    //drive forward
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:70 "];			//tilt angle 70
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:0.5 "];    //stationary
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:7 "];   // dizzy
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:2 SPEED:0.2 "];  //backwards
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:130 "];		//tilt angle 130
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:2.0 "];    //stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.5  CMD:2 "];   // sad
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.5 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
    
    
}
- (void) doSight2{
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "];    //stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.1 "];    //drive forward
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:70 "];			//tilt angle 70
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:0.5 "];    //stationary
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:7 "];   // dizzy
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:2 SPEED:0.2 "];  //backwards
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:130 "];		//tilt angle 130
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:2.0 "];    //stationary
    
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
}

-(void) doSight3{
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "];    //stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.1 "];    //drive forward
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];			//tilt angle 70
    
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:1.0 "];    //stationary
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:9 "];   // sniff
    
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:130 "];		//tilt angle 130
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:12 "];   // want
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:1 "];   // happy
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:3.0 "];    //stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    
    
    [self movementTimerRun];
    [self emotionTimerRun];
}

- (void) doHearing1{
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "]; 	//stationary
    
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "]; 	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:2.5  CMD:4 "];   // scared
    
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:90 "]; 	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:5 "];  // angry
    
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:1 SPEED:0.2 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:1 SPEED:0.2 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:1 SPEED:0.2 "];	//shake backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:3 "];   // frustrated
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    [movementQueue addObject:@"TYPE:M CMD:4 ANGLE:360 RADIUS:0.0 "];	//spin in a circle
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    /*[emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:8 "];   // curious
    //[movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:70 "]; 	//stationary
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "]; 	//stationary
    
    //[movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "]; 	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:4 "];  // scared
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:2 SPEED:0.3 "]; 	//drive back
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:3 "];  // FRUSTRATED
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:6 ANGLE:45 RADIUS:0.0 SPEED:0.3 "]; 	//TURN
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:6 ANGLE:-45 RADIUS:0.0 SPEED:0.3 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:6 ANGLE:45 RADIUS:0.0 SPEED:0.3 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:6 ANGLE:-45 RADIUS:0.0 SPEED:0.3 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:6 ANGLE:45 RADIUS:0.0 SPEED:0.3 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:6 ANGLE:-45 RADIUS:0.0 SPEED:0.3 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.4 CMD:5 "];  // angry
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:3 "];   // frustrated
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:2 SPEED:0.1 "];	//backwards
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:16 "];   // NERVOUS
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "]; 	//stationary
    */
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}
- (void) doHearing2{
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.2  CMD:7 "];   // dizzy
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "]; 	//stationary
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:2 SPEED:0.2 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake backward
    
    
    //[movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "]; 	//stationary
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:0 "]; 	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:8 "];   // curious
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:9 "];  // sniff
    
    //[movementQueue addObject:@"TYPE:M DURATION:1.0 T ILT_ANGLE:90 "]; 	//stationary
    
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    
    
    [self movementTimerRun];
    [self emotionTimerRun];
}

-(void) doHearing3{
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "]; 	//stationary
    
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "]; 	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:9 "];   // sniff
    
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:90 "]; 	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:4.0  CMD:10 "];  // excited
    
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:1 SPEED:0.2 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:1 SPEED:0.2 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:1 SPEED:0.2 "];	//shake backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:1 "];   // happy
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    [movementQueue addObject:@"TYPE:M CMD:4 ANGLE:360 RADIUS:0.0 "];	//spin in a circle
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
}

- (void) doSmell1{
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.2 "];	//forward with duration
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stay still
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION: 2.0 TILT_ANGLE:70 "];	//head tilt 70 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:0 "];	//stay still
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:6 "];   // sneeze
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:130 "];	//head tilt 130 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:6 "];  // sneeze
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.5 "];	//backward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];  // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:2 "];  // sad
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}

-(void) doSmell2{
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.2 "];	//forward with duration
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stay still
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION: 2.0 TILT_ANGLE:70 "];	//head tilt 70 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:0 "];	//stay still
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:6 "];   // sneeze
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:130 "];	//head tilt 130 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:6 "];  // sneeze
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.5 "];	//backward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];  // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:9 "];  // sniff
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}
- (void) doSmell3{
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:1 SPEED:0.2 "];	//forward with duration
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stay still
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION: 2.0 TILT_ANGLE:70 "];	//head tilt 70 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:0 "];	//stay still
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:6 "];   // sneeze
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:130 "];	//head tilt 130 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:6 "];  // sneeze
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.5 "];	//backward
    [movementQueue addObject:@"TYPE:M DURATION:0.3 CMD:2 SPEED:0.2 "];	//backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];  // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:10 "];  // excited/laughing
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}
-(void) doTaste1{
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.7  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.7 CMD:1 SPEED:0.1 "];	//drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.5  CMD:12 "]; // want
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];			//tilt angle 80 degrees
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];		//tilt angle 100 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:2 SPEED:0.1 "];	//drive backward
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:4 ANGLE:25 RADIUS:0.1 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:8 "]; // curious
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.2  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.1 "];	//drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stay still
    
    [movementQueue addObject:@"TYPE:M DURATION:1.3 TILT_ANGLE:70 "];			//tilt angle 70 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:1.3  CMD:4 "];   // scared
    
    [movementQueue addObject:@"TYPE:M DURATION:1.3 TILT_ANGLE:130 "];		//tilt angle 130 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:1.3  CMD:4 "]; // scared
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:13 "];   // tired
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:2 SPEED:0.1 "];	//drive backward
    
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:4 ANGLE:360 RADIUS:0.1 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:5 "]; // angry
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:5 "];  // angry
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];  //neutral
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}
- (void) doTaste2{
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.7  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.7 CMD:1 SPEED:0.1 "];	//drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.5  CMD:12 "]; // want
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];			//tilt angle 80 degrees
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];		//tilt angle 100 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:2 SPEED:0.1 "];	//drive backward
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:4 ANGLE:25 RADIUS:0.1 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:8 "]; // curious
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.2  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.1 "];	//drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stay still
    
    [movementQueue addObject:@"TYPE:M DURATION:1.3 TILT_ANGLE:70 "];			//tilt angle 70 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:1.3  CMD:5 "];   // ANGRY
    
    [movementQueue addObject:@"TYPE:M DURATION:1.3 TILT_ANGLE:130 "];		//tilt angle 130 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:1.3  CMD:5 "]; // ANGRY
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:13 "];   // tired
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:2 SPEED:0.1 "];	//drive backward
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:9"];  //neutral
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];  //neutral
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}

-(void) doTaste3{
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.7  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.7 CMD:1 SPEED:0.1 "];	//drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.5  CMD:12 "]; // want
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];			//tilt angle 80 degrees
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];		//tilt angle 100 degrees
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:2 SPEED:0.1 "];	//drive backward
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:4 ANGLE:25 RADIUS:0.1 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:8 "]; // curious
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.2  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.1 "];	//drive forward
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:9 "];   // sniff
    [movementQueue addObject:@"TYPE:M DURATION:1.5 CMD:0 "];	//stay still
    
    [movementQueue addObject:@"TYPE:M DURATION:1.3 TILT_ANGLE:70 "];			//tilt angle 70 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:1.3  CMD:8 "];   // CURIOUS
    
    [movementQueue addObject:@"TYPE:M DURATION:1.3 TILT_ANGLE:130 "];		//tilt angle 130 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:1.3  CMD:8 "]; // CURIOUS
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:9 "];   // SNIFF
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:2 SPEED:0.1 "];	//drive backward
    
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:4 ANGLE:360 RADIUS:0.1 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:10 "]; // EXCITED
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:1 "];  // HAPPY
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];  //neutral
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}

- (void) doTouch1{
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.75 CMD:1 SPEED:0.1 "];	//forward
    [movementQueue addObject:@"TYPE:M DURATION:0.75 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:4 "]; // scared
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:80 "];			//tilt angle 80 degrees
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//back
     [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:0 "];	//still
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:100 "];		//tilt angle 100 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:2.8  CMD:3 "];   // frustrated
    
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:0 "];	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:2 "];  // sad
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
}

-(void) doTouch2{
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.75 CMD:1 SPEED:0.1 "];	//forward
    [movementQueue addObject:@"TYPE:M DURATION:0.75 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:9 "]; // sniff
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:80 "];			//tilt angle 80 degrees
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:0 "];	//stationary
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:100 "];		//tilt angle 100 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.8  CMD:0 "];  // default
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:4.0 CMD:0 "];	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:6.0  CMD:11 "];  // sleep
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
}
-(void) doTouch3{
    
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:105 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.5  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:0.5 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.5  CMD:8 "];   // curious
    [movementQueue addObject:@"TYPE:M DURATION:0.75 CMD:1 SPEED:0.1 "];	//forward
    [movementQueue addObject:@"TYPE:M DURATION:0.75 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:12 "]; // want
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:80 "];			//tilt angle 80 degrees
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:0 "];	//stationary
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 TILT_ANGLE:100 "];		//tilt angle 100 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:2.0  CMD:1 "];   // happy
    
    [emotionQueue addObject:@"TYPE:E DURATION:0.8  CMD:1 "];  // happy
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.2 "];	//shake backward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.2 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.2 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:4.0 CMD:0 "];	//stationary
    [emotionQueue addObject:@"TYPE:E DURATION:4.0  CMD:10 "];  // excited
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.2  CMD:22 "];  // yawn
    [emotionQueue addObject:@"TYPE:E DURATION:5.0  CMD:11 "];  // sleepy
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];  // default
    
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [self movementTimerRun];
    [self emotionTimerRun];
}
-(void) doVestibular{
    
    [emotionQueue addObject:@"TYPE:E DURATION:3.2  CMD:19 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:3.2 CMD:0 "];	//stationary
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M DURATION:1.0 CMD:0 "];	//stationary
    
    [movementQueue addObject:@"TYPE:M DURATION:3.0 CMD:4 ANGLE:360 RADIUS:0.0 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:3.0  CMD:1 "];   // happy
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.2  CMD:7 "];  // dizzy
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:1 SPEED:0.4 "];	//shake forward
    [movementQueue addObject:@"TYPE:M DURATION:0.2 CMD:2 SPEED:0.4 "];	//shake backward
    
    [movementQueue addObject:@"TYPE:M DURATION:3.2 CMD:4 ANGLE:-720 RADIUS:0.1 "];	//turn 180 degrees
    [emotionQueue addObject:@"TYPE:E DURATION:3.2  CMD:19 "];   // excited
    
    //[movementQueue addObject:@"TYPE:M DURATION:5.0 CMD:108 SPEED:0.2 RADIUS:0.2 "];	//figure 8
    [emotionQueue addObject:@"TYPE:E DURATION:6.0  CMD:10 "];  // excited
    
    [movementQueue addObject:@"TYPE:M DURATION:2.0 CMD:4 ANGLE:270 RADIUS:0.1 "];	//turn 180 degrees
    [movementQueue addObject:@"TYPE:M CMD:1 SPEED:0.2 DURATION:1.0 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:1.0  CMD:0 "];   // default
    [movementQueue addObject:@"TYPE:M CMD:0 DURATION:4.0 "];
    
    
    [self movementTimerRun];
    [self emotionTimerRun];

    
}

- (void) doCallOver1{
    [emotionQueue addObject:@"TYPE:E DURATION:4.0 CMD:2 "];   // SAD
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:4.0 CMD:14 "];   // UNHAPPY
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:120 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [emotionQueue addObject:@"TYPE:E DURATION:0.5 CMD:0 "];   // DEFAULT
    
    [self movementTimerRun];
    [self emotionTimerRun];
    
}
- (void) doCallOver2{
    [emotionQueue addObject:@"TYPE:E DURATION:4.0 CMD:8 "];   // CURIOUS
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:4.0 CMD:9 "];   // SNIFF
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:120 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [emotionQueue addObject:@"TYPE:E DURATION:0.5 CMD:0 "];   // DEFAULT
    
    [self movementTimerRun];
    [self emotionTimerRun];
}
- (void) doCallOver3{
    [emotionQueue addObject:@"TYPE:E DURATION:4.0 CMD:12 "];   // WANT
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [emotionQueue addObject:@"TYPE:E DURATION:4.0 CMD:1 "];   // HAPPY
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:1 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:100 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.5 TILT_ANGLE:70 "];
    
    [movementQueue addObject:@"TYPE:M DURATION:1.0 TILT_ANGLE:120 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:2 SPEED:0.2 "];
    [movementQueue addObject:@"TYPE:M DURATION:0.25 CMD:0 "];
    [emotionQueue addObject:@"TYPE:E DURATION:0.5 CMD:0 "];   // DEFAULT
    
    [self movementTimerRun];
    [self emotionTimerRun];
}

- (void)doManualActions:(NSString *)message {
    if([message rangeOfString:TYPE_EMOTION].location != NSNotFound) {
        [self makeEmotion:message];
    }
    else if([message rangeOfString:TYPE_MOVEMENT].location != NSNotFound) {
        [self makeMovement:message];
    }
}


- (void)movementTimerRun {
    
    if([movementQueue count] != 0) {
        NSString *currentMovement = [movementQueue objectAtIndex:0];
        [movementQueue removeObjectAtIndex:0];
        [self makeMovement:currentMovement];
        movementDuration = [self getDuration:currentMovement];
        if(movementDuration != -1.f) {
            [NSTimer scheduledTimerWithTimeInterval:movementDuration
                                             target:self
                                           selector:@selector(movementTimerRun)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
    else {
        movementLabel.text = @"mQueue Empty";
        movementDuration = -1.f;
    }
}

- (void)emotionTimerRun {
    if(previousEmotion != -1) {
        [self sendRomoMessage:[NSString stringWithFormat:@"EMOTION:%d\n", previousEmotion]];
    }
    if([emotionQueue count] != 0) {
        NSString *currentEmotion = [emotionQueue objectAtIndex:0];
        [emotionQueue removeObjectAtIndex:0];
        emotionLabel.text = currentEmotion;
        [self makeEmotion:currentEmotion];
        emotionDuration = [self getDuration:currentEmotion];
        
        [NSTimer scheduledTimerWithTimeInterval:emotionDuration
                                         target:self
                                       selector:@selector(emotionTimerRun)
                                       userInfo:nil
                                        repeats:NO];
    }
    else {
        emotionLabel.text = @"emotionQueue is empty";
        emotionDuration = -1.f;
    }
}

- (float)getDuration:(NSString *)cmd {
    NSString *durationStr = [self extractString:cmd toLookFor:CMD_DURATION skipForwardX:[CMD_DURATION length] toStopBefore:A_SPACE];
    if(durationStr)
        return [durationStr floatValue];
    else
        return -1.f;
}

/*
- (void)changeEmotionParam:(NSString *)message {
    NSString *emotionNumStr = [self extractString:message toLookFor:ORDINAL_NUMBER skipForwardX:[ORDINAL_NUMBER length] toStopBefore:A_SPACE];
    NSString *paramNumStr = [self extractString:message toLookFor:<#(NSString *)#> skipForwardX:<#(NSInteger)#> toStopBefore:<#(NSString *)#>]
}
*/

- (void)makeEmotion:(NSString *)message {

    NSString *emotionNum = [self extractString:message toLookFor:CMD_NUMBER skipForwardX:[CMD_NUMBER length] toStopBefore:A_SPACE];
    if(emotionNum) {
        NSArray *images;
        CGFloat duration;
        int emotionNumber = [emotionNum intValue];
        previousEmotion = emotionNumber;
        
        [self stopPlayingMusic];
        switch (emotionNumber) {
            case 0: {
                if(!defaultSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"default" ofType:@"mp3"]];
                    defaultSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    defaultSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:defaultSoundPlayer];
                [defaultSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:138/255.f green:213/255.f blue:220/255.f alpha:1.0];
                }];
                images = [animationHandler getDefaultArray:defaultParam];
                duration = [animationHandler getDefaultDuration:defaultParam];
                break;
            }
            case 1: {
                if(!happySoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"happy" ofType:@"caf"]];
                    happySoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    happySoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:happySoundPlayer];
                [happySoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:126/255.f green:204/255.f blue:129/255.f alpha:1.0];
                }];
                images = [animationHandler getHappyArray:happyParam];
                duration = [animationHandler getHappyDuration:happyParam];
                // [self sendAck:@"HAPPY\n"];
                break;
            }
            case 2: {
                if(!sadSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    sadSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    sadSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:sadSoundPlayer];
                [sadSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getSadArray:sadParam];
                duration = [animationHandler getSadDuration:sadParam];
                break;
            }
            case 3: {
                if(!frustratedSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"frustrated" ofType:@"caf"]];
                    frustratedSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    frustratedSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:frustratedSoundPlayer];
                [frustratedSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:228/255.f green:153/255.f blue:231/255.f alpha:1.0];
                }];
                images = [animationHandler getFrustratedArray:frustratedParam];
                duration = [animationHandler getFrustratedDuration:frustratedParam];
                break;
            }
            case 4: {
                if(!scaredSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"scared" ofType:@"caf"]];
                    scaredSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    scaredSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:scaredSoundPlayer];
                [scaredSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:208/255.f green:194/255.f blue:87/255.f alpha:1.0];
                }];
                images = [animationHandler getScaredArray:scaredParam];
                duration = [animationHandler getScaredDuration:scaredParam];
                break;
            }
            case 5: {
                if(!angrySoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"angry" ofType:@"mp3"]];
                    angrySoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    angrySoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:angrySoundPlayer];
                [angrySoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:255/255.f green:135/255.f blue:133/255.f alpha:1.0];
                }];
                images = [animationHandler getAngryArray:angryParam];
                duration = [animationHandler getAngryDuration:angryParam];
                break;
            }
            case 6: {
                if(!sneezeSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sneeze" ofType:@"caf"]];
                    sneezeSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    sneezeSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:sneezeSoundPlayer];
                [sneezeSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:231/255.f green:170/255.f blue:190/255.f alpha:1.0];
                }];
                images = [animationHandler getSneezeArray:sneezeParam];
                duration = [animationHandler getSneezeDuration:sneezeParam];
                break;
            }
            case 7: {
                if(!dizzySoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"dizzy" ofType:@"mp3"]];
                    dizzySoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    dizzySoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:dizzySoundPlayer];
                [dizzySoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:242/255.f green:208/255.f blue:151/255.f alpha:1.0];
                }];
                images = [animationHandler getDizzyArray:dizzyParam];
                duration = [animationHandler getDizzyDuration:dizzyParam];
                break;
            }
            case 8: {
                if(!curiousSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"curious" ofType:@"mp3"]];
                    curiousSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    curiousSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:curiousSoundPlayer];
                [curiousSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:219/255.f green:218/255.f blue:118/255.f alpha:1.0];
                }];
                images = [animationHandler getCuriousArray:curiousParam];
                duration = [animationHandler getCuriousDuration:curiousParam];
                break;
            }
            case 9: {
                if(!sniffSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sniff" ofType:@"mp3"]];
                    sniffSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    sniffSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:sniffSoundPlayer];
                [sniffSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:207/255.f green:228/255.f blue:140/255.f alpha:1.0];
                }];
                images = [animationHandler getSniffArray:sniffParam];
                duration = [animationHandler getSniffDuration:sniffParam];
                break;
            }
            case 10: {
                if(!excitedSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"excited" ofType:@"mp3"]];
                    excitedSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    excitedSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:excitedSoundPlayer];
                [excitedSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:150/255.f green:211/255.f blue:108/255.f alpha:1.0];
                }];
                images = [animationHandler getExcitedArray:excitedParam];
                duration = [animationHandler getExcitedDuration:excitedParam];
                break;
            }
            case 11: {
                if(!sleepySoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sleepy" ofType:@"caf"]];
                    sleepySoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    sleepySoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:sleepySoundPlayer];
                [sleepySoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:186/255.f green:206/255.f blue:208/255.f alpha:1.0];
                }];
                images = [animationHandler getSleepyArray:sleepyParam];
                duration = [animationHandler getSleepyDuration:sleepyParam];
                break;
            }
            case 12: {
                if(!wantSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"want" ofType:@"caf"]];
                    wantSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    wantSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:wantSoundPlayer];
                [wantSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:109/255.f green:212/255.f blue:167/255.f alpha:1.0];
                }];
                images = [animationHandler getWantArray:wantParam];
                duration = [animationHandler getWantDuration:wantParam];
                break;
            }
            case 13: {
                if(!tiredSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tired" ofType:@"mp3"]];
                    tiredSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    tiredSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:tiredSoundPlayer];
                [tiredSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:253/255.f green:135/255.f blue:104/255.f alpha:1.0];
                }];
                images = [animationHandler getTiredArray:tiredParam];
                duration = [animationHandler getTiredDuration:tiredParam];
                break;
            }
            case 14: {  //new 02/05/16
                if(!unhappySoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"unhappy" ofType:@"mp3"]];
                    unhappySoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    unhappySoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:unhappySoundPlayer];
                [unhappySoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:253/255.f green:135/255.f blue:104/255.f alpha:1.0];
                }];
                images = [animationHandler getUnhappyArray:unhappyParam];
                duration = [animationHandler getUnhappyDuration:unhappyParam];
                break;
            }
            case 15: {  //new 02/05/16
                if(!cryingSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"crying" ofType:@"mp3"]];
                    cryingSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    cryingSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:cryingSoundPlayer];
                [cryingSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getCryingArray:cryingParam];
                duration = [animationHandler getCryingDuration:cryingParam];
                break;
            }
            case 16: {  //all new 2/17/16
                if(!nervousSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"nervous" ofType:@"mp3"]];
                    nervousSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    nervousSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:nervousSoundPlayer];
                [nervousSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getNervousArray:nervousParam];
                duration = [animationHandler getNervousDuration:nervousParam];
                break;
            }
            case 17: {
                if(!terrifiedSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    terrifiedSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    terrifiedSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:terrifiedSoundPlayer];
                [terrifiedSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getTerrifiedArray:terrifiedParam];
                duration = [animationHandler getTerrifiedDuration:terrifiedParam];
                break;
            }
            case 18: {
                if(!surprisedSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    surprisedSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    surprisedSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:surprisedSoundPlayer];
                [surprisedSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getSurprisedArray:surprisedParam];
                duration = [animationHandler getSurprisedDuration:surprisedParam];
                break;
            }
            case 19: {
                if(!celebratingSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"celebrating" ofType:@"mp3"]];
                    celebratingSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    celebratingSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:celebratingSoundPlayer];
                [celebratingSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getCelebratingArray:celebratingParam];
                duration = [animationHandler getCelebratingDuration:celebratingParam];
                break;
            }
            case 20: {
                if(!grumpySoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    grumpySoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    grumpySoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:grumpySoundPlayer];
                [grumpySoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getGrumpyArray:grumpyParam];
                duration = [animationHandler getGrumpyDuration:grumpyParam];
                break;
            }
            case 21: {
                if(!furiousSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    furiousSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    furiousSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:furiousSoundPlayer];
                [furiousSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getFuriousArray:furiousParam];
                duration = [animationHandler getFuriousDuration:furiousParam];
                break;
            }
            case 22: {
                if(!boredSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"bored" ofType:@"mp3"]];
                    boredSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    boredSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:boredSoundPlayer];
                [boredSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getBoredArray:boredParam];
                duration = [animationHandler getBoredDuration:boredParam];
                break;
            }
            case 23: {
                if(!ickSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    ickSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    ickSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:ickSoundPlayer];
                [ickSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getIckArray:ickParam];
                duration = [animationHandler getIckDuration:ickParam];
                break;
            }
            case 24: {
                if(!disgustSoundPlayer) {
                    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sad" ofType:@"caf"]];
                    disgustSoundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
                    disgustSoundPlayer.numberOfLoops = -1;
                }
                [playingMusicArray addObject:disgustSoundPlayer];
                [disgustSoundPlayer play];
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.backgroundColor = [UIColor colorWithRed:128/255.f green:183/255.f blue:232/255.f alpha:1.0];
                }];
                images = [animationHandler getDisgustArray:disgustParam];
                duration = [animationHandler getDisgustDuration:disgustParam];
                break;
            }
            default:
                break;
        }
        animationImageView.animationImages = images;
        animationImageView.animationDuration = duration;
        animationImageView.animationRepeatCount = INFINITY;
        [animationImageView startAnimating];
    }
}

- (void)stopPlayingMusic {
    for(AVAudioPlayer *audioPlayer in playingMusicArray) {
        [audioPlayer pause];
        [playingMusicArray removeObject:audioPlayer];
    }
}

- (void)makeMovement:(NSString *)message {
    NSString *tiltStr = [self extractString:message toLookFor:TILT_ANGLE skipForwardX:[TILT_ANGLE length] toStopBefore:A_SPACE];
    if(tiltStr) {
        tiltAngle = [tiltStr floatValue];
        [self.robot tiltToAngle:tiltAngle completion:nil];
    }
    NSString *movementStr = [self extractString:message toLookFor:CMD_NUMBER skipForwardX:[CMD_NUMBER length] toStopBefore:A_SPACE];
    if(movementStr) {
        movementNumber = [movementStr intValue];
        switch (movementNumber) {
            case 0: {   //stop driving
                [self.robot stopDriving];
                break;
            }
            case 1: {   //drive forward
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                if(speedStr)
                    [self.robot driveForwardWithSpeed:[speedStr floatValue]];
                else {
                    // send message "wrong command"
                }
                break;
            }
            case 2: {   //drive backward works
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                if(speedStr)
                    [self.robot driveBackwardWithSpeed:[speedStr floatValue]];
                else {
                    // send message "wrong command"
                }
                break;
            }
            case 3: {   //drive with radius works
                NSString *radiusStr = [self extractString:message toLookFor:MOVEMENT_RADIUS skipForwardX:[MOVEMENT_RADIUS length] toStopBefore:A_SPACE];
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                if(speedStr && radiusStr)
                    [self.robot driveWithRadius:[radiusStr floatValue] speed:[speedStr floatValue]];
                else {
                    // send message "wrong command"
                }
                break;
            }
            case 4: {   //to the left, works
                NSString *angleStr = [self extractString:message toLookFor:MOVEMENT_ANGLE skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                NSString *radiusStr = [self extractString:message toLookFor:MOVEMENT_RADIUS skipForwardX:[MOVEMENT_RADIUS length] toStopBefore:A_SPACE];
                if(angleStr && radiusStr)
                    [self.robot turnByAngle:[angleStr floatValue] withRadius:[radiusStr floatValue] completion:nil];
                else {
                    // send message "wrong command"
                }
                break;
            }
            case 5: {   //works, when below not commented out, keep driving forward indefinitely
                NSString *angleStr = [self extractString:message toLookFor:MOVEMENT_ANGLE skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                NSString *radiusStr = [self extractString:message toLookFor:MOVEMENT_RADIUS skipForwardX:[MOVEMENT_RADIUS length] toStopBefore:A_SPACE];
                if(angleStr && radiusStr)
                    [self.robot turnByAngle:[angleStr floatValue] withRadius:[radiusStr floatValue]
                            /*finishingAction:finishingAction*/ completion:nil];    //11-19-15 commented out to mimic case 4
                else {
                    // send message "wrong command"
                }
                break;
            }
            case 6: {   //drives forward indefinitely
                NSString *angleStr = [self extractString:message toLookFor:MOVEMENT_ANGLE skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                NSString *radiusStr = [self extractString:message toLookFor:MOVEMENT_RADIUS skipForwardX:[MOVEMENT_RADIUS length] toStopBefore:A_SPACE];
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                if(angleStr && radiusStr && speedStr)
                   [self.robot turnByAngle:[angleStr floatValue] withRadius:[radiusStr floatValue] speed:[speedStr floatValue] finishingAction:finishingAction completion:nil];
                else {
                    // send message "wrong command"
                }
                break;
            }
            case 101: { //drive forward with duration works
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                NSString *durationStr = [self extractString:message toLookFor:CMD_DURATION skipForwardX:[CMD_DURATION length] toStopBefore:A_SPACE];
                if(speedStr && durationStr) {
                    [self driveForwardWithDuration:[durationStr floatValue] withSpeed:[speedStr floatValue]];
                }
                else {
                    // send message "wrong command"
                }

                break;
            }
            case 102: {
                
                break;
            }
            case 103: { //keeps going forward after circle is completed
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                NSString *radiusStr = [self extractString:message toLookFor:MOVEMENT_RADIUS skipForwardX:[MOVEMENT_RADIUS length] toStopBefore:A_SPACE];
                if(speedStr && radiusStr) {
                    [self driveClockWiseCircleWithSpeed:[speedStr floatValue] withRadius:[radiusStr floatValue]];
                    
                }
                else {
                    // send message "wrong command"
                }

                break;
            }
            case 108: { //finishes figure 8, then turns and drives forward nonstop
                NSLog(@"Got CMD 108");
                NSString *speedStr = [self extractString:message toLookFor:MOVEMENT_SPEED skipForwardX:[MOVEMENT_SPEED length] toStopBefore:A_SPACE];
                NSString *radiusStr = [self extractString:message toLookFor:MOVEMENT_RADIUS skipForwardX:[MOVEMENT_RADIUS length] toStopBefore:A_SPACE];
                if(speedStr && radiusStr) {
                    [self driveEightWithSpeed:[speedStr floatValue] withRadius:[radiusStr floatValue]];
                    //finishingAction:finishingAction completion:nil
                }
                else {
                    // send message "wrong command"
                    NSLog(@"108 error");
                }
                break;
            }
            default: {
                // [self.robot turnToHeading: withRadius:<#(float)#> finishingAction:<#(RMCoreTurnFinishingAction)#> completion:<#^(BOOL success, float heading)completion#>];
                
                // [self.robot turnToHeading:<#(float)#> withRadius:<#(float)#> speed:<#(float)#> forceShortestTurn:<#(BOOL)#> finishingAction:<#(RMCoreTurnFinishingAction)#> completion:<#^(BOOL success, float heading)completion#>];
                NSLog(@"Command Error");
                break;
            }
        }
    }
}

- (NSString *)extractString:(NSString *)fullString
                  toLookFor:(NSString *)lookFor
               skipForwardX:(NSInteger)skipForward
               toStopBefore:(NSString *)stopBefore {
    
    NSRange firstRange = [fullString rangeOfString:lookFor];
    if(firstRange.location != NSNotFound) {
        NSRange secondRange = [[fullString substringFromIndex:firstRange.location + skipForward] rangeOfString:stopBefore];
        if(secondRange.location != NSNotFound) {
            NSRange finalRange = NSMakeRange(firstRange.location + skipForward,
                                             secondRange.location + [stopBefore length] - 1);
            return [fullString substringWithRange:finalRange];
        }
    }
    return nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// For expression transition testing
-(void)swipedUp:(UIGestureRecognizer *)sender {
    testPenguinEmotion = ++testPenguinEmotion % NUM_EMOTION;
    NSString *str = CMD_NUMBER;
    str = [str stringByAppendingString:[NSString stringWithFormat:@"%d ",testPenguinEmotion]];
    [self makeEmotion:str];
}

- (void)addGestureRecognizers
{
    // Let's start by adding some gesture recognizers with which to interact with Romo
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(swipedUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    /*
     UITapGestureRecognizer *tapReceived = [[UITapGestureRecognizer alloc]
     initWithTarget:self action:@selector(tappedScreen:)];
     [self.view addGestureRecognizer:tapReceived];
     */
}

// CMD_NUMBER:101, duration, speed
- (void)driveForwardWithDuration:(float)duration withSpeed:(float)speed {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", speed], @"speed", nil];
    [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(stopDrivingWithTimer:) userInfo:dict repeats:NO];
    [self.robot driveForwardWithSpeed:speed];
    
}

- (void)stopDrivingWithTimer:(NSTimer *)timer {  //////pjh ack sample
    [self.robot stopDriving];
    [self movementTimerRun];
    NSDictionary *dict = [timer userInfo];
    float speed = [[dict objectForKey:@"speed"] floatValue];
    // send ack
    NSString *testAck = [NSString stringWithFormat:@"MOVEMENT:%d SPEED:%f \n", 101, speed]; // DURATION:%f
    NSLog(testAck);
    [self sendRomoMessage:testAck];
}

// CMD_NUMBER:103, speed, radius
- (void)driveClockWiseCircleWithSpeed:(float)speed withRadius:(float)radius {   // require minimum duration
    [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion: ^(BOOL success, float heading) {
        if(success) {
            [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                if(success) {
                    // send ack
                    
                }
                else {
                    // send fail msg
                    
                }
            }];
        }
        else {
            
        }
    }];
    
}

// CMD_NUMBER:104, speed, radius
- (void)driveCounterClockWiseCircleWithSpeed:(float)speed withRadius:(float)radius {
    [self.robot turnByAngle:180.f withRadius:radius speed:speed finishingAction:finishingAction completion: ^(BOOL success, float heading) {
        if(success) {
            [self.robot turnByAngle:180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                if(success) {
                    // send ack
                    
                }
                else {
                    // send fail msg
                    
                }
            }];
        }
        else {
            
        }
    }];
}

// CMD_NUMBER:108, REQUIRED: speed, radius
- (void)driveEightWithSpeed:(float)speed withRadius:(float)radius {    // require minimum duration
    // turn 90 in placef//
    float turnInPlaceSpeed = 0.6;
    NSLog(@"Step 1");
    [self.robot tiltToAngle:80 completion:nil];
    NSLog(@"Flag reset."); //
    [self.robot turnByAngle:90.f withRadius:0 speed:turnInPlaceSpeed finishingAction:finishingAction completion:^(BOOL success, float heading) {
        if(success) {
            // turn 180
            NSLog(@"Step 2");
            [self.robot tiltToAngle:80 completion:nil];
            
            [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                if(success) {
                    NSLog(@"Step 3");
                    [self.robot turnByAngle:180.f withRadius:radius speed:speed finishingAction:finishingAction completion: ^(BOOL success, float heading) {
                        if(success) {
                            NSLog(@"Step 4");
                            NSLog(@"Success flag reset4");
                            [self.robot turnByAngle:-90.f withRadius:0 speed:turnInPlaceSpeed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                                if(success) {
                                    // send ack
                                    NSLog(@"DriveEight Success and send ACK to server");
                                }
                                else {
                                    // send nack
                                    // show error log
                                    NSLog(@"DriveEight Part #4 error and send NACK to server");
                                }
                            }];
                        }
                        else {
                            // send nack
                            // show error log
                            NSLog(@"DriveEight Part #3 error and send NACK to server");
                        }
                    }];
                }
                else {
                    // send nack
                    // show error log
                    NSLog(@"DriveEight Part #2 error and send NACK to server");
                }
            }];
        }
        else {
            // send nack
            // show error log
            NSLog(@"DriveEight Part #1 error and send NACK to server");
        }
    }];
}



// CMD_NUMBER:110, speed, radius
- (void)driveCloverWithSpeed:(float)speed withRadius:(float)radius {   // require minimum duration
    // turn -180 (== draw a leaf of clover)
    float turnInPlaceSpeed = 0.6;
    [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
        if(success) {
            // turn in place 90
            [self.robot turnByAngle:90 withRadius:0 speed:turnInPlaceSpeed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                if(success) {
                    // turn -180
                    [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                        if(success) {
                            // turn 90
                            [self.robot turnByAngle:90 withRadius:0 speed:turnInPlaceSpeed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                                if(success) {
                                    // turn -180
                                    [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                                        if(success) {
                                            // turn 90
                                            [self.robot turnByAngle:90 withRadius:0 speed:turnInPlaceSpeed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                                                if(success) {
                                                    // turn -180
                                                    [self.robot turnByAngle:-180.f withRadius:radius speed:speed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                                                        if(success) {
                                                            // turn 90
                                                            [self.robot turnByAngle:90 withRadius:0 speed:turnInPlaceSpeed finishingAction:finishingAction completion:^(BOOL success, float heading) {
                                                                if(success) {
                                                                    // send ack
                                                                }
                                                                else {
                                                                    
                                                                }
                                                            }];
                                                        }
                                                        else {
                                                            
                                                        }
                                                    }];
                                                }
                                                else {
                                                    
                                                }
                                            }];
                                        }
                                        else {
                                            
                                        }
                                    }];
                                }
                                else {
                                    
                                }
                            }];
                        }
                        else {
                            
                        }
                        
                    }];
                }
                else {
                    
                }
            }];
        }
        else {
            
        }
    }];
    
}

// CMD_NUMBER:201, distance, speed
- (void)driveForwardWithDistance:(float)distance withSpeed:(float)speed {
    float duration = distance / speed;
    [self driveForwardWithDuration:duration withSpeed:speed];
}



- (void)sendRomoMessage:(NSString *)romoMessage {
    NSData* data = [romoMessage dataUsingEncoding:NSASCIIStringEncoding];
    [socketComm sendData:data];
}


// extra functions below:




- (void)driveForwardWithTimer:(NSTimer *)timer {
    float speed = [[[timer userInfo] objectForKey:@"speed"] floatValue];
    [self.robot driveForwardWithSpeed:speed];
}

- (void)driveBackwardWithTimer:(NSTimer *)timer {
    float speed = [[[timer userInfo] objectForKey:@"speed"] floatValue];
    [self.robot driveBackwardWithSpeed:speed];
}

- (void)radiusWithTimer:(NSTimer *)timer {
    float radius = [[[timer userInfo] objectForKey:@"radius"] floatValue];
    float speed = [[[timer userInfo] objectForKey:@"speed"] floatValue];
    [self.robot driveWithRadius:radius speed:speed];
}

- (void)turnByAngleWithTimer1:(NSTimer *)timer {
    float angle = [[[timer userInfo] objectForKey:@"angle"] floatValue];
    float radius = [[[timer userInfo] objectForKey:@"radius"] floatValue];
    [self.robot turnByAngle:angle withRadius:radius completion:nil];
}

- (void)turnByAngleWithTimer2:(NSTimer *)timer {
    float angle = [[[timer userInfo] objectForKey:@"angle"] floatValue];
    float radius = [[[timer userInfo] objectForKey:@"radius"] floatValue];
    float speed = [[[timer userInfo] objectForKey:@"speed"] floatValue];
    [self.robot turnByAngle:angle withRadius:radius speed:speed finishingAction:finishingAction completion:nil];
}





@end
