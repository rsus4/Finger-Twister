//TWISTER Game Code using Arduino UNO.  This game uses 12 keys on Arduino digital pin 2 to pin 13.  The Key if left open sends back a Hi.  If pressed, sends 
// a low signal to this code through Serial Events.
// The moto of the game is to press the respective keys on the keyboard as instructed by the system.  The key once pressed is not to be released.  If the 
//key is released before the game is over, then the player loses the game.
// The game has two modes: Hard & Easy
// It can be played in SINGLE_PLAYER or TWO_PLAYER modes



import processing.serial.*;

Serial myPort;  // Create object from Serial class
//String sInStrVal;     // Data received from the serial port


int nCurrentPlayer = 1, nTotalPlayers = 2, nTogglePlayer = 0;
int nFingerIndex = 0, GameOnFlag = 1, nColIndex=0;
int[] nTotalFingerCntCurrCol= {0,0,0,0};// indicates the total no. of fingers in a particular column at any point of time
int[][] nPlayerFingerUsedIndex = {{6,6,6,6,6},{6,6,6,6,6}};//assign a index which is never possible
int[] nMyKeys = {1,1,1,1,1,1,1,1,1,1,1,1};
int[] nKeyAssignedTo = {0,0,0,0,0,0,0,0,0,0,0,0}; //0->Not Assigned, 1->Assigned to Player1, 2->Assigned to Player2
int inSerialEventFlag = 0;  //indicates we are in serial event routine
int nPlayerLost = 0; //if 1 then -> Player 1 loses, if 2-> player2 loses, if 0-> game still on and no player loses
int nLDRstatus = 0;  //LDR input is Low when exposed to light and vice versa 

String[] FingerType = {"Thumb ", "Index ", "Middle", "Ring  ", "Pinky "};//represents player finger index 0-4
String quote = "Game TWISTER Begins.........";

int MAX_FINGERS=5;
int MAX_COLS = 4;
int MAX_PLAYERS = 2;
int MAX_KEYS = 12;

int MAX_WAIT_SECONDS = 20;
int KEYCHECK_INTERVAL = 1000;
int USE_LDR = 1;

int SINGLE_PLAYER = 1;
int TWO_PLAYER = 2;

int HIGH = 1;
int LOW = 0;

int nDifficultyLevel = HIGH;


void initVar()
{
  int Cnt1,Cnt2;
  
  for(Cnt1=0;Cnt1<MAX_PLAYERS;Cnt1++)
    for(Cnt2=0;Cnt2<MAX_FINGERS;Cnt2++)
      nPlayerFingerUsedIndex[Cnt1][Cnt2] = 6; //assign a index which is never possible
  
      for(Cnt1=0;Cnt1<MAX_COLS;Cnt1++)
        nTotalFingerCntCurrCol[Cnt1] = 0;// indicates the total no. of fingers in a particular column at any point of time
        
      for(Cnt1=0;Cnt1<MAX_KEYS;Cnt1++)
        nKeyAssignedTo[Cnt1] = 0;//0->Not Assigned, 1->Assigned to Player1, 2->Assigned to Player2
}// end fxn initVar()

void setup(){
     size(400,400);
     background(102);
     text(quote, 26, 30, 240, 100);
 
//I know that the first port in the serial list on my mac
//is Serial.list()[0].
// On Windows machines, this generally opens COM1.
// Open whatever port is the one you're using.
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 9600);
  
  if (USE_LDR == 1) {
    print("\nTouch LDR to Start Game.........\n");
    while(nLDRstatus == 0) {delay(50);} // Wait until nLDRstatus is read as 1 from Serial Port. It is 1, in dark and 0 in light
  }
  print("\nGame TWISTER Begins.........\n");
  initVar();
}// end fxn setup()



//This function is used to choose a finger for the player passed as pCurrPlIndex based on the random value pX
//This function checks the value of random var pX and if this finger is not already used, then it accepts 
// that value, otherwise if it has already been used earlier, it passes the next unused index from
// nPlayerFingerUsedIndex array.
int chooseFinger(int pCurrPlIndex, int pX)
{
  int Cnt,returnVal=0;
  for(Cnt=0;Cnt<MAX_FINGERS;Cnt++)
  {
    if (nPlayerFingerUsedIndex[pCurrPlIndex][pX] != 1){
      nPlayerFingerUsedIndex[pCurrPlIndex][pX] =1;
      returnVal = pX;
      break;
    }
    else // i.e. the index has already been used so find next unused index value
    {
      if (pX == 4)
        pX = 0;
      else
        pX++;
    }// end else    
  }// end for(Cnt=0;Cnt<5;Cnt++)
  return returnVal;
}// end fxn int chooseFinger(int pX)


