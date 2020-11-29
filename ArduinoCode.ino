/*
  DigitalReadSerial

  Reads a digital input on pin 2, prints the
  result to the serial monitor

  This example code is in the public domain.
*/

unsigned char uchButtonState[12] = {1,1,1,1,1,1,1,1,1,1,1,1};
unsigned char USE_LDR = 1;
void setup()
{
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  pinMode(4, INPUT);
  pinMode(5, INPUT);
  pinMode(6, INPUT);
  pinMode(7, INPUT);
  pinMode(8, INPUT);
  pinMode(9, INPUT);
  pinMode(10, INPUT);
  pinMode(11, INPUT);
  pinMode(12, INPUT);
  pinMode(13, INPUT);
  pinMode(A5, INPUT);

  Serial.begin(9600);

}

void loop()
{
  unsigned char Cnt;
  unsigned char uchLdrStatus;
  for (Cnt=0;Cnt<12;Cnt++)
  {
    uchButtonState[Cnt] = digitalRead(Cnt+2);
    Serial.print(uchButtonState[Cnt]);
    Serial.print(','); //comma delimits the data of 12 switches
    //delay(5);
  }//end for
  if (USE_LDR == 1)
  {
  // now send the status of the ldr
    uchLdrStatus = digitalRead(A5);
    Serial.print(uchLdrStatus);
    Serial.print(','); //comma delimits the data of LDR
  }
  Serial.println();//Newline denotes end of 1 set of data
  delay(500);
}