//
//  Constant.swift
//  AWSIoTSlider
//
//  Created by hai on 29/11/20.
//  Copyright © 2020 biorithm. All rights reserved.
//

import Foundation
import AWSCore

//WARNING: To run this sample correctly, you must set the following constants.

let CertificateSigningRequestCommonName = "IoTSampleSwift Application"
let CertificateSigningRequestCountryName = "Your Country"
let CertificateSigningRequestOrganizationName = "Your Organization"
let CertificateSigningRequestOrganizationalUnitName = "Your Organizational Unit"

let POLICY_NAME = "IoSAWSIoT"

// This is the endpoint in your AWS IoT console. eg: https://xxxxxxxxxx.iot.<region>.amazonaws.com
let AWS_REGION = AWSRegionType.APSoutheast1

//For both connecting over websockets and cert, IOT_ENDPOINT should look like
//https://xxxxxxx-ats.iot.REGION.amazonaws.com
let IOT_ENDPOINT = "https://a209xbcpyxq5au-ats.iot.ap-southeast-1.amazonaws.com"
let IDENTITY_POOL_ID = "ap-southeast-1:3cae90a6-2cda-42ab-9965-7c199ede9e51"

//Used as keys to look up a reference of each manager
let AWS_IOT_DATA_MANAGER_KEY = "MyIotDataManager"
let AWS_IOT_MANAGER_KEY = "MyIotManager"