int uchDetectKeyPress(int pColIdx)
{
  //Return 0 if Key Press Detected
  //Return 1 if Timeout Detected
  //Return 2 if Assigned Key is Released during checkKeyStatus()
  int Cnt;
  int nRetnVal = 1;
  
 int initialTime = millis();
 int finalTime = initialTime + (MAX_WAIT_SECONDS*1000);
 int checkKeysTime = initialTime + KEYCHECK_INTERVAL;
 
 int nStartIndex = pColIdx*3;
 
 while (millis() < finalTime) // for checking the timeout time
 {
  
   if (checkKeysTime < millis()) // for checking keys every 2 seconds
     {
       checkKeysTime = millis() + KEYCHECK_INTERVAL;
       if (checkKeyStatus() == 2)
       {
         nRetnVal = 2; //i.e. game over
         break;
       }
     }//end if (checkKeysTime < millis())
   
   for (Cnt=nStartIndex;Cnt<nStartIndex+3;Cnt++)
   {
     if (nKeyAssignedTo[Cnt] == 0)
       if ((inSerialEventFlag ==0) && (nMyKeys[Cnt] ==0)) // i.e. key is pressed
       {
         nKeyAssignedTo[Cnt] = nCurrentPlayer;
         nRetnVal = 0;
         break;
       }
   }// end for
   if (nRetnVal == 0) //i.e. key has been assigned
     break;
 }//end while
   
 return(nRetnVal);
}// end fxn int uchDetectKeyPress()

int checkKeyStatus()
{
  // This fxn will check for the keys which were assigned to the players.  If any of them is UP, then we will set a variable to Stop the Game 
  //immediately.  This function should be called by a timer every 2-3 seconds
  
  int Cnt;
  int nRetnVal = 0; //2-> game over, 0-> normal 
  for (Cnt=0;Cnt<MAX_KEYS;Cnt++)
  {
    if (nKeyAssignedTo[Cnt] != 0) //i.e. key has been assigned and is supposed to be DOWN
      if ((inSerialEventFlag ==0) && (nMyKeys[Cnt] ==1)) // i.e. key is RELEASED or UP
      {
        GameOnFlag = 0;
        nPlayerLost = nKeyAssignedTo[Cnt];
        nRetnVal = 2;
        break;
      }
  }// end for(Cnt=0;Cnt<MAX_KEYS;Cnt++)
  return(nRetnVal);
}// end fxn void checkKeyStatus()


