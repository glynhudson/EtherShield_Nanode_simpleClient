//--------------------------------------------------------
//   EtherShield examples: simple client Emoncms with DHCP + RF12
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
//   RF12 Library by Jean-Claude Wippler
//   http://jeelabs.org/
//
//   Example by Trystan Lea, building on Andrew D Lindsay's and Jean-Claude Wippler's examples
//
//   Projects: Nanode.eu and OpenEnergyMonitor.org
//   Licence: GPL GNU v3
//--------------------------------------------------------
#include <Ports.h>
#include <RF12.h>

#define MYNODE 30            //node ID 30 reserved for base station
#define freq RF12_433MHZ     //frequency
#define group 212            //network group 


#include <EtherShield.h>

byte mac[6] =     { 0x54,0x55,0x38,0x12,0x01,0x23};
byte server[4] =  {192,168,1,5};

#define HOST ""  // Blank "" if on your local network: www.yourdomain.org if not
#define API "/emoncms/api/post.php?apikey=XXXXXXXXXXXXXXXXX&json="

char str[150]; // emontx json may reach 130 characters
int dataReady=0;

//########################################################################################################################
// EmonTX Data Structure to be received 
//########################################################################################################################
typedef struct {
  	  int ct1;		// current transformer 1
	  int ct2;		// current transformer 2
	  int nPulse;		// number of pulses recieved since last update
	  int temp1;		// One-wire temperature 1
	  int temp2;		// One-wire temperature 2
	  int temp3;		// One-wire temperature 3
	  int supplyV;		// emontx voltage
	} Payload;
	Payload emontx;

int emontx_nodeID;    //node ID of emon tx, extracted from RF datapacket. Not transmitted as part of structure
//########################################################################################################################
    
void setup()
{
  Serial.begin(9600);
  Serial.println("EtherShield_simpleClient_Emoncms_DHCP_RF12");
  
  ethernet_setup_dhcp(mac,server,80,8); // Last two: PORT and SPI PIN: 8 for Nanode, 10 for nuelectronics
  
  rf12_initialize(MYNODE, freq,group);
}

void loop()
{
  //----------------------------------------
  // 1) Recieve data from rf12
  //----------------------------------------
  if (rf12_recvDone() && rf12_crc == 0 && (rf12_hdr & RF12_HDR_CTL) == 0 && rf12_len==sizeof(Payload) ) 
  {
    emontx=*(Payload*) rf12_data;   
    emontx_nodeID=rf12_hdr & 0x1F;   //extract node ID from received packet 
    
    // Construct json
    sprintf(str,"{emontx_ID:%d,emontx_ctA:%d,emontx_ctB:%d,nPulse:%d,emontx_temp1:%d,emontx_temp2:%d,emontx_temp3:%d,emontx_V:%d}",emontx_nodeID,emontx.ct1, emontx.ct2, emontx.nPulse, emontx.temp1,emontx.temp2,emontx.temp3,emontx.supplyV);
    Serial.println(str);
    
    dataReady = 1;
  }
  
  //----------------------------------------
  // 2) Send the data
  //----------------------------------------
  if (ethernet_ready_dhcp() && dataReady==1)
  {
    ethernet_send_url(PSTR(HOST),PSTR(API),str);
    Serial.println("sent"); dataReady = 0;
  }
  
}


