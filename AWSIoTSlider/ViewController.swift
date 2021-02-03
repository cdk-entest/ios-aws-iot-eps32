//
//  ViewController.swift
//  AWSIoTSlider
//
//  Created by hai on 29/11/20.
//  Copyright © 2020 biorithm. All rights reserved.
//

import UIKit
import AWSIoT
import AWSMobileClient
import CoreBluetooth

let heartRateServiceCBUUID = CBUUID.init(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
let heartRateMeasurementCharacteristicCBUUID = CBUUID.init(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
let bodySensorLocationCharacteristicCBUUID = CBUUID.init(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")


class ViewController: UIViewController {
    
    // BLE
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    var heartRateValue: Int!
    var AWSIOTConnectStatus: Bool = false
    
    // AWS
    let IOT_CERT = "IoT Cert"
    let IOT_WEBSOCKET = "IoT Websocket"
    var connectIoTDataWebSocket: UIButton!
    var activityIndicatorView: UIActivityIndicatorView!
    var logTextView: UITextView!
    var connectButton: UIButton!
    
    @objc var connected = false
    @objc var publishViewController : UIViewController!
    @objc var subscribeViewController : UIViewController!
    @objc var configurationViewController : UIViewController!
    
    @objc var iotDataManager: AWSIoTDataManager!
    @objc var iotManager: AWSIoTManager!
    @objc var iot: AWSIoT!
    
    @IBOutlet var myLabel: UILabel!
    @IBOutlet var heartRateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        myLabel.text = "Slider Value "
    }
    
    func onHeartRateReceived(_ heartRate: Int) {
        heartRateLabel.text = "BPM \(heartRate)"
        self.heartRateValue = heartRate
        
        if self.AWSIOTConnectStatus {
            iotDataManager.publishString("\(heartRate)",
            onTopic:"testble",
            qoS:.messageDeliveryAttemptedAtMostOnce)
        }
        
//        print("BLE Value: \(heartRate)")
    }
    
    @IBAction func sliderDidSlide(_ sender: UISlider) {
        let value =  sender.value
        myLabel.text = "Slider Value: \(value)"
        
        // publish message
        iotDataManager.publishString("\(value)",
            onTopic:"slider",
            qoS:.messageDeliveryAttemptedAtMostOnce)
        
        //

    }
    
    @IBAction func pressAWSIoTConnectButton() {
        
        // AWS cognito id
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:AWS_REGION,
                                                                identityPoolId:IDENTITY_POOL_ID)
        initializeControlPlane(credentialsProvider: credentialsProvider)
        initializeDataPlane(credentialsProvider: credentialsProvider)
        iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
        
        // Load p12 and connect to AWS Iot
        let certificateIdInBundle = searchForExistingCertificateIdInBundle()
        
        print(certificateIdInBundle ?? "")
        
        //
        
    }
    
    func mqttEventCallback( _ status: AWSIoTMQTTStatus ) {
        print("status \(status.rawValue)")
        
        switch status {
        case .connecting:
            print("connecting")
        case .connected:
            print("connected")
            self.AWSIOTConnectStatus = true
        default:
            print("unknown")
        }
        
    }
    
    func searchForExistingCertificateIdInBundle() -> String? {
        let defaults = UserDefaults.standard
        // No certificate ID has been stored in the user defaults; check to see if any .p12 files
        // exist in the bundle.
        let myBundle = Bundle.main
        let myImages = myBundle.paths(forResourcesOfType: "p12" as String, inDirectory:nil)
        let uuid = UUID().uuidString
        
        guard let certId = myImages.first else {
            let certificateId = defaults.string(forKey: "certificateId")
            return certificateId
        }
        
        // A PKCS12 file may exist in the bundle.  Attempt to load the first one
        // into the keychain (the others are ignored), and set the certificate ID in the
        // user defaults as the filename.  If the PKCS12 file requires a passphrase,
        // you'll need to provide that here; this code is written to expect that the
        // PKCS12 file will not have a passphrase.
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: certId)) else {
            print("[ERROR] Found PKCS12 File in bundle, but unable to use it")
            let certificateId = defaults.string( forKey: "certificateId")
            return certificateId
        }
        
        if AWSIoTManager.importIdentity( fromPKCS12Data: data, passPhrase:"", certificateId:certId) {
            // Set the certificate ID and ARN values to indicate that we have imported
            // our identity from the PKCS12 file in the bundle.
            defaults.set(certId, forKey:"certificateId")
            defaults.set("from-bundle", forKey:"certificateArn")
            DispatchQueue.main.async {
                self.iotDataManager.connect( withClientId: uuid,
                                             cleanSession:true,
                                             certificateId:certId,
                                             statusCallback: self.mqttEventCallback)
            }
        }
        
        let certificateId = defaults.string( forKey: "certificateId")
        return certificateId
    }
    
    
    func initializeControlPlane(credentialsProvider: AWSCredentialsProvider) {
        //Initialize control plane
        // Initialize the Amazon Cognito credentials provider
        let controlPlaneServiceConfiguration = AWSServiceConfiguration(region:AWS_REGION, credentialsProvider:credentialsProvider)
        
        //IoT control plane seem to operate on iot.<region>.amazonaws.com
        //Set the defaultServiceConfiguration so that when we call AWSIoTManager.default(), it will get picked up
        AWSServiceManager.default().defaultServiceConfiguration = controlPlaneServiceConfiguration
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
    }
    
    func initializeDataPlane(credentialsProvider: AWSCredentialsProvider) {
        //Initialize Dataplane:
        // IoT Dataplane must use your account specific IoT endpoint
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        // Configuration for AWSIoT data plane APIs
        let iotDataConfiguration = AWSServiceConfiguration(region: AWS_REGION,
                                                           endpoint: iotEndPoint,
                                                           credentialsProvider: credentialsProvider)
        //IoTData manager operates on xxxxxxx-iot.<region>.amazonaws.com
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: AWS_IOT_DATA_MANAGER_KEY)
        iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices:nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        @unknown default:
            fatalError()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Stop scan
        centralManager.stopScan()
        
        // Print peripheral
        print(peripheral)
        
        // Copy of peripheral instance
        heartRatePeripheral = peripheral
        heartRatePeripheral.delegate = self
        
        // Connect
        centralManager.connect(heartRatePeripheral, options: nil)
        
        //
        print(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
    }
}

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        print("discovering services ...")
        
        guard let services = peripheral.services else { return }
        for service in services {
            print(service)
            peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicCBUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case bodySensorLocationCharacteristicCBUUID:
            //      print("body location")
//            print(heartRate(from: characteristic))
            let bpm = heartRate(from: characteristic)
            onHeartRateReceived(bpm)
            //      let bodySensorLocation = bodyLocation(from: characteristic)
        //      bodySensorLocationLabel.text = bodySensorLocation
        case heartRateMeasurementCharacteristicCBUUID:
            print(heartRate(from: characteristic))
            //      let bpm = heartRate(from: characteristic)
        //      onHeartRateReceived(bpm)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
            let byte = characteristicData.first else { return "Error" }
        
        switch byte {
        case 0: return "Other"
        case 1: return "Chest"
        case 2: return "Wrist"
        case 3: return "Finger"
        case 4: return "Hand"
        case 5: return "Ear Lobe"
        case 6: return "Foot"
        default:
            return "Reserved for future use"
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        // See: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.heart_rate_measurement.xml
        // The heart rate mesurement is in the 2nd, or in the 2nd and 3rd bytes, i.e. one one or in two bytes
        // The first byte of the first bit specifies the length of the heart rate data, 0 == 1 byte, 1 == 2 bytes
        //    let firstBitValue = byteArray[0] & 0x01
        //    if firstBitValue == 0 {
        //      // Heart Rate Value Format is in the 2nd byte
        //      return Int(byteArray[1])
        //    } else {
        //      // Heart Rate Value Format is in the 2nd and 3rd bytes
        //      return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        //    }
        
        return Int(byteArray[0])
        
    }
}