void draw()
{
  int infinite = 1;
  int nTotalFingerCount = 0;
  int nRetnVal=0;
  
  int initialTime = millis();
  int finalTime = initialTime + (2000);
  int Cnt;
 
  //Get nTotalPlayers Input i.e. 1 or 2 Here
  //nTotalPlayers = SINGLE_PLAYER;
  nTotalPlayers = TWO_PLAYER;
  
  //Get Difficulty Level, HIGH->1, LOW->0
  //nDifficultyLevel = HIGH;
  nDifficultyLevel = LOW;
  
  
  if (nTotalPlayers == TWO_PLAYER)
    nTogglePlayer = 1;
  else
    nTogglePlayer=0;
    
 nCurrentPlayer = 1;
 
 while(GameOnFlag==1)
 {
   //Generate a random no. between 0-5 to indicate finger to be used
  int x = (int) random(0,5);
  if (x>4)
    x=4; //as finger index should be between 0 to 4
  nTotalFingerCount = nTotalFingerCount +1;
  nFingerIndex = chooseFinger(nCurrentPlayer-1,x);
  
  //Now generate random no. to get the column where the finger is to be placed.  
  //We assuse 4 columns having 3 rows each to accomodate 10 fingers in total
  //So in any column, maximum of 3 fingers can be put
  do{
    nColIndex = (int) random(0,4);
    if (nColIndex > 3)
      nColIndex = 3; // as column index should be between 0-3 for 4 columns
      //print("\n No. of Times in Col # = #",nColIndex, nTotalFingerCntCurrCol[nColIndex]); 
    if (nTotalFingerCntCurrCol[nColIndex] < 3)
      break;
    // if we already have 3 fingers in the column, then repeat the process till we get one 
    //column with less than 3 fingers
  }while (infinite == 1);
  nTotalFingerCntCurrCol[nColIndex]++; 
  
  if (nDifficultyLevel == HIGH)
    print("\n Player ",nCurrentPlayer,", Put ",FingerType[nFingerIndex], "finger in Col ",nColIndex+1);
  else
    print("\n Player ",nCurrentPlayer,", Put any finger in Col ",nColIndex+1);
    
  //print(". Total Fingers in this Col are ",nTotalFingerCntCurrCol[nColIndex]); 
   
  nRetnVal = uchDetectKeyPress(nColIndex);
   
   if (nRetnVal == 0) // i.e. keypress detected
   {
     if (nTogglePlayer == 1)
     {       
       if (USE_LDR == 1) {
          print("\nPlayer ",nCurrentPlayer," Key Registered...");
       }
       if (nCurrentPlayer == 1)
         nCurrentPlayer = 2;
       else
         nCurrentPlayer = 1;
       
       if (USE_LDR == 1) {
          print("\nTouch LDR to Change to Player ",nCurrentPlayer," \n");
          while(nLDRstatus == 0) {delay(50);}  // Wait until nLDRstatus is read as 1 from Serial Port. It is 1, in dark and 0 in light
        }
     
   } // end if(nTogglePlayer == 1)
   } // end if (nRetnVal == 0) // i.e. keypress detected 
   else if (nRetnVal == 1)// i.e. timeout error detected
   {
     print("\n\nPlayer ",nCurrentPlayer, " Timeout.  Player ", nCurrentPlayer, " Loses !!!!!");
     break;
   }
   else //i.e. nRetnVal = 2 i.e. Key had been released by player inadvertantly in checkKeyStatus()
   {
     print("\n\nPlayer ",nPlayerLost, " Released Key.  Player ", nPlayerLost, " Loses !!!!!");
     break;
   }
  if (nTotalPlayers == 2)
  {
    if (nTotalFingerCount > 9)
    {
       print("\n\nMatch is Draw... Congrats to Both Players!!!");
         break;
       //for (Cnt=0;Cnt<MAX_KEYS;Cnt++)
         //print("\n\n nKeyAssignedTo[",Cnt,"] = ",nKeyAssignedTo[Cnt],"\n");
    }//end if (nTotalFingerCount > 9)
  }// end if (nTotalPlayers == 2)
  else // i.e. no. of players is 1
  {
    if (nTotalFingerCount > 4)
    {
      print("\n\nYou Win....CONGRATULATIONS!!!");
      break;
    }
  }// end else
  
 } //end while (GameOnFlag==TRUE)
 
 while (infinite == 1){};
}// end fxn draw()


void serialEvent (Serial myPort) {
// get the ASCII string:
inSerialEventFlag = 1;
String inString = myPort.readStringUntil('\n');

  if (inString != null) {
    int CommaStartIndex = 0;
    //println();
    //println(inString);
    //println();
    
    //for (int Cnt=0;Cnt<MAX_KEYS;Cnt++)
    //we add +1 to read the status of LDR
    for (int Cnt=0;Cnt<MAX_KEYS+1;Cnt++)
    {    
      int CommaEndIndex = inString.indexOf(",");      
      String a = inString.substring(CommaStartIndex, CommaEndIndex);
      
       if (USE_LDR == 1) {
          if (Cnt < MAX_KEYS)
            nMyKeys[Cnt] = int(a);
          else //get status of ldr
            nLDRstatus = int(a);      
       }
       else {
          if (Cnt < MAX_KEYS)
            nMyKeys[Cnt] = int(a);
       }
       
      
      inString = inString.substring(CommaEndIndex+1);
      CommaStartIndex = 0;
     if ((USE_LDR != 1) &&  (Cnt == (MAX_KEYS-1)))
       break;
    }// end for
  }//end if
  inSerialEventFlag = 0;
}//end of fxn serialEvent()



/***********************************
void TestKeyString(){
// get the ASCII string:
inSerialEventFlag = 1;
String inString = "2,1,4,3,6,5,8,7,9,0,1,2,'\10'";

  if (inString != null) {
    // trim off any whitespace:
    int CommaStartIndex = 0;
    for (int Cnt=0;Cnt<MAX_KEYS;Cnt++)
    {    
      int CommaEndIndex = inString.indexOf(",");
      
      String a = inString.substring(CommaStartIndex, CommaEndIndex);
      nMyKeys[Cnt] = int(a);
      inString = inString.substring(CommaEndIndex+1);
      CommaStartIndex = 0;
     
    }// end for
  }//end if
  inSerialEventFlag = 0;
}//end of fxn TestKeyString()
******************************************/