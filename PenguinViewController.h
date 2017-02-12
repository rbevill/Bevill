//
//  PenguinViewController.h
//  PenguinVer1
//
//  Created by Jongwon Lee on 6/27/15.
//  Copyright (c) 2015 Jongwon Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocketCommunicator.h"
#import "SocketSingleton.h"
#import <RMCore/RMCore.h>
#import <AVFoundation/AVFoundation.h>
// #import "AnimationSingleton.h"
#import "AnimationHandler.h"

@interface PenguinViewController : UIViewController <RMCoreDelegate> {
    SocketCommunicator *socketComm;
    UILabel *messageLabel;
    UILabel *emotionLabel;
    UILabel *movementLabel;
    
    UIImageView *animationImageView;
    
    NSMutableArray *playingMusicArray;
    
    AVAudioPlayer *defaultSoundPlayer;
    AVAudioPlayer *happySoundPlayer;
    AVAudioPlayer *sadSoundPlayer;
    AVAudioPlayer *frustratedSoundPlayer;
    AVAudioPlayer *scaredSoundPlayer;
    AVAudioPlayer *angrySoundPlayer;
    AVAudioPlayer *sneezeSoundPlayer;
    AVAudioPlayer *dizzySoundPlayer;
    AVAudioPlayer *curiousSoundPlayer;
    AVAudioPlayer *sniffSoundPlayer;
    AVAudioPlayer *excitedSoundPlayer;
    AVAudioPlayer *sleepySoundPlayer;
    AVAudioPlayer *wantSoundPlayer;
    AVAudioPlayer *tiredSoundPlayer;
    AVAudioPlayer *unhappySoundPlayer;  //new 02/05/16
    AVAudioPlayer *cryingSoundPlayer;   //new 02/05/16
    AVAudioPlayer *nervousSoundPlayer;  //all new 2/17/16
    AVAudioPlayer *terrifiedSoundPlayer;
    AVAudioPlayer *surprisedSoundPlayer;
    AVAudioPlayer *celebratingSoundPlayer;
    AVAudioPlayer *grumpySoundPlayer;
    AVAudioPlayer *furiousSoundPlayer;
    AVAudioPlayer *boredSoundPlayer;
    AVAudioPlayer *ickSoundPlayer;
    AVAudioPlayer *disgustSoundPlayer;

    
    float tiltAngle;
    
    int movementNumber;
    float movement_speed;
    float turnRadius;
    float turnAngle;
    RMCoreTurnFinishingAction finishingAction;
    
    int testPenguinEmotion;
    
    float emotionDuration;
    NSMutableArray *emotionQueue;
    
    float movementDuration;
    NSMutableArray *movementQueue;
    
    NSMutableArray *cmdQueue;
    
    int defaultParam;
    int happyParam;
    int sadParam;
    int frustratedParam;
    int scaredParam;
    int angryParam;
    int sneezeParam;
    int dizzyParam;
    int curiousParam;
    int sniffParam;
    int excitedParam;
    int sleepyParam;
    int wantParam;
    int tiredParam;
    int unhappyParam;   //new 02/05/16
    int cryingParam;    //new 02/05/16
    int nervousParam;   //all new 2/17/16
    int terrifiedParam;
    int surprisedParam;
    int celebratingParam;
    int grumpyParam;
    int furiousParam;
    int boredParam;
    int ickParam;
    int disgustParam;
    
    AnimationHandler *animationHandler;
    
    int previousEmotion;
}

@property (nonatomic, strong) RMCoreRobot<HeadTiltProtocol, DriveProtocol, LEDProtocol> *robot;
//@property (nonatomic, strong) NSString *type;
//@property (nonatomic, strong) NSString *scenario;
//@property (nonatomic, strong) NSString *speed;

- (NSString *)extractString:(NSString *)fullString
                  toLookFor:(NSString *)lookFor
               skipForwardX:(NSInteger)skipForward
               toStopBefore:(NSString *)stopBefore;

- (void)sendRomoMessage:(NSString *)romoMessage;
@end
