#define RF_D0 9
#define MOTOR 5

int lastCommand = 0;
unsigned long lastSignalTime = 0;

int readStableRF()
{
  int highCount = 0;

  for(int i=0;i<10;i++)
  {
    if(digitalRead(RF_D0) == HIGH)
      highCount++;

    delay(2);
  }

  if(highCount >= 7) return HIGH;
  if(highCount <= 3) return LOW;

  return -1; // noise
}

void setup()
{
  Serial.begin(9600);
  pinMode(RF_D0, INPUT);
  pinMode(MOTOR, OUTPUT);
}

void loop()
{
  int state = readStableRF();

  if(state != -1)   // valid decision
  {
    lastCommand = state;
    lastSignalTime = millis();
  }

  // failsafe if signal lost > 1 second
  if(millis() - lastSignalTime > 1000)
  {
    analogWrite(MOTOR, 0);
    Serial.println("Signal Lost -> Motor OFF");
    return;
  }

  if(lastCommand == HIGH)
  {
    analogWrite(MOTOR, 120);
    Serial.println("LOW SPEED");
  }
  else
  {
    analogWrite(MOTOR, 225);
    Serial.println("HIGH SPEED");
  }
}
