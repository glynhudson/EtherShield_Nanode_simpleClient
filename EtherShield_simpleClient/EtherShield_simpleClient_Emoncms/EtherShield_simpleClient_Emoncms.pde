//--------------------------------------------------------
// EtherShield examples: simple client Emoncms
//
//   simple client code layer:
//
// - ethernet_setup(mac,ip,gateway,server,port)
// - ethernet_ready() - check this before sending
//
// - ethernet_setup_dhcp(mac,serverip,port)
// - ethernet_ready_dhcp() - check this before sending
//
// - ethernet_setup_dhcp_dns(mac,domainname,port)
// - ethernet_ready_dhcp_dns() - check this before sending
//
//   Posting data within request body:
// - ethernet_send_post(PSTR(PACHUBEAPIURL),PSTR(PACHUBE_VHOST),PSTR(PACHUBEAPIKEY), PSTR("PUT "),str);
// 
//   Sending data in the URL
// - ethernet_send_url(PSTR(HOST),PSTR(API),str);
//
//   EtherShield library by: Andrew D Lindsay
//   http://blog.thiseldo.co.uk
//
//   Example by Trystan Lea, building on Andrew D Lindsay's examples
//
//   Projects: Nanode.eu and OpenEnergyMonitor.org
//   Licence: GPL GNU v3
//--------------------------------------------------------

#include <EtherShield.h>

byte mac[6] =     { 0x54,0x55,0x38,0x12,0x01,0x23};
byte ip[4] =      {192,168,1,8};
byte gateway[4] = {192,168,1,1};
byte server[4] =  {85, 92, 86, 84};

#define HOST ""  // Blank "" if on your local network: www.yourdomain.org if not
#define API "/emoncms/api/post.php?apikey=XXXXXXXXXXXXXXXXX&json="

unsigned long lastupdate;

char str[50];
char fstr[10];
int dataReady=0;
    
void setup()
{
  Serial.begin(9600);
  Serial.println("EtherShield_simpleClient_Emoncms");
  
  ethernet_setup(mac,ip,gateway,server,80);
}

void loop()
{
  //--------------------------------------
  // 1) Measurements and data preparation
  //--------------------------------------
  if ((millis()-lastupdate)>6000)
  {
    lastupdate = millis();
    
    int a0 = analogRead(0);
    int a1 = analogRead(1);
    
    // Build up a json string: {key:value,key:value}
    // dtostrf - converts a double to a string!
    // strcat  - adds a string to another string
    // strcpy  - copies a string
    strcpy(str,"{a0:"); dtostrf(a0,0,1,fstr); strcat(str,fstr); strcat(str,",");
    strcat(str,"a1:"); dtostrf(a1,0,1,fstr); strcat(str,fstr); strcat(str,"}");
    
    dataReady = 1;
  }
  
  //----------------------------------------
  // 2) Send the data
  //----------------------------------------
  if (ethernet_ready() && dataReady==1)
  {
    ethernet_send_url(PSTR(HOST),PSTR(API),str);
    Serial.println("sent"); dataReady = 0;
  }
  
}


