**Summary**

Experiment with a very simple IoT system which transfers data from ESP32 => BLE => AWS IoT Core, and the mobile app is written in Swift (iOS). An [x509-client-certs](https://docs.aws.amazon.com/iot/latest/developerguide/x509-client-certs.html) is attached at the client (moible app) to enable transfer data to AWS IoT via SDK in Swift. It is noted that it is possible to transfer data directly from ESP32 to AWS IoT core, however, in this case, I want to experiment BLE connection between ESP32 <==> mobile phone as well. In addition, in some cases, when there is not WIFI, the the phone with 3G/4G simcard will help. 


![esp32_iot_aws](https://user-images.githubusercontent.com/20411077/159871392-b345d18b-d989-4922-9280-ca3b1121f98e.png)
